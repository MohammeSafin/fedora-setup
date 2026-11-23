#!/usr/bin/bash
# Snapshot this Fedora setup into this repo: package/repo lists, configs,
# scripts and user services. Re-run any time, then commit and push.
#
# Secrets are deliberately left out (~/.ssh, ~/.gnupg, ~/.npmrc, gh login,
# browser profiles); see README.md.
set -uo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
pkgs="$repo/packages"
home_out="$repo/home"
mkdir -p "$pkgs/repos" "$home_out"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- packages
say "Packages and repos"
cat /etc/fedora-release >"$pkgs/fedora-release.txt"

# Packages you installed explicitly (dependencies come back on their own).
dnf repoquery --userinstalled -q --qf '%{name}\n' 2>/dev/null | grep -v '^kmod-' | sort -u >"$pkgs/dnf-userinstalled.txt"
# Of those, the ones installed from a local .rpm file: dnf cannot fetch them
# again, so they are listed for manual download.
dnf repoquery --installed -q --qf '%{name} %{from_repo}\n' 2>/dev/null |
  awk '$2 == "@commandline" {print $1}' |
  grep -v -E '^rpmfusion-(non)?free-release$|^kmod-' | sort -u >"$pkgs/rpm-from-file.txt"
# (RPM Fusion's release packages are set up by restore.sh; kmod-* driver builds
# are kernel-specific and get rebuilt by akmod-*.)
dnf copr list 2>/dev/null | sed 's#^copr.fedorainfracloud.org/##; s# .*##' | sort -u >"$pkgs/coprs.txt"

# Third-party repo files (not Fedora's own, not COPR, not RPM Fusion, which
# restore.sh sets up from its release packages).
rm -f "$pkgs/repos/"*.repo
for f in /etc/yum.repos.d/*.repo; do
  case "${f##*/}" in
    fedora*.repo | _copr:* | rpmfusion-*) ;;
    *) cp "$f" "$pkgs/repos/" ;;
  esac
done
ls /etc/yum.repos.d/ | grep -q '^rpmfusion-free' && echo free >"$pkgs/rpmfusion.txt"
ls /etc/yum.repos.d/ | grep -q '^rpmfusion-nonfree' && echo nonfree >>"$pkgs/rpmfusion.txt"

flatpak remotes --columns=name,url 2>/dev/null >"$pkgs/flatpak-remotes.txt"
flatpak list --app --columns=origin,application 2>/dev/null >"$pkgs/flatpaks.txt"
command -v snap >/dev/null && snap list 2>/dev/null | awk 'NR > 1 {print $1, $4, ($6 ~ /classic/ ? "classic" : "-")}' >"$pkgs/snaps.txt"

# Language/tool installs outside dnf.
command -v npm >/dev/null && npm ls -g --depth=0 --parseable 2>/dev/null | tail -n +2 | xargs -r -n1 basename >"$pkgs/npm-global.txt"
command -v uv >/dev/null && uv tool list 2>/dev/null | awk '/^[^ -]/ {print $1}' >"$pkgs/uv-tools.txt"
command -v cargo >/dev/null && cargo install --list 2>/dev/null | awk '/^[^ ]/ {print $1}' >"$pkgs/cargo.txt"
command -v code >/dev/null && code --list-extensions 2>/dev/null >"$pkgs/vscode-extensions.txt"

# Fonts are too big to keep in git (GBs); record what was installed.
fc-list --format '%{family[0]}\n' 2>/dev/null | sort -u >"$pkgs/fonts-all.txt"
find "$HOME/.local/share/fonts" -type f 2>/dev/null | sed "s#^$HOME/.local/share/fonts/##" | sort >"$pkgs/fonts-user-files.txt"

# ----------------------------------------------------------------- configs
say "Configs and scripts"
# Paths relative to $HOME. Folders are copied whole (minus the excludes).
paths=(
  .zshrc .zprofile .bashrc .bash_profile .gitconfig
  .oh-my-zsh/custom
  .config/hypr .config/waybar .config/rofi .config/swaync .config/wlogout .config/ags
  .config/Kvantum .config/qt5ct .config/qt6ct .config/gtk-3.0 .config/gtk-4.0
  .config/kitty .config/nvim .config/btop .config/cava .config/fastfetch .config/neofetch
  .config/wallust .config/swappy .config/nwg-look .config/waypaper .config/xsettingsd
  .config/Thunar .config/xfce4 .config/mpv .config/htop .config/contour .config/qalculate
  .config/juhradial .config/autostart .config/systemd/user
  .config/mimeapps.list .config/user-dirs.dirs .config/user-dirs.locale
  .config/Code/User/settings.json .config/Code/User/keybindings.json
  .local/share/applications
  Pictures/wallpapers
)
# Your own scripts in ~/.local/bin (pip/npm entry points and symlinks are
# reinstalled by their tools instead).
for f in "$HOME"/.local/bin/*; do
  [ -f "$f" ] && [ ! -L "$f" ] || continue
  head -c 400 "$f" | grep -q -E 'from .* import main|sys\.exit\(main|load_entry_point' && continue
  file -b "$f" | grep -q -i text && paths+=(".local/bin/${f##*/}")
done

rm -rf "$home_out"
mkdir -p "$home_out"
for p in "${paths[@]}"; do
  [ -e "$HOME/$p" ] || continue
  mkdir -p "$home_out/$(dirname "$p")"
  rsync -a --delete \
    --exclude '.git' --exclude '*.bak' --exclude '*-backup-back-up_*' \
    --exclude 'mimeinfo.cache' --exclude 'chrome-*.desktop' --exclude 'wine*' \
    --exclude '*.log' --exclude 'cache' --exclude '__pycache__' \
    "$HOME/$p" "$home_out/$(dirname "$p")/"
done

# Plugins in .oh-my-zsh/custom are git clones; keep their URLs to re-clone.
: >"$pkgs/omz-plugins.txt"
for d in "$HOME"/.oh-my-zsh/custom/{plugins,themes}/*/; do
  [ -d "$d/.git" ] || continue
  url="$(git -C "$d" remote get-url origin 2>/dev/null)" || continue
  printf '%s %s\n' "${d#$HOME/.oh-my-zsh/custom/}" "$url" >>"$pkgs/omz-plugins.txt"
done

# ---------------------------------------------------- settings and services
say "dconf settings and user services"
dconf dump / >"$repo/dconf.ini" 2>/dev/null
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null |
  awk '{print $1}' >"$pkgs/systemd-user-enabled.txt"
basename "$SHELL" >"$pkgs/login-shell.txt"

# --------------------------------------------------------- secret check
say "Checking for secrets"
if grep -r -I -l -E 'gh[opsu]_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9_-]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[abp]-[A-Za-z0-9-]{20,}' "$repo" --exclude-dir=.git; then
  echo "!! The files above look like they contain secrets. Remove them before committing." >&2
  exit 1
fi

say "Done: $(du -sh "$repo" --exclude=.git | cut -f1) in $repo"
