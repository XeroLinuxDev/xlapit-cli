#!/usr/bin/env bash
set -e

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

# Function to display the menu
display_menu() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Initial System Setup"
  echo
  gum style --foreground 141 "Hello $USER, please select an option."
  echo
  gum style --foreground 46 "u. Update System (Simple/Extended/Adv.)."
  echo
  gum style --foreground 7 "1. Fix PipeWire & Bluetooth (Vanilla Arch)."
  gum style --foreground 7 "2. Activate Flathub Repositories (Vanilla Arch)."
  gum style --foreground 7 "3. Enable Multithreaded Compilation (Vanilla Arch)."
  gum style --foreground 7 "4. Install 3rd-Party GUI or TUI Package Manager(s)."
  echo
  gum style --foreground 122 "i. Download latest (official) Arch Linux ISO."
  gum style --foreground 190 "f. Enable Fingerprint Auth. Service (KDE Only)."
  gum style --foreground 39 "a. Install Multi-A.I Model Chat G.U.I (Local/LMStudio)."
  gum style --foreground 212 "p. Change ParallelDownloads value for faster installs."
}

# Function to change parallel downloads
parallel_downloads() {
  sudo pmpd
  clear && exec "$0"
}

# Function for each task
install_pipewire_bluetooth() {
    # Check if running on XeroLinux
    if grep -q "XeroLinux" /etc/os-release; then
        gum style --foreground 49 "This option is already pre-configured."
        echo
        sleep 3
        exec "$0"
        return
    fi

    # Proceed with installation for Vanilla Arch
    gum style --foreground 213 "Vanilla Arch Detected - Proceeding..."
    echo
    
    gum style --foreground 35 "Installing PipeWire/Bluetooth Packages..."
    echo
    sleep 2

    # Check if jack2 is installed
    if pacman -Q jack2 &>/dev/null; then
        gum style --foreground 6 "Removing jack2 package..."
        sudo pacman -Rdd --noconfirm jack2
    else
        gum style --foreground 6 "jack2 package not found, skipping removal..."
    fi
    echo
    
    gum style --foreground 6 "Installing audio packages..."
    sudo pacman -S --needed --noconfirm gstreamer gst-libav gst-plugins-bad gst-plugins-base \
        gst-plugins-ugly gst-plugins-good libdvdcss alsa-utils alsa-firmware pavucontrol \
        pipewire-jack lib32-pipewire-jack pipewire-support ffmpeg ffmpegthumbs ffnvcodec-headers
    echo

    gum style --foreground 6 "Installing Bluetooth packages..."
    sudo pacman -S --needed --noconfirm bluez bluez-utils bluez-plugins bluez-hid2hci \
        bluez-cups bluez-libs bluez-tools
    echo

    gum style --foreground 6 "Enabling Bluetooth service..."
    sudo systemctl enable --now bluetooth.service
    echo

    gum style --foreground 2 "PipeWire/Bluetooth Packages installation complete!"
    echo
    sleep 3
    exec "$0"
}

# Function to Enable Fingerprint Service
enable_fprintd() {
  gum style --foreground 7 "Enabling Fingerprint Service..."
  echo
  sudo systemctl enable --now fprintd.service
  echo
  gum style --foreground 7 "Service enabled, open User Settings for configuration..."
  sleep 6
  clear && exec "$0"
}

install_topgrade_aio_updater() {
  if ! command -v topgrade &> /dev/null; then
    gum style --foreground 7 "Topgrade not installed, installing it..."
    sleep 2
    echo
    $AUR_HELPER -S --noconfirm --needed topgrade-bin
  fi
  gum style --foreground 7 "Running Topgrade..."
  topgrade
  echo
  gum style --foreground 7 "Done, Systemm updated."
  sleep 3
  exec "$0"
}

activate_flathub_repositories() {
    # Check if running on XeroLinux
        gum style --foreground 7 "Activating Flathub Repositories..."
        sleep 2
        echo
        sudo pacman -S --noconfirm --needed flatpak
        echo
        gum style --foreground 7 "##########    Activating Flatpak Overrides.    ##########"
        sudo flatpak override --filesystem="$HOME/.themes"
        sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
        sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro
        echo
        gum style --foreground 7 "##########     Flatpak Overrides Activated     ##########"
        echo
        gum style --foreground 7 "Flathub Repositories activated! Please reboot."
    sleep 3
    exec "$0"
}

enable_multithreaded_compilation() {
    # Check if running on XeroLinux
    if grep -q "XeroLinux" /etc/os-release; then
        gum style --foreground 49 "This option is already pre-configured."
        echo
        sleep 5
        exec "$0"
        return
    fi

    # Proceed with installation for Vanilla Arch
    gum style --foreground 213 "Vanilla Arch Detected, Proceeding..."
    sleep 2
    echo
    numberofcores=$(grep -c ^processor /proc/cpuinfo)
    if [ "$numberofcores" -gt 1 ]; then
        sudo sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$((numberofcores+1))\"/" /etc/makepkg.conf
        sudo sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/" /etc/makepkg.conf
        sudo sed -i "s/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/" /etc/makepkg.conf
        sudo sed -i "s/PKGEXT='.pkg.tar.xz'/PKGEXT='.pkg.tar.zst'/" /etc/makepkg.conf
    fi
    gum style --foreground 7 "Multithreaded Compilation enabled!"
    sleep 3
    exec "$0"
}

