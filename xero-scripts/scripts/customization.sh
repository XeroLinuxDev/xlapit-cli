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

# Function to detect if running on XeroLinux
is_xerolinux() {
    grep -q "XeroLinux" /etc/os-release
}

# Function to display header
display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "System Customization"
  echo
  gum style --foreground 141 "Hello $USER, please select an option."
  echo
}
# Function to display options
display_options() {
  gum style --foreground 40 ".::: Main Options :::."
  echo
  
  # Dynamic numbering for visible options
  local option_number=1
  
  # Only show "(Vanilla Arch)" option if not running XeroLinux
  if ! is_xerolinux; then
    gum style --foreground 7 "${option_number}. Setup Fastfetch (Vanilla Arch)."
    ((option_number++))
  fi
  
  gum style --foreground 7 "${option_number}. Setup ZSH All in one with Oh-My-Posh/Plugs."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Install Save Desktop Config tool (KDE/Gnome)."
  echo
  gum style --foreground 226 ".::: Additional Options :::."
  echo
  gum style --foreground 175 "g. Change Grub Theme (Xero Script)."
  gum style --foreground 50 "h. Install Gnome Live Wallpaper (Hanabi)."
  if ! is_xerolinux; then
    gum style --foreground 200 "x. XeroLinux's Layan Rice (Vanilla KDE)."
  fi
  gum style --foreground 225 "w. Install more Plasma Wallpapers (~1.2gb)."
  gum style --foreground 153 "u. Layan GTK4 Patch & Update (Xero-KDE Only)."
    if ! is_xerolinux; then
    gum style --foreground 120 "z. Apply XeroLinux Gnome Settings (Vanilla Gnome)."
  fi
}

