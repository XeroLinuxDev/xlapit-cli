#!/usr/bin/env bash
set -e

# Source common functions
source "$(dirname "$0")/common.sh"

# Check for root and clear sudo cache before AUR operations
check_root_and_clear_cache

# Add this at the start of the script, right after the shebang
trap 'clear && exec "$0"' INT

# Check if being run from xero-cli
if [ -z "$AUR_HELPER" ]; then
    echo
    gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 196 "$(gum style --foreground 196 'ERROR: This script must be run through the toolkit.')"
    echo
    gum style --border normal --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 33 "$(gum style --foreground 33 'Or use this command instead:') $(gum style --bold --foreground 47 'clear && xero-cli -m')"
    echo
    exit 1
fi

# Function to display header
display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "XeroLinux Distrobox/Docker/Podman Tool"
  echo
  gum style --foreground 33 "Hello $USER, what would you like to do ?"
  echo
}

# Function to display options
display_options() {
  gum style --foreground 215 "=== Docker/DistroBox/Podman ==="
  echo
  gum style --foreground 7 "1. Install Docker."
  gum style --foreground 7 "2. Install Podman."
  gum style --foreground 7 "3. Install Distrobox."
}

# Dependency check for yay or paru
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
else
    gum style --foreground 196 "Error: No supported AUR helper (yay or paru) found"
    exit 1
fi

# Function to process user choice
process_choice() {
  # Check if AUR_HELPER is set
  if [ -z "$AUR_HELPER" ]; then
    gum style --foreground 196 "Error: AUR_HELPER variable is not set"
    sleep 3
    exit 1
  fi

  while :; do
    echo
    read -rp "Enter your choice, 'r' to reboot or 'q' for main menu : " CHOICE
    echo

    case $CHOICE in
      1)
        gum style --foreground 7 "Installing & Setting up Docker..."
        sleep 2
        echo
        sudo pacman -S --noconfirm --needed docker docker-compose docker-buildx || handle_error
        $AUR_HELPER -S --noconfirm --needed lazydocker-bin || handle_error
        # Prompt the user
        echo
        gum confirm "Do you want to install Podman Desktop ?" && \
            flatpak install io.podman_desktop.PodmanDesktop -y || \
            echo "Podman Desktop installation skipped."
        sleep 2
        echo
        sudo systemctl enable --now docker || handle_error
        sudo usermod -aG docker "$USER" || handle_error
        sudo -K
        sleep 3
        gum style --foreground 7 "Docker setup complete!"
        sleep 3
        clear && exec "$0"
        ;;
      2)
        # Define error handling function
        handle_error() {
            echo "An error occurred. Exiting..."
            exit 1
        }

        gum style --foreground 7 "Installing & Setting up Podman..."
        sleep 2
        echo
        # Install Podman and related packages
        sudo pacman -S --noconfirm --needed podman podman-docker || handle_error
        
        # Enable and start required services
        sudo systemctl enable --now podman.socket || handle_error
        
        # Note: Removed usermod command as Podman doesn't require a special group
        # on most systems for rootless containers
        
        # Install Podman Desktop from Flathub
        echo
        gum confirm "Do you want to install Podman Desktop?" && \
            flatpak install flathub io.podman_desktop.PodmanDesktop -y || \
            echo "Podman Desktop installation skipped."
        
        sleep 2
        gum style --foreground 7 "Podman setup complete!"
        sudo -K
        sleep 3
        clear && exec "$0"
        ;;
      3)
        gum style --foreground 7 "Installing Distrobox..."
        sleep 2
        echo
        sudo pacman -S --noconfirm --needed distrobox || handle_error
        flatpak install -y io.github.dvlv.boxbuddyrs
        echo
        gum style --foreground 7 "Distrobox installation complete!"
        sudo -K
        sleep 3
        clear && exec "$0"
        ;;
      r)
        gum style --foreground 33 "Rebooting System..."
        sleep 3
        if confirm_prompt "Do you want to reboot now?"; then
          reboot
        else
          echo "Please reboot your system to apply the changes."
        fi
        ;;
      q)
        clear && exec xero-cli -m
        ;;
      *)
        gum style --foreground 31 "Invalid choice. Please select a valid option."
        echo
        ;;
    esac
    sleep 3
  done
}

# Main execution
display_header
display_options
process_choice
