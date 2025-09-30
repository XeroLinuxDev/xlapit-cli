#!/usr/bin/env bash
set -e

# Relaunch cleanly on Ctrl+C
trap 'clear && exec "$0"' INT

SCRIPTS="/usr/share/xero-scripts/"

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

# Restart helper
restart_script() { clear && exec "$0"; }

# Package helpers
install_pacman_packages() {
  sudo -K
  sudo pacman -S --noconfirm --needed "$@" ||
    { gum style --foreground 196 "Failed to install: $*"; sleep 2; restart_script; }
  sudo -K
}

install_aur_packages() {
  $AUR_HELPER -S --noconfirm --needed "$@" ||
    { gum style --foreground 196 "Failed to install AUR: $*"; sleep 2; restart_script; }
}

install_flatpak_packages() {
  flatpak install -y "$@" ||
    { gum style --foreground 196 "Failed to install Flatpak: $*"; sleep 2; restart_script; }
}

# Package presence checks
is_pacman_installed() { pacman -Q "$1" &>/dev/null; }
is_aur_installed() { pacman -Qm "$1" &>/dev/null; }
is_flatpak_installed() { flatpak list --app --columns=application | grep -wq "^$1$"; }

# Header / Menu
display_header() {
  clear
  gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "Essential Package Installer"
  gum style --foreground 141 "Hello $USER, curated software picks below — for more use a package manager."
  echo
}

display_options() {
  local n=1
  gum style --foreground 7 "${n}. LibreOffice"; ((n++))
  gum style --foreground 7 "${n}. Web Browsers"; ((n++))
  gum style --foreground 7 "${n}. Development Tools"; ((n++))
  gum style --foreground 7 "${n}. Photo & 3D Tools"; ((n++))
  gum style --foreground 7 "${n}. Music & Audio Tools"; ((n++))
  gum style --foreground 7 "${n}. Social & Chat Tools"; ((n++))
  gum style --foreground 7 "${n}. Virtualization Tools"; ((n++))
  gum style --foreground 7 "${n}. Video Tools & Editors"
}

# Multi-select dialog
package_selection_dialog() {
  local title=$1; shift
  local options=("$@") pkg_names=()
  for ((i=0; i<${#options[@]}; i+=3)); do pkg_names+=("${options[i]}"); done

  clear
  echo -e "\n\e[36m[Space]\e[0m = select, \e[33m[ESC]\e[0m = back, \e[32m[Enter]\e[0m = confirm.\n"
  PACKAGES=$(printf "%s\n" "${pkg_names[@]}" | gum choose --no-limit --header "$title" --cursor.foreground 212 --selected.background 236) || true

  if [[ -z "$PACKAGES" ]]; then
    figlet -t -c "No selection. Returning..." | lolcat
    sleep 3
    restart_script
  fi
}

# -- Category Installers --

install_libreoffice() {
  install_pacman_packages libreoffice-fresh hunspell hunspell-en_us \
    ttf-caladea ttf-carlito ttf-dejavu ttf-liberation ttf-linux-libertine-g \
    noto-fonts adobe-source-code-pro-fonts adobe-source-sans-pro-fonts \
    adobe-source-serif-pro-fonts libreoffice-extension-texmaths libreoffice-extension-writer2latex
  gum style --foreground 7 "LibreOffice installed successfully."
  sleep 2; restart_script
}

install_browsers() {
  local opts=()
  ! is_aur_installed brave-bin && opts+=("Brave" "Privacy browser" OFF)
  ! is_pacman_installed firefox && opts+=("Firefox" "Open web browser" OFF)
  ! is_flatpak_installed com.vivaldi.Vivaldi && opts+=("Vivaldi" "Feature-packed browser" OFF)
  ! is_aur_installed mullvad-browser-bin && opts+=("Mullvad" "Anti-tracking browser" OFF)
  ! is_flatpak_installed one.ablaze.floorp && opts+=("Floorp" "Firefox fork" OFF)
  ! is_flatpak_installed io.gitlab.librewolf-community && opts+=("LibreWolf" "Privacy Firefox fork" OFF)
  ! is_flatpak_installed com.github.Eloston.UngoogledChromium && opts+=("Chromium" "Ungoogled browser" OFF)
  ! is_flatpak_installed org.torproject.torbrowser-launcher && opts+=("Tor" "Tor anonymity browser" OFF)

  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "All browsers installed." && sleep 2 && restart_script
  package_selection_dialog "Select Browsers to install:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      Brave) install_aur_packages brave-bin ;;
      Firefox) install_pacman_packages firefox firefox-ublock-origin ;;
      Vivaldi) install_flatpak_packages com.vivaldi.Vivaldi ;;
      Mullvad) install_aur_packages mullvad-browser-bin ;;
      Floorp) install_flatpak_packages one.ablaze.floorp ;;
      LibreWolf) install_flatpak_packages io.gitlab.librewolf-community ;;
      Chromium) install_flatpak_packages com.github.Eloston.UngoogledChromium ;;
      Tor) install_flatpak_packages org.torproject.torbrowser-launcher ;;
    esac
  done
  gum style --foreground 7 "Browser installation complete."
  sleep 2; restart_script
}

