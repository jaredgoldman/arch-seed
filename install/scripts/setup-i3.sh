#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_msg() {
  echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

# Function to handle errors
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Install i3 and required packages
print_msg "Installing i3 and required packages..."
sudo pacman -S --noconfirm \
    i3-wm \
    i3status \
    i3lock \
    dmenu \
    rofi \
    feh \
    picom \
    alacritty \
    dunst \
    flameshot \
    blueberry \
    pavucontrol \
    arandr \
    dex \
    xss-lock \
    network-manager-applet \
    ttf-fira-code \
    || error_exit "Failed to install i3 and required packages"

# Create necessary directories
print_msg "Creating configuration directories..."
mkdir -p "$HOME/.config/i3" || error_exit "Failed to create i3 config directory"
mkdir -p "$HOME/.config/picom" || error_exit "Failed to create picom config directory"

# Copy i3 configuration
print_msg "Installing i3 configuration..."
cp "$INSTALL_DIR/install/configs/i3/config" "$HOME/.config/i3/config" || error_exit "Failed to copy i3 config"
cp "$INSTALL_DIR/install/configs/i3/wallpaper.jpg" "$HOME/.config/i3/wallpaper.jpg" || error_exit "Failed to copy wallpaper image"

# Create basic picom configuration
print_msg "Creating picom configuration..."
cat > "$HOME/.config/picom/picom.conf" << EOF
# Basic picom configuration
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;

# Opacity
active-opacity = 1.0;
inactive-opacity = 0.9;
frame-opacity = 1.0;
inactive-opacity-override = false;

# Fading
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Shadows
shadow = true;
shadow-radius = 12;
shadow-offset-x = -5;
shadow-offset-y = -5;
shadow-opacity = 0.5;

# Blur
blur-background = true;
blur-background-frame = true;
blur-background-fixed = true;
blur-kern = "3x3box";
blur-strength = 5;

# Other
detect-rounded-corners = true;
detect-client-opacity = true;
vsync = true;
dbe = false;
unredir-if-possible = false;
focus-exclude = [];
detect-transient = true;
detect-client-leader = true;
EOF

# Create .xinitrc if it doesn't exist
if [ ! -f "$HOME/.xinitrc" ]; then
    print_msg "Creating .xinitrc..."
    echo "exec i3" > "$HOME/.xinitrc"
fi

print_msg "i3 setup complete!"
print_msg "You can start i3 by running 'startx' or by selecting i3 from your display manager." 