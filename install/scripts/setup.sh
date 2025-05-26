#!/usr/bin/env bash
# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# setup.sh - Complete Arch Linux setup script
# Integrates chezmoi for dotfile management and package tracking

# Function to handle errors
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print status message
print_msg() {
  echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

# Get the directory where the script is located
if [[ -L "${BASH_SOURCE[0]}" ]]; then
  # If the script is a symlink, resolve it
  REPO_DIR="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" && pwd)"
else
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Use ~/.config/arch-setup for package lists
PACKAGES_DIR="$HOME/.config/arch-setup"
mkdir -p "$PACKAGES_DIR"

# Package lists
PACMAN_LIST="$PACKAGES_DIR/pacman-packages.txt"
AUR_LIST="$PACKAGES_DIR/aur-packages.txt"
PKGLIST="$PACKAGES_DIR/pkglist.txt"

# Create package list files if they don't exist and populate them
if [ ! -f "$PACMAN_LIST" ] || [ ! -s "$PACMAN_LIST" ]; then
  echo "# List of explicitly installed pacman packages" >"$PACMAN_LIST"
  echo "# Generated on $(date)" >>"$PACMAN_LIST"
  echo "# Format: package_name" >>"$PACMAN_LIST"
  # Get explicitly installed pacman packages
  sudo pacman -Qen | awk '{print $1}' >>"$PACMAN_LIST"
fi

if [ ! -f "$AUR_LIST" ] || [ ! -s "$AUR_LIST" ]; then
  echo "# List of explicitly installed AUR packages" >"$AUR_LIST"
  echo "# Generated on $(date)" >>"$AUR_LIST"
  echo "# Format: package_name" >>"$AUR_LIST"
  # Get AUR packages
  sudo pacman -Qem | awk '{print $1}' >>"$AUR_LIST"
fi

if [ ! -f "$PKGLIST" ] || [ ! -s "$PKGLIST" ]; then
  echo "# Combined list of all installed packages" >"$PKGLIST"
  echo "# Generated on $(date)" >>"$PKGLIST"
  echo "# Format: package_name" >>"$PKGLIST"
  # Combine both lists
  cat "$PACMAN_LIST" "$AUR_LIST" | grep -v "^#" >>"$PKGLIST"
fi

# Function to install yay
install_yay() {
  local YAY_DIR="$HOME/yay"
  print_msg "Installing yay..."

  # Check for git and base-devel
  if ! command -v git &>/dev/null; then
    sudo pacman -Sy --noconfirm git || error_exit "Failed to install git"
  fi

  sudo pacman -S --needed --noconfirm base-devel || error_exit "Failed to install base-devel"

  git clone https://aur.archlinux.org/yay.git "$YAY_DIR" || error_exit "Failed to clone yay repository"
  cd "$YAY_DIR" || error_exit "Failed to change to yay directory"
  makepkg -si --noconfirm || error_exit "Failed to install yay"
  cd - || error_exit "Failed to return to previous directory"
  rm -rf "$YAY_DIR"

  print_msg "yay installed successfully"
}

# Setup chezmoi for dotfile management
setup_chezmoi() {
  print_msg "Setting up chezmoi for dotfile management..."

  # Check if chezmoi is installed
  if ! command -v chezmoi &>/dev/null; then
    # Download and install chezmoi
    print_msg "Downloading chezmoi..."
    curl -sfL https://git.io/chezmoi | sh || error_exit "Failed to download chezmoi"
  else
    print_msg "chezmoi is already installed."
  fi

  # Check if chezmoi is initialized
  if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    print_msg "Initializing chezmoi..."

    # If we have a chezmoi source directory in the repo, use it
    if [ -d "$REPO_DIR/chezmoi" ]; then
      chezmoi init --source="$REPO_DIR/chezmoi" || error_exit "Failed to initialize chezmoi"
    else
      # Initialize chezmoi and let it create its own source directory
      print_msg "Initializing chezmoi..."

      # Initialize chezmoi (this creates ~/.local/share/chezmoi)
      chezmoi init --apply || error_exit "Failed to initialize chezmoi"

      # If you want to link it to your repo directory
      if [ ! -d "$REPO_DIR/chezmoi" ]; then
        mkdir -p "$REPO_DIR/chezmoi"
        # Copy the initialized chezmoi source to your repo
        cp -r "$HOME/.local/share/chezmoi/." "$REPO_DIR/chezmoi/"
      fi
    fi
  else
    print_msg "chezmoi is already initialized."
  fi

  # Pull and apply the latest chezmoi changes
  print_msg "Pulling and applying the latest chezmoi changes..."
  chezmoi update || error_exit "Failed to update chezmoi configuration"
}

# Function to update package lists
update_pkglist() {
  print_msg "Updating package lists..."

  # Create package lists directory if it doesn't exist
  mkdir -p "$PACKAGES_DIR"

  # Get explicitly installed pacman packages (excluding AUR)
  sudo pacman -Qen | awk '{print $1}' >"$PACMAN_LIST"

  # Get AUR packages
  sudo pacman -Qem | awk '{print $1}' >"$AUR_LIST"

  # Combine both for the full package list
  cat "$PACMAN_LIST" "$AUR_LIST" >"$PKGLIST"

  print_msg "Package lists updated at $(date)"

  # If we're in a git repository, commit the changes
  if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR" || error_exit "Failed to change to repo directory"
    git add "$PACMAN_LIST" "$AUR_LIST" "$PKGLIST"
    git commit -m "Update package lists: $(date +%Y-%m-%d)" || true
    cd - || error_exit "Failed to return to previous directory"
    print_msg "Changes committed to git repository"
  fi
}

