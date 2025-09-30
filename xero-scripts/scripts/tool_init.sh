#!/usr/bin/env bash
set -e

# Relaunch on Ctrl+C
trap 'clear && exec "$0"' INT

# Ensure script is run via toolkit
if [[ -z "$AUR_HELPER" ]]; then
  echo
  gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" \
    --border-foreground 196 "$(gum style --foreground 196 'ERROR: This script must be run through the toolkit.')"
  echo
  gum style --border normal --align center --width 70 --margin "1 2" --padding "1 2" \
    --border-foreground 33 "$(gum style --foreground 33 'Or use this command instead:') \
    $(gum style --bold --foreground 47 'clear && xero-cli')"
  echo
  exit 1
fi

# --- Helper Functions ---

is_pacman_installed() { pacman -Q "$1" &>/dev/null; }
is_aur_installed() { pacman -Qm "$1" &>/dev/null; }
is_flatpak_installed() { flatpak list --app --columns=application | grep -qw "$1"; }

restart_script() { clear && exec "$0"; }

install_aur_packages() {
  local pkgs=("$@")
  if [[ -z "$AUR_HELPER" || ! $(command -v "$AUR_HELPER") ]]; then
    gum style --foreground 196 "Error: AUR helper not defined or not found."
    return 1
  fi
  if ! "$AUR_HELPER" -S --needed --noconfirm "${pkgs[@]}"; then
    gum style --foreground 196 "Failed to install AUR package(s): ${pkgs[*]}"
    sleep 2
    restart_script
  fi
}

# --- Menu Display ---

display_menu() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" \
    --align center "Initial System Setup"
  echo
  gum style --foreground 33 "Hello $USER, please select an option."
  echo
  gum style --foreground 40 ".::: Main Options :::."
  echo
  gum style --foreground 7 "u. Update System (Xero Update Script.)"
  gum style --foreground 7 "t. Install 3rd-Party GUI or TUI Package Manager(s)"
  gum style --foreground 7 "a. Install Multi-A.I Model Chat GUI (Local/LMStudio)"
  gum style --foreground 7 "p. Change ParallelDownloads value (faster installs)"
  echo
  gum style --foreground 156 "i. Download latest Arch Linux ISO (LeaseWeb)"
}

# --- Actions ---

parallel_downloads() {
  sudo pmpd
  sudo -K
  [[ $EUID -eq 0 && $SUDO_USER ]] && su "$SUDO_USER" -c "$0" || restart_script
}

install_topgrade_aio_updater() {
  if ! command -v topgrade &>/dev/null; then
    gum style --foreground 7 "Installing Topgrade..."
    "$AUR_HELPER" -S --needed --noconfirm topgrade-bin
  fi
  gum style --foreground 7 "Running Topgrade..."
  topgrade
  gum style --foreground 7 "System updated."
  sleep 2
  restart_script
}

activate_flathub_repositories() {
  gum style --foreground 7 "Activating Flathub Repositories..."
  sleep 2
  sudo pacman -S --noconfirm --needed flatpak
  echo
  gum style --foreground 7 "Applying Flatpak Overrides..."
  sudo flatpak override --filesystem="$HOME/.themes"
  sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
  sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro
  gum style --foreground 7 "Flathub activated. Please reboot."
  sleep 2
  restart_script
}

download_latest_arch_iso() {
  local base_url="https://mirror.fra10.de.leaseweb.net/archlinux/iso/latest/"
  local download_dir="$HOME/Downloads/ArchISO"
  mkdir -p "$download_dir"

  local html iso_file year month day month_name day_suffix
  html=$(curl -fsSL "$base_url") || {
    gum style --foreground 196 "Failed to fetch ISO list."
    return 1
  }
  iso_file=$(grep -oP 'archlinux-\d{4}\.\d{2}\.\d{2}-x86_64\.iso' <<<"$html" | head -n1) || true

  if [[ -z $iso_file ]]; then
    gum style --foreground 196 "Could not detect ISO filename."
    return 1
  fi

  # Extract and format date
  year=${iso_file#archlinux-}
  year=${year%%.*}
  month=${iso_file#archlinux-????.}
  month=${month%%.*}
  day=${iso_file#archlinux-????.??.}
  day=${day%%-*}
  month_name=$(date -d "$year-$month-$day" +%B)
  case "$day" in
    01|21|31) day_suffix="st" ;;
    02|22) day_suffix="nd" ;;
    03|23) day_suffix="rd" ;;
    *) day_suffix="th" ;;
  esac

  if [[ -f "$download_dir/$iso_file" ]]; then
    gum style --foreground 214 "Latest ISO already exists in $download_dir."
    sleep 3
    return
  fi

  gum style --foreground 51 "Latest ISO: $month_name ${day#0}$day_suffix, $year"
  read -rp "Download now? [Y/n]: " confirm
  confirm=${confirm,,}
  [[ $confirm == n ]] && { gum style --foreground 214 "Cancelled."; return; }

  gum style --foreground 51 "Downloading..."
  if curl -# -o "$download_dir/$iso_file" "${base_url}${iso_file}"; then
    gum style --foreground 46 "Download complete → $download_dir/$iso_file"
  else
    gum style --foreground 196 "Download failed."
  fi
  sleep 2
}

