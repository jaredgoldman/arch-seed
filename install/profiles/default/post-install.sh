#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_msg() {
  echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

# Create a new user interactively
print_msg "Creating a new user..."
read -p "Enter the username to create: " username
if id "$username" &>/dev/null; then
  echo "User $username already exists."
  exit 1
fi
read -s -p "Enter password for $username: " password
echo
read -s -p "Confirm password: " password2
echo
if [[ "$password" != "$password2" ]]; then
  echo "Passwords do not match."
  exit 1
fi
useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$password" | chpasswd
print_msg "User $username created and added to wheel group (sudoers)."

# Configure sudo
print_msg "Configuring sudo..."
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Set timezone
print_msg "Setting timezone..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Set locale
print_msg "Setting locale..."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/local.conf

# Set hostname
print_msg "Setting hostname..."
echo "archlinux" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 archlinux.localdomain archlinux
EOF

# Install and configure bootloader
print_msg "Installing bootloader..."
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install additional packages
print_msg "Installing additional packages..."
pacman -S --noconfirm \
  base-devel \
  git \
  networkmanager \
  sudo \
  vim \
  wget \
  curl \
  openssh

# Enable services
print_msg "Enabling services..."
systemctl enable NetworkManager
systemctl enable sshd

# Ensure /tmp is world-writable
chmod 1777 /tmp

# Install yay for AUR packages
print_msg "Installing yay..."
sudo -u "$username" bash -c '
  rm -rf /tmp/yay
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
'

# Set up the arch-setup tool
print_msg "Setting up arch-setup..."
cd /root/install
make install

# Run initial setup
print_msg "Running initial system setup..."
/usr/local/bin/arch-setup install

print_msg "Post-installation complete!" 