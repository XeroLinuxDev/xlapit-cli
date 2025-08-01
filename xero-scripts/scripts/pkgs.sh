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

SCRIPTS="/usr/share/xero-scripts/"

# Function to detect if running on XeroLinux
is_xerolinux() {
    grep -q "XeroLinux" /etc/os-release
}

# Function to display header
display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Essential Package Installer"
  gum style --foreground 141 "Hello $USER, this is a curated list of packages, for more use a package manager."
  echo
}

# Function to display options
display_options() {
  # Dynamic numbering for visible options
  local option_number=1
  
  gum style --foreground 7 "${option_number}. LibreOffice."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Web Browsers."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Development Tools."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Photo and 3D Tools."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Music & Audio Tools."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Social & Chat Tools."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Virtualization Tools."
  ((option_number++))
  gum style --foreground 7 "${option_number}. Video Tools & Software."
  ((option_number++))
  gum style --foreground 7 "${option_number}. DaVinci Resolve (Free/Studio)."
  ((option_number++))
  # Only show "(Vanilla Arch)" option if not running XeroLinux
  if ! is_xerolinux; then
    gum style --foreground 7 "${option_number}. Various System Tools (Vanilla Arch)."
  fi
}

# Function to install packages using pacman
install_pacman_packages() {
    sudo -K
    if ! sudo pacman -S --noconfirm --needed "$@"; then
        gum style --foreground 196 "Failed to install package(s): $*"
        sleep 2
        clear && exec "$0"
    fi
    sudo -K
}

# Function to install packages using AUR Helper
install_aur_packages() {
    if ! $AUR_HELPER -S --noconfirm --needed "$@"; then
        gum style --foreground 196 "Failed to install AUR package(s): $*"
        sleep 2
        clear && exec "$0"
    fi
}

