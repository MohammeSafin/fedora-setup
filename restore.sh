#!/usr/bin/bash
# Rebuild this setup on a fresh Fedora install.
#
#   ./restore.sh --dry-run   print every step without changing anything
#   ./restore.sh             do it (asks for sudo)
#
# Existing files in $HOME that would be overwritten are moved to
# ~/fedora-setup-restore-backup-<date>/ first.
set -uo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
pkgs="$repo/packages"
dry=0
[ "${1:-}" = "--dry-run" ] && dry=1

say() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
run() {
  if [ $dry -eq 1 ]; then
    printf '   %s\n' "$*"
  else
    "$@" || printf '\033[1;33m   (failed, continuing): %s\033[0m\n' "$*"
  fi
}
list() { [ -s "$1" ] && grep -v '^\s*$' "$1"; }

fedora="$(rpm -E %fedora)"
say "Restoring onto Fedora $fedora (backup was taken on: $(cat "$pkgs/fedora-release.txt"))"

# ------------------------------------------------------------------ repos
say "Repositories"
run sudo dnf install -y dnf-plugins-core
if grep -q free "$pkgs/rpmfusion.txt" 2>/dev/null; then
  run sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$fedora.noarch.rpm"
fi
if grep -q nonfree "$pkgs/rpmfusion.txt" 2>/dev/null; then
  run sudo dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fedora.noarch.rpm"
fi
list "$pkgs/coprs.txt" | while read -r copr; do
  run sudo dnf copr enable -y "$copr"
done
for f in "$pkgs"/repos/*.repo; do
  [ -f "$f" ] && run sudo cp "$f" /etc/yum.repos.d/
done

# --------------------------------------------------------------- packages
say "dnf packages ($(list "$pkgs/dnf-userinstalled.txt" | wc -l))"
# Names that no longer exist on this Fedora release are skipped, not fatal.
mapfile -t dnf_pkgs < <(list "$pkgs/dnf-userinstalled.txt" | grep -v -x -F -f <(list "$pkgs/rpm-from-file.txt" || true))
run sudo dnf install -y --skip-unavailable --skip-broken "${dnf_pkgs[@]}"

if [ -s "$pkgs/flatpaks.txt" ]; then
  say "Flatpaks"
  run sudo dnf install -y flatpak
  while read -r name url; do
    [ -n "$name" ] && run flatpak remote-add --user --if-not-exists "$name" "$url"
  done <"$pkgs/flatpak-remotes.txt"
  while read -r origin app; do
    [ -n "$app" ] && run flatpak install -y --noninteractive "$origin" "$app"
  done <"$pkgs/flatpaks.txt"
fi

if [ -s "$pkgs/snaps.txt" ]; then
  say "Snaps"
  run sudo dnf install -y snapd
  run sudo ln -sf /var/lib/snapd/snap /snap
  while read -r snap channel confinement; do
    # Runtimes and themes come back as dependencies.
    case "$snap" in core | core[0-9]* | bare | snapd | gnome-* | gtk-common-themes | kf5-* | mesa-*) continue ;; esac
    if [ "$channel" = "-" ] || [ -z "$channel" ]; then channel=stable; fi
    if [ "$confinement" = "classic" ]; then
      run sudo snap install "$snap" --classic --channel="$channel"
    else
      run sudo snap install "$snap" --channel="$channel"
    fi
  done <"$pkgs/snaps.txt"
fi

# ---------------------------------------------------------- language tools
say "npm / uv / cargo / VS Code extensions"
command -v npm >/dev/null && list "$pkgs/npm-global.txt" | while read -r p; do run npm install -g "$p"; done
command -v uv >/dev/null && list "$pkgs/uv-tools.txt" | while read -r p; do run uv tool install "$p"; done
command -v cargo >/dev/null && list "$pkgs/cargo.txt" | while read -r p; do run cargo install "$p"; done
command -v code >/dev/null && list "$pkgs/vscode-extensions.txt" | while read -r e; do run code --install-extension "$e"; done

# ------------------------------------------------------------------ shell
say "Shell"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  run git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
while read -r dir url; do
  [ -n "$url" ] && [ ! -d "$HOME/.oh-my-zsh/custom/$dir" ] &&
    run git clone --depth 1 "$url" "$HOME/.oh-my-zsh/custom/$dir"
done < <(list "$pkgs/omz-plugins.txt")
shell="$(cat "$pkgs/login-shell.txt" 2>/dev/null)"
if [ -n "$shell" ] && [ "$(basename "$SHELL")" != "$shell" ]; then
  run sudo usermod --shell "$(command -v "$shell" || echo "/usr/bin/$shell")" "$USER"
fi

# ----------------------------------------------------------------- configs
say "Configs (existing files are moved aside first)"
saved="$HOME/fedora-setup-restore-backup-$(date +%Y%m%d-%H%M%S)"
(cd "$repo/home" && find . -type f -o -type l) | sed 's#^\./##' | while read -r rel; do
  if [ -e "$HOME/$rel" ] && ! cmp -s "$repo/home/$rel" "$HOME/$rel"; then
    run mkdir -p "$saved/$(dirname "$rel")"
    run mv "$HOME/$rel" "$saved/$rel"
  fi
done
run rsync -a "$repo/home/" "$HOME/"
[ -d "$saved" ] && echo "   Previous versions of overwritten files: $saved"

if [ -s "$repo/dconf.ini" ] && command -v dconf >/dev/null; then
  run sh -c "dconf load / < '$repo/dconf.ini'"
fi

# --------------------------------------------------------------- services
say "User services"
run systemctl --user daemon-reload
list "$pkgs/systemd-user-enabled.txt" | while read -r unit; do
  # Only units whose file exists here (installed by a package or restored above).
  systemctl --user cat "$unit" >/dev/null 2>&1 && run systemctl --user enable "$unit"
done

# ------------------------------------------------------------------ manual
say "Left for you"
if [ -s "$pkgs/rpm-from-file.txt" ]; then
  echo "   These were installed from downloaded .rpm files; download and install them again:"
  sed 's/^/     - /' "$pkgs/rpm-from-file.txt"
fi
echo "   - Fonts: copy your font files to ~/.local/share/fonts (list: packages/fonts-user-files.txt), then run fc-cache -f"
echo "   - Sign in again: GitHub (gh auth login), browsers, apps. Restore ~/.ssh and ~/.gnupg from your own secure copy."
echo "   - Log out and back in so Hyprland, the shell and user services pick everything up."
