#!/usr/bin/env bash

# Default partitioning scheme for a typical desktop installation
# Expects disk as first argument

local disk="$1"

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

# Format partitions
mkfs.fat -F32 "${disk}1"
mkswap "${disk}2"
mkfs.ext4 "${disk}3"

# Mount partitions
mount "${disk}3" /mnt
mkdir -p /mnt/boot/efi
mount "${disk}1" /mnt/boot/efi
swapon "${disk}2" 