# Function to install flatpak packages
install_flatpak_packages() {
    if ! flatpak install -y "$@"; then
        gum style --foreground 196 "Failed to install Flatpak package(s): $*"
        sleep 2
        clear && exec "$0"
    fi
}

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
                Brave)
                    clear
                    install_aur_packages brave-bin
                    ;;
                Firefox)
                    clear
                    install_pacman_packages firefox firefox-ublock-origin
                    ;;
                Filezilla)
                    clear
                    install_flatpak_packages org.filezillaproject.Filezilla
                    ;;
                Vivaldi)
                    clear
                    install_flatpak_packages com.vivaldi.Vivaldi
                    ;;
                Mullvad)
                    clear
                    install_aur_packages mullvad-browser-bin
                    ;;
                Floorp)
                    clear
                    install_flatpak_packages flathub one.ablaze.floorp
                    ;;
                LibreWolf)
                    clear
                    install_flatpak_packages io.gitlab.librewolf-community
                    ;;
                Chromium)
                    clear
                    install_flatpak_packages com.github.Eloston.UngoogledChromium
                    ;;
                Tor)
                    clear
                    install_flatpak_packages org.torproject.torbrowser-launcher
                    ;;
                AndroidStudio)
                    clear
                    install_flatpak_packages com.google.AndroidStudio
                    ;;
                neoVide)
                    clear
                    install_pacman_packages tmux neovide neovim-plug python-pynvim neovim-remote neovim-lspconfig
                    sleep 3
                    echo
                    if [ -d "$HOME/.config/nvim" ]; then
                        gum style --foreground 196 --bold "Warning: NeoVim configuration folder already exists!"
                        echo
                        read -rp "Would you like to Backup & Replace it with Xero/Drew's config ? (y/n): " replace_config
                        if [[ $replace_config =~ ^[Yy]$ ]]; then
                            backup_date=$(date '+%Y-%m-%d-%H')
                            echo
                            echo "Backing up existing nVim config..."

                            # Backup existing folders with date suffix
                            [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bk-$backup_date"
                            [ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bk-$backup_date"
                            [ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bk-$backup_date"
                            [ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bk-$backup_date"

                            echo
                            gum style --foreground 212 ".:: Importing Xero/Drew Custom nVim Config ::."
                            echo
                            cd ~/.config/ && git clone https://github.com/xerolinux/nvim.git && \
                            rm ~/.config/nvim/LICENSE ~/.config/nvim/README.md ~/.config/nvim/.gitignore && \
                            rm -rf ~/.config/nvim/.git
                            echo
                            gum style --foreground 196 --bold "Backups crea20ted under ~/.config/nvim.bk-date & ~/.local/share/nvim.bk-date"
                            sleep 6
                        else
                            echo
                            echo "Keeping your custom configuration. Returning to menu..."
                            sleep 3
                            continue
                        fi
                    else
                        echo
                        gum style --foreground 212 ".:: Importing Xero/Drew Custom nVim Config ::."
                        echo
                        cd ~/.config/ && git clone https://github.com/xerolinux/nvim.git && \
                        rm ~/.config/nvim/LICENSE ~/.config/nvim/README.md ~/.config/nvim/.gitignore && \
                        rm -rf ~/.config/nvim/.git
                    fi
                    sleep 6
                    ;;
                Hugo)
                    clear
                    install_pacman_packages hugo
                    ;;
                Github)
                    clear
                    install_flatpak_packages io.github.shiftey.Desktop
                    ;;
                VSCodium)
                    clear
                    install_aur_packages vscodium-bin vscodium-bin-marketplace vscodium-bin-features
                    ;;
                Meld)
                    clear
                    install_pacman_packages meld
                    ;;
                Cursor)
                    clear
                    install_aur_packages cursor-extracted
                    ;;
                Emacs)
                    clear
                    echo "Please select which version you want to install :"
                    echo
                    echo "1. Vanilla Emacs"
                    echo "2. DistroTube's Emacs"
                    echo
                    read -rp "Enter your choice (1 or 2): " emacs_choice
                    echo
                    case $emacs_choice in
                        1)
                            install_pacman_packages emacs ttf-ubuntu-font-family ttf-jetbrains-mono-nerd ttf-jetbrains-mono
                            ;;
                        2)
                            install_pacman_packages emacs ttf-ubuntu-font-family ttf-jetbrains-mono-nerd ttf-jetbrains-mono
                            echo
                            echo ".:: Importing DistroTube's Custom emacs Config ::."
                            echo
                            cd ~ && git clone https://github.com/xerolinux/eMacs-Config.git && cd eMacs-Config/ && cp -R emacs/ $HOME/.config
                            rm -rf ~/emacs/ && rm -rf ~/emacs/eMacs-Config/
                            sleep 6
                            ;;
                        *)
                            echo "Invalid choice. Returning to menu."
                            ;;
                    esac
                    ;;
                LazyGit)
                    clear
                    install_pacman_packages lazygit
                    ;;
                Warp)
                    clear
                    install_aur_packages warp-terminal-bin
                    ;;
                IntelliJ)
                    clear
                    install_flatpak_packages com.jetbrains.IntelliJ-IDEA-Community
                    ;;
                GiMP)
                    clear
                    install_flatpak_packages org.gimp.GIMP org.gimp.GIMP.Manual org.gimp.GIMP.Plugin.Resynthesizer org.gimp.GIMP.Plugin.LiquidRescale org.gimp.GIMP.Plugin.Lensfun org.gimp.GIMP.Plugin.GMic org.gimp.GIMP.Plugin.Fourier org.gimp.GIMP.Plugin.FocusBlur org.gimp.GIMP.Plugin.BIMP
                    ;;
                Krita)
                    clear
                    install_flatpak_packages flathub org.kde.krita
                    ;;
                Blender)
                    clear
                    install_pacman_packages blender
                    ;;
                GoDot)
                    clear
                    install_pacman_packages godot
                    ;;
                MPV)
                    clear
                    install_pacman_packages mpv mpv-mpris
                    ;;
                Spotify)
                    clear
                    install_flatpak_packages com.spotify.Client
                    ;;
                Tenacity)
                    clear
                    install_flatpak_packages org.tenacityaudio.Tenacity
                    ;;
                Strawberry)
                    clear
                    install_flatpak_packages org.strawberrymusicplayer.strawberry
                    ;;
                JamesDSP)
                    clear
                    install_flatpak_packages me.timschneeberger.jdsp4linux
                    ;;
                qpwgraph)
                    clear
                    install_flatpak_packages org.rncbc.qpwgraph
                    ;;
                Equibop)
                    clear
                    install_flatpak_packages io.github.equicord.equibop
                    ;;
                Ferdium)
                    clear
                    install_flatpak_packages org.ferdium.Ferdium
                    ;;
                Telegram)
                    clear
                    install_flatpak_packages org.telegram.desktop
                    ;;
                Tokodon)
                    clear
                    install_flatpak_packages org.kde.tokodon
                    ;;
                WhatsApp)
                    clear
                    install_flatpak_packages com.rtosta.zapzap
                    ;;
                Chatterino)
                    clear
                    install_flatpak_packages com.chatterino.chatterino
                    ;;
                Element)
                    clear
                    install_pacman_packages element-desktop
                    ;;
                SimpleX)
                    clear
                    install_flatpak_packages chat.simplex.simplex
                    ;;
                VirtManager)
                    clear
                    for pkg in iptables gnu-netcat; do
                        if pacman -Q $pkg &>/dev/null; then
                            sudo pacman -Rdd --noconfirm $pkg
                        fi
                    done;
                    install_pacman_packages virt-manager-meta openbsd-netcat
                    echo -e "options kvm-intel nested=1" | sudo tee -a /etc/modprobe.d/kvm-intel.conf
                    sudo systemctl restart libvirtd.service
                    echo
                    ;;
                VirtualBox)
                    clear
                    install_pacman_packages virtualbox-meta
                    ;;
                KDEnLive)
                    clear
                    install_pacman_packages kdenlive
                    ;;
                LosslessCut)
                    clear
                    install_aur_packages losslesscut-bin
                    ;;
                OBS-Studio)
                    clear
                    install_flatpak_packages com.obsproject.Studio com.obsproject.Studio.Plugin.waveform com.obsproject.Studio.Plugin.WebSocket com.obsproject.Studio.Plugin.TransitionTable com.obsproject.Studio.Plugin.SceneSwitcher com.obsproject.Studio.Plugin.ScaleToSound com.obsproject.Studio.Plugin.OBSVkCapture com.obsproject.Studio.Plugin.MoveTransition com.obsproject.Studio.Plugin.Gstreamer com.obsproject.Studio.Plugin.GStreamerVaapi com.obsproject.Studio.Plugin.DroidCam com.obsproject.Studio.Plugin.BackgroundRemoval com.obsproject.Studio.Plugin.AitumMultistream com.obsproject.Studio.Plugin.AdvancedMasks com.obsproject.Studio.Plugin.CompositeBlur com.obsproject.Studio.Plugin.SourceClone com.obsproject.Studio.Plugin.DownstreamKeyer com.obsproject.Studio.Plugin.Shaderfilter com.obsproject.Studio.Plugin.FreezeFilter com.obsproject.Studio.Plugin.SourceRecord org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08
                    install_aur_packages obs-vkcapture-git lib32-obs-vkcapture-git
                    if pacman -Q obs-studio &> /dev/null; then
                        sudo pacman -Rdd --noconfirm obs-studio
                    fi
                    ;;
                Mystiq)
                    clear
                    install_aur_packages mystiq
                    ;;
                MKVToolNix)
                    clear
                    install_pacman_packages mkvtoolnix-gui
                    ;;
                MakeMKV)
                    clear
                    install_flatpak_packages com.makemkv.MakeMKV
                    ;;
                Avidemux)
                    clear
                    install_pacman_packages avidemux-qt
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