install_devtools() {
  local opts=()
  ! is_flatpak_installed com.google.AndroidStudio && opts+=("AndroidStudio" "Android IDE" OFF)
  ! is_pacman_installed neovide && opts+=("neoVide" "Neovim GUI" OFF)
  ! is_pacman_installed emacs && opts+=("Emacs" "Lisp-based editor" OFF)
  ! is_pacman_installed lazygit && opts+=("LazyGit" "Git TUI" OFF)
  ! is_pacman_installed hugo && opts+=("Hugo" "Static Site Generator" OFF)
  ! is_flatpak_installed io.github.shiftey.Desktop && opts+=("Github" "GitHub Desktop" OFF)
  ! is_aur_installed vscodium-bin && opts+=("VSCodium" "VSCode sans telemetry" OFF)
  ! is_pacman_installed meld && opts+=("Meld" "Visual diff tool" OFF)
  ! is_flatpak_installed com.jetbrains.IntelliJ-IDEA-Community && opts+=("IntelliJ" "Java IDE" OFF)

  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "All dev tools installed." && sleep 2 && restart_script
  package_selection_dialog "Select Development Tools:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      AndroidStudio) install_flatpak_packages com.google.AndroidStudio ;;
      neoVide) install_pacman_packages tmux neovide neovim-plug python-pynvim ;;
      Emacs) install_pacman_packages emacs ttf-ubuntu-font-family ttf-jetbrains-mono ;;
      LazyGit) install_pacman_packages lazygit ;;
      Hugo) install_pacman_packages hugo ;;
      Github) install_flatpak_packages io.github.shiftey.Desktop ;;
      VSCodium) install_aur_packages vscodium-bin vscodium-bin-marketplace ;;
      Meld) install_pacman_packages meld ;;
      IntelliJ) install_flatpak_packages com.jetbrains.IntelliJ-IDEA-Community ;;
    esac
  done
  gum style --foreground 7 "Development setup done."
  sleep 2; restart_script
}

install_photo_3d() {
  local opts=()
  ! is_flatpak_installed org.gimp.GIMP && opts+=("GiMP" "Image editor" OFF)
  ! is_flatpak_installed org.kde.krita && opts+=("Krita" "Digital painting" OFF)
  ! is_pacman_installed blender && opts+=("Blender" "3D Suite" OFF)
  ! is_pacman_installed godot && opts+=("GoDot" "Game Engine" OFF)
  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "All Photo/3D tools installed." && sleep 2 && restart_script
  package_selection_dialog "Select Photo / 3D Tools:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      GiMP) install_flatpak_packages org.gimp.GIMP ;;
      Krita) install_flatpak_packages org.kde.krita ;;
      Blender) install_pacman_packages blender ;;
      GoDot) install_pacman_packages godot ;;
    esac
  done
  gum style --foreground 7 "Photo & 3D tools installed."
  sleep 2; restart_script
}

install_music_audio() {
  local opts=()
  ! is_pacman_installed mpv && opts+=("MPV" "Media player" OFF)
  ! is_flatpak_installed com.spotify.Client && opts+=("Spotify" "Streaming" OFF)
  ! is_flatpak_installed org.tenacityaudio.Tenacity && opts+=("Tenacity" "Audio Editor" OFF)
  ! is_flatpak_installed org.strawberrymusicplayer.strawberry && opts+=("Strawberry" "Music Player" OFF)
  ! is_flatpak_installed me.timschneeberger.jdsp4linux && opts+=("JamesDSP" "Pipewire FX" OFF)
  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "All audio tools installed." && sleep 2 && restart_script
  package_selection_dialog "Select Music & Audio Tools:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      MPV) install_pacman_packages mpv mpv-mpris ;;
      Spotify) install_flatpak_packages com.spotify.Client ;;
      Tenacity) install_flatpak_packages org.tenacityaudio.Tenacity ;;
      Strawberry) install_flatpak_packages org.strawberrymusicplayer.strawberry ;;
      JamesDSP) install_flatpak_packages me.timschneeberger.jdsp4linux ;;
    esac
  done
  gum style --foreground 7 "Audio setup complete."
  sleep 2; restart_script
}

