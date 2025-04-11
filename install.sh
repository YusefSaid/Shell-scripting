#!/usr/bin/env bash
# Set default values
VERBOSE=false
MTU=1500

# Global variables (set in detect_os)
PACKAGE_MANAGER=""
OS_TYPE=""

# Function to print verbose messages
log() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1"
    fi
}

# Function to detect OS and package manager
detect_os() {
    echo "Detecting OS..."

    if [ ! -f /etc/os-release ]; then
        echo "OS release file not found. Unsupported OS."
        exit 1
    fi

    if grep -qi "bookworm" /etc/os-release && grep -qi "debian" /etc/os-release; then
        echo "Detected Debian Bookworm - Using APT"
        PACKAGE_MANAGER="apt"
        OS_TYPE="debian"
    elif grep -q "AlmaLinux" /etc/os-release; then
        echo "Detected AlmaLinux - Using DNF"
        PACKAGE_MANAGER="dnf"
        OS_TYPE="almalinux"
    elif grep -q "Alpine" /etc/os-release; then
        echo "Detected Alpine - Using APK"
        PACKAGE_MANAGER="apk"
        OS_TYPE="alpine"
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Helper function to restart Docker
restart_docker() {
    if [ "$OS_TYPE" = "alpine" ]; then
        # Alpine uses OpenRC
        sudo service docker restart
    else
        # Debian/AlmaLinux use systemd
        sudo systemctl restart docker
    fi
}

# Helper function to create a user
create_user() {
    local user="$1"
    if [ "$OS_TYPE" = "alpine" ]; then
        # Alpine uses 'adduser' (with -D for no password)
        sudo adduser -D "$user"
    else
        sudo useradd -m "$user"
    fi
}

# Helper function to create a group
create_group() {
    local group="$1"
    if [ "$OS_TYPE" = "alpine" ]; then
        sudo addgroup "$group"
    else
        sudo groupadd "$group"
    fi
}

# Function to install Docker and Docker Compose
install_docker() {
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        # ------------------
        # Debian Bookworm
        # ------------------
        sudo apt update
        sudo apt install -y docker.io curl

        # Start/enable Docker
        sudo systemctl enable --now docker

        # Install Docker Compose v2 (manually from GitHub)
        echo "Installing Docker Compose v2 on Debian..."
        COMPOSE_VERSION="v2.23.0"
        sudo mkdir -p /usr/local/bin
        sudo curl -SL \
          "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
          -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    elif [ "$PACKAGE_MANAGER" = "dnf" ]; then
        # ------------------
        # AlmaLinux
        # ------------------
        echo "Installing Docker for AlmaLinux using DNF..."
        sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io curl
        sudo systemctl enable --now docker
        echo "Docker installed successfully on AlmaLinux."

        # Install Docker Compose v2 (manually from GitHub)
        echo "Installing Docker Compose v2 on AlmaLinux..."
        COMPOSE_VERSION="v2.23.0"
        sudo mkdir -p /usr/local/bin
        sudo curl -SL \
          "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
          -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    elif [ "$PACKAGE_MANAGER" = "apk" ]; then
        # ------------------
        # Alpine
        # ------------------
        echo "Installing Docker for Alpine using APK..."
        sudo apk update
        sudo apk add docker docker-compose
        sudo rc-update add docker boot
        sudo service docker start
        echo "Docker installed successfully on Alpine Linux."
    fi

    # Check Docker installation
    if command -v docker &> /dev/null; then
        echo "Docker installed and working correctly!"
    else
        echo "Docker installation failed!"
        exit 1
    fi
}

# Function to create users
create_users() {
    if [ -z "$USERS" ]; then
        log "No users specified"
        return
    fi

    echo "Creating users: $USERS"
    for user in $USERS; do
        if id "$user" &>/dev/null; then
            echo "User $user already exists"
        else
            create_user "$user"
            echo "User $user created"
        fi
    done
}

# Function to create groups and add users to groups
create_groups() {
    if [ "${#USER_GROUPS[@]}" -eq 0 ]; then
        log "No groups specified"
        return
    fi

    echo "Creating groups: ${USER_GROUPS[*]}"
    for group in "${USER_GROUPS[@]}"; do
        # Replace spaces with underscores to make it a valid group name
        valid_group_name=$(echo "$group" | tr ' ' '_')

        if getent group "$valid_group_name" &>/dev/null; then
            echo "Group $valid_group_name already exists"
        else
            create_group "$valid_group_name"
            echo "Group $valid_group_name created"
        fi

        # Add each user to this group
        if [ -n "$USERS" ]; then
            for user in $USERS; do
                if id "$user" &>/dev/null; then
                    # Try usermod first
                    sudo usermod -aG "$valid_group_name" "$user" 2>/dev/null || {
                        # On Alpine, usermod might not exist if 'shadow' isn't installed
                        # So fallback to addgroup <user> <group>
                        if [ "$OS_TYPE" = "alpine" ]; then
                            sudo addgroup "$user" "$valid_group_name"
                        else
                            echo "Error adding $user to $valid_group_name"
                        fi
                    }
                    echo "Added $user to group $valid_group_name"
                fi
            done
        fi
    done
}

# Function for MTU configuration
configure_mtu() {
    echo "Configuring Docker MTU..."
    sudo mkdir -p /etc/docker
    echo "{\"mtu\": $MTU}" | sudo tee /etc/docker/daemon.json
    restart_docker
    echo "Docker MTU set to $MTU"
}

# Function to set up logging
setup_logging() {
    log "Setting up logging for Docker"

    if [ ! -d /etc/docker ]; then
        sudo mkdir -p /etc/docker
    fi

    CONFIG_FILE="/etc/docker/daemon.json"
    TEMP_FILE=$(mktemp)

    # Copy config as current user (avoid root-owned /tmp issues on Alpine)
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$TEMP_FILE" 2>/dev/null || {
            echo "Could not copy $CONFIG_FILE to $TEMP_FILE. Check permissions."
            exit 1
        }

        # If the file ends with '}', turn that into ',' for merging new keys
        sed '$ s/}$/,/' "$TEMP_FILE" > "${TEMP_FILE}.new"
        mv -f "${TEMP_FILE}.new" "$TEMP_FILE"

        cat <<EOF >> "$TEMP_FILE"
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    else
        cat <<EOF > "$TEMP_FILE"
{
  "mtu": $MTU,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    fi

    # Now move it into place with sudo
    sudo mv -f "$TEMP_FILE" "$CONFIG_FILE"
    restart_docker
    log "Logging configuration applied"
}

# Parse command line arguments
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --users)
                shift
                USERS="$1"
                ;;
            --groups)
                shift
                IFS=' ' read -r -a USER_GROUPS <<< "$1"  # Convert string to array
                ;;
            --mtu)
                shift
                MTU="$1"
                ;;
            --verbose|-v)
                VERBOSE=true
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: $0 [--users \"user1 user2\"] [--groups \"group1 group2\"] [--mtu value] [--verbose|-v]"
                exit 1
                ;;
        esac
        shift
    done
}

# Main function
main() {
    parse_args "$@"

    if [ "$VERBOSE" = true ]; then
        echo "Verbose mode enabled"
        echo "Users: $USERS"
        echo "Groups: ${USER_GROUPS[*]}"
        echo "MTU: $MTU"
    fi

    detect_os
    install_docker
    create_users
    create_groups
    configure_mtu

    # Now that Docker is installed, do a final Docker Compose check
    if command -v docker-compose &>/dev/null; then
        echo "Docker Compose installed successfully!"
    elif docker compose version &>/dev/null; then
        echo "Docker Compose plugin is installed successfully!"
    else
        echo "Docker Compose installation might have issues. Please check manually."
    fi

    setup_logging

    echo "Installation and configuration complete!"
}

# Start the script
main "$@"




# Start the script
main "$@"