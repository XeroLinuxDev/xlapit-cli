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
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "System Customization"
  echo
  gum style --foreground 141 "Hello $USER, please select an option."
  echo
}
check_dependency() {
  local dependency=$1
  command -v $dependency >/dev/null 2>&1 || { echo >&2 "$dependency is not installed. Installing..."; sudo pacman -S --noconfirm $dependency; }
}

# Function to display header
display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Gaming Tools & Launchers"
  echo
  gum style --foreground 33 "Hello $USER, select what gaming software to install. Press 'i' for the Wiki."
  echo
}

# Function to install AUR packages
install_aur_packages() {
  $AUR_HELPER -S --noconfirm --needed "$@"
}

# Function to display options
display_options() {
  gum style --foreground 40 ".::: Main (Chaotic-AUR) :::."
  echo
  gum style --foreground 7 "1. Steam + Tools."
  gum style --foreground 7 "2. Game Controllers."
  gum style --foreground 7 "3. LACT GPU-Overclock."
  echo
  gum style --foreground 226 ".::: Extras (Flatpaks) :::."
  echo
  gum style --foreground 7 "4. Heroic."
  gum style --foreground 7 "5. Lutris."
  gum style --foreground 7 "6. Bottles."
  gum style --foreground 7 "7. ProtonPlus."
  echo
  gum style --foreground 196 "Note : Flatpaks = Official, Native = Unofficial."
}

# Helper functions to check if a package is installed
is_pacman_installed() {
    pacman -Q "$1" &>/dev/null
}

is_aur_installed() {
    pacman -Qm "$1" &>/dev/null
}

# Function to display package selection dialog for controllers (gum-based)
controller_selection_dialog() {
    local title=$1
    shift
    local options=("$@")
    local controller_options=()

    # Only add options for drivers that are not installed
    ! is_aur_installed dualsensectl && controller_options+=("DualSense" "DualSense Driver" OFF)
    ! is_aur_installed ds4drv && controller_options+=("DualShock4" "DualShock 4 Driver" OFF)
    ! is_aur_installed xone-dkms && controller_options+=("XBoxOne" "XBOX One Controller Driver" OFF)

    if [ ${#controller_options[@]} -eq 0 ]; then
        gum style --foreground 7 "All supported game controller drivers are already installed."
        sleep 3
        return
    fi

    # Build a list of just the package names for gum choose
    local pkg_names=()
    for ((i=0; i<${#controller_options[@]}; i+=3)); do
        pkg_names+=("${controller_options[i]}")
    done
    clear
    echo
    echo -e "\e[36m[Space]\e[0m to select, \e[33m[ESC]\e[0m to go back & \e[32m[Enter]\e[0m to make it so."
    echo
    # Use gum choose for menu-style multi-select
    PACKAGES=$(printf "%s\n" "${pkg_names[@]}" | gum choose --no-limit --header "$title" --cursor.foreground 212 --selected.background 236) || true

    if [ -n "$PACKAGES" ]; then
        for PACKAGE in $PACKAGES; do
            case $PACKAGE in
                DualSense)
                    clear
                    install_aur_packages dualsensectl game-devices-udev
                    gum style --foreground 7 "_:: Please follow guide on Github for configuration ::_"
                    sleep 2
                    xdg-open "https://github.com/nowrep/dualsensectl"  > /dev/null 2>&1
                    ;;
                DualShock4)
                    clear
                    install_aur_packages ds4drv game-devices-udev
                    gum style --foreground 7 "_:: Please follow guide on Github for configuration ::_"
                    sleep 2
                    xdg-open "https://github.com/chrippa/ds4drv"  > /dev/null 2>&1
                    ;;
                XBoxOne)
                    clear
                    install_aur_packages xone-dkms game-devices-udev
                    gum style --foreground 7 "_:: Please follow guide on Github for configuration ::_"
                    sleep 2
                    xdg-open "https://github.com/medusalix/xone"  > /dev/null 2>&1
                    ;;
                *)
                    gum style --foreground 196 "Unknown package: $PACKAGE"
                    ;;
            esac
        done
    else
        PKG_DIALOG_EXITED=1
        clear
        echo
        echo
        figlet -t -c "No packages selected. Returning to menu." | lolcat
        sleep 10
    fi
}

# Function to install gaming packages
install_gaming_packages() {
  case $1 in
    steam)
      sudo -K
      install_aur_packages steam steam-native-runtime lib32-pipewire-jack gamemode gamescope mangohud mangoverlay lib32-mangohud wine-meta wine-nine ttf-liberation lib32-fontconfig wqy-zenhei vkd3d giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses ocl-icd lib32-ocl-icd libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups dosbox lib32-opencl-icd-loader lib32-vkd3d opencl-icd-loader wine-meta
      sudo -K
      ;;
    bottles)
      flatpak install -y com.usebottles.bottles org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
      ;;
    heroic)
      flatpak install -y com.heroicgameslauncher.hgl org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
      ;;
    lutris)
      flatpak install -y net.lutris.Lutris org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
      ;;
    emulators)
      flatpak install -y org.libretro.RetroArch org.ppsspp.PPSSPP org.DolphinEmu.dolphin-emu org.flycast.Flycast org.pcsx2.PCSX2 flathub net.rpcs3.RPCS3
      ;;
    ProtonPlus)
      flatpak install -y com.vysp3r.ProtonPlus
      ;;
    *)
      echo "Unknown package: $1"
      ;;
  esac
}

