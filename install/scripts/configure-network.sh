#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default config file location
CONFIG_DIR="$(dirname "$(dirname "$0")")/config"
CONFIG_FILE="$CONFIG_DIR/network.env"

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

# Function to check required packages
check_requirements() {
  print_msg "Checking required packages..."
  
  local required_packages=(
    "networkmanager"
    "wireless_tools"
    "wpa_supplicant"
    "dialog"
  )
  
  for pkg in "${required_packages[@]}"; do
    if ! sudo pacman -Qi "$pkg" &>/dev/null; then
      print_msg "Installing $pkg..."
      sudo pacman -S --noconfirm "$pkg" || error_exit "Failed to install $pkg"
    fi
  done
}

# Function to load environment file
load_env() {
  if [ ! -f "$CONFIG_FILE" ]; then
    if [ -f "${CONFIG_FILE}.template" ]; then
      print_msg "Creating network configuration file from template..."
      cp "${CONFIG_FILE}.template" "$CONFIG_FILE"
      chmod 600 "$CONFIG_FILE"
      print_warn "Please edit $CONFIG_FILE with your network settings"
      exit 1
    else
      error_exit "Network configuration file not found at $CONFIG_FILE"
    fi
  fi

  # Load the environment file
  set -a
  source "$CONFIG_FILE"
  set +a

  # Validate required variables
  if [ -z "${WIFI_SSID:-}" ] || [ -z "${WIFI_PASSWORD:-}" ]; then
    print_warn "WiFi credentials not found in $CONFIG_FILE"
    return 1
  fi
  return 0
}

# Function to get available network interfaces
get_interfaces() {
  local interfaces=()
  while IFS= read -r line; do
    if [[ $line =~ ^[0-9]+:[[:space:]]+([^:]+): ]]; then
      interfaces+=("${BASH_REMATCH[1]}")
    fi
  done < <(ip link show)
  echo "${interfaces[@]}"
}

# Function to scan for WiFi networks
scan_wifi() {
  local interface="$1"
  print_msg "Scanning for WiFi networks on $interface..."
  
  # Check if interface is wireless
  if ! iwconfig "$interface" &>/dev/null; then
    error_exit "$interface is not a wireless interface"
  fi
  
  # Scan for networks
  iwlist "$interface" scan 2>/dev/null | grep -i "essid" | sed 's/.*ESSID:"\(.*\)".*/\1/'
}

# Function to configure WiFi connection
configure_wifi() {
  local interface="$1"
  local ssid="$2"
  local password="$3"
  
  print_msg "Configuring WiFi connection to $ssid..."
  
  # Create NetworkManager connection
  nmcli connection add \
    type wifi \
    con-name "$ssid" \
    ifname "$interface" \
    ssid "$ssid" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$password" \
    ipv4.method auto \
    ipv6.method auto || error_exit "Failed to create WiFi connection"
  
  # Connect to the network
  nmcli connection up "$ssid" || error_exit "Failed to connect to $ssid"
}

# Function to configure wired connection
configure_wired() {
  local interface="$1"
  local use_dhcp="${2:-true}"
  local static_ip="${3:-}"
  local static_gateway="${4:-}"
  local static_dns="${5:-}"
  
  print_msg "Configuring wired connection on $interface..."
  
  if [ "$use_dhcp" = "true" ]; then
    # Create DHCP connection
    nmcli connection add \
      type ethernet \
      con-name "Wired-$interface" \
      ifname "$interface" \
      ipv4.method auto \
      ipv6.method auto || error_exit "Failed to create wired connection"
  else
    # Create static IP connection
    if [ -z "$static_ip" ] || [ -z "$static_gateway" ]; then
      error_exit "Static IP configuration incomplete"
    fi
    
    nmcli connection add \
      type ethernet \
      con-name "Wired-$interface" \
      ifname "$interface" \
      ipv4.method manual \
      ipv4.addresses "$static_ip" \
      ipv4.gateway "$static_gateway" \
      ipv4.dns "$static_dns" || error_exit "Failed to create wired connection"
  fi
  
  # Connect to the network
  nmcli connection up "Wired-$interface" || error_exit "Failed to connect to wired network"
}

# Function to handle interactive mode
interactive_mode() {
  print_msg "Starting interactive network configuration..."
  
  # Get available interfaces
  local interfaces=($(get_interfaces))
  if [ ${#interfaces[@]} -eq 0 ]; then
    error_exit "No network interfaces found"
  fi
  
  # Show interface selection menu
  echo "Available network interfaces:"
  select interface in "${interfaces[@]}"; do
    if [ -n "$interface" ]; then
      break
    fi
  done
  
  # Check if interface is wireless
  if iwconfig "$interface" &>/dev/null; then
    # Show WiFi networks
    local networks=($(scan_wifi "$interface"))
    if [ ${#networks[@]} -eq 0 ]; then
      error_exit "No WiFi networks found"
    fi
    
    echo "Available WiFi networks:"
    select ssid in "${networks[@]}"; do
      if [ -n "$ssid" ]; then
        break
      fi
    done
    
    # Get WiFi password
    read -sp "Enter WiFi password for $ssid: " password
    echo
    
    configure_wifi "$interface" "$ssid" "$password"
  else
    configure_wired "$interface"
  fi
}

# Function to handle command-line mode
cli_mode() {
  local interface="$1"
  local ssid="$2"
  local password="$3"
  
  if [ -z "$interface" ]; then
    error_exit "Interface not specified"
  fi
  
  if iwconfig "$interface" &>/dev/null; then
    if [ -z "$ssid" ] || [ -z "$password" ]; then
      error_exit "SSID and password required for WiFi connection"
    fi
    configure_wifi "$interface" "$ssid" "$password"
  else
    configure_wired "$interface"
  fi
}

# Function to handle environment file mode
env_mode() {
  if ! load_env; then
    error_exit "Failed to load environment configuration"
  fi
  
  # Configure WiFi if credentials are available
  if [ -n "${WIFI_SSID:-}" ] && [ -n "${WIFI_PASSWORD:-}" ]; then
    configure_wifi "${WIFI_INTERFACE:-wlan0}" "$WIFI_SSID" "$WIFI_PASSWORD"
  fi
  
  # Configure wired connection if specified
  if [ -n "${WIRED_INTERFACE:-}" ]; then
    configure_wired "$WIRED_INTERFACE" "${WIRED_USE_DHCP:-true}" \
      "${STATIC_IP:-}" "${STATIC_GATEWAY:-}" "${STATIC_DNS:-}"
  fi
}

# Main function
main() {
  check_root
  check_requirements
  
  # Parse command line arguments
  if [ $# -eq 0 ]; then
    interactive_mode
  else
    case "$1" in
      --wifi)
        if [ $# -lt 4 ]; then
          error_exit "Usage: $0 --wifi <interface> <ssid> <password>"
        fi
        cli_mode "$2" "$3" "$4"
        ;;
      --wired)
        if [ $# -lt 2 ]; then
          error_exit "Usage: $0 --wired <interface>"
        fi
        cli_mode "$2" "" ""
        ;;
      --env)
        env_mode
        ;;
      --help|-h)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --wifi <interface> <ssid> <password>  Configure WiFi connection"
        echo "  --wired <interface>                   Configure wired connection"
        echo "  --env                                 Use configuration from network.env"
        echo "  --help                                Show this help message"
        echo "  (no args)                            Start interactive mode"
        ;;
      *)
        error_exit "Unknown option: $1"
        ;;
    esac
  fi
  
  print_msg "Network configuration complete!"
}

# Run main function
main "$@" 