# Function to process user choice
process_choice() {
  # Define AUR helper
  if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
  elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
  else
    gum style --foreground 196 "No AUR helper found. Please install yay or paru first."
    exit 1
  fi

  while :; do
    echo
    read -rp "Enter your choice, 'r' to reboot or 'q' for main menu : " CHOICE
    echo

    # Map user choice to actual option based on what's visible
    local actual_choice=""
    if ! is_xerolinux; then
      # On vanilla Arch: 1=fastfetch, 2=zsh, 3=save_desktop
      case $CHOICE in
        1) actual_choice="fastfetch" ;;
        2) actual_choice="zsh" ;;
        3) actual_choice="save_desktop" ;;
        *) actual_choice="$CHOICE" ;;
      esac
    else
      # On XeroLinux: 1=zsh, 2=save_desktop (since fastfetch is hidden)
      case $CHOICE in
        1) actual_choice="zsh" ;;
        2) actual_choice="save_desktop" ;;
        *) actual_choice="$CHOICE" ;;
      esac
    fi

    case $actual_choice in
      fastfetch)
        gum style --foreground 7 "Setting up Fastfetch..."
        sleep 2
        echo
        if ! command -v fastfetch &> /dev/null; then
          sudo -K
          sudo pacman -S --noconfirm --needed fastfetch imagemagick ffmpeg ffmpegthumbnailer ffmpegthumbs qt6-multimedia-ffmpeg
          sudo -K
        fi
        
        # Create config directory if it doesn't exist
        mkdir -p "$HOME/.config/fastfetch"
        
        # Only generate config if it doesn't exist
        if [ ! -f "$HOME/.config/fastfetch/config.jsonc" ]; then
          fastfetch --gen-config
        fi
        
        # Change to the ~/.config/fastfetch directory
        cd "$HOME/.config/fastfetch"

        # Rename the existing config file by appending .bk to its name
        mv config.jsonc{,.bk}

        # Download the new image and config file
        wget -qO Arch.png https://raw.githubusercontent.com/xerolinux/xero-fixes/main/xero.png
        wget -q https://raw.githubusercontent.com/xerolinux/xero-layan-git/main/Configs/Home/.config/fastfetch/config.jsonc

        # Update the config file to use the new image name
        sed -i 's/xero.png/Arch.png/' $HOME/.config/fastfetch/config.jsonc
        sleep 2
        echo
        add_fastfetch() {
          if ! grep -Fxq 'fastfetch' "$HOME/.bashrc"; then
            echo 'fastfetch' >> "$HOME/.bashrc"
            echo "fastfetch has been added to your .bashrc and will run on Terminal launch."
          else
            echo "fastfetch is already set to run on Terminal launch."
          fi
        }

        # Prompt the user
        read -p "Do you want to enable fastfetch to run on Terminal launch? (y/n): " response

        case "$response" in
          [yY])
            add_fastfetch
            ;;
          [nN])
            echo "fastfetch will not be added to your .bashrc."
            ;;
          *)
            echo "Invalid response. Please enter y or n."
            ;;
        esac
        echo
        gum style --foreground 7 "Fastfetch setup complete!"
        sleep 3
        clear && exec "$0"
        ;;
      zsh)
        gum style --foreground 7 "Setting up ZSH with OMP & OMZ Plugins..."
        sleep 2
        echo
        # Check if zsh is already installed
        if ! command -v zsh &> /dev/null; then
          sudo -K
          sudo pacman -S --needed --noconfirm zsh grml-zsh-config fastfetch
          sudo -K
        fi
        
        # Check if oh-my-zsh is already installed
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
          sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
        $AUR_HELPER -S --noconfirm --needed pacseek ttf-meslo-nerd siji-git otf-unifont bdf-unifont noto-color-emoji-fontconfig xorg-fonts-misc ttf-dejavu ttf-meslo-nerd-font-powerlevel10k noto-fonts-emoji powerline-fonts oh-my-posh-bin
        git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        cd $HOME/ && mv ~/.zshrc ~/.zshrc.user && wget https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/.zshrc
        sleep 2
        echo
        echo "Applying Oh-My-Posh to ZSH"
        echo
        # Check if the folder exists, if not create it and download the file
        if [ ! -d "$HOME/.config/ohmyposh" ]; then
          mkdir -p "$HOME/.config/ohmyposh"
        fi
        curl -o "$HOME/.config/ohmyposh/xero.omp.json" https://raw.githubusercontent.com/XeroLinuxDev/desktop-config/refs/heads/main/etc/skel/.config/ohmyposh/xero.omp.json

        # Check if the line exists in ~/.zshrc, if not add it
        if ! grep -Fxq 'eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/xero.omp.json)"' "$HOME/.zshrc"; then
          echo '' >> "$HOME/.zshrc"
          echo 'eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/xero.omp.json)"' >> "$HOME/.zshrc"
        fi
        sleep 2
        echo
        echo "Switching to ZSH..."
        echo
        sudo chsh $USER -s /bin/zsh
        # Check if the current terminal is Konsole and if KDE Plasma is running
        if [[ "$KONSOLE_VERSION" && "$XDG_CURRENT_DESKTOP" == "KDE" ]]; then
            sed -i 's|Command=/bin/bash|Command=/bin/zsh|' "$HOME/.local/share/konsole/XeroLinux.profile"
        fi
        echo
        gum style --foreground 7 "ZSH setup complete! Log out and back in."
        sleep 3
        clear && exec "$0"
        ;;
      save_desktop)
        gum style --foreground 7 "Installing Save Desktop Tool..."
        sleep 2
        echo
        flatpak install -y io.github.vikdevelop.SaveDesktop
        echo
        gum style --foreground 7 "All Done, Enjoy..."
        sleep 3
        clear && exec "$0"
        ;;
      g)
        gum style --foreground 7 "XeroLinug Grub Themes..."
        sleep 2
        echo
        cd ~ && git clone https://github.com/xerolinux/xero-grubs
        cd ~/xero-grubs/ && sh install.sh
        echo
        rm -rf ~/xero-grubs/
        sleep 3
        clear && exec "$0"
        ;;
      h)
        gum style --foreground 7 "Hanabi Live Wallpaper (Gnome)..."
        sleep 2
        echo
        cd ~ && git clone https://github.com/jeffshee/gnome-ext-hanabi.git -b gnome-48
        cd ~/gnome-ext-hanabi/ && sh run.sh install
        echo
        sudo pacman -S --noconfirm clapper clapper-enhancers libclapper
        rm -rf ~/gnome-ext-hanabi/
        sleep 3
        clear && exec "$0"
        ;;
      x)
        gum style --foreground 200 "Setting up XeroLinux KDE Rice..."
        sleep 2
        echo
        cd ~ && git clone https://github.com/xerolinux/xero-layan-git.git
        cd ~/xero-layan-git/ && sh install.sh
        echo
        gum style --foreground 200 "XeroLinux KDE Rice setup complete!"
        sleep 3
        # Countdown from 15 to 1
        for i in {15..1}; do
            dialog --infobox "Rebooting in $i seconds..." 3 30
            sleep 1
        done
        reboot
        sleep 3
        ;;
      w)
        gum style --foreground 7 "Downloading Extra KDE Wallpapers..."
        sleep 2
        echo
        sudo pacman -S --noconfirm --needed kde-wallpapers-extra
        echo
        gum style --foreground 7 "All done, enjoy !"
        sleep 3
        clear && exec "$0"
        ;;
      u)
        gum style --foreground 200 "Applying Layan GTK4 Patch/Updating..."
        sleep 2
        echo
        cd ~ && git clone https://github.com/vinceliuice/Layan-gtk-theme.git
        cd ~/Layan-gtk-theme/ && sh install.sh -l -c dark -d $HOME/.themes
        cd ~ && rm -Rf Layan-gtk-theme/
        sleep 3
        echo
        gum style --foreground 200 "Updating Layan KDE Theme..."
        echo
        cd ~ && git clone https://github.com/vinceliuice/Layan-kde.git
        cd ~/Layan-kde/ && sh install.sh
        cd ~ && rm -Rf Layan-kde/
        echo
        gum style --foreground 200 "GTK4 Pacthing & Update Complete!"
        sleep 3
        clear && exec "$0"
        ;;
      z)
        gum style --foreground 7 "Grabbing Packages..."
        sleep 2
        echo
        $AUR_HELPER -S --noconfirm --needed ptyxis pacseek btop gparted flatseal awesome-terminal-fonts extension-manager gnome-shell-extension-arc-menu gnome-shell-extension-caffeine gnome-shell-extension-gsconnect gnome-shell-extension-arch-update gnome-shell-extension-blur-my-shell gnome-shell-extension-appindicator gnome-shell-extension-dash-to-dock gnome-shell-extension-weather-oclock chafa nautilus-share nautilus-compare nautilus-admin-gtk4 nautilus-image-converter libappindicator-gtk3 tela-circle-icon-theme-purple kvantum-theme-libadwaita-git qt5ct qt6ct kvantum fastfetch adw-gtk-theme oh-my-posh-bin ttf-fira-code guake desktop-config-gnome
        sleep 3
        echo
        gum style --foreground 7 "Applying Xero Gnome Settings..."
        echo
        cp -Rf /etc/skel/. ~
        sleep 2
        sudo mkdir -p /usr/share/defaultbg && sudo cp /home/xero/.local/share/backgrounds/Xero-G69.png /usr/share/defaultbg/XeroG.png
        sleep 2
        dconf load /org/gnome/ < /etc/skel/.config/xero-dconf.conf
        sleep 1.5
        dconf load /com/github/stunkymonkey/nautilus-open-any-terminal/ < /etc/skel/.config/term.conf
        sleep 1.5
        guake --restore-preferences=$HOME/.config/guake-prefs.cfg
        sleep 1.5
        dconf load /org/gnome/Ptyxis/ < /etc/skel/.config/Ptyxis.conf
        sleep 1.5
        dconf write /org/gnome/Ptyxis/Profiles/a8419c1b5f17fef263add7d367cd68cf/opacity 0.85
        rm ~/.config/autostart/dconf-load.desktop
        sleep 2
        cd ~ && mv .bashrc .bashrc.bk && wget https://raw.githubusercontent.com/XeroLinuxDev/xero-build/refs/heads/main/XeroG/airootfs/etc/skel/.bashrc
        echo
        gum style --foreground 7 "Settings applied, please reboot..."
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
        if command -v xero-cli &> /dev/null; then
          clear && exec xero-cli
        else
          gum style --foreground 196 "xero-cli not found. Exiting..."
          exit 1
        fi
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