install_social_chat() {
  local opts=()
  ! is_flatpak_installed org.ferdium.Ferdium && opts+=("Ferdium" "Unified messenger" OFF)
  ! is_flatpak_installed org.telegram.desktop && opts+=("Telegram" "Official Telegram" OFF)
  ! is_flatpak_installed org.kde.tokodon && opts+=("Tokodon" "Mastodon Client" OFF)
  ! is_flatpak_installed com.rtosta.zapzap && opts+=("WhatsApp" "ZapZap client" OFF)
  ! is_pacman_installed element-desktop && opts+=("Element" "Matrix client" OFF)
  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "All chat tools installed." && sleep 2 && restart_script
  package_selection_dialog "Select Chat / Social Apps:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      Ferdium) install_flatpak_packages org.ferdium.Ferdium ;;
      Telegram) install_flatpak_packages org.telegram.desktop ;;
      Tokodon) install_flatpak_packages org.kde.tokodon ;;
      WhatsApp) install_flatpak_packages com.rtosta.zapzap ;;
      Element) install_pacman_packages element-desktop ;;
    esac
  done
  gum style --foreground 7 "Social tools installed."
  sleep 2; restart_script
}

install_virtualization() {
  local opts=()
  ! is_pacman_installed virt-manager-meta && opts+=("VirtManager" "QEMU GUI" OFF)
  ! is_pacman_installed virtualbox-meta && opts+=("VirtualBox" "x86 Virtualization" OFF)
  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "Virtualization already setup." && sleep 2 && restart_script
  package_selection_dialog "Select Virtualization Tools:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      VirtManager)
        for p in iptables gnu-netcat; do pacman -Q "$p" &>/dev/null && sudo pacman -Rdd --noconfirm "$p"; done
        install_pacman_packages virt-manager-meta openbsd-netcat
        echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf
        sudo systemctl restart libvirtd.service
        ;;
      VirtualBox)
        install_pacman_packages virtualbox-meta ;;
    esac
  done
  gum style --foreground 7 "Virtualization setup complete."
  sleep 2; restart_script
}

install_video_tools() {
  local opts=()
  ! is_pacman_installed kdenlive && opts+=("KDEnLive" "Video Editor" OFF)
  ! is_aur_installed losslesscut-bin && opts+=("LosslessCut" "Lossless Trimmer" OFF)
  ! is_flatpak_installed com.obsproject.Studio && opts+=("OBS-Studio" "Streaming Studio" OFF)
  ! is_aur_installed mystiq && opts+=("Mystiq" "FFmpeg GUI" OFF)
  ! is_pacman_installed mkvtoolnix-gui && opts+=("MKVToolNix" "Matroska Editor" OFF)
  ! is_flatpak_installed com.makemkv.MakeMKV && opts+=("MakeMKV" "DVD/BD to MKV" OFF)
  [[ ${#opts[@]} -eq 0 ]] && gum style --foreground 214 "All video tools installed." && sleep 2 && restart_script
  package_selection_dialog "Select Video Tools:" "${opts[@]}"

  for pkg in $PACKAGES; do
    case $pkg in
      KDEnLive) install_pacman_packages kdenlive ;;
      LosslessCut) install_aur_packages losslesscut-bin ;;
      OBS-Studio)
        install_flatpak_packages com.obsproject.Studio
        ;;
      Mystiq) install_aur_packages mystiq ;;
      MKVToolNix) install_flatpak_packages org.bunkus.mkvtoolnix-gui ;;
      MakeMKV) install_flatpak_packages com.makemkv.MakeMKV ;;
    esac
  done
  gum style --foreground 7 "Video tools installed."
  sleep 2; restart_script
}

# Main dispatcher
main() {
  display_header
  display_options
  echo
  read -rp "Select option (r=reboot, q=quit): " CHOICE
  case "$CHOICE" in
    1) install_libreoffice ;;
    2) install_browsers ;;
    3) install_devtools ;;
    4) install_photo_3d ;;
    5) install_music_audio ;;
    6) install_social_chat ;;
    7) install_virtualization ;;
    8) install_video_tools ;;
    r)
      gum style --foreground 33 "Rebooting..."
      for i in {5..1}; do dialog --infobox "Rebooting in $i..." 3 30; sleep 1; done
      reboot ;;
    q) clear && exec xero-cli ;;
    *) gum style --foreground 196 "Invalid choice." ;;
  esac
}

main