download_latest_arch_iso() {
    local base_url="https://mirror.fra10.de.leaseweb.net/archlinux/iso/latest/"
    local html iso_file year month day month_name day_suffix download_dir="$HOME/Downloads/ArchISO"

    html=$(curl -s "$base_url")
    iso_file=$(echo "$html" | grep -oP 'archlinux-\d{4}\.\d{2}\.\d{2}-x86_64\.iso' | head -n 1)

    if [[ -z "$iso_file" ]]; then
        gum style --foreground 196 "Could not detect ISO filename. Check your connection or the mirror."
        echo
        return 1
    fi

    year=$(echo "$iso_file" | cut -d'-' -f2 | cut -d'.' -f1)
    month=$(echo "$iso_file" | cut -d'-' -f2 | cut -d'.' -f2)
    day=$(echo "$iso_file" | cut -d'-' -f2 | cut -d'.' -f3)
    month_name=$(date -d "$year-$month-$day" +%B)

    # Ordinal suffix
    case "$day" in
        01|21|31) day_suffix="st" ;;
        02|22) day_suffix="nd" ;;
        03|23) day_suffix="rd" ;;
        *) day_suffix="th" ;;
    esac

    mkdir -p "$download_dir"

    # Check if ISO already exists
    if [[ -f "$download_dir/$iso_file" ]]; then
        gum style --foreground 214 "Latest Arch ISO already exists, try again later..."
        sleep 8
        echo
        return
    fi

    printf "\033[0;32mLatest available ISO is %s %s%s %s, download? [Y/n]: \033[0m" "$month_name" "${day#0}" "$day_suffix" "$year"
    read confirm
    confirm=${confirm,,}
    confirm=${confirm:-y}

    echo

    if [[ "$confirm" != "y" ]]; then
        gum style --foreground 214 "Download cancelled by user."
        sleep 3
        echo
        return
    fi

    gum style --foreground 51 "Downloading..."
    echo
    sleep 1

    curl --progress-bar -o "$download_dir/$iso_file" "${base_url}${iso_file}"

    echo
    if [[ $? -eq 0 ]]; then
        gum style --foreground 46 "Download complete! You can find the ISO at : $download_dir"
        sleep 10
        echo
    else
        gum style --foreground 196 "Download failed."
        sleep 3
        echo
    fi
}

install_gui_package_managers() {
  gum style --foreground 7 "Installing 3rd-Party GUI Package Managers..."
  sleep 2
  echo

  PACKAGES=$(dialog --checklist "Select GUI Package Managers to install:" 13 60 10 \
    "OctoPi" "Octopi Package Manager" off \
    "PacSeek" "PacSeek Package Manager" off \
    "BauhGUI" "Bauh GUI Package Manager" off \
    "Warehouse" "Flatpak management tool" off \
    "Flatseal" "Flatpak Permissions tool" off \
    "EasyFlatpak" "Flatpak Package Manager" off 6>&1 1>&2 2>&6)

  if [[ $? -ne 0 ]]; then
    echo "Error: Dialog exited with non-zero status. Aborting."
    return 1
  fi

  # Process each package individually
  if [[ "$PACKAGES" == *"OctoPi"* ]]; then
    clear && $AUR_HELPER -S --noconfirm --needed octopi || echo "Error installing OctoPi"
  fi
  if [[ "$PACKAGES" == *"PacSeek"* ]]; then
    clear && $AUR_HELPER -S --noconfirm --needed pacseek pacfinder || echo "Error installing PacSeek"
  fi
  if [[ "$PACKAGES" == *"BauhGUI"* ]]; then
    clear && $AUR_HELPER -S --noconfirm --needed bauh || echo "Error installing BauhGUI"
  fi
  if [[ "$PACKAGES" == *"Warehouse"* ]]; then
    clear && flatpak install -y io.github.flattool.Warehouse || echo "Error installing Warehouse"
  fi
  if [[ "$PACKAGES" == *"Flatseal"* ]]; then
    clear && flatpak install -y com.github.tchx84.Flatseal || echo "Error installing Flatseal"
  fi
  if [[ "$PACKAGES" == *"EasyFlatpak"* ]]; then
    clear && flatpak install -y org.dupot.easyflatpak || echo "Error installing EasyFlatpak"
  fi

  gum style --foreground 7 "3rd-Party GUI Package Managers installation complete!"
  sleep 3
}

install_lmstudio() {
  if pacman -Qs lmstudio > /dev/null; then
    gum style --foreground 46 "LMStudio is already installed!"
    sleep 3
  else
    gum style --foreground 7 "Installing LMStudio from AUR..."
    echo
    sleep 3
    $AUR_HELPER -S lmstudio --noconfirm
    echo
    gum style --foreground 46 "LMStudio has been installed!"
    sleep 4
  fi
  exec "$0"
}

# Function to update system
update_system() {
  sh /usr/local/bin/upd
  sleep 10
  clear && exec "$0"
}

restart() {
  # Notify the user that the system is rebooting
  gum style --foreground 69 "Rebooting System..."
  sleep 3

  # Countdown from 5 to 1
  for i in {5..1}; do
    dialog --infobox "Rebooting in $i seconds..." 3 30
    sleep 1
  done

  # Execute the reboot command
  reboot
}

main() {
  while :; do
    display_menu
    echo
    read -rp "Enter your choice, 'r' to reboot or 'q' for main menu : " CHOICE
    echo

    case $CHOICE in
      1) install_pipewire_bluetooth ;;
      2) activate_flathub_repositories ;;
      3) enable_multithreaded_compilation ;;
      4) install_gui_package_managers ;;
      i) download_latest_arch_iso ;;
      f) enable_fprintd ;;
      a) install_lmstudio ;;
      u) update_system ;;
      p) parallel_downloads ;;
      r) restart ;;
      q) clear && exec xero-cli -m ;;
      *)
        gum style --foreground 50 "Invalid choice. Please select a valid option."
        echo
        ;;
    esac
    sleep 3
  done
}

main