# Function to process user choice
process_choice() {
  while :; do
    echo
    read -rp "Enter your choice, or 'q' to return to main menu : " CHOICE
    echo

    case $CHOICE in
      1)
        gum style --foreground 7 "Installing Steam + Mangohud + Gamemode + Gamescope..."
        sleep 2
        echo
        if ! install_gaming_packages steam; then
          gum style --foreground 196 "Failed to install Steam and related packages."
          sleep 2
          clear && exec "$0"
        fi
        sleep 3
        echo
        echo "Applying Download Speed Enhancement Patch..."
        [ ! -d ~/.local/share/Steam ] && mkdir -p ~/.local/share/Steam
        echo -e "@nClientDownloadEnableHTTP2PlatformLinux 0\n@fDownloadRateImprovementToAddAnotherConnection 1.0" > ~/.local/share/Steam/steam_dev.cfg
        sleep 3
        echo
        echo "Patching VM.Max.MapCount"
        echo
        if ! echo "vm.max_map_count=2147483642" | sudo tee /etc/sysctl.d/99-sysctl.conf >/dev/null; then
          gum style --foreground 196 "Failed to patch VM.Max.MapCount."
          sleep 2
          clear && exec "$0"
        fi
        sleep 3
        gum style --foreground 7 "Steam installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      2)
        controller_selection_dialog "Select Controller Driver(s) to install:" \
        "DualSense" "DualSense Driver" OFF \
        "DualShock4" "DualShock 4 Driver" OFF \
        "XBoxOne" "XBOX One Controller Driver" OFF
        sleep 3
        clear && exec "$0"
        ;;
      3)
        gum style --foreground 7 "Installing LACT GPU OC Utility..."
        sleep 2
        echo
        if ! install_aur_packages lact; then
          gum style --foreground 196 "Failed to install LACT."
          sleep 2
          clear && exec "$0"
        fi
        if ! sudo systemctl enable --now lactd; then
          gum style --foreground 196 "Failed to enable lactd service."
          sleep 2
          clear && exec "$0"
        fi
        echo
        gum style --foreground 7 "LACT GPU OC Utility installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      4)
        gum style --foreground 7 "Installing Heroic Games Launcher..."
        sleep 2
        echo
        if ! install_gaming_packages heroic; then
          gum style --foreground 196 "Failed to install Heroic Games Launcher."
          sleep 2
          clear && exec "$0"
        fi
        echo
        gum style --foreground 7 "Heroic Games Launcher installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      5)
        gum style --foreground 7 "Installing Lutris..."
        sleep 2
        echo
        if ! install_gaming_packages lutris; then
          gum style --foreground 196 "Failed to install Lutris."
          sleep 2
          clear && exec "$0"
        fi
        echo
        gum style --foreground 7 "Lutris installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      6)
        gum style --foreground 7 "Installing Bottles..."
        sleep 2
        echo
        if ! install_gaming_packages bottles; then
          gum style --foreground 196 "Failed to install Bottles."
          sleep 2
          clear && exec "$0"
        fi
        echo
        gum style --foreground 7 "Bottles installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      7)
        gum style --foreground 7 "Installing ProtonPlus..."
        sleep 2
        echo
        if ! install_gaming_packages ProtonPlus; then
          gum style --foreground 196 "Failed to install ProtonPlus."
          sleep 2
          clear && exec "$0"
        fi
        echo
        gum style --foreground 7 "ProtonPlus installation complete!"
        sleep 3
        clear && exec "$0"
        ;;
      q)
        clear && exec xero-cli
        ;;
      *)
        gum style --foreground 50 "Invalid choice. Please select a valid option."
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
