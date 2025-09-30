#!/usr/bin/env bash
set -e

# Relaunch on Ctrl+C
trap 'clear && exec "$0"' INT

# Ensure run via xero-cli
if [ -z "$AUR_HELPER" ]; then
  echo
  gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" \
    --border-foreground 196 "$(gum style --foreground 196 'ERROR: Run this script through the toolkit.')"
  echo
  gum style --border normal --align center --width 70 --margin "1 2" --padding "1 2" \
    --border-foreground 33 "$(gum style --foreground 33 'Or use:') $(gum style --bold --foreground 47 'clear && xero-cli')"
  echo
  exit 1
fi

# Helper to restart cleanly
restart_script() { clear && exec "$0"; }

# Detect AUR helper
if command -v yay &>/dev/null; then
  AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
  AUR_HELPER="paru"
else
  gum style --foreground 196 "No AUR helper found. Please install yay or paru."
  exit 1
fi

# Header
display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" \
    --align center "System Customization"
  gum style --foreground 141 "Hello $USER, please select an option."
  echo
}

# Menu
display_options() {
  gum style --foreground 40 ".::: Main Options :::."
  echo
  gum style --foreground 7 "1. Setup ZSH (All-in-one with Plugins)"
  gum style --foreground 7 "2. Install Save Desktop Config Tool (KDE/GNOME)"
  echo
  gum style --foreground 226 ".::: Additional Options :::."
  echo
  gum style --foreground 175 "g. Change GRUB Theme (Xero Script)"
  gum style --foreground 225 "w. Install Plasma Wallpapers (~1.2GB)"
  gum style --foreground 153 "u. Layan GTK4 Patch & Update (Xero-KDE Only)"
}

# --- Actions ---

setup_zsh() {
  gum style --foreground 7 "Setting up ZSH with OMP & OMZ Plugins..."
  sleep 1

  sudo -K
  if ! command -v zsh &>/dev/null; then
    sudo pacman -S --needed --noconfirm zsh grml-zsh-config fastfetch ||
      { gum style --foreground 196 "Failed to install ZSH."; restart_script; }
  fi
  sudo -K

  [[ ! -d "$HOME/.oh-my-zsh" ]] && {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended ||
      { gum style --foreground 196 "Oh-My-Zsh install failed."; restart_script; }
  }

  $AUR_HELPER -S --noconfirm --needed pacseek ttf-meslo-nerd siji-git otf-unifont \
    bdf-unifont noto-color-emoji-fontconfig xorg-fonts-misc ttf-dejavu \
    ttf-meslo-nerd-font-powerlevel10k noto-fonts-emoji powerline-fonts oh-my-posh-bin ||
    { gum style --foreground 196 "Failed installing plugins/fonts."; restart_script; }

  # Plugins
  git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions"
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

  # Config
  cd "$HOME"
  mv -f ~/.zshrc ~/.zshrc.user 2>/dev/null || true
  wget -q https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/.zshrc

  # Switch shell
  if sudo chsh "$USER" -s /bin/zsh; then
    if [[ "$KONSOLE_VERSION" && "$XDG_CURRENT_DESKTOP" == "KDE" ]]; then
      sed -i 's|Command=/bin/bash|Command=/bin/zsh|' "$HOME/.local/share/konsole/XeroLinux.profile" 2>/dev/null || true
    fi
    gum style --foreground 7 "ZSH setup complete! Log out and back in."
  else
    gum style --foreground 196 "Could not set ZSH as default shell."
  fi

  sleep 2
  restart_script
}

install_save_desktop() {
  gum style --foreground 7 "Installing Save Desktop Tool..."
  flatpak install -y io.github.vikdevelop.SaveDesktop ||
    { gum style --foreground 196 "Failed to install Save Desktop Tool."; restart_script; }
  gum style --foreground 7 "Done!"
  sleep 2; restart_script
}

install_grub_theme() {
  gum style --foreground 7 "Applying XeroLinux GRUB theme..."
  cd "$HOME"
  git clone --depth 1 https://github.com/xerolinux/xero-grubs
  cd xero-grubs && sh install.sh
  rm -rf "$HOME/xero-grubs"
  gum style --foreground 7 "Theme applied successfully."
  sleep 2; restart_script
}

install_wallpapers() {
  gum style --foreground 7 "Installing Plasma wallpapers (~1.2GB)..."
  sudo pacman -S --noconfirm --needed kde-wallpapers-extra ||
    { gum style --foreground 196 "Failed to install wallpapers."; restart_script; }
  gum style --foreground 7 "Wallpapers installed!"
  sleep 2; restart_script
}

layan_patch_update() {
  gum style --foreground 200 "Applying Layan GTK4 Patch & Updating Theme..."
  cd "$HOME"

  git clone --depth 1 https://github.com/vinceliuice/Layan-gtk-theme.git
  cd Layan-gtk-theme && sh install.sh -l -c dark -d "$HOME/.themes"
  cd "$HOME" && rm -rf Layan-gtk-theme

  git clone --depth 1 https://github.com/vinceliuice/Layan-kde.git
  cd Layan-kde && sh install.sh
  cd "$HOME" && rm -rf Layan-kde

  gum style --foreground 200 "Layan GTK/KDE updated!"
  sleep 2; restart_script
}

reboot_system() {
  gum style --foreground 33 "Rebooting..."
  for i in {5..1}; do
    dialog --infobox "Rebooting in $i seconds..." 3 30
    sleep 1
  done
  reboot
}

# --- Choice Handler ---

process_choice() {
  while :; do
    echo
    read -rp "Enter your choice (r=reboot, q=quit): " CHOICE
    echo

    case "$CHOICE" in
      1) setup_zsh ;;
      2) install_save_desktop ;;
      g) install_grub_theme ;;
      w) install_wallpapers ;;
      u) layan_patch_update ;;
      r) reboot_system ;;
      q)
        if command -v xero-cli &>/dev/null; then
          clear && exec xero-cli
        else
          gum style --foreground 196 "xero-cli not found. Exiting..."
          exit 1
        fi
        ;;
      *) gum style --foreground 196 "Invalid choice. Try again." ;;
    esac
    sleep 2
  done
}

# --- Main ---
display_header
display_options
process_choice
