## XeroLinux Essential Package Installer: Summarized Package List

This script is an interactive Bash tool for installing curated sets of packages on XeroLinux (or Arch-based systems). It organizes software into categories, allowing users to select which apps to install via a menu-driven interface.

Below is a structured summary of the main package groups and the individual packages or applications offered for installation.

### 1. LibreOffice Suite

- **Packages Installed:**
  - libreoffice-fresh
  - hunspell, hunspell-en_us
  - ttf-caladea, ttf-carlito, ttf-dejavu, ttf-liberation, ttf-linux-libertine-g, noto-fonts
  - adobe-source-code-pro-fonts, adobe-source-sans-pro-fonts, adobe-source-serif-pro-fonts
  - libreoffice-extension-texmaths, libreoffice-extension-writer2latex

### 2. Web Browsers

| Browser Name | Package(s) Installed | Source/Method |
|--------------|---------------------|--------------|
| Brave        | brave-bin           | AUR          |
| Firefox      | firefox, firefox-ublock-origin | Pacman |
| Filezilla    | org.filezillaproject.Filezilla | Flatpak |
| Vivaldi      | com.vivaldi.Vivaldi | Flatpak      |
| Mullvad      | mullvad-browser-bin | AUR          |
| Floorp       | one.ablaze.floorp   | Flatpak      |
| LibreWolf    | io.gitlab.librewolf-community | Flatpak |
| Chromium     | com.github.Eloston.UngoogledChromium | Flatpak |
| Tor Browser  | org.torproject.torbrowser-launcher | Flatpak |

### 3. Development Tools

| App/Tool      | Package(s) Installed | Source/Method |
|---------------|---------------------|--------------|
| Android Studio| com.google.AndroidStudio | Flatpak   |
| NeoVide       | tmux, neovide, neovim-plug, python-pynvim, neovim-remote, neovim-lspconfig | Pacman |
| Emacs         | emacs, ttf-ubuntu-font-family, ttf-jetbrains-mono-nerd, ttf-jetbrains-mono | Pacman |
| LazyGit       | lazygit             | Pacman       |
| Hugo          | hugo                | Pacman       |
| GitHub Desktop| io.github.shiftey.Desktop | Flatpak  |
| VSCodium      | vscodium-bin, vscodium-bin-marketplace, vscodium-bin-features | AUR |
| Meld          | meld                | Pacman       |
| Warp Terminal | warp-terminal-bin   | AUR          |
| IntelliJ IDEA | com.jetbrains.IntelliJ-IDEA-Community | Flatpak |

### 4. Photo and 3D Tools

| App/Tool   | Package(s) Installed | Source/Method |
|------------|---------------------|--------------|
| GIMP       | org.gimp.GIMP, org.gimp.GIMP.Manual, org.gimp.GIMP.Plugin.Resynthesizer, org.gimp.GIMP.Plugin.LiquidRescale, org.gimp.GIMP.Plugin.Lensfun, org.gimp.GIMP.Plugin.GMic, org.gimp.GIMP.Plugin.Fourier, org.gimp.GIMP.Plugin.FocusBlur, org.gimp.GIMP.Plugin.BIMP | Flatpak |
| Krita      | org.kde.krita       | Flatpak      |
| Blender    | blender             | Pacman       |
| Godot      | godot               | Pacman       |

### 5. Music & Audio Tools

| App/Tool    | Package(s) Installed | Source/Method |
|-------------|---------------------|--------------|
| MPV         | mpv, mpv-mpris      | Pacman       |
| Spotify     | com.spotify.Client  | Flatpak      |
| Tenacity    | org.tenacityaudio.Tenacity | Flatpak |
| Strawberry  | org.strawberrymusicplayer.strawberry | Flatpak |
| JamesDSP    | me.timschneeberger.jdsp4linux | Flatpak |
| qpwgraph    | org.rncbc.qpwgraph  | Flatpak      |

### 6. Social & Chat Tools

| App/Tool   | Package(s) Installed | Source/Method |
|------------|---------------------|--------------|
| Equibop    | io.github.equicord.equibop | Flatpak  |
| Ferdium    | org.ferdium.Ferdium | Flatpak      |
| Telegram   | org.telegram.desktop | Flatpak      |
| Tokodon    | org.kde.tokodon     | Flatpak      |
| WhatsApp   | com.rtosta.zapzap   | Flatpak      |
| Chatterino | com.chatterino.chatterino | Flatpak  |
| Element    | element-desktop     | Pacman       |
| SimpleX    | chat.simplex.simplex | Flatpak      |

### 7. Virtualization Tools

| App/Tool     | Package(s) Installed | Source/Method |
|--------------|---------------------|--------------|
| VirtManager  | virt-manager-meta, openbsd-netcat | Pacman |
| VirtualBox   | virtualbox-meta      | Pacman       |

### 8. Video Tools & Software

| App/Tool     | Package(s) Installed | Source/Method |
|--------------|---------------------|--------------|
| KDEnLive     | kdenlive            | Pacman       |
| LosslessCut  | losslesscut-bin      | AUR          |
| OBS Studio   | com.obsproject.Studio, plus many Flatpak plugins | Flatpak |
| Mystiq       | mystiq              | AUR          |
| MKVToolNix   | mkvtoolnix-gui      | Pacman       |
| MakeMKV      | com.makemkv.MakeMKV | Flatpak      |
| Avidemux     | avidemux-qt         | Pacman       |

### 9. DaVinci Resolve

- **Installer:** Downloads and runs an external script to handle DaVinci Resolve installation.

### 10. Various System Tools (Vanilla Arch only)

A large set of recommended system utilities, including (but not limited to):

linux-headers, downgrade, mkinitcpio-firmware, pkgstats, alsi, update-grub, expac, linux-firmware-marvell, eza, numlockx, lm_sensors, appstream-glib, bat, bat-extras, pacman-contrib, pacman-bintrans, yt-dlp, gnustep-base, parallel, dex, make, libxinerama, logrotate, bash-completion, gtk-update-icon-cache, gnome-disk-utility, appmenu-gtk-module, dconf-editor, dbus-python, lsb-release, asciinema, playerctl, s3fs-fuse, vi, duf, gcc, yad, zip, xdo, inxi, lzop, nmon, mkinitcpio-archiso, mkinitcpio-nfs-utils, tree, vala, btop, lshw, expac, fuse3, meson, unace, unrar, unzip, p7zip, rhash, sshfs, vnstat, nodejs, cronie, hwinfo, hardinfo2, arandr, assimp, netpbm, wmctrl, grsync, libmtp, polkit, sysprof, gparted, hddtemp, mlocate, fuseiso, gettext, node-gyp, graphviz, inetutils, appstream, cifs-utils, ntfs-3g, nvme-cli, exfatprogs, f2fs-tools, man-db, man-pages, tldr, python-pip, python-cffi, python-numpy, python-docopt, python-pyaudio, xdg-desktop-portal-gtk

---

## Notes

- **Package Sources:** Packages are installed via Pacman (official repos), AUR helpers, or Flatpak, depending on availability.
- **Menu-Driven:** The script checks if packages are already installed and only offers those not present.
- **Custom Configs:** Some development tools (e.g., NeoVide, Emacs) offer to install custom configurations from GitHub.
- **System Tools:** The "Various System Tools" option is only visible on non-XeroLinux (Vanilla Arch) systems.
