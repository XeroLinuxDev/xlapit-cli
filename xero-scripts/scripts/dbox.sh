#!/usr/bin/env bash
set -e

# Add this at the start of the script, right after the shebang
trap 'clear && exec "$0"' INT

# Check if being run from xero-cli
if [ -z "$AUR_HELPER" ]; then
    echo
    gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 196 "$(gum style --foreground 196 'ERROR: This script must be run through the toolkit.')"
    echo
    gum style --border normal --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 33 "$(gum style --foreground 33 'Or use this command instead:') $(gum style --bold --foreground 47 'clear && xero-cli')"
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

# Add this before process_choice function
# Determine AUR helper
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
        sudo -K
        if ! sudo pacman -S --noconfirm --needed docker docker-compose docker-buildx; then
            gum style --foreground 196 "Failed to install Docker packages."
            sleep 2
            clear && exec "$0"
        fi
        sudo -K
        if ! sudo systemctl enable --now docker.service && sudo groupadd docker && sudo usermod -aG docker $USER; then
        gum style --foreground 196 "Failed to enable Docker service"
        exit 1
    fi
        echo
        if gum confirm "Do you want to install Podman Desktop ?"; then
            if ! flatpak install io.podman_desktop.PodmanDesktop -y; then
                gum style --foreground 196 "Failed to install Podman Desktop."
                sleep 2
            fi
        else
            echo "Podman Desktop installation skipped."
        fi
        sleep 2
        echo
        sudo -K
        if ! sudo systemctl enable --now docker; then
            gum style --foreground 196 "Failed to enable Docker service."
            sleep 2
            clear && exec "$0"
        fi
        sudo -K
        if ! sudo usermod -aG docker "$USER"; then
            gum style --foreground 196 "Failed to add user to docker group."
            sleep 2
            clear && exec "$0"
        fi
        sudo -K
        sleep 2
        gum style --foreground 7 "Docker setup complete!"
        sleep 3
        clear && exec "$0"
        ;;
      2)
        gum style --foreground 7 "Installing & Setting up Podman..."
        sleep 2
        echo
        sudo -K
        if ! sudo pacman -S --noconfirm --needed podman podman-docker; then
            gum style --foreground 196 "Failed to install Podman packages."
            sleep 2
            clear && exec "$0"
        fi
        sudo -K
        if ! sudo systemctl enable --now podman.socket; then
            gum style --foreground 196 "Failed to enable Podman socket."
            sleep 2
            clear && exec "$0"
        fi
        echo
        if gum confirm "Do you want to install Podman Desktop?"; then
            if ! flatpak install flathub io.podman_desktop.PodmanDesktop -y; then
                gum style --foreground 196 "Failed to install Podman Desktop."
                sleep 2
            fi
        else
            echo "Podman Desktop installation skipped."
        fi
        sleep 2
        gum style --foreground 7 "Podman setup complete!"
        sleep 3
        clear && exec "$0"
        ;;
      3)
        gum style --foreground 7 "Installing Distrobox..."
        sleep 2
        echo
        sudo -K
        if ! sudo pacman -S --noconfirm --needed distrobox; then
            gum style --foreground 196 "Failed to install Distrobox."
            sleep 2
            clear && exec "$0"
        fi
        sudo -K
        if ! flatpak install -y io.github.dvlv.boxbuddyrs; then
            gum style --foreground 196 "Failed to install BoxBuddyRs."
            sleep 2
            clear && exec "$0"
        fi
        echo
        gum style --foreground 7 "Distrobox installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      r)
        gum style --foreground 33 "Rebooting System..."
        sleep 3
        # Countdown from 5 to 1
        for i in {5..1}; do
            dialog --infobox "Rebooting in $i seconds..." 3 30
            sleep 1
        done

        # Reboot after the countdown
        reboot
        sleep 3
        ;;
      q)
        clear && exec xero-cli
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
