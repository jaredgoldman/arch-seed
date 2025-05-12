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

# Setup Node.js environment
setup_nodejs() {
  print_msg "Setting up Node.js environment..."
  
  # Install global npm packages
  npm install -g npm@latest
  npm install -g typescript
  npm install -g ts-node
  npm install -g nodemon
  npm install -g eslint
  npm install -g prettier
  
  print_msg "Node.js environment setup complete!"
}

# Setup Python environment
setup_python() {
  print_msg "Setting up Python environment..."
  
  # Configure Poetry
  poetry config virtualenvs.in-project true
  poetry config virtualenvs.path "./.venv"
  
  # Install common Python packages
  pip install --user black
  pip install --user flake8
  pip install --user mypy
  pip install --user pytest
  pip install --user ipython
  
  print_msg "Python environment setup complete!"
}

# Main execution
main() {
  print_msg "Starting development environment setup..."
  
  setup_nodejs
  setup_python
  
  print_msg "Development environment setup complete!"
}

main 