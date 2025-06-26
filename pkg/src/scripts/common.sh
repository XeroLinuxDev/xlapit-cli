#!/usr/bin/env bash

# Common reusable functions for XeroLinux scripts

# Dependency check and install
require_dependency() {
  local dep="$1"
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "$dep is not installed. Installing..."
    sudo pacman -S --noconfirm "$dep"
  fi
}

# Reboot countdown
reboot_countdown() {
  local seconds=${1:-5}
  for i in $(seq $seconds -1 1); do
    dialog --infobox "Rebooting in $i seconds..." 3 30
    sleep 1
  done
}

# Standard menu loop
menu_loop() {
  local menu_function="$1"
  while :; do
    $menu_function
    sleep 3
  done
}

# Confirm prompt (returns 0 for yes, 1 for no)
confirm_prompt() {
  local prompt_text="$1"
  read -rp "$prompt_text [y/N]: " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Check for root and clear sudo cache before AUR operations
check_root_and_clear_cache() {
  if [[ $EUID -eq 0 ]]; then
    echo "Warning: Script is running as root. Clearing sudo cache for AUR operations..."
    sudo -K
    # Switch to the original user if possible
    if [[ -n "$SUDO_USER" ]]; then
      echo "Switching to user: $SUDO_USER"
      exec sudo -u "$SUDO_USER" "$0" "$@"
    else
      echo "Error: Cannot determine original user. Please run as a regular user."
      exit 1
    fi
  fi
} 