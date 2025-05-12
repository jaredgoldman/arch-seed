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

# Setup modern CLI tools
setup_cli_tools() {
  print_msg "Setting up modern CLI tools..."

  # Configure exa aliases
  if ! grep -q "alias ls='exa'" "$HOME/.bashrc"; then
    echo "alias ls='exa'" >> "$HOME/.bashrc"
    echo "alias ll='exa -l'" >> "$HOME/.bashrc"
    echo "alias la='exa -la'" >> "$HOME/.bashrc"
    echo "alias lt='exa -T'" >> "$HOME/.bashrc"
  fi

  # Configure bat
  if ! grep -q "alias cat='bat'" "$HOME/.bashrc"; then
    echo "alias cat='bat'" >> "$HOME/.bashrc"
  fi

  # Configure zoxide
  if ! grep -q "eval \"\$(zoxide init bash)\"" "$HOME/.bashrc"; then
    echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
  fi

  # Configure fzf
  if ! grep -q "source /usr/share/fzf/key-bindings.bash" "$HOME/.bashrc"; then
    echo "source /usr/share/fzf/key-bindings.bash" >> "$HOME/.bashrc"
    echo "source /usr/share/fzf/completion.bash" >> "$HOME/.bashrc"
  fi

  print_msg "CLI tools setup complete!"
}

# Setup security tools
setup_security_tools() {
  print_msg "Setting up security tools..."

  # Initialize GPG
  if ! gpg --list-keys &>/dev/null; then
    print_msg "Initializing GPG..."
    gpg --full-generate-key
  fi

  # Initialize pass
  if ! pass &>/dev/null; then
    print_msg "Initializing pass..."
    pass init "$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2)"
  fi

  # Configure UFW
  print_msg "Configuring UFW..."
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow http
  sudo ufw allow https
  sudo ufw --force enable

  # Configure ClamAV
  print_msg "Configuring ClamAV..."
  sudo freshclam
  sudo systemctl enable clamav-freshclam
  sudo systemctl start clamav-freshclam

  print_msg "Security tools setup complete!"
}

# Setup system monitors
setup_system_monitors() {
  print_msg "Setting up system monitors..."

  # Configure bottom
  mkdir -p "$HOME/.config/bottom"
  cat > "$HOME/.config/bottom/bottom.toml" << EOF
[flags]
mem_as_value = true
dot_marker = false
left_mouse_pane = true
temperature_type = "c"
group_processes = true
tree = true
EOF

  # Configure btop
  mkdir -p "$HOME/.config/btop"
  cat > "$HOME/.config/btop/btop.conf" << EOF
color_theme = "default"
truecolor = true
force_tty = false
presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:default,proc:0:default"
EOF

  print_msg "System monitors setup complete!"
}

# Main execution
main() {
  print_msg "Starting CLI tools and security setup..."
  
  setup_cli_tools
  setup_security_tools
  setup_system_monitors
  
  print_msg "Setup complete! Please restart your shell to apply changes."
}

main 