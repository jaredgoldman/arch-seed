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

# Setup AWS CLI
setup_aws_cli() {
  print_msg "Setting up AWS CLI..."

  # Create AWS config directory if it doesn't exist
  mkdir -p "$HOME/.aws"

  # Create AWS config file if it doesn't exist
  if [ ! -f "$HOME/.aws/config" ]; then
    cat > "$HOME/.aws/config" << EOF
[default]
region = us-east-1
output = json
cli_pager =
EOF
  fi

  # Create AWS credentials file if it doesn't exist
  if [ ! -f "$HOME/.aws/credentials" ]; then
    cat > "$HOME/.aws/credentials" << EOF
[default]
# Add your AWS credentials here:
# aws_access_key_id = YOUR_ACCESS_KEY
# aws_secret_access_key = YOUR_SECRET_KEY
EOF
    chmod 600 "$HOME/.aws/credentials"
  fi

  # Install AWS CLI completion
  if ! grep -q "complete -C '/usr/bin/aws_completer' aws" "$HOME/.bashrc"; then
    echo "complete -C '/usr/bin/aws_completer' aws" >> "$HOME/.bashrc"
  fi

  print_msg "AWS CLI setup complete!"
  print_msg "Please add your AWS credentials to ~/.aws/credentials"
}

# Setup Font Awesome
setup_font_awesome() {
  print_msg "Setting up Font Awesome..."

  # Create font config directory if it doesn't exist
  mkdir -p "$HOME/.config/fontconfig/conf.d"

  # Create font config file if it doesn't exist
  if [ ! -f "$HOME/.config/fontconfig/conf.d/10-font-awesome.conf" ]; then
    cat > "$HOME/.config/fontconfig/conf.d/10-font-awesome.conf" << EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test qual="any" name="family">
      <string>Font Awesome</string>
    </test>
    <edit name="family" mode="assign" binding="same">
      <string>Font Awesome</string>
    </edit>
  </match>
</fontconfig>
EOF
  fi

  # Update font cache
  fc-cache -f -v

  print_msg "Font Awesome setup complete!"
}

# Main execution
main() {
  print_msg "Starting AWS CLI and Font Awesome setup..."
  
  setup_aws_cli
  setup_font_awesome
  
  print_msg "Setup complete! Please restart your shell to apply changes."
}

main 