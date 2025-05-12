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

# Function to detect and validate installation media
check_installation_media() {
  if ! mountpoint -q /mnt; then
    error_exit "No installation media mounted at /mnt"
  fi
  
  if [ ! -f /mnt/arch/setup/airootfs/etc/hostname ]; then
    error_exit "Invalid Arch Linux installation media"
  fi
}

# Function to handle disk partitioning
partition_disk() {
  local disk="$1"
  local profile="$2"
  
  print_msg "Partitioning disk $disk according to profile $profile"
  
  # Load partitioning scheme from profile
  if [ -f "install/profiles/$profile/partitioning.sh" ]; then
    source "install/profiles/$profile/partitioning.sh"
  else
    error_exit "Partitioning profile not found: $profile"
  fi
}

# Function to install base system
install_base() {
  local profile="$1"
  
  print_msg "Installing base system"
  pacstrap /mnt base linux linux-firmware
  
  # Generate fstab
  genfstab -U /mnt >> /mnt/etc/fstab
  
  # Copy installation scripts to new system
  cp -r install /mnt/root/
  chmod +x /mnt/root/install/scripts/*.sh
}

# Function to configure the new system
configure_system() {
  local profile="$1"
  
  print_msg "Configuring new system"
  
  # Copy configuration files
  if [ -d "install/profiles/$profile/configs" ]; then
    cp -r "install/profiles/$profile/configs/"* /mnt/etc/
  fi
  
  # Run post-installation script
  if [ -f "install/profiles/$profile/post-install.sh" ]; then
    chmod +x "install/profiles/$profile/post-install.sh"
    arch-chroot /mnt /root/install/profiles/$profile/post-install.sh
  fi
}

# Main installation function
install_arch() {
  local profile="$1"
  local disk="$2"
  
  check_root
  check_installation_media
  
  print_msg "Starting Arch Linux installation with profile: $profile"
  
  # Partition disk
  partition_disk "$disk" "$profile"
  
  # Install base system
  install_base "$profile"
  
  # Configure system
  configure_system "$profile"
  
  print_msg "Installation complete! You can now reboot into your new system."
}

# Interactive mode
interactive_mode() {
  print_msg "Starting interactive Arch Linux installation"
  
  # List available profiles
  echo "Available installation profiles:"
  ls -1 install/profiles/
  
  read -p "Enter profile name: " profile
  read -p "Enter target disk (e.g., /dev/sda): " disk
  
  install_arch "$profile" "$disk"
}

# Main script logic
if [ $# -eq 0 ]; then
  interactive_mode
else
  case "$1" in
    --profile)
      if [ -z "$2" ] || [ -z "$3" ]; then
        error_exit "Usage: $0 --profile <profile_name> <disk>"
      fi
      install_arch "$2" "$3"
      ;;
    --help|-h)
      echo "Usage: $0 [--profile <profile_name> <disk>]"
      echo "  --profile    Install using specified profile and disk"
      echo "  --help       Show this help message"
      echo "  (no args)    Start interactive installation"
      ;;
    *)
      error_exit "Unknown option: $1"
      ;;
  esac
fi 