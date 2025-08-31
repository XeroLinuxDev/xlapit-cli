#!/usr/bin/env bash

# Trap INT signal to clear and restart the script
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

SCRIPTS="/usr/share/xero-scripts/"

# Function to detect if running on XeroLinux
is_xerolinux() {
    grep -q "XeroLinux" /etc/lsb-release
}

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
    gum style --foreground 40 ".::: Main Options :::."
    echo
    
    # Dynamic numbering for visible options
    local option_number=1
    
    gum style --foreground 85 "${option_number}. GPU Drivers/Codecs (Intel/AMD/nVidia)."
    ((option_number++))
    
    # Only show "(Vanilla Arch)" option if not running XeroLinux
    if ! is_xerolinux; then
        gum style --foreground 7 "${option_number}. Printer Drivers (Vanilla Arch)."
        ((option_number++))
    fi
    
    gum style --foreground 7 "${option_number}. Setup Tailscale Incl. fix for XeroLinux."
    ((option_number++))
    gum style --foreground 7 "${option_number}. ASUS ROG Laptop Tools by ASUS-Linux team (AUR)."
    echo
    gum style --foreground 226 ".::: Additional Options :::."
    echo
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
                sudo -K
                sudo pacman -S --needed --noconfirm linux-headers vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader linux-firmware-radeon amdvlk lib32-amdvlk vulkan-mesa-layers lib32-vulkan-mesa-layers
                sudo -K
                read -rp "Will you be using DaVinci Resolve and/or Machine Learning? (y/n): " davinci
                if [[ $davinci =~ ^[Yy](es)?$ ]]; then
                    sudo pacman -S --needed --noconfirm rocm-opencl-runtime rocm-hip-runtime
                fi
                ;;
            intel)
                sudo pacman -S --needed --noconfirm linux-headers vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader intel-media-driver intel-gmmlib onevpl-intel-gpu gstreamer-vaapi intel-gmmlib
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
                # Grub stuff
                if [ -f /etc/default/grub ]; then
                    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
                        if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=".*"' /etc/default/grub; then
                            sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s/"$/ nvidia-drm.modeset=1"/' /etc/default/grub
                        elif grep -q "^GRUB_CMDLINE_LINUX_DEFAULT='.*'" /etc/default/grub; then
                            sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/s/'$/ nvidia-drm.modeset=1'/" /etc/default/grub
                        fi
                    fi
                    echo "Updating Grub"
                    sudo grub-mkconfig -o /boot/grub/grub.cfg
                fi
                # MKINITCPIO crap
                REQUIRED_MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)

                # Read current MODULES line
                current_line=$(grep '^MODULES=' /etc/mkinitcpio.conf)
                if [[ "$current_line" =~ ^MODULES=\"\"$ ]]; then
                    sudo sed -i 's/^MODULES=""/MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"/' /etc/mkinitcpio.conf
                elif [[ "$current_line" =~ ^MODULES=\(\)$ ]]; then
                    sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
                else
                    for mod in "${REQUIRED_MODULES[@]}"; do
                        if ! grep -q "$mod" /etc/mkinitcpio.conf; then
                            sudo sed -i "/^MODULES=(/ s/)$/ $mod)/" /etc/mkinitcpio.conf
                        fi
                    done
                fi
                sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
                sudo mkinitcpio -P
                echo
                read -rp "Do you want to install CUDA for Machine Learning? (y/n): " cuda
                if [[ $cuda =~ ^[Yy](es)?$ ]]; then
                    sudo pacman -S --needed --noconfirm cuda
                fi
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
        read -rp "Enter your choice, 'r' to reboot or 'q' for main menu : " CHOICE
        
        # Map user choice to actual option based on what's visible
        local actual_choice=""
        if ! is_xerolinux; then
            # On vanilla Arch: 1=gpu, 2=printer, 3=tailscale, 4=asus
            case $CHOICE in
                1) actual_choice="gpu" ;;
                2) actual_choice="printer" ;;
                3) actual_choice="tailscale" ;;
                4) actual_choice="asus" ;;
                *) actual_choice="$CHOICE" ;;
            esac
        else
            # On XeroLinux: 1=gpu, 2=tailscale, 3=asus (since printer is hidden)
            case $CHOICE in
                1) actual_choice="gpu" ;;
                2) actual_choice="tailscale" ;;
                3) actual_choice="asus" ;;
                *) actual_choice="$CHOICE" ;;
            esac
        fi
        
        case $actual_choice in
            gpu) prompt_user && sleep 3 && clear && exec "$0" ;;
            printer)
                gum style --foreground 7 "Installing Printer Drivers..."
                sudo pacman -S --needed --noconfirm ghostscript gsfonts cups cups-filters cups-pdf system-config-printer avahi foomatic-db-engine foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds gutenprint python-pyqt5
                sudo systemctl enable --now avahi-daemon cups.socket
                sudo usermod -aG sys,lp,cups "$(whoami)"
                gum style --foreground 7 "Printer setup complete!"
                sleep 3 && clear && exec "$0"
                ;;
            tailscale)
                gum style --foreground 7 "Installing Tailscale..."
                bash -c "$(curl -fsSL https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/install.sh)"
                gum style --foreground 7 "Tailscale setup complete!"
                sleep 3 && clear && exec "$0"
                ;;
            asus)
                gum style --foreground 7 "Installing ASUS ROG Tools..."
                install_aur_packages rog-control-center asusctl supergfxctl
                sudo systemctl enable --now asusd supergfxd
                gum style --foreground 7 "Setup complete!"
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
                clear && exec xero-cli
                ;;
            *)
                gum style --foreground 50 "Invalid choice."
                ;;
        esac
    done
}

# Main
display_header
display_options
process_choice
