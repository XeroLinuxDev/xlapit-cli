#!/usr/bin/env bash
set -e

# Relaunch cleanly on Ctrl+C
trap 'clear && exec "$0"' INT

SCRIPTS="/usr/share/xero-scripts"

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

is_xerolinux() { grep -q "XeroLinux" /etc/lsb-release; }

restart_script() { clear && exec "$0"; }

install_aur_packages() {
  local pkgs=("$@")
  if [[ -z "$AUR_HELPER" || ! $(command -v "$AUR_HELPER") ]]; then
    gum style --foreground 196 "Error: AUR helper not defined or not found."
    return 1
  fi
  "$AUR_HELPER" -S --noconfirm --needed "${pkgs[@]}"
}

warn_nvidia_closed_removed() {
  echo
  gum style --border double --align center --width 84 --margin "1 2" --padding "1 2" \
    --border-foreground 196 \
    "$(gum style --bold --foreground 196 '⚠️  IMPORTANT NVIDIA NOTICE  ⚠️')" \
    "" \
    "$(gum style --bold --foreground 15 'NVIDIA 900 & 1000 series (Maxwell/Pascal) are NO LONGER supported by NVIDIA proprietary drivers.')" \
    "" \
    "$(gum style --foreground 15 'Only the Open NVIDIA kernel module is supported for Turing/RTX+ (nvidia-open-dkms).')" \
    "" \
    "$(gum style --foreground 40 'Supported:     ' )$(gum style --bold --foreground 40 'nvidia-open-dkms  (Turing/RTX+)')" \
    "$(gum style --foreground 196 'Not supported:  ' )$(gum style --bold --foreground 196 'nvidia-dkms  (removed / unavailable)')"
  echo
  read -rp "Press Enter to continue... " _
}

# --- UI ---

display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Device Drivers"
  echo
  gum style --foreground 141 "Hello $USER, please select what drivers to install."
  echo
}

display_options() {
  gum style --foreground 40 ".::: Main Options :::."
  echo
  gum style --foreground 85 "1. GPU Drivers/Codecs (Intel/AMD/NVIDIA-OPEN)"
  gum style --foreground 7  "2. Setup Tailscale (incl. XeroLinux Patch/fix)"
  gum style --foreground 7  "3. ASUS ROG Laptop Drivers & Tools (ASUS-Linux / AUR)"
}

# --- GPU Setup ---

