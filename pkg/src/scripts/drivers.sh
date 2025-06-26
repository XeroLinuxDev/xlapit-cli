#!/usr/bin/env bash

# Source common functions
source "$(dirname "$0")/common.sh"

# Check for root and clear sudo cache before AUR operations
check_root_and_clear_cache

# Trap INT signal to clear and restart the script
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

SCRIPTS="/usr/share/xero-scripts/"

# Function to display header
display_header() {
    clear
    gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Device Drivers"
    echo
    gum style --foreground 141 "Hello $USER, please select what drivers to install."
    echo
}

# Function to display options
display_options() {
    gum style --foreground 85 "1. GPU Drivers (Intel/AMD/nVidia)."
    gum style --foreground 7 "2. Printer Drivers (Vanilla Arch)."
    gum style --foreground 7 "3. Scanner Drivers & Tools (Vanilla Arch)."
    gum style --foreground 7 "4. Setup Tailscale Incl. fix for XeroLinux."
    gum style --foreground 7 "5. DeckLink & StreamDeck Drivers/Tools (AUR)."
    gum style --foreground 7 "6. ASUS ROG Laptop Tools by ASUS-Linux team (AUR)."
    echo
    gum style --foreground 190 "g. Apply nVidia GSP Firmware Fix (Closed Drivers)."
    gum style --foreground 196 "k. Install Arch Kernel Manager Tool (XeroLinux Repo)."
}

# Function to prompt user for GPU drivers
prompt_user() {
    gum style --foreground 123 "Gathering information about your connected GPUs..."
    echo
    inxi -G
    echo
    gum style --foreground 154 "Answer below prompts wisely. No Legacy GPU Support."
    echo
    while true; do
        read -rp "Single or Dual (Hybrid) GPU/iGPU Setup ? (s/d): " setup_type
        if [[ $setup_type =~ ^[sd]$ ]]; then
            break
        fi
        gum style --foreground 196 "Invalid input. Please enter 's' or 'd'."
    done

    if [[ $setup_type == "s" ]]; then
        while true; do
            read -rp "Is your GPU AMD, Intel, or NVIDIA? (amd/intel/nvidia): " gpu_type
            gpu_type=$(echo "$gpu_type" | tr '[:upper:]' '[:lower:]')
            if [[ $gpu_type =~ ^(amd|intel|nvidia)$ ]]; then
                break
            fi
            gum style --foreground 196 "Invalid input. Please enter 'amd', 'intel', or 'nvidia'."
        done
        case $gpu_type in
            amd)
                sudo pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader linux-firmware-amdgpu linux-firmware-radeon amdvlk lib32-amdvlk
                read -rp "Will you be using DaVinci Resolve and/or Machine Learning? (y/n): " davinci
                if [[ $davinci =~ ^[Yy](es)?$ ]]; then
                    sudo pacman -S --needed --noconfirm mesa lib32-mesa rocm-opencl-runtime rocm-hip-runtime
                fi
                sudo -K
                ;;
            intel)
                sudo pacman -S --needed --noconfirm vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader intel-media-driver intel-gmmlib onevpl-intel-gpu gstreamer-vaapi intel-gmmlib
                sudo -K
                ;;
            nvidia)
                read -rp "Closed-Source (Most) or Open-Kernel Modules (Turing+) ? (c/o): " nvidia_series
                if [[ $nvidia_series == "c" || $nvidia_series == "1000" ]]; then
                    sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia
                elif [[ $nvidia_series == "o" ]]; then
                    sudo pacman -S --needed --noconfirm linux-headers nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia
                else
                    echo "Invalid selection."
                    return
                fi
                # Robustly update mkinitcpio and grub for nvidia
                add_nvidia_to_mkinitcpio
                add_nvidia_to_grub
                sudo -K
                sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
                sudo mkinitcpio -P
                sudo -K
                echo
                read -rp "Do you want to install CUDA for Machine Learning? (y/n): " cuda
                if [[ $cuda =~ ^[Yy](es)?$ ]]; then
                    sudo pacman -S --needed --noconfirm cuda
                fi
                sudo -K
                ;;
        esac
    else
        echo
        bash "$SCRIPTS/hybrid.sh"
        return
    fi
    echo
    gum style --foreground 83 "Time to reboot for everything to work."
    gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 129 \
        "$(gum style --foreground 196 --bold '⚠️ IMPORTANT GAMING NOTICE ⚠️')" \
        "" \
        "$(gum style --foreground 15 'If you use Lutris, Heroic, or Bottles as Flatpaks,')" \
        "" \
        "$(gum style --foreground 15 'Please run this command after reboot:')" \
        "" \
        "$(gum style --foreground 226 --bold 'flatpak update -y')"
    sleep 6
}

# AUR installer
install_aur_packages() {
    if [[ -z "$AUR_HELPER" || ! -x "$(command -v $AUR_HELPER)" ]]; then
        gum style --foreground 196 "Error: AUR helper not defined or not found"
        return 1
    fi
    $AUR_HELPER -S --noconfirm --needed "$@"
}

package_selection_dialog() {
    local options=$1 install_cmd=$2
    PACKAGES=$(gum choose --multiple --cursor.foreground 212 --selected.background 236 $options)
    for pkg in $PACKAGES; do
        eval "$install_cmd $pkg"
    done
}