package_selection_dialog() {
  local title=$1; shift
  local options=("$@")

  clear
  echo -e "\n\e[36m[Space]\e[0m select, \e[33m[ESC]\e[0m back, \e[32m[Enter]\e[0m confirm.\n"

  local selected
  selected=$(printf "%s\n" "${options[@]}" | gum choose --no-limit --header "$title" \
             --cursor.foreground 212 --selected.background 236) || true

  if [[ -z $selected ]]; then
    figlet -t -c "No packages selected. Returning..." | lolcat
    sleep 3
    return 1
  fi

  for pkg in $selected; do
    case $pkg in
      OctoPi) install_aur_packages octopi ;;
      PacSeek) install_aur_packages pacseek pacfinder ;;
      BauhGUI) install_aur_packages bauh ;;
      Warehouse) flatpak install -y io.github.flattool.Warehouse ;;
      Flatseal) flatpak install -y com.github.tchx84.Flatseal ;;
      Bazaar) flatpak install -y io.github.kolunmi.Bazaar ;;
    esac
  done
}

install_gui_package_managers() {
  gum style --foreground 7 "Installing 3rd-Party Package Managers..."
  sleep 1

  local gui_pkg_options=()
  ! is_aur_installed octopi && gui_pkg_options+=("OctoPi")
  ! is_aur_installed pacseek && gui_pkg_options+=("PacSeek")
  ! is_aur_installed bauh && gui_pkg_options+=("BauhGUI")
  ! is_flatpak_installed io.github.flattool.Warehouse && gui_pkg_options+=("Warehouse")
  ! is_flatpak_installed com.github.tchx84.Flatseal && gui_pkg_options+=("Flatseal")
  ! is_flatpak_installed io.github.kolunmi.Bazaar && gui_pkg_options+=("Bazaar")

  if [[ ${#gui_pkg_options[@]} -eq 0 ]]; then
    gum style --foreground 7 "All GUI managers already installed."
    sleep 2
    restart_script
  fi

  package_selection_dialog "Select GUI Package Managers:" "${gui_pkg_options[@]}" && {
    gum style --foreground 7 "Installation complete!"
    sleep 2
  }
  restart_script
}

install_lmstudio() {
  if pacman -Qs lmstudio &>/dev/null; then
    gum style --foreground 46 "LMStudio already installed!"
  else
    gum style --foreground 7 "Installing LMStudio..."
    "$AUR_HELPER" -S --noconfirm --needed lmstudio
    gum style --foreground 46 "LMStudio installation complete."
  fi
  sleep 2
  restart_script
}

update_system() {
  sh /usr/local/bin/upd
  sleep 5
  restart_script
}

restart() {
  gum style --foreground 69 "Rebooting..."
  for i in {5..1}; do
    dialog --infobox "Rebooting in $i seconds..." 3 30
    sleep 1
  done
  reboot
}

# --- Main Loop ---

main() {
  while true; do
    display_menu
    echo
    read -rp "Enter your choice ('r' to reboot, 'q' for main menu): " CHOICE
    echo
    case "$CHOICE" in
      t) install_gui_package_managers ;;
      a) install_lmstudio ;;
      i) download_latest_arch_iso ;;
      u) update_system ;;
      p) parallel_downloads ;;
      r) restart ;;
      q) clear && exec xero-cli ;;
      *) gum style --foreground 50 "Invalid option. Try again."; sleep 2 ;;
    esac
  done
}

main