# Function to install packages from lists
install_packages() {
  print_msg "Installing packages from package lists..."

  # Split the package list into pacman and yay packages
  PKGLIST_PACMAN="$HOME/pkglist_pacman.txt"
  PKGLIST_YAY="$HOME/pkglist_yay.txt"

  # Clear old lists
  >"$PKGLIST_PACMAN"
  >"$PKGLIST_YAY"

  # Check if we should use the combined list or separate lists
  if [ -f "$PKGLIST" ]; then
    SOURCE_LIST="$PKGLIST"
  else
    # Combine pacman and AUR lists if separate
    cat "$PACMAN_LIST" "$AUR_LIST" >"$HOME/combined_pkglist.txt"
    SOURCE_LIST="$HOME/combined_pkglist.txt"
  fi

  # Separate packages
  while IFS= read -r pkg; do
    # Skip empty lines and comments
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

    if sudo pacman -Si "$pkg" &>/dev/null; then
      echo "$pkg" >>"$PKGLIST_PACMAN"
    else
      echo "$pkg" >>"$PKGLIST_YAY"
    fi
  done <"$SOURCE_LIST"

  # Run the pacman installation as root
  if [ -s "$PKGLIST_PACMAN" ]; then
    print_msg "Installing packages from $PKGLIST_PACMAN using pacman..."
    sudo pacman -Syu --needed --noconfirm || error_exit "Failed to update system"
    sudo pacman -S --needed --noconfirm - <"$PKGLIST_PACMAN" || print_msg "Some packages were not found in pacman, they might need to be installed with yay."
  fi

  # Install packages from pkglist_yay.txt using yay as non-root
  if [ -s "$PKGLIST_YAY" ]; then
    print_msg "Installing packages from $PKGLIST_YAY using yay..."
    # Make sure yay is installed
    if ! command -v yay &>/dev/null; then
      install_yay
    fi
    xargs -a "$PKGLIST_YAY" yay -S --needed --noconfirm || error_exit "Failed to install some packages using yay"
  fi

  # Clean up temporary files
  rm -f "$PKGLIST_PACMAN" "$PKGLIST_YAY" "$HOME/combined_pkglist.txt"

  print_msg "Package installation complete!"
}

# Function to set up git hooks
setup_git_hooks() {
  print_msg "Setting up git hooks for package tracking..."

  HOOKS_DIR="$REPO_DIR/.git/hooks"
  mkdir -p "$HOOKS_DIR"

  # Create pre-commit hook
  cat >"$HOOKS_DIR/pre-commit" <<'EOF'
#!/bin/bash
# pre-commit hook to ensure package lists are up-to-date

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPT_PATH="$REPO_ROOT/setup.sh"

# Run the update_pkglist function
bash "$SCRIPT_PATH" update

# Add the updated package lists
git add "$REPO_ROOT/packages/pacman-packages.txt"
git add "$REPO_ROOT/packages/aur-packages.txt"
git add "$REPO_ROOT/packages/pkglist.txt"

# Continue with commit
exit 0
EOF

  chmod +x "$HOOKS_DIR/pre-commit"
  print_msg "Git hooks installed"
}

# Main function to handle different commands
main() {
  local command="${1:-}" # Default to empty string if no argument provided

  case "$command" in
  install)
    # Full installation
    setup_chezmoi
    install_packages
    setup_git_hooks
    ;;
  update)
    # Update package lists
    update_pkglist
    ;;
  sync)
    # Update package lists and push to git
    update_pkglist
    cd "$REPO_DIR" || error_exit "Failed to change to repo directory"
    git push || print_msg "Failed to push changes, please push manually"
    cd - || error_exit "Failed to return to previous directory"
    ;;
  diff)
    # Show differences between installed and tracked packages
    print_msg "Showing package differences..."

    # Create temporary lists
    TEMP_PACMAN=$(mktemp)
    TEMP_AUR=$(mktemp)

    # Get current packages
    pacman -Qen | awk '{print $1}' | sort >"$TEMP_PACMAN"
    pacman -Qem | awk '{print $1}' | sort >"$TEMP_AUR"

    # Compare pacman packages
    print_msg "Pacman packages installed but not tracked:"
    comm -23 "$TEMP_PACMAN" <(sort "$PACMAN_LIST")

    print_msg "Pacman packages tracked but not installed:"
    comm -13 "$TEMP_PACMAN" <(sort "$PACMAN_LIST")

    # Compare AUR packages
    print_msg "AUR packages installed but not tracked:"
    comm -23 "$TEMP_AUR" <(sort "$AUR_LIST")

    print_msg "AUR packages tracked but not installed:"
    comm -13 "$TEMP_AUR" <(sort "$AUR_LIST")

    # Clean up
    rm "$TEMP_PACMAN" "$TEMP_AUR"
    ;;
  setup-hooks)
    # Just set up git hooks
    setup_git_hooks
    ;;
  help | --help | -h | "")
    echo "Usage: $0 {install|update|sync|diff|setup-hooks}"
    echo "  install     - Full installation of packages and setup"
    echo "  update      - Update package lists from current system"
    echo "  sync        - Update package lists and push to git"
    echo "  diff        - Show differences between installed and tracked packages"
    echo "  setup-hooks - Set up git hooks for automatic tracking"
    ;;
  *)
    # Default to full installation
    setup_chezmoi
    install_packages
    setup_git_hooks
    ;;
  esac
}

# Call the main function with all arguments
main "$@"
