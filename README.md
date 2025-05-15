# Arch Linux Setup

A comprehensive setup package for Arch Linux that automates the installation and configuration of essential tools, development environments, and security features.

## Fresh Installation from USB

### Prerequisites
1. Download the latest Arch Linux ISO from [archlinux.org](https://archlinux.org/download/)
2. Create a bootable USB stick using tools like `dd` or `balenaEtcher`
3. Ensure you have an active internet connection

### Installation Steps

1. Boot from the USB stick and follow the initial Arch Linux installation:
   ```bash
   # Connect to the internet (if using WiFi)
   iwctl
   device list
   station wlan0 connect <SSID>
   
   # Update the system clock
   timedatectl set-ntp true
   
   # Partition your disk (example for UEFI)
   parted /dev/sda mklabel gpt
   parted /dev/sda mkpart ESP fat32 1MiB 513MiB
   parted /dev/sda set 1 boot on
   parted /dev/sda mkpart primary ext4 513MiB 100%
   
   # Format partitions
   mkfs.fat -F32 /dev/sda1
   mkfs.ext4 /dev/sda2
   
   # Mount partitions
   mount /dev/sda2 /mnt
   mkdir /mnt/boot
   mount /dev/sda1 /mnt/boot
   
   # Install base system
   pacstrap /mnt base linux linux-firmware
   
   # Generate fstab
   genfstab -U /mnt >> /mnt/etc/fstab
   
   # Change root into the new system
   arch-chroot /mnt
   ```

2. Set up the new system:
   ```bash
   # Set timezone
   ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
   hwclock --systohc
   
   # Set locale
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
   
   # Set hostname
   echo "your-hostname" > /etc/hostname
   
   # Set root password
   passwd
   
   # Install bootloader (for UEFI)
   pacman -S grub efibootmgr
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   
   # Create a new user
   useradd -m -G wheel -s /bin/bash yourusername
   passwd yourusername
   
   # Enable sudo for wheel group
   echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
   ```

3. Exit chroot and reboot:
   ```bash
   exit
   umount -R /mnt
   reboot
   ```

4. After reboot, log in as your new user and install this setup package:
   ```bash
   # Install git
   sudo pacman -S git
   
   # Clone and run this setup
   git clone https://github.com/jaredgoldman/arch-setup.git
   cd arch-setup
   ./bootstrap.sh
   ```

## Features

### Development Environment
- **Node.js & npm**
  - Latest Node.js runtime
  - Global packages: typescript, ts-node, nodemon, eslint, prettier
  - Yarn package manager

- **Python & Poetry**
  - Python development environment
  - Poetry for dependency management
  - Common development tools: black, flake8, mypy, pytest, ipython

### Modern CLI Tools
- **File Navigation & Management**
  - `exa` - Modern replacement for `ls`
  - `fd` - Alternative to `find`
  - `bat` - Better `cat` with syntax highlighting
  - `zoxide` - Smarter `cd` command
  - `fzf` - Fuzzy finder

- **System Monitoring**
  - `bottom` - System monitor
  - `btop` - Advanced system monitor
  - `procs` - Modern `ps` alternative
  - `tldr` - Simplified man pages

### Security Tools
- **Password Management**
  - `pass` - Password manager
  - `gpg` - Encryption support

- **System Security**
  - `ufw` - Simple firewall
  - `clamav` - Antivirus scanner
  - `openssh` - SSH client/server

### Cloud & Development Tools
- **AWS CLI**
  - AWS Command Line Interface
  - Bash completion
  - Secure credential management

### Fonts & Typography
- **Programming Fonts**
  - Fira Code
  - JetBrains Mono
  - Hack
  - Roboto
  - Ubuntu Font Family

- **Icon Fonts**
  - Font Awesome

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jaredgoldman/arch-setup.git
   cd arch-setup
   ```

2. Run the bootstrap script:
   ```bash
   ./bootstrap.sh
   ```

The bootstrap script will:
- Install required packages
- Set up development environments
- Configure CLI tools
- Set up security features
- Configure AWS CLI
- Install and configure fonts

## Configuration

### AWS CLI
After installation, add your AWS credentials to `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

### Security Tools
- GPG key will be generated during setup
- UFW firewall will be configured with basic rules
- ClamAV will be set up with automatic updates

### Development Environment
- Node.js and Python environments are configured automatically
- Poetry is configured to use project-based virtual environments
- Common development tools are installed globally

## Usage

### CLI Tools
- Use `ls` for `exa` with better formatting
- Use `cat` for `bat` with syntax highlighting
- Use `z` instead of `cd` for smarter directory navigation
- Press `Ctrl+R` for fuzzy history search with `fzf`
- Use `btop` or `bottom` for system monitoring

### Development
- Use `poetry` for Python project management
- Use `npm` or `yarn` for Node.js development
- AWS CLI commands have bash completion

## Directory Structure
```
arch-setup/
├── bootstrap.sh           # Main installation script
├── install/
│   ├── config/           # Configuration files
│   ├── profiles/         # System profiles
│   ├── scripts/          # Setup scripts
│   └── configs/          # Additional configurations
└── packages/
    ├── pkglist.txt       # Combined package list
    ├── aur-packages.txt  # AUR packages
    └── pacman-packages.txt # Pacman packages
```

## Contributing
Feel free to submit issues and enhancement requests!

## License
This project is licensed under the MIT License - see the LICENSE file for details. 