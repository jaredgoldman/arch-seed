#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to handle errors
error_exit() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

# Print status message
print_msg() {
  echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

# Function to check if running as root
check_root() {
  if [ "$(id -u)" != "0" ]; then
    error_exit "This script must be run as root"
  fi
}

# Function to install GNOME packages
install_gnome() {
  print_msg "Installing GNOME desktop environment..."
  
  # Install GNOME and common applications
  sudo pacman -S --noconfirm \
    gnome \
    gnome-extra \
    gnome-tweaks \
    gnome-shell-extensions \
    gdm \
    networkmanager \
    network-manager-applet \
    xdg-user-dirs-gtk \
    xdg-utils \
    xdg-desktop-portal-gnome \
    gnome-keyring \
    libsecret \
    seahorse \
    gnome-backgrounds \
    gnome-calculator \
    gnome-calendar \
    gnome-clocks \
    gnome-contacts \
    gnome-control-center \
    gnome-disk-utility \
    gnome-documents \
    gnome-font-viewer \
    gnome-logs \
    gnome-maps \
    gnome-music \
    gnome-photos \
    gnome-screenshot \
    gnome-settings-daemon \
    gnome-shell \
    gnome-software \
    gnome-system-monitor \
    gnome-terminal \
    gnome-weather \
    gnome-usage \
    gnome-user-share \
    gnome-video-effects \
    gnome-characters \
    gnome-color-manager \
    gnome-dictionary \
    gnome-getting-started-docs \
    gnome-initial-setup \
    gnome-packagekit \
    gnome-power-manager \
    gnome-session \
    gnome-shell-extensions \
    gnome-software-packagekit-plugin \
    gnome-sound-recorder \
    gnome-tour \
    gnome-user-docs \
    gnome-video-effects \
    gnome-weather \
    gnome-usage \
    gnome-user-share \
    gnome-characters \
    gnome-color-manager \
    gnome-dictionary \
    gnome-getting-started-docs \
    gnome-initial-setup \
    gnome-packagekit \
    gnome-power-manager \
    gnome-session \
    gnome-shell-extensions \
    gnome-software-packagekit-plugin \
    gnome-sound-recorder \
    gnome-tour \
    gnome-user-docs

  # Install additional GNOME packages
  sudo pacman -S --noconfirm \
    adwaita-icon-theme \
    adwaita-qt5 \
    adwaita-qt6 \
    gtk3 \
    gtk4 \
    gvfs \
    gvfs-afc \
    gvfs-goa \
    gvfs-gphoto2 \
    gvfs-mtp \
    gvfs-nfs \
    gvfs-smb \
    nautilus \
    nautilus-sendto \
    nautilus-share \
    nautilus-terminal \
    nautilus-typeahead \
    nautilus-wallpaper \
    nautilus-actions \
    nautilus-admin \
    nautilus-compare \
    nautilus-copy-path \
    nautilus-dropbox \
    nautilus-emblems \
    nautilus-filename-repairer \
    nautilus-folder-icons \
    nautilus-git \
    nautilus-gtkhash \
    nautilus-hide \
    nautilus-image-converter \
    nautilus-open-any-terminal \
    nautilus-open-terminal \
    nautilus-preview \
    nautilus-python \
    nautilus-renamer \
    nautilus-scripts-manager \
    nautilus-seahorse \
    nautilus-share \
    nautilus-sidebar \
    nautilus-terminal \
    nautilus-typeahead \
    nautilus-wallpaper \
    nautilus-actions \
    nautilus-admin \
    nautilus-compare \
    nautilus-copy-path \
    nautilus-dropbox \
    nautilus-emblems \
    nautilus-filename-repairer \
    nautilus-folder-icons \
    nautilus-git \
    nautilus-gtkhash \
    nautilus-hide \
    nautilus-image-converter \
    nautilus-open-any-terminal \
    nautilus-open-terminal \
    nautilus-preview \
    nautilus-python \
    nautilus-renamer \
    nautilus-scripts-manager \
    nautilus-seahorse \
    nautilus-share \
    nautilus-sidebar \
    nautilus-terminal \
    nautilus-typeahead \
    nautilus-wallpaper
}

# Function to configure GNOME
configure_gnome() {
  print_msg "Configuring GNOME..."
  
  # Enable GDM
  systemctl enable gdm
  
  # Set default GNOME settings
  sudo -u $SUDO_USER dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Arc'
  sudo -u $SUDO_USER dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
  sudo -u $SUDO_USER dbus-launch gsettings set org.gnome.desktop.interface font-name 'DejaVu Sans 11'
  sudo -u $SUDO_USER dbus-launch gsettings set org.gnome.desktop.interface monospace-font-name 'DejaVu Sans Mono 11'
  
  # Configure GNOME extensions
  if command -v gnome-extensions &> /dev/null; then
    # Install common extensions
    sudo -u $SUDO_USER gnome-extensions install \
      "appindicatorsupport@rgcjonas.gmail.com" \
      "dash-to-dock@micxgx.gmail.com" \
      "user-theme@gnome-shell-extensions.gcampax.github.com" \
      "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
    
    # Enable extensions
    sudo -u $SUDO_USER gnome-extensions enable "appindicatorsupport@rgcjonas.gmail.com"
    sudo -u $SUDO_USER gnome-extensions enable "dash-to-dock@micxgx.gmail.com"
    sudo -u $SUDO_USER gnome-extensions enable "user-theme@gnome-shell-extensions.gcampax.github.com"
    sudo -u $SUDO_USER gnome-extensions enable "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
  fi
}

# Function to set up user preferences
setup_preferences() {
  print_msg "Setting up user preferences..."
  
  # Create user config directory
  mkdir -p "/home/$SUDO_USER/.config/gtk-3.0"
  
  # Set up GTK theme
  cat > "/home/$SUDO_USER/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Arc
gtk-icon-theme-name=Papirus
gtk-font-name=DejaVu Sans 11
gtk-cursor-theme-name=Adwaita
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-animations=1
EOF

  # Set correct permissions
  chown -R "$SUDO_USER:$SUDO_USER" "/home/$SUDO_USER/.config"
}

# Main function
main() {
  check_root
  install_gnome
  configure_gnome
  setup_preferences
  
  print_msg "GNOME setup complete! Please reboot your system."
}

# Run main function
main "$@" 