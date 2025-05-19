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

# Check if git is installed
if ! command -v git &> /dev/null; then
  print_msg "Installing git..."
  sudo pacman -S --noconfirm git || error_exit "Failed to install git"
fi

# Check if make is installed
if ! command -v make &> /dev/null; then
  print_msg "Installing make..."
  sudo pacman -S --noconfirm make || error_exit "Failed to install make"
fi

# Set installation directory to current directory
INSTALL_DIR="$(pwd)"

print_msg "Installing from $INSTALL_DIR..."

# Install the tool
print_msg "Installing arch-setup..."
sudo make install || error_exit "Failed to install arch-setup"

# Initialize the tool
print_msg "Initializing arch-setup..."
arch-setup install

print_msg "Installation complete! You can now use 'arch-setup' from anywhere."
print_msg "Try 'arch-setup help' to see available commands."

# Configure network using environment file
print_msg "Configuring network..."
sudo ./install/scripts/configure-network.sh --env || error_exit "Failed to configure network"

# Run the development environment setup script
print_msg "Setting up development environment..."
./install/scripts/setup-dev-env.sh

# Run the Node.js tools setup script
print_msg "Setting up Node.js tools..."
./install/scripts/setup-node-tools.sh

# Run the CLI tools and security setup script
print_msg "Setting up CLI tools and security..."
./install/scripts/setup-cli-tools.sh

# Run the AWS CLI and Font Awesome setup script
print_msg "Setting up AWS CLI and Font Awesome..."
./install/scripts/setup-aws-fonts.sh

# Run the i3 setup script
print_msg "Setting up i3 window manager..."
./install/scripts/setup-i3.sh