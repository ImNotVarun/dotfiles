#!/bin/bash
set -e

REPO="git@github.com:ImNotVarun/dotfiles.git"
DOTFILES="$HOME/.dotfiles"

echo "==> Setting up dotfiles for Varun's Arch + Niri setup"

# ── 1. Install git if somehow missing ────────────────────────────────
sudo pacman -S --needed --noconfirm git base-devel

# ── 2. Clone bare dotfiles repo ──────────────────────────────────────
git clone --bare "$REPO" "$DOTFILES"

dotfiles() {
  git --git-dir="$DOTFILES/" --work-tree="$HOME" "$@"
}

# ── 3. Backup any conflicting files ──────────────────────────────────
echo "==> Backing up conflicting files to ~/.dotfiles-backup/"
mkdir -p "$HOME/.dotfiles-backup"
dotfiles checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | \
  xargs -I{} sh -c 'mkdir -p "$HOME/.dotfiles-backup/$(dirname {})" && mv "$HOME/{}" "$HOME/.dotfiles-backup/{}"' 2>/dev/null || true

dotfiles checkout
dotfiles config --local status.showUntrackedFiles no

# ── 4. Install paru (AUR helper) ─────────────────────────────────────
echo "==> Installing paru..."
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si --noconfirm && cd ~

# ── 5. Install official packages ─────────────────────────────────────
echo "==> Installing packages from pkglist.txt..."
sudo pacman -S --needed --noconfirm - < "$HOME/pkglist.txt"

# ── 6. Install AUR packages ──────────────────────────────────────────
echo "==> Installing AUR packages from aurlist.txt..."
paru -S --needed --noconfirm - < "$HOME/aurlist.txt"

# ── 7. Install flatpaks ──────────────────────────────────────────────
echo "==> Installing flatpaks..."
flatpak install -y $(cat "$HOME/flatpak.txt" | tr '\n' ' ')

# ── 8. Restore Plymouth theme ────────────────────────────────────────
echo "==> Restoring Plymouth ifruit theme..."
sudo cp -r "$HOME/dotfiles-system/plymouth/ifruit" /usr/share/plymouth/themes/
sudo cp "$HOME/dotfiles-system/plymouth/plymouthd.conf" /etc/plymouth/
sudo plymouth-set-default-theme -R ifruit

# ── 9. Restore bootloader config ─────────────────────────────────────
echo "==> Restoring bootloader entries..."
sudo cp "$HOME/dotfiles-system/bootloader/"*.conf /boot/loader/entries/ 2>/dev/null || true
sudo cp "$HOME/dotfiles-system/bootloader/loader.conf" /boot/loader/ 2>/dev/null || true

# ── 10. Restore TLP config ───────────────────────────────────────────
echo "==> Restoring TLP config..."
sudo cp "$HOME/dotfiles-system/tlp.conf" /etc/tlp.conf

# ── 11. Enable systemd services ──────────────────────────────────────
echo "==> Enabling system services..."
sudo systemctl enable --now NetworkManager preload tlp windscribe-helper systemd-resolved

echo "==> Enabling user services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# ── 12. Set fish as default shell ────────────────────────────────────
echo "==> Setting fish as default shell..."
chsh -s $(which fish)

echo ""
echo "✓ All done! Reboot and you're home."
echo "  Don't forget to: set your wallpaper, log into Windscribe, Spotify, Brave"