# Function to process user choice
process_choice() {
  while :; do
    echo
    read -rp "Enter your choice, 'r' to reboot or 'q' for main menu : " CHOICE
    echo

    # Map user choice to actual option based on what's visible
    local actual_choice=""
    if ! is_xerolinux; then
      # On vanilla Arch: 1=libreoffice, 2=browsers, 3=dev, 4=photo, 5=music, 6=social, 7=virt, 8=video, 9=davinci, 10=system_tools
      case $CHOICE in
        1) actual_choice="libreoffice" ;;
        2) actual_choice="browsers" ;;
        3) actual_choice="dev" ;;
        4) actual_choice="photo" ;;
        5) actual_choice="music" ;;
        6) actual_choice="social" ;;
        7) actual_choice="virt" ;;
        8) actual_choice="video" ;;
        9) actual_choice="davinci" ;;
        10) actual_choice="system_tools" ;;
        *) actual_choice="$CHOICE" ;;
      esac
    else
      # On XeroLinux: 1=libreoffice, 2=browsers, 3=dev, 4=photo, 5=music, 6=social, 7=virt, 8=video, 9=davinci (since system_tools is hidden)
      case $CHOICE in
        1) actual_choice="libreoffice" ;;
        2) actual_choice="browsers" ;;
        3) actual_choice="dev" ;;
        4) actual_choice="photo" ;;
        5) actual_choice="music" ;;
        6) actual_choice="social" ;;
        7) actual_choice="virt" ;;
        8) actual_choice="video" ;;
        9) actual_choice="davinci" ;;
        *) actual_choice="$CHOICE" ;;
      esac
    fi

    case $actual_choice in
      libreoffice)
        install_pacman_packages libreoffice-fresh hunspell hunspell-en_us ttf-caladea ttf-carlito ttf-dejavu ttf-liberation ttf-linux-libertine-g noto-fonts adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts libreoffice-extension-texmaths libreoffice-extension-writer2latex
        echo
        gum style --foreground 7 "##########  Done, Please Reboot !  ##########"
        sleep 3
        clear && exec "$0"
        ;;
      browsers)
        # Browsers
        browser_options=()
        ! is_pacman_installed brave-bin && browser_options+=("Brave" "The web browser from Brave" OFF)
        ! is_pacman_installed firefox && browser_options+=("Firefox" "Fast, Private & Safe Web Browser" OFF)
        ! is_flatpak_installed org.filezillaproject.Filezilla && browser_options+=("Filezilla" "Fast and reliable FTP client" OFF)
        ! is_flatpak_installed com.vivaldi.Vivaldi && browser_options+=("Vivaldi" "Feature-packed web browser" OFF)
        ! is_aur_installed mullvad-browser-bin && browser_options+=("Mullvad" "Mass surveillance free browser" OFF)
        ! is_flatpak_installed one.ablaze.floorp && browser_options+=("Floorp" "A Firefox-based Browser" OFF)
        ! is_flatpak_installed io.gitlab.librewolf-community && browser_options+=("LibreWolf" "LibreWolf Web Browser" OFF)
        ! is_flatpak_installed com.github.Eloston.UngoogledChromium && browser_options+=("Chromium" "Ungoogled Chromium Browser" OFF)
        ! is_flatpak_installed org.torproject.torbrowser-launcher && browser_options+=("Tor" "Tor Browser Bundle" OFF)
        if [ ${#browser_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All browser packages are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select Browser(s) to install:" "${browser_options[@]}"
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "##########  Done ! ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      dev)
        # Development Tools
        dev_options=()
        ! is_flatpak_installed com.google.AndroidStudio && dev_options+=("AndroidStudio" "IDE for Android app development" OFF)
        ! is_pacman_installed neovide && dev_options+=("neoVide" "No Nonsense Neovim Client in Rust" OFF)
        ! is_pacman_installed emacs && dev_options+=("Emacs" "An extensible & customizable text editor" OFF)
        ! is_pacman_installed lazygit && dev_options+=("LazyGit" "Powerful terminal UI for git commands" OFF)
        ! is_pacman_installed hugo && dev_options+=("Hugo" "The fastest Static Site Generator" OFF)
        ! is_flatpak_installed io.github.shiftey.Desktop && dev_options+=("Github" "GitHub Desktop application" OFF)
        ! is_aur_installed vscodium-bin && dev_options+=("VSCodium" "Telemetry-less code editing" OFF)
        ! is_pacman_installed meld && dev_options+=("Meld" "Visual diff and merge tool" OFF)
        ! is_aur_installed warp-terminal-bin && dev_options+=("Warp" "The intelligent terminal with AI" OFF)
        ! is_flatpak_installed com.jetbrains.IntelliJ-IDEA-Community && dev_options+=("IntelliJ" "IntelliJ IDEA IDE for Java" OFF)
        if [ ${#dev_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All development tools are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select Development Apps to install :" "${dev_options[@]}"
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "##########  Done ! ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      photo)
        # Photo and 3D Tools
        photo_options=()
        ! is_flatpak_installed org.gimp.GIMP && photo_options+=("GiMP" "GNU Image Manipulation Program" OFF)
        ! is_flatpak_installed org.kde.krita && photo_options+=("Krita" "Edit and paint images" OFF)
        ! is_pacman_installed blender && photo_options+=("Blender" "A 3D graphics creation suite" OFF)
        ! is_pacman_installed godot && photo_options+=("GoDot" "Cross-platform 3D game engine" OFF)
        if [ ${#photo_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All photo/3D tools are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select Photography & 3D Apps to install:" "${photo_options[@]}"
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "##########  Done ! ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      music)
        # Music & Media Tools
        music_options=()
        ! is_pacman_installed mpv && music_options+=("MPV" "An OpenSource media player" OFF)
        ! is_flatpak_installed com.spotify.Client && music_options+=("Spotify" "Online music streaming service" OFF)
        ! is_flatpak_installed org.tenacityaudio.Tenacity && music_options+=("Tenacity" "Telemetry-less Audio editing" OFF)
        ! is_flatpak_installed org.strawberrymusicplayer.strawberry && music_options+=("Strawberry" "A music player for collectors" OFF)
        ! is_flatpak_installed me.timschneeberger.jdsp4linux && music_options+=("JamesDSP" "FOSS audio effect processor for Pipewire" OFF)
        ! is_flatpak_installed org.rncbc.qpwgraph && music_options+=("qpwgraph" "A PipeWire Graph Qt GUI Interface" OFF)
        if [ ${#music_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All music/media tools are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select Music & Media Apps to install:" "${music_options[@]}"
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "##########  Done ! ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      social)
        # Social & Chat Tools
        social_options=()
        ! is_flatpak_installed io.github.equicord.equibop && social_options+=("Equibop" "Snappier Discord app with Equicord" OFF)
        ! is_flatpak_installed org.ferdium.Ferdium && social_options+=("Ferdium" "Organize many web-apps into one" OFF)
        ! is_flatpak_installed org.telegram.desktop && social_options+=("Telegram" "Official Telegram Desktop client" OFF)
        ! is_flatpak_installed org.kde.tokodon && social_options+=("Tokodon" "A Mastodon client for Plasma" OFF)
        ! is_flatpak_installed com.rtosta.zapzap && social_options+=("WhatsApp" "WhatsApp client called ZapZap" OFF)
        ! is_flatpak_installed com.chatterino.chatterino && social_options+=("Chatterino" "A Chat client for twitch.tv" OFF)
        ! is_pacman_installed element-desktop && social_options+=("Element" "Matrix collaboration client" OFF)
        ! is_flatpak_installed chat.simplex.simplex && social_options+=("SimpleX" "A private & encrypted messenger" OFF)
        if [ ${#social_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All social/chat tools are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select Social/Web Apps to install:" "${social_options[@]}"
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "##########  Done ! ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      virt)
        # Virtualization Tools
        virt_options=()
        ! is_pacman_installed virt-manager-meta && virt_options+=("VirtManager" "QEMU virtual machines" OFF)
        ! is_pacman_installed virtualbox-meta && virt_options+=("VirtualBox" "x86 virtualization" OFF)
        if [ ${#virt_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All virtualization tools are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select Virtualization System to install:" "${virt_options[@]}"
          if [ -n "$PACKAGES" ]; then
            for PACKAGE in $PACKAGES; do
              case $PACKAGE in
                VirtManager)
                  clear
                  for pkg in iptables gnu-netcat; do
                    if pacman -Q $pkg &>/dev/null; then
                      sudo pacman -Rdd --noconfirm $pkg
                    fi
                  done;
                  install_pacman_packages virt-manager-meta openbsd-netcat
                  echo -e "options kvm-intel nested=1" | sudo tee -a /etc/modprobe.d/kvm-intel.conf
                  sudo systemctl restart libvirtd.service
                  echo
                  ;;
                VirtualBox)
                  clear
                  install_pacman_packages virtualbox-meta
                  ;;
              esac
            done
          fi
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "########## Done! Please Reboot. ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      video)
        # Video Tools & Software
        video_options=()
        ! is_pacman_installed kdenlive && video_options+=("KDEnLive" "A non-linear video editor" OFF)
        ! is_aur_installed losslesscut-bin && video_options+=("LosslessCut" "GUI tool for lossless trimming of videos" OFF)
        ! is_flatpak_installed com.obsproject.Studio && video_options+=("OBS-Studio" "Includes many Plugins (Flatpak)" OFF)
        ! is_aur_installed mystiq && video_options+=("Mystiq" "FFmpeg GUI front-end based on Qt5" OFF)
        ! is_pacman_installed mkvtoolnix-gui && video_options+=("MKVToolNix" "Matroska files creator and tools" OFF)
        ! is_flatpak_installed com.makemkv.MakeMKV && video_options+=("MakeMKV" "DVD and Blu-ray to MKV converter" OFF)
        ! is_pacman_installed avidemux-qt && video_options+=("Avidemux" "Graphical tool to edit video" OFF)
        if [ ${#video_options[@]} -eq 0 ]; then
          gum style --foreground 7 "All video tools are already installed."
          sleep 3
          clear && exec "$0"
        else
          package_selection_dialog "Select App(s) to install :" "${video_options[@]}"
        fi
        if [ "${PKG_DIALOG_EXITED:-0}" -eq 0 ]; then
          echo
          gum style --foreground 7 "##########  Done ! ##########"
          sleep 3
        fi
        clear && exec "$0"
        ;;
      davinci)
        bash -c "$(curl -fsSL https://xerolinux.xyz/script/davinci.sh)"
        clear && exec "$0"
        ;;
      system_tools)
        gum style --foreground 7 "########## Installing Recommended Tools ##########"
        echo
        gum style --foreground 200 "Be patient while this installs the many recommended packages..."
        echo
        sleep 3
        install_aur_packages linux-headers downgrade mkinitcpio-firmware pkgstats alsi update-grub expac linux-firmware-marvell eza numlockx lm_sensors appstream-glib bat bat-extras pacman-contrib pacman-bintrans yt-dlp gnustep-base parallel dex make libxinerama logrotate bash-completion gtk-update-icon-cache gnome-disk-utility appmenu-gtk-module dconf-editor dbus-python lsb-release asciinema playerctl s3fs-fuse vi duf gcc yad zip xdo inxi lzop nmon mkinitcpio-archiso mkinitcpio-nfs-utils tree vala btop lshw expac fuse3 meson unace unrar unzip p7zip rhash sshfs vnstat nodejs cronie hwinfo hardinfo2 arandr assimp netpbm wmctrl grsync libmtp polkit sysprof gparted hddtemp mlocate fuseiso gettext node-gyp graphviz inetutils appstream cifs-utils ntfs-3g nvme-cli exfatprogs f2fs-tools man-db man-pages tldr python-pip python-cffi python-numpy python-docopt python-pyaudio xdg-desktop-portal-gtk
        echo
        gum style --foreground 7 "##########  Done ! ##########"
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
