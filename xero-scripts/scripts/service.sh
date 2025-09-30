#!/usr/bin/env bash
set -e

# Relaunch cleanly on Ctrl+C
trap 'clear && exec "$0"' INT

# Ensure run through toolkit
# if [[ -z "$AUR_HELPER" ]]; then
#   echo
#   gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" \
#     --border-foreground 196 "$(gum style --foreground 196 'ERROR: This script must be run through the toolkit.')"
#   echo
#   gum style --border normal --align center --width 70 --margin "1 2" --padding "1 2" \
#     --border-foreground 33 "$(gum style --foreground 33 'Or run:') $(gum style --bold --foreground 47 'clear && xero-cli')"
#   echo
#   exit 1
# fi

# --- Helper ---
restart_script() { clear && exec "$0"; }

# --- Menu ---
display_menu() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "System Fixes & Tweaks"
  echo
  gum style --foreground 141 "Hello $USER, what would you like to do today?"
  echo
  gum style --foreground 40 ".::: Main Options :::."
  echo
  gum style --foreground 7  "1. Clear Pacman Cache (Free Space)"
  gum style --foreground 7  "2. Unlock Pacman DB (DB Lock Error)"
  gum style --foreground 7  "3. Install & Enable Plasma X11 Session"
  gum style --foreground 7  "4. Activate v4l2loopback for OBS VirtualCam"
  gum style --foreground 7  "5. Disable Debug flag in MAKEPKG (Pkg Devs)"
  echo
  gum style --foreground 226 ".::: Additional Options :::."
  echo
  gum style --foreground 39  "a. Build Updated Arch ISO"
  gum style --foreground 196 "s. Reset KDE/Xero Layout to Stock"
  gum style --foreground 51  "v. Install VM Guest Utils / Agents"
  gum style --foreground 150 "f. Fix GPGME: NODATA Database Issue"
  gum style --foreground 40  "w. WayDroid Installation Guide (Website)"
  gum style --foreground 111 "g. Fix Arch GnuPG Keyring (Pkg Sig Issues)"
  gum style --foreground 172 "m. Update Arch Mirrorlist (Faster Downloads)"
}

# --- Fix Actions ---

clear_pacman_cache() {
  echo
  sudo pacman -Scc || gum style --foreground 196 "Failed to clear cache."
  sleep 2
  restart_script
}

unlock_pacman_db() {
  echo
  sudo rm -f /var/lib/pacman/db.lck || gum style --foreground 196 "DB lock not found."
  sleep 1
  restart_script
}

activate_v4l2loopback() {
  echo
  gum style --foreground 7 "Setting up v4l2loopback..."
  sudo pacman -S --noconfirm --needed v4l2loopback-dkms v4l2loopback-utils || exit 1
  echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
  echo 'options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"' \
    | sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
  gum style --foreground 7 "Reboot required for changes to take effect."
  sleep 2
  restart_script
}

x11_session() {
  echo
  gum style --foreground 7 "Installing KDE X11 Session..."
  sudo pacman -S --noconfirm kwin-x11 plasma-x11-session
  gum style --foreground 7 "Done! Please reboot to apply."
  sleep 2
  restart_script
}

disable_debug() {
  echo
  gum style --foreground 69 "Disabling Makepkg Debug Flag..."
  echo
  if ! sudo test -w /etc/makepkg.conf; then
    gum style --foreground 196 "Cannot write /etc/makepkg.conf. Run via user with sudo access."
    return
  fi
  if grep -q "!debug lto" /etc/makepkg.conf; then
    gum style --foreground 7 "Debug already disabled."
  else
    sudo sed -i "s/debug lto/!debug lto/g" /etc/makepkg.conf && \
      gum style --foreground 7 "Debug flag disabled." || \
      gum style --foreground 196 "Failed to modify makepkg.conf."
  fi
  sleep 2
  restart_script
}

build_archiso() {
  echo
  gum style --foreground 7 "Building Arch ISO..."
  mkdir -p ~/ArchWork ~/ArchOut
  sudo mkarchiso -v -w ~/ArchWork -o ~/ArchOut /usr/share/archiso/configs/releng || exit 1
  sudo rm -rf ~/ArchWork
  gum style --foreground 7 "Done! Check ~/ArchOut"
  sleep 2
  restart_script
}

