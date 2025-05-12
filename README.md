# Arch Linux Setup

A comprehensive setup package for Arch Linux that automates the installation and configuration of essential tools, development environments, and security features.

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