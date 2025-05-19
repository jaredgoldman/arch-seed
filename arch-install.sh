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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  error_exit "Please run as root"
fi

# Get disk from user
read -p "Enter the disk to install to (e.g. /dev/sda): " DISK

# Run partitioning script
print_msg "Partitioning disk..."
./install/profiles/default/partitioning.sh "$DISK" || error_exit "Failed to partition disk"

# Install base system
print_msg "Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware || error_exit "Failed to install base system"

# Generate fstab
print_msg "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab || error_exit "Failed to generate fstab"

# Copy the repository to the new system
print_msg "Copying installation files..."
cp -r . /mnt/root/install || error_exit "Failed to copy installation files"

# Chroot into the new system and run post-install
print_msg "Running post-installation setup..."
arch-chroot /mnt /root/install/install/profiles/default/post-install.sh || error_exit "Failed to run post-installation"

# Unmount everything
print_msg "Unmounting partitions..."
umount -R /mnt || error_exit "Failed to unmount partitions"

print_msg "Installation complete! You can now reboot into your new system."
print_msg "After rebooting, run 'bootstrap.sh' to complete the setup." 