process_choice() {
    while :; do
        echo
        read -rp "Enter choice (1‑6), g, k, r, or q: " CHOICE
        case $CHOICE in
            1) prompt_user && sleep 3 && clear && exec "$0" ;;
            2)
                if grep -q "XeroLinux" /etc/os-release; then
                    gum style --foreground 49 "Printer Drivers already installed!"
                else
                    gum style --foreground 7 "Installing Printer Drivers..."
                    sudo pacman -S --needed --noconfirm ghostscript gsfonts cups cups-filters cups-pdf system-config-printer avahi foomatic-db-engine foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds gutenprint python-pyqt5
                    sudo systemctl enable --now avahi-daemon cups.socket
                    sudo usermod -aG sys,lp,cups "$(whoami)"
                    gum style --foreground 7 "Printer setup complete!"
                fi
                sleep 3 && clear && exec "$0"
                ;;
            3)
                if grep -q "XeroLinux" /etc/os-release; then
                    gum style --foreground 49 "Scanner Drivers already installed!"
                else
                    gum style --foreground 7 "Installing Scanner Drivers..."
                    sudo pacman -S --needed --noconfirm scanner-support
                    gum style --foreground 7 "Scanner setup complete!"
                fi
                sleep 3 && clear && exec "$0"
                ;;
            4)
                gum style --foreground 7 "Installing Tailscale..."
                bash -c "$(curl -fsSL https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/install.sh)"
                gum style --foreground 7 "Tailscale setup complete!"
                sleep 3 && clear && exec "$0"
                ;;
            5)
                gum style --foreground 7 "Installing DeckLink & StreamDeck..."
                package_selection_dialog "Decklink DeckMaster StreamDeckUI" "install_aur_packages"
                gum style --foreground 7 "Installation complete!"
                sleep 3 && clear && exec "$0"
                ;;
            6)
                gum style --foreground 7 "Installing ASUS ROG Tools..."
                install_aur_packages rog-control-center asusctl supergfxctl
                sudo systemctl enable --now asusd supergfxd
                gum style --foreground 7 "Setup complete!"
                sleep 3 && clear && exec "$0"
                ;;
            g)
                gum style --foreground 7 "Managing nVidia GSP fix..."
                if pacman -Qq | grep -qE 'nvidia-dkms|nvidia-open-dkms'; then
                    if pacman -Qq | grep -q 'nvidia-open-dkms'; then
                        read -rp "Open modules found. Switch to closed? (y/n): " resp
                        if [[ $resp =~ ^[Yy]$ ]]; then
                            sudo pacman -Rdd --noconfirm nvidia-open-dkms
                            sudo pacman -S --noconfirm nvidia-dkms
                            echo -e "options nvidia-drm modeset=1 fbdev=1\noptions nvidia NVreg_EnableGpuFirmware=0" | sudo tee -a /etc/modprobe.d/nvidia-modeset.conf
                            sudo mkinitcpio -P
                            gum style --foreground 33 "Closed drivers + GSP fix enabled."
                        else
                            gum style --foreground 33 "No change made."
                        fi
                    else
                        read -rp "Pick: 1) Apply GSP 2) Remove 3) Switch to open: " choice
                        case $choice in
                            1)
                                echo -e "options nvidia-drm modeset=1 fbdev=1\noptions nvidia NVreg_EnableGpuFirmware=0" | sudo tee -a /etc/modprobe.d/nvidia-modeset.conf
                                sudo mkinitcpio -P
                                gum style --foreground 33 "GSP fix applied."
                                ;;
                            2)
                                sudo rm -f /etc/modprobe.d/nvidia-modeset.conf && sudo mkinitcpio -P
                                gum style --foreground 33 "GSP fix removed."
                                ;;
                            3)
                                sudo rm -f /etc/modprobe.d/nvidia-modeset.conf
                                sudo pacman -Rdd --noconfirm nvidia-dkms
                                sudo pacman -S --noconfirm nvidia-open-dkms
                                sudo mkinitcpio -P
                                gum style --foreground 33 "Switched to open + fix removed."
                                ;;
                            *)
                                gum style --foreground 33 "No change."
                                ;;
                        esac
                    fi
                    read -rp "Reboot now? (y/n): " rb
                    [[ $rb =~ ^[Yy]$ ]] && reboot
                    gum style --foreground 33 "Remember to reboot."
                else
                    gum style --foreground 40 "No nVidia closed driver installed."
                fi
                sleep 3 && clear && exec "$0"
                ;;
            r)
                gum style --foreground 33 "Rebooting in 5s..."
                for i in {5..1}; do
                    echo "Rebooting in $i..."
                    sleep 1
                done
                reboot
                ;;
            k)
                gum style --foreground 7 "Installing Arch Kernel Manager..."
                sudo pacman -S --needed --noconfirm archlinux-kernel-manager python-tomlkit
                gum style --foreground 7 "Installation complete!"
                sleep 3 && clear && exec "$0"
                ;;
            q)
                clear && exec xero-cli -m
                ;;
            *)
                gum style --foreground 50 "Invalid choice."
                ;;
        esac
    done
}

# Robustly add nvidia modules to mkinitcpio.conf
add_nvidia_to_mkinitcpio() {
  local conf="/etc/mkinitcpio.conf"
  local required="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
  # Remove any existing nvidia modules to avoid duplicates
  sudo sed -i 's/\\b\(nvidia\\|nvidia_modeset\\|nvidia_uvm\\|nvidia_drm\)\\b//g' "$conf"
  # Clean up extra spaces
  sudo sed -i 's/MODULES=( */MODULES=(/; s/  */ /g; s/ )/)/' "$conf"
  # Add required modules
  sudo sed -i "s/^MODULES=(/MODULES=($required /" "$conf"
}

# Robustly add nvidia-drm.modeset=1 to GRUB
add_nvidia_to_grub() {
  local grub="/etc/default/grub"
  if ! grep -q 'nvidia-drm.modeset=1' "$grub"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' "$grub"
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='\(.*\)'/GRUB_CMDLINE_LINUX_DEFAULT='\1 nvidia-drm.modeset=1'/" "$grub"
  fi
  sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Main
display_header
display_options
process_choice
