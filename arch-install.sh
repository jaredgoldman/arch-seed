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
  
  # Debug: Show raw lsblk output with explicit sudo
  echo "Raw lsblk output:"
  sudo lsblk -d -o NAME,SIZE,MODEL,TYPE
  
  # Get all block devices with more detailed information
  local disks=()
  
  # Create a temporary file for lsblk output
  local temp_file=$(mktemp)
  sudo lsblk -d -o NAME,SIZE,MODEL,TYPE -n > "$temp_file"
  
  # Process the output file
  while IFS= read -r line; do
    # Skip loop devices and partitions
    if [[ "$line" =~ loop[0-9]+$ ]] || [[ "$line" =~ [0-9]+$ ]]; then
      continue
    fi
    # Get disk name and size
    local name=$(echo "$line" | awk '{print $1}')
    local size=$(echo "$line" | awk '{print $2}')
    local model=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf $i" "; print ""}')
    local type=$(echo "$line" | awk '{print $NF}')
    
    # Add NVMe tag if it's an NVMe device
    if [[ "$name" =~ ^nvme ]]; then
      disks+=("$name (${size}) - $model [NVMe]")
    else
      disks+=("$name (${size}) - $model")
    fi
  done < "$temp_file"
  
  # Clean up temp file
  rm -f "$temp_file"

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