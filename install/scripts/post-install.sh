#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

# Function to check and install chezmoi
check_chezmoi() {
  print_msg "Checking for chezmoi..."
  if ! command -v chezmoi &> /dev/null; then
    print_msg "Installing chezmoi..."
    # Install chezmoi using the official install script
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$GITHUB_USERNAME"
    if [ $? -ne 0 ]; then
      error_exit "Failed to install chezmoi"
    fi
  else
    print_msg "chezmoi is already installed"
  fi
}

# Function to setup user
setup_user() {
  print_msg "Setting up user..."
  
  # Check and install chezmoi first
  check_chezmoi
  
  # Setup chezmoi
  chezmoi init --apply "$GITHUB_USERNAME"
  if [ $? -ne 0 ]; then
    error_exit "Failed to setup chezmoi"
  fi
}

# Function to setup system
setup_system() {
  print_msg "Setting up system..."
  
  # Check and install chezmoi first
  check_chezmoi
  
  # Setup chezmoi
  chezmoi init --apply "$GITHUB_USERNAME"
  if [ $? -ne 0 ]; then
    error_exit "Failed to setup chezmoi"
  fi
}

# Main execution
main() {
  print_msg "Starting post-install setup..."
  
  # Check and install chezmoi first
  check_chezmoi
  
  # Setup user
  setup_user
  
  # Setup system
  setup_system
  
  print_msg "Post-install setup completed successfully"
}

# Run main function
main 