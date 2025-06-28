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

# Helper functions to check if a package is installed
is_pacman_installed() {
    pacman -Q "$1" &>/dev/null
}

is_aur_installed() {
    pacman -Qm "$1" &>/dev/null
}

is_flatpak_installed() {
    flatpak list --app --columns=application | grep -wq "^$1$"
}

# Function to install AUR packages
install_aur_packages() {
    if [[ -z "$AUR_HELPER" || ! -x "$(command -v $AUR_HELPER)" ]]; then
        gum style --foreground 196 "Error: AUR helper not defined or not found"
        return 1
    fi
    $AUR_HELPER -S --noconfirm --needed "$@"
}

# Function to display the menu
display_menu() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Initial System Setup"
  echo
  gum style --foreground 33 "Hello $USER, please select an option."
  echo
  gum style --foreground 40 ".::: Main Options :::."
  echo
  gum style --foreground 7 "1. Activate Flathub Repositories (Vanilla Arch)."
  gum style --foreground 7 "2. Install 3rd-Party GUI or TUI Package Manager(s)."
  echo
  gum style --foreground 226 ".::: Additional Options :::."
  echo
  gum style --foreground 7 "u. Update System (Simple/Extended/Adv.)."
  gum style --foreground 7 "i. Download latest (official) Arch Linux ISO."
  gum style --foreground 7 "f. Enable Fingerprint Auth. Service (KDE Only)."
  gum style --foreground 7 "a. Install Multi-A.I Model Chat G.U.I (Local/LMStudio)."
  gum style --foreground 7 "p. Change ParallelDownloads value for faster installs."
}

# Function to change parallel downloads
parallel_downloads() {
  sudo pmpd
  clear && exec "$0"
}

# Function for each task

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

# Function to display package selection dialog
package_selection_dialog() {
    local title=$1
    shift
    local options=("$@")
    # Build a list of just the package names for gum choose
    local pkg_names=()
    for ((i=0; i<${#options[@]}; i+=3)); do
        pkg_names+=("${options[i]}")
    done
    clear
    echo
    echo
    echo -e "\e[36m[Space]\e[0m to select, \e[33m[ESC]\e[0m to go back & \e[32m[Enter]\e[0m to make it so."
    echo
    # Use gum choose for menu-style multi-select
    PACKAGES=$(printf "%s\n" "${pkg_names[@]}" | gum choose --no-limit --header "$title" --cursor.foreground 212 --selected.background 236) || true

    if [ -n "$PACKAGES" ]; then
        PKG_DIALOG_EXITED=0
        for PACKAGE in $PACKAGES; do
            case $PACKAGE in
                OctoPi)
                    clear
                    install_aur_packages octopi
                    ;;
                PacSeek)
                    clear
                    install_aur_packages pacseek pacfinder
                    ;;
                BauhGUI)
                    clear
                    install_aur_packages bauh
                    ;;
                Warehouse)
                    clear
                    flatpak install -y io.github.flattool.Warehouse
                    ;;
                Flatseal)
                    clear
                    flatpak install -y com.github.tchx84.Flatseal
                    ;;
                EasyFlatpak)
                    clear
                    flatpak install -y org.dupot.easyflatpak
                    ;;
                *)
                    echo "Unknown package: $PACKAGE"
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

install_gui_package_managers() {
  gum style --foreground 7 "Installing 3rd-Party GUI Package Managers..."
  sleep 2
  echo
  
  # Build list of available packages (only those not already installed)
  gui_pkg_options=()
  
  ! is_aur_installed octopi && gui_pkg_options+=("OctoPi" "OctoPi Package Manager" OFF)
  ! is_aur_installed pacseek && ! is_aur_installed pacfinder && gui_pkg_options+=("PacSeek" "PacSeek Package Finder" OFF)
  ! is_aur_installed bauh && gui_pkg_options+=("BauhGUI" "Bauh GUI Package Manager" OFF)
  ! is_flatpak_installed io.github.flattool.Warehouse && gui_pkg_options+=("Warehouse" "Flatpak Package Manager" OFF)
  ! is_flatpak_installed com.github.tchx84.Flatseal && gui_pkg_options+=("Flatseal" "Flatpak Permission Manager" OFF)
  ! is_flatpak_installed org.dupot.easyflatpak && gui_pkg_options+=("EasyFlatpak" "Easy Flatpak Manager" OFF)
  
  if [ ${#gui_pkg_options[@]} -eq 0 ]; then
    gum style --foreground 7 "All GUI package managers are already installed."
    sleep 3
    clear && exec "$0"
  else
    package_selection_dialog "Select GUI Package Managers to install:" "${gui_pkg_options[@]}"
    if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
      echo
      gum style --foreground 7 "##########  Done ! ##########"
      sleep 3
    fi
    clear && exec "$0"
  fi
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
      1) activate_flathub_repositories ;;
      2) install_gui_package_managers ;;
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