gpgme_error() {
  echo
  gum style --foreground 7 "Fixing GPGME Database Issue..."
  sudo rm -rf /var/lib/pacman/sync && sudo pacman -Syy
  gum style --foreground 7 "Done!"
  sleep 2
  restart_script
}

reset_everything() {
  echo
  gum style --foreground 69 "Resetting Layout & Configs..."
  echo
  if gum confirm "Are you using XeroLinux Distro?"; then
    cp -Rf ~/.config ~/.config-backup-$(date +%F-%H%M)
    cp -aT /etc/skel/. "$HOME/"
  else
    cp -Rf ~/.config ~/.config-backup-$(date +%F-%H%M)
    rm -rf ~/.config
  fi

  for i in {5..1}; do
    dialog --infobox "Rebooting in $i seconds..." 3 40
    sleep 1
  done
  reboot
}

waydroid_guide() {
  echo
  gum style --foreground 36 "Opening WayDroid Guide..."
  sleep 1
  xdg-open "https://xerolinux.xyz/posts/waydroid-guide/" >/dev/null 2>&1
  restart_script
}

vm_guest() {
  echo
  gum style --foreground 7 "Detecting VM Environment..."
  local virt
  virt=$(systemd-detect-virt)
  case "$virt" in
    oracle)
      gum style --foreground 7 "Installing VirtualBox Guest Utils..."
      sudo pacman -S --needed --noconfirm virtualbox-guest-utils && reboot
      ;;
    kvm)
      gum style --foreground 7 "Installing QEMU Guest Agent..."
      sudo pacman -S --needed --noconfirm qemu-guest-agent spice-vdagent && reboot
      ;;
    *)
      gum style --foreground 214 "No VM detected."
      ;;
  esac
  sleep 2
  restart_script
}

update_mirrorlist() {
  echo
  gum style --foreground 69 "Updating Mirrorlists..."
  if ! command -v rate-mirrors &>/dev/null; then
    gum style --foreground 214 "Installing rate-mirrors..."
    "$AUR_HELPER" -S --needed --noconfirm rate-mirrors || exit 1
  fi

  if gum confirm "Also update Chaotic-AUR mirrorlist?"; then
    rate-mirrors --allow-root --protocol https arch | sudo tee /etc/pacman.d/mirrorlist
    rate-mirrors --allow-root --protocol https chaotic-aur | sudo tee /etc/pacman.d/chaotic-mirrorlist
  else
    rate-mirrors --allow-root --protocol https arch | sudo tee /etc/pacman.d/mirrorlist
  fi

  sudo pacman -Syy
  gum style --foreground 7 "Mirrorlist update complete!"
  sleep 2
  restart_script
}

fix_gpg_keyring() {
  echo
  gum style --foreground 69 "Fixing GnuPG Keyring..."
  sudo rm -rf /etc/pacman.d/gnupg/*
  sudo pacman-key --init && sudo pacman-key --populate
  echo "keyserver hkp://keyserver.ubuntu.com:80" | sudo tee -a /etc/pacman.d/gnupg/gpg.conf
  sudo pacman -Syy --noconfirm archlinux-keyring
  gum style --foreground 7 "Keyring fix complete!"
  sleep 2
  restart_script
}

restart_system() {
  gum style --foreground 33 "Rebooting..."
  for i in {5..1}; do
    dialog --infobox "Rebooting in $i seconds..." 3 40
    sleep 1
  done
  reboot
}

# --- Main ---

main() {
  if [[ $EUID -eq 0 ]]; then
    gum style --foreground 196 "Do not run this script as root."
    exit 1
  fi

  while true; do
    display_menu
    echo
    read -rp "Enter choice ('r' reboot, 'q' return): " CHOICE
    echo
    case "$CHOICE" in
      1) clear_pacman_cache ;;
      2) unlock_pacman_db ;;
      3) x11_session ;;
      4) activate_v4l2loopback ;;
      5) disable_debug ;;
      a) build_archiso ;;
      f) gpgme_error ;;
      s) reset_everything ;;
      w) waydroid_guide ;;
      v) vm_guest ;;
      m) update_mirrorlist ;;
      g) fix_gpg_keyring ;;
      r) restart_system ;;
      q) clear && exec xero-cli ;;
      *) gum style --foreground 31 "Invalid choice. Try again." ;;
    esac
    sleep 2
  done
}

main
