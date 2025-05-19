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

# Function to detect available disks
detect_disks() {
  print_msg "Detecting available disks..."
  
  # Debug: Show current user and permissions
  echo "Current user: $(whoami)"
  echo "Current EUID: $EUID"
  
  # Debug: Show raw lsblk output
  echo "Raw lsblk output:"
  sudo lsblk -J -o NAME,SIZE,MODEL,TYPE
  
  # Get all block devices with more detailed information
  local disks=()
  
  # Get all disk information at once using JSON format
  local all_disks
  all_disks=$(sudo lsblk -J -o NAME,SIZE,MODEL,TYPE)
  
  # Process JSON output
  while IFS= read -r line; do
    # Skip empty lines and non-device lines
    [ -z "$line" ] && continue
    [[ "$line" != *"\"type\":\"disk\""* ]] && continue
    
    # Extract device information
    local name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    local size=$(echo "$line" | grep -o '"size":"[^"]*"' | cut -d'"' -f4)
    local model=$(echo "$line" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
    
    # Skip if any required field is missing
    [ -z "$name" ] || [ -z "$size" ] || [ -z "$model" ] && continue
    
    # Add NVMe tag if it's an NVMe device
    if [[ "$name" =~ ^nvme ]]; then
      disks+=("$name (${size}) - $model [NVMe]")
    else
      disks+=("$name (${size}) - $model")
    fi
  done < <(echo "$all_disks" | grep -A 4 '"type":"disk"')

  # If no disks found
  if [ ${#disks[@]} -eq 0 ]; then
    error_exit "No suitable disks found"
  fi

  # Print available disks
  print_msg "Available disks:"
  for i in "${!disks[@]}"; do
    echo "$((i+1)). ${disks[$i]}"
  done

  # Get user selection
  local choice
  while true; do
    read -p "Select disk number (1-${#disks[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#disks[@]} ]; then
      # Extract disk name from selection
      DISK="/dev/$(echo "${disks[$((choice-1))]}" | cut -d' ' -f1)"
      break
    fi
    echo "Invalid selection. Please try again."
  done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  error_exit "Please run as root"
fi

# Detect and select disk
detect_disks

print_msg "Selected disk: $DISK"
read -p "Are you sure you want to partition $DISK? This will erase all data! (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  error_exit "Installation cancelled"
fi

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