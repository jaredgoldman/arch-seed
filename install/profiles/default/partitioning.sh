#!/usr/bin/env bash
set -euo pipefail
set -x

# Check for required argument
disk=""
if [ $# -lt 1 ]; then
  echo "Usage: $0 <disk>"
  exit 1
fi
disk="$1"

# Determine partition prefix for NVMe devices
if [[ "$disk" =~ nvme ]]; then
  partprefix="p"
else
  partprefix=""
fi

# Default partitioning scheme for a typical desktop installation
# Expects disk as first argument

# Unmount any existing partitions
umount -R /mnt 2>/dev/null || true

# Create GPT partition table
parted "$disk" mklabel gpt

# Create partitions
# EFI partition (512MB)
parted "$disk" mkpart primary fat32 1MiB 513MiB
parted "$disk" set 1 esp on

# Swap partition (16GB)
parted "$disk" mkpart primary linux-swap 513MiB 17.5GiB

# Root partition (remaining space)
parted "$disk" mkpart primary ext4 17.5GiB 100%

# Force kernel to reread partition table
partprobe "$disk"
sleep 2

# Format partitions
mkfs.fat -F32 "${disk}${partprefix}1"
mkswap "${disk}${partprefix}2"
mkfs.ext4 "${disk}${partprefix}3"

# Mount partitions
mount "${disk}${partprefix}3" /mnt
mkdir -p /mnt/boot/efi
mount "${disk}${partprefix}1" /mnt/boot/efi
swapon "${disk}${partprefix}2" 