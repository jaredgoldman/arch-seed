#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Print warning message
print_warn() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

# Function to check if running as root
check_root() {
  if [ "$(id -u)" != "0" ]; then
    error_exit "This script must be run as root"
  fi
}

# Function to create backup
create_backup() {
  local backup_dir="/var/backups/arch-setup"
  local date_stamp=$(date +%Y%m%d_%H%M%S)
  
  print_msg "Creating system backup..."
  mkdir -p "$backup_dir"
  
  # Backup pacman database
  tar -czf "$backup_dir/pacman_db_$date_stamp.tar.gz" /var/lib/pacman/local
  
  # Backup important config files
  tar -czf "$backup_dir/etc_$date_stamp.tar.gz" /etc
  
  print_msg "Backup created in $backup_dir"
}

# Function to check disk space
check_disk_space() {
  local required_space=5000 # 5GB in MB
  local available_space=$(df -m / | awk 'NR==2 {print $4}')
  
  if [ "$available_space" -lt "$required_space" ]; then
    print_warn "Low disk space: $available_space MB available"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      error_exit "Update cancelled due to low disk space"
    fi
  fi
}

# Function to check for conflicting packages
check_conflicts() {
  print_msg "Checking for package conflicts..."
  sudo pacman -Qkk 2>/dev/null || true
}

# Function to update system
update_system() {
  print_msg "Updating system..."
  
  # Update package database
  sudo pacman -Sy
  
  # Check for updates
  if ! sudo pacman -Qu; then
    print_msg "System is up to date"
    return 0
  fi
  
  # Create backup before update
  create_backup
  
  # Update packages
  sudo pacman -Syu --noconfirm
  
  # Update AUR packages if yay is installed
  if command -v yay &> /dev/null; then
    print_msg "Updating AUR packages..."
    yay -Syu --noconfirm
  fi
}

# Function to clean up
cleanup() {
  print_msg "Cleaning up..."
  
  # Remove old packages
  sudo pacman -Sc --noconfirm
  
  # Remove old kernels
  if command -v pacman-remove-orphans &> /dev/null; then
    sudo pacman-remove-orphans
  fi
  
  # Clean package cache
  sudo paccache -r
}

# Main function
main() {
  check_root
  check_disk_space
  check_conflicts
  update_system
  cleanup
  
  print_msg "System update complete!"
}

# Run main function
main "$@" 