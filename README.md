# Fedora setup

A backup of this Fedora 41 + Hyprland setup, so a fresh install can be turned
back into it.

## Restore on a new Fedora

```bash
sudo dnf install -y git gh rsync
gh auth login
gh repo clone MohammeSafin/fedora-setup ~/fedora-setup
cd ~/fedora-setup
./restore.sh --dry-run   # look at what it will do
./restore.sh
```

Then log out and back in.

`restore.sh` adds the repos (RPM Fusion, COPRs, Docker, Chrome, VS Code,
git-lfs), installs the dnf packages, Flatpaks, Snaps, npm/uv tools and VS Code
extensions, sets up oh-my-zsh and zsh, copies the configs into `$HOME`, loads
dconf settings and enables the user services. Any file it would overwrite is
moved to `~/fedora-setup-restore-backup-<date>/` first. Packages that no longer
exist on a newer Fedora are skipped, not fatal.

### Still manual

- Packages installed from downloaded `.rpm` files, listed in
  `packages/rpm-from-file.txt`. `restore.sh` prints them at the end. For example,
  JuhRadial MX: <https://github.com/JuhLabs/juhradial-mx/releases>.
- Fonts (2+ GB, too big for git): copy them into `~/.local/share/fonts` and run
  `fc-cache -f`. `packages/fonts-user-files.txt` lists the files.
- Secrets, which are never stored here: `~/.ssh`, `~/.gnupg`, `~/.npmrc`, the
  `gh` login, browser profiles, app logins. Keep your own secure copy of `~/.ssh`
  and `~/.gnupg`.

## Update the backup

```bash
cd ~/fedora-setup
./backup.sh
git add -A && git commit -m "Update backup" && git push
```

`backup.sh` stops before you commit if any file looks like it holds a secret
(GitHub/OpenAI/AWS/Slack tokens or private keys).

## What's inside

| Path | Contents |
|---|---|
| `packages/dnf-userinstalled.txt` | dnf packages you installed (dependencies come back on their own) |
| `packages/coprs.txt`, `packages/repos/`, `packages/rpmfusion.txt` | Extra repositories |
| `packages/flatpaks.txt`, `packages/snaps.txt` | Flatpak and Snap apps |
| `packages/npm-global.txt`, `uv-tools.txt`, `cargo.txt`, `vscode-extensions.txt` | Tools installed outside dnf |
| `packages/systemd-user-enabled.txt` | Enabled user services (e.g. `ydotoold` for JuhRadial) |
| `home/` | Configs, mirrored at their `$HOME` paths: Hyprland, Waybar, rofi, swaync, wlogout, ags, Kvantum/Qt/GTK themes, kitty, nvim, btop, fastfetch, JuhRadial, Thunar, zsh/bash, git, VS Code settings, `~/.local/bin` scripts, `.desktop` overrides, wallpapers |
| `dconf.ini` | GNOME/GTK settings (`dconf dump /`) |

### Custom pieces worth knowing

- `~/.local/bin/juhradial-switcher` is the macOS-style app switcher (Alt+Tab, or
  hold the MX Master gesture button). Its bindings are at the end of
  `~/.config/hypr/UserConfigs/UserKeybinds.conf`.
- `~/.config/systemd/user/ydotoold.service` runs ydotool, which JuhRadial needs to
  send keys (thumb-wheel volume and so on).
- `~/.local/share/applications/juhradial-mx.desktop` makes the JuhRadial MX menu
  entry open its settings window.
