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

# Install NVM
install_nvm() {
  print_msg "Installing NVM..."
  
  # Check if NVM is already installed
  if [ -d "$HOME/.nvm" ]; then
    print_msg "NVM is already installed"
    return
  fi

  # Install NVM
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || error_exit "Failed to install NVM"

  # Source NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  print_msg "NVM installation complete!"
}

# Install Node.js using NVM
install_nodejs() {
  print_msg "Installing Node.js..."
  
  # Source NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install latest LTS version of Node.js
  nvm install --lts || error_exit "Failed to install Node.js"
  nvm use --lts || error_exit "Failed to switch to LTS version"
  nvm alias default node || error_exit "Failed to set default Node.js version"

  print_msg "Node.js installation complete!"
}

# Install pnpm
install_pnpm() {
  print_msg "Installing pnpm..."
  
  # Source NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install pnpm
  curl -fsSL https://get.pnpm.io/install.sh | sh - || error_exit "Failed to install pnpm"

  # Add pnpm to PATH
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export PATH="$PNPM_HOME:$PATH"

  print_msg "pnpm installation complete!"
}

# Install global packages
install_global_packages() {
  print_msg "Installing global packages..."
  
  # Source NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install essential global packages
  pnpm add -g typescript
  pnpm add -g ts-node
  pnpm add -g nodemon
  pnpm add -g eslint
  pnpm add -g prettier
  pnpm add -g @types/node

  print_msg "Global packages installation complete!"
}

# Main execution
main() {
  print_msg "Starting Node.js tools setup..."
  
  install_nvm
  install_nodejs
  install_pnpm
  install_global_packages
  
  print_msg "Node.js tools setup complete!"
  print_msg "Please restart your shell or run 'source ~/.bashrc' to start using the new tools"
}

main 