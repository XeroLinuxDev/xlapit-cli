#!/usr/bin/env bash
set -e

# Add this at the start of the script, right after the shebang
trap 'clear && exec "$0"' INT

# Function to check for dual GPU
check_dual_gpu() {
    if lspci | grep -E "VGA|3D" | grep -q -E "NVIDIA|AMD" && lspci | grep -E "VGA|3D" | grep -q -E "Intel|AMD"; then
        return 0
    else
        return 1
    fi
}

# Function to check current NVIDIA driver
check_current_driver() {
    if pacman -Qs nvidia-dkms > /dev/null; then
        echo "closed"
    elif pacman -Qs nvidia-open-dkms > /dev/null; then
        echo "open"
    else
        echo "none"
    fi
}

# Function to install NVIDIA and Intel drivers
install_nvidia_intel() {
    local driver_type=$1
    sudo -K
    if [ "$driver_type" = "closed" ]; then
        sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia
    else
        sudo pacman -S --needed --noconfirm linux-headers nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia
    fi
    sudo pacman -S --needed --noconfirm linux-headers vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader intel-media-driver intel-gmmlib onevpl-intel-gpu gstreamer-vaapi intel-gmmlib

    # Add nvidia-drm.modeset=1 to GRUB if not present
    if ! grep -q 'nvidia-drm.modeset=1' /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' /etc/default/grub
        echo "Added nvidia-drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    # Ensure NVIDIA modules in mkinitcpio.conf
    if ! grep -q '^MODULES=.*nvidia.*' /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        echo "Added NVIDIA modules to mkinitcpio.conf."
        sudo mkinitcpio -P
    fi
}

# Function to install NVIDIA and AMD drivers
install_nvidia_amd() {
    local driver_type=$1
    sudo -K
    if [ "$driver_type" = "closed" ]; then
        sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia
    else
        sudo pacman -S --needed --noconfirm linux-headers nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau linux-firmware-nvidia
    fi
    sudo pacman -S --needed --noconfirm linux-headers vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader linux-firmware-radeon vulkan-mesa-layers lib32-vulkan-mesa-layers

    # Add nvidia-drm.modeset=1 to GRUB if not present
    if ! grep -q 'nvidia-drm.modeset=1' /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' /etc/default/grub
        echo "Added nvidia-drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    # Ensure NVIDIA modules in mkinitcpio.conf
    if ! grep -q '^MODULES=.*nvidia.*' /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        echo "Added NVIDIA modules to mkinitcpio.conf."
        sudo mkinitcpio -P
    fi
}

# Function to switch NVIDIA drivers
switch_nvidia_drivers() {
    current_driver=$(check_current_driver)
    
    if [ "$current_driver" = "closed" ]; then
        echo "Switching from closed to open drivers..."
        sudo pacman -R --noconfirm nvidia-dkms
        sudo pacman -S --needed --noconfirm nvidia-open-dkms
    elif [ "$current_driver" = "open" ]; then
        echo "Switching from open to closed drivers..."
        sudo pacman -R --noconfirm nvidia-open-dkms
        sudo pacman -S --needed --noconfirm nvidia-dkms
    else
        echo "No NVIDIA drivers detected. Please install drivers first."
        return 1
    fi
}

# Main script
if check_dual_gpu; then
    if lspci | grep -E "VGA|3D" | grep -q "NVIDIA" && lspci | grep -E "VGA|3D" | grep -q "Intel"; then
        gum style --foreground 33 "Intel/nVidia detected, Setup should work for most."
        echo
        current_driver=$(check_current_driver)
        if [ "$current_driver" != "none" ]; then
            read -p "Do you want to (S)witch drivers or (I)nstall new drivers? (s/i): " action_choice
            echo
            action_choice=${action_choice,,}
            
            if [ "$action_choice" = "s" ]; then
                switch_nvidia_drivers
            elif [ "$action_choice" = "i" ]; then
                read -p "Do you want (C)losed (All) or (O)pen Module (Turing+) nVidia drivers? (c/o): " driver_choice
                echo
                driver_choice=${driver_choice,,}
                if [ -z "$driver_choice" ]; then
                    echo "No input provided. Please choose 'c' or 'o'."
                    exit 1
                elif [ "$driver_choice" = "c" ]; then
                    install_nvidia_intel "closed"
                elif [ "$driver_choice" = "o" ]; then
                    install_nvidia_intel "open"
                else
                    echo "Invalid input. Please choose 'c' or 'o'."
                    exit 1
                fi
            else
                echo "Invalid input. Please choose 's' or 'i'."
                exit 1
            fi
        else
            read -p "Do you want (C)losed (All) or (O)pen Module (Turing+) nVidia drivers? (c/o): " driver_choice
            echo
            driver_choice=${driver_choice,,}  # Convert to lowercase
            if [ -z "$driver_choice" ]; then
                echo "No input provided. Please choose 'c' or 'o'."
                exit 1
            elif [ "$driver_choice" = "c" ]; then
                install_nvidia_intel "closed"
            elif [ "$driver_choice" = "o" ]; then
                install_nvidia_intel "open"
            else
                echo "Invalid input. Please choose 'c' or 'o'."
                exit 1
            fi
        fi
    elif lspci | grep -E "VGA|3D" | grep -q "NVIDIA" && lspci | grep -E "VGA|3D" | grep -q "AMD"; then
        gum style --foreground 196 "nVidia/AMD detected, Setup should work for most."
        echo
        read -p "Do you want (C)losed or (O)pen drivers? (c/o): " driver_choice
        echo
        driver_choice=${driver_choice,,}  # Convert to lowercase
        if [ -z "$driver_choice" ]; then
            echo "No input provided. Please choose 'c' or 'o'."
            exit 1
        elif [ "$driver_choice" = "c" ]; then
            install_nvidia_amd "closed"
        elif [ "$driver_choice" = "o" ]; then
            install_nvidia_amd "open"
        else
            echo "Invalid input. Please choose 'c' or 'o'."
            exit 1
        fi
    fi
    echo
    read -p "A reboot is required. Do you want to reboot now? (y/n): " reboot_choice
    echo
    reboot_choice=${reboot_choice,,}  # Convert to lowercase
    if [ -z "$reboot_choice" ]; then
        echo "No input provided. System will not reboot."
    elif [ "$reboot_choice" = "y" ]; then
        sudo reboot
    else
        echo "Please remember to reboot your system to apply the changes."
    fi
else
    gum style --foreground 214 "No dual GPU configuration detected."
fi