prompt_user() {
  gum style --foreground 123 "Gathering GPU info..."
  echo
  inxi -G || gum style --foreground 196 "inxi not found. Please install it first."
  echo
  gum style --foreground 154 "No Legacy GPU support. Answer carefully!"
  echo

  local setup_type gpu_type nvidia_series

  # Detect setup type
  while true; do
    read -rp "Single or Dual (Hybrid) GPU/iGPU setup? (s/d): " setup_type
    [[ $setup_type =~ ^[sd]$ ]] && break
    gum style --foreground 196 "Invalid input. Enter 's' or 'd'."
  done

  if [[ $setup_type == s ]]; then
    # Select GPU vendor
    while true; do
      read -rp "GPU Vendor (amd/intel/nvidia): " gpu_type
      gpu_type=${gpu_type,,}
      [[ $gpu_type =~ ^(amd|intel|nvidia)$ ]] && break
      gum style --foreground 196 "Invalid input. Enter amd, intel, or nvidia."
    done

    case $gpu_type in
      amd)
        sudo -K
        sudo pacman -S --needed --noconfirm \
          linux-headers vulkan-radeon lib32-vulkan-radeon \
          vulkan-icd-loader lib32-vulkan-icd-loader \
          linux-firmware-radeon \
          vulkan-mesa-layers lib32-vulkan-mesa-layers
        sudo -K
        read -rp "Using DaVinci Resolve / ML tools? (y/n): " davinci
        [[ $davinci =~ ^[Yy] ]] && sudo pacman -S --needed --noconfirm rocm-opencl-runtime rocm-hip-runtime
        ;;

      intel)
        sudo pacman -S --needed --noconfirm \
          linux-headers vulkan-intel lib32-vulkan-intel \
          vulkan-icd-loader lib32-vulkan-icd-loader \
          intel-media-driver intel-gmmlib onevpl-intel-gpu \
          gstreamer-vaapi
        ;;

      nvidia)
        local pkg_list="linux-headers nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia"

        # nvidia-dkms removed/unavailable: only nvidia-open-dkms is supported going forward.
        # Still accept "c" input so users get a clear warning instead of a failed install.
        while true; do
          read -rp "NVIDIA Driver: Open (o, Turing/RTX+) only. Type 'o' to install (or 'p' for proprietary): " nvidia_series
          nvidia_series=${nvidia_series,,}
          case "$nvidia_series" in
            o)
              sudo pacman -S --needed --noconfirm nvidia-open-dkms $pkg_list
              break
              ;;
            p)
              warn_nvidia_closed_removed
              ;;
            *)
              gum style --foreground 196 "Invalid option. Enter 'o' (or 'c' to read the notice)."
              ;;
          esac
        done

        # --- GRUB tweak ---
        if [[ -f /etc/default/grub ]] && ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
          sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=["'\'']\)/\1nvidia-drm.modeset=1 /' /etc/default/grub
          gum style --foreground 7 "Updating GRUB..."
          sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi

        # --- MKINITCPIO modules ---
        local mods=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
        local mkfile="/etc/mkinitcpio.conf"
        local current_line
        current_line=$(grep '^MODULES=' "$mkfile" || true)

        if [[ $current_line =~ ^MODULES=\"\"$ ]]; then
          sudo sed -i 's/^MODULES=""/MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"/' "$mkfile"
        elif [[ $current_line =~ ^MODULES=\(\)$ ]]; then
          sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkfile"
        else
          for mod in "${mods[@]}"; do
            grep -qw "$mod" "$mkfile" || sudo sed -i "/^MODULES=(/ s/)/ $mod)/" "$mkfile"
          done
        fi

        sudo systemctl enable nvidia-{suspend,hibernate,resume}.service
        sudo mkinitcpio -P

        read -rp "Install CUDA (ML support)? (y/n): " cuda
        [[ $cuda =~ ^[Yy] ]] && sudo pacman -S --needed --noconfirm cuda
        ;;
    esac
  else
    bash "$SCRIPTS/hybrid.sh"
    return
  fi

  echo
  gum style --foreground 83 "All done! Please reboot."
  gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" \
    --border-foreground 129 "$(gum style --foreground 196 --bold '⚠️ GAMING NOTICE ⚠️')" \
    "" "$(gum style --foreground 15 'For Lutris, Heroic, or Bottles Flatpaks,')" \
    "" "$(gum style --foreground 15 'run after reboot:')" \
    "" "$(gum style --foreground 226 --bold 'flatpak update -y')"
  sleep 5
}

# --- Menu Loop ---

process_choice() {
  while true; do
    echo
    read -rp "Enter choice ('r' reboot, 'q' main menu): " CHOICE
    echo
    case "$CHOICE" in
      1|gpu)
        prompt_user
        sleep 2
        restart_script
        ;;
      2|tailscale)
        gum style --foreground 7 "Installing Tailscale..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/install.sh)"
        gum style --foreground 7 "Tailscale setup complete!"
        sleep 2
        restart_script
        ;;
      3|asus)
        gum style --foreground 7 "Installing ASUS ROG Tools..."
        install_aur_packages rog-control-center asusctl supergfxctl
        sudo systemctl enable --now asusd supergfxd
        gum style --foreground 7 "Setup complete!"
        sleep 2
        restart_script
        ;;
      k)
        gum style --foreground 7 "Installing Arch Kernel Manager..."
        sudo pacman -S --needed --noconfirm archlinux-kernel-manager python-tomlkit
        gum style --foreground 7 "Installation complete!"
        sleep 2
        restart_script
        ;;
      r)
        gum style --foreground 33 "Rebooting..."
        for i in {5..1}; do
          echo "Rebooting in $i..."
          sleep 1
        done
        reboot
        ;;
      q)
        clear && exec xero-cli
        ;;
      *)
        gum style --foreground 50 "Invalid choice. Try again."
        ;;
    esac
  done
}

# --- Main Execution ---

display_header
display_options
process_choice
