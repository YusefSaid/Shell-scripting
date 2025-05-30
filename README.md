# Exercise 01 - Shell Scripting

This project demonstrates comprehensive shell scripting for automated Linux system configuration across multiple distributions. The script automates Docker and Docker Compose installation, user and group management, network configuration, and system setup with cross-platform compatibility for Debian, AlmaLinux, and Alpine Linux.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Features](#features)
- [Script Architecture](#script-architecture)
- [Cross-Platform Compatibility](#cross-platform-compatibility)
- [Command-Line Interface](#command-line-interface)
- [Configuration](#configuration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Daily Operations](#daily-operations)
- [Technical Details](#technical-details)

## Overview

This project provides an autonomous shell script that configures virtual machines across different Linux distributions with the following capabilities:
- **Multi-Distribution Support**: Debian Bookworm, AlmaLinux 9, and Alpine Linux 3.19
- **Package Manager Detection**: Automatic APT, DNF, and APK detection and usage
- **Docker Installation**: Official Docker Engine and Docker Compose v2 setup
- **User Management**: Automated user and group creation with membership assignment
- **Network Configuration**: MTU configuration for Docker daemon
- **Verbose Logging**: Comprehensive debugging and monitoring capabilities
- **Zero Interaction**: Fully autonomous execution after initial command

## Prerequisites

Before running the script, ensure you have:

- **Vagrant** (2.2.19 or later) for VM management
- **VirtualBox** (6.1 or later) as the virtualization provider
- **Host System**: Linux, macOS, or Windows with WSL2
- **Network Access**: For downloading packages and Docker images
- **Sufficient Resources**: At least 4GB RAM and 10GB disk space

### Supported Operating Systems

| OS | Version | Package Manager | Vagrant Box |
|-----|---------|----------------|-------------|
| **Debian** | Bookworm (12) | APT | debian/bookworm64 |
| **AlmaLinux** | 9 | DNF | almalinux/9 |
| **Alpine** | 3.19 | APK | generic/alpine319 |

## Project Structure

```
exercise-01-shell-scripting/
├── README.md --------------------------------> # This file
├── install.sh -------------------------------> # Main installation script
├── Vagrantfile ------------------------------> # Multi-VM environment definition
├── .vagrant/ --------------------------------> # Vagrant runtime data (auto-generated)
│   └── machines/ ----------------------------> # VM-specific configurations
│       ├── debian/ --------------------------> # Debian VM state
│       ├── almalinux/ -----------------------> # AlmaLinux VM state
│       └── alpine/ --------------------------> # Alpine VM state
├── terminal_log.txt -------------------------> # Script execution logs
├── docker_debug_log.txt ---------------------> # Docker-specific debug output
└── rgloader/ --------------------------------> # Vagrant internal loader
    └── loader.rb ----------------------------> # Ruby loader configuration
```

## Quick Start

### Automated Setup

1. **Clone and navigate to the project:**
   ```bash
   git clone <repository-url>
   cd exercise-01-shell-scripting
   ```

2. **Start all virtual machines:**
   ```bash
   vagrant up
   ```

3. **Run the script with full configuration:**
   ```bash
   # Example with all features
   vagrant ssh debian -c "chmod +x /vagrant/install.sh && /vagrant/install.sh --users 'Ed Kelly Bortus' --groups 'Crew Officers' --mtu 1442 --verbose"
   
   # Minimal installation
   vagrant ssh debian -c "chmod +x /vagrant/install.sh && /vagrant/install.sh"
   ```

4. **Test on different distributions:**
   ```bash
   # AlmaLinux with DNF
   vagrant ssh almalinux -c "/vagrant/install.sh --users 'Ed Kelly' --groups 'Crew' --verbose"
   
   # Alpine with APK  
   vagrant ssh alpine -c "/vagrant/install.sh --mtu 1500 --verbose"
   ```

### Manual Step-by-Step

1. **Initialize and start specific VM:**
   ```bash
   # Start single distribution
   vagrant up debian
   vagrant ssh debian
   ```

2. **Inside the VM, run the script:**
   ```bash
   # Make script executable
   chmod +x /vagrant/install.sh
   
   # Run with custom parameters
   /vagrant/install.sh --users "Ed Kelly Bortus" --groups "Crew Officers" --mtu 1442 --verbose
   ```

3. **Verify installation:**
   ```bash
   # Check Docker installation
   docker --version
   docker compose version
   
   # Verify users and groups
   id Ed
   groups Kelly
   ```

## Features

### Core Functionality

| Feature | Description | Command Example |
|---------|-------------|-----------------|
| **OS Detection** | Automatic distribution and package manager detection | `./install.sh` |
| **Docker Installation** | Official Docker Engine + Compose v2 setup | `./install.sh` |
| **User Management** | Create users with existence checking | `./install.sh --users "Ed Kelly Bortus"` |
| **Group Management** | Create groups and assign user memberships | `./install.sh --groups "Crew Officers"` |
| **MTU Configuration** | Docker daemon network optimization | `./install.sh --mtu 1442` |
| **Verbose Logging** | Detailed execution monitoring | `./install.sh --verbose` |

### Advanced Features

- **Cross-Platform Compatibility**: Single script works across APT, DNF, and APK systems
- **Error Handling**: Comprehensive error checking and graceful failure handling
- **Idempotent Operations**: Safe to run multiple times without side effects
- **ShellCheck Compliance**: Validated against shell scripting best practices
- **Modular Design**: Function-based architecture for maintainability

## Script Architecture

### High-Level Flow

<img width="600" alt="Script workflow diagram showing OS detection, package installation, user management, and configuration steps" src="https://github.com/user-attachments/assets/d27d44d4-4cc9-44a5-87ed-a1c28b77d290" />

*Figure 1: Shell script workflow showing the complete automation process from OS detection to final configuration.*

### Function Structure

```bash
#!/usr/bin/env bash

# Core Functions
detect_os()           # Identify OS and package manager
install_docker()      # Install Docker Engine and Compose
create_users()        # User creation and validation
create_groups()       # Group creation and membership
configure_docker()    # MTU and daemon configuration
parse_args()          # Command-line argument processing
log()                # Verbose output management
```

### Execution Flow

1. **Initialization**: Parse command-line arguments and set global variables
2. **Detection**: Identify operating system and select appropriate package manager
3. **Installation**: Install Docker and Docker Compose using official methods
4. **User Management**: Create specified users and groups with membership assignment
5. **Configuration**: Set Docker MTU and configure logging driver
6. **Validation**: Verify all installations and configurations

## Cross-Platform Compatibility

### Package Manager Detection

The script automatically detects the appropriate package manager by analyzing `/etc/os-release`:

```bash
# Debian Bookworm Detection
if grep -qi "bookworm" /etc/os-release && grep -qi "debian" /etc/os-release; then
    PACKAGE_MANAGER="apt"
    OS_TYPE="debian"

# AlmaLinux Detection  
elif grep -q "AlmaLinux" /etc/os-release; then
    PACKAGE_MANAGER="dnf"
    OS_TYPE="almalinux"

# Alpine Linux Detection
elif grep -q "Alpine" /etc/os-release; then
    PACKAGE_MANAGER="apk" 
    OS_TYPE="alpine"
```

### Distribution-Specific Implementations

#### Debian Bookworm (APT)
```bash
# Official Docker repository setup
sudo apt update
sudo apt install -y ca-certificates curl gnupg
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo tee /etc/apt/keyrings/docker.gpg
echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

#### AlmaLinux 9 (DNF)
```bash
# Fedora-compatible Docker installation
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

#### Alpine Linux 3.19 (APK)
```bash
# Alpine-specific package installation
sudo apk update
sudo apk add docker openrc docker-cli-compose
sudo rc-update add docker default
sudo service docker start
```

### User Management Compatibility

```bash
# Cross-platform user creation
create_user() {
    local user="$1"
    if [ "$OS_TYPE" = "alpine" ]; then
        sudo adduser -D "$user"  # Alpine syntax
    else
        sudo useradd -m "$user"  # Standard Linux syntax
    fi
}

# Cross-platform group creation
create_group() {
    local group="$1"
    if [ "$OS_TYPE" = "alpine" ]; then
        sudo addgroup "$group"   # Alpine syntax
    else
        sudo groupadd "$group"   # Standard Linux syntax
    fi
}
```

## Command-Line Interface

### Syntax
```bash
./install.sh [OPTIONS]
```

### Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--users` | | Space-separated list of users to create | `--users "Ed Kelly Bortus"` |
| `--groups` | | Space-separated list of groups to create | `--groups "Crew Officers"` |
| `--mtu` | | Set Docker daemon MTU value | `--mtu 1442` |
| `--verbose` | `-v` | Enable detailed logging output | `--verbose` |
| `--help` | `-h` | Display usage information | `--help` |

### Usage Examples

```bash
# Full configuration example
./install.sh --users "Ed Kelly Bortus" --groups "Crew Officers" --mtu 1442 --verbose

# Minimal installation (Docker only)
./install.sh

# User management only
./install.sh --users "Alice Bob" --groups "Developers Admins"

# Network optimization
./install.sh --mtu 1500 --verbose

# Debug mode
./install.sh -v
```

### Argument Processing

```bash
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --users)
                USERS="$2"
                shift 2
                ;;
            --groups)
                IFS=' ' read -r -a USER_GROUPS <<< "$2"
                shift 2
                ;;
            --mtu)
                MTU="$2"
                shift 2
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}
```

## Configuration

### Environment Variables

The script uses several global variables that can be customized:

```bash
# Default Configuration
VERBOSE=false              # Enable verbose logging
MTU=1500                  # Default Docker MTU
USERS=""                  # Space-separated user list
USER_GROUPS=()            # Array of groups to create
PACKAGE_MANAGER=""        # Detected package manager
OS_TYPE=""               # Detected OS type
```

### Docker Configuration

#### MTU Settings
```bash
# Create Docker daemon configuration
configure_docker_mtu() {
    local mtu_value="${1:-1500}"
    sudo mkdir -p /etc/docker
    echo "{\"mtu\": $mtu_value}" | sudo tee /etc/docker/daemon.json
    restart_docker_service
    log "Docker MTU set to $mtu_value"
}
```

#### Logging Driver
```bash
# Configure Docker logging
configure_docker_logging() {
    sudo mkdir -p /etc/docker
    echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' | sudo tee /etc/docker/daemon.json
    restart_docker_service
    log "Docker logging configured"
}
```

### Vagrant Configuration

```ruby
Vagrant.configure("2") do |config|
  # Debian Bookworm VM
  config.vm.define "debian" do |debian|
    debian.vm.box = "debian/bookworm64"
    debian.vm.hostname = "debian-vm"
    debian.vm.network "private_network", type: "dhcp"
    debian.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end

  # AlmaLinux 9 VM
  config.vm.define "almalinux" do |alma|
    alma.vm.box = "almalinux/9"
    alma.vm.hostname = "almalinux-vm"
    alma.vm.network "private_network", type: "dhcp"
    alma.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end

  # Alpine Linux 3.19 VM
  config.vm.define "alpine" do |alpine|
    alpine.vm.box = "generic/alpine319"
    alpine.vm.hostname = "alpine-vm"
    alpine.vm.network "private_network", type: "dhcp"
    alpine.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    alpine.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end
  end
end
```

## Testing

### Automated Testing

```bash
# Test script on all distributions
test_all_distributions() {
    for vm in debian almalinux alpine; do
        echo "Testing on $vm..."
        vagrant ssh $vm -c "/vagrant/install.sh --users 'testuser' --groups 'testgroup' --verbose"
        
        # Verify installation
        vagrant ssh $vm -c "docker --version && docker compose version"
        vagrant ssh $vm -c "id testuser && groups testuser"
    done
}
```

### Manual Testing

1. **OS Detection Test:**
   ```bash
   vagrant ssh debian -c "/vagrant/install.sh --verbose" | grep "Detected"
   vagrant ssh almalinux -c "/vagrant/install.sh --verbose" | grep "Detected"
   vagrant ssh alpine -c "/vagrant/install.sh --verbose" | grep "Detected"
   ```

2. **Docker Installation Test:**
   ```bash
   vagrant ssh debian -c "/vagrant/install.sh && docker run hello-world"
   ```

3. **User Management Test:**
   ```bash
   vagrant ssh debian -c "/vagrant/install.sh --users 'Ed Kelly' --groups 'Crew' && id Ed && groups Kelly"
   ```

### ShellCheck Validation

```bash
# Validate script with ShellCheck
shellcheck install.sh

# Expected output: No issues found
```

### Test Results Validation

| Test Case | Debian | AlmaLinux | Alpine | Status |
|-----------|--------|-----------|--------|--------|
| OS Detection | ✅ APT | ✅ DNF | ✅ APK | Pass |
| Docker Installation | ✅ | ✅ | ✅ | Pass |
| User Creation | ✅ | ✅ | ✅ | Pass |
| Group Management | ✅ | ✅ | ✅ | Pass |
| MTU Configuration | ✅ | ✅ | ✅ | Pass |
| Verbose Logging | ✅ | ✅ | ✅ | Pass |

## Troubleshooting

### Common Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Script not executable** | "Permission denied" error | `chmod +x /vagrant/install.sh` |
| **Vagrant shared folder missing** | "/vagrant: No such directory" | Add `synced_folder` to Vagrantfile |
| **Package manager detection fails** | "Unsupported OS" message | Check `/etc/os-release` file exists |
| **Docker installation hangs** | Process stops during installation | Check network connectivity and retry |
| **Group creation fails** | "Group 1000 created" instead of custom name | Avoid using reserved variable names |
| **MTU configuration ignored** | Default MTU still active | Restart Docker service after configuration |

### Diagnostic Commands

#### System Diagnostics
```bash
# Check OS detection
cat /etc/os-release

# Verify package managers
which apt || which dnf || which apk

# Check script permissions
ls -la /vagrant/install.sh

# Test script syntax
bash -n /vagrant/install.sh
```

#### Docker Diagnostics
```bash
# Check Docker installation
docker --version
docker compose version

# Verify Docker service
sudo systemctl status docker      # Debian/AlmaLinux
sudo service docker status        # Alpine

# Check Docker daemon configuration
cat /etc/docker/daemon.json

# Test Docker functionality
docker run hello-world
```

#### User Management Diagnostics
```bash
# List all users
cut -d: -f1 /etc/passwd | sort

# Check specific user
id username

# List all groups
cut -d: -f1 /etc/group | sort

# Check group membership
groups username
```

### Error Resolution

#### Alpine Shared Folder Issue
```bash
# Problem: /vagrant directory not found
# Solution: Update Vagrantfile
alpine.vm.synced_folder ".", "/vagrant", type: "virtualbox"

# Then reload VM
vagrant reload alpine
```

#### Reserved Variable Conflict
```bash
# Problem: Using $GROUPS variable (reserved in bash)
# Solution: Rename to $USER_GROUPS
# Before: GROUPS="Crew Officers"
# After:  USER_GROUPS=("Crew" "Officers")
```

#### Package Installation Interruption
```bash
# Problem: Kernel update prompt during installation
# Solution: Accept update or use -y flag for automatic yes
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

## Daily Operations

### Development Workflow

1. **Start development environment:**
   ```bash
   # Start all VMs
   vagrant up
   
   # Check VM status
   vagrant status
   ```

2. **Test script changes:**
   ```bash
   # Edit script
   nano install.sh
   
   # Test on single distribution
   vagrant ssh debian -c "/vagrant/install.sh --verbose"
   
   # Test on all distributions
   for vm in debian almalinux alpine; do
       vagrant ssh $vm -c "/vagrant/install.sh --users 'test' --verbose"
   done
   ```

3. **Clean up and reset:**
   ```bash
   # Destroy and recreate VMs
   vagrant destroy -f
   vagrant up
   ```

### Production Usage

1. **Deploy to target system:**
   ```bash
   # Copy script to target system
   scp install.sh user@target-system:/tmp/
   
   # Execute on target
   ssh user@target-system "chmod +x /tmp/install.sh && sudo /tmp/install.sh --users 'prod_user' --groups 'app_group' --mtu 1442"
   ```

2. **Batch deployment:**
   ```bash
   # Deploy to multiple systems
   for host in server1 server2 server3; do
       scp install.sh $host:/tmp/
       ssh $host "sudo /tmp/install.sh --users 'app' --groups 'docker' --verbose"
   done
   ```

### Maintenance Tasks

#### VM Management
```bash
# Start specific VM
vagrant up debian

# Stop all VMs
vagrant halt

# Restart VM with new configuration
vagrant reload alpine

# SSH into VM
vagrant ssh almalinux

# Check VM status
vagrant status
```

#### Script Updates
```bash
# Validate script changes
shellcheck install.sh

# Test changes on clean environment
vagrant destroy -f && vagrant up
vagrant ssh debian -c "/vagrant/install.sh --verbose"

# Backup working version
cp install.sh install.sh.backup
```

#### Log Management
```bash
# View verbose output
vagrant ssh debian -c "/vagrant/install.sh --verbose" | tee execution.log

# Check system logs
vagrant ssh debian -c "sudo journalctl -u docker.service"

# Archive logs
tar -czf logs-$(date +%Y%m%d).tar.gz *.log
```

## Technical Details

### Shell Scripting Best Practices

- **ShebangLine**: `#!/usr/bin/env bash` for portability
- **Error Handling**: `set -euo pipefail` for strict error checking
- **Function Design**: Modular functions with single responsibilities
- **Variable Naming**: Descriptive names with appropriate scoping
- **Quoting**: Proper quoting to prevent word splitting
- **Comments**: Clear documentation for complex logic

### Security Considerations

- **Input Validation**: Sanitize user-provided usernames and group names
- **Privilege Escalation**: Minimal use of sudo with specific commands
- **File Permissions**: Restrict access to sensitive configuration files
- **Package Verification**: Use official repositories and GPG signatures
- **Error Information**: Avoid exposing sensitive data in error messages

### Performance Optimization

- **Package Caching**: Leverage distribution package caches
- **Parallel Operations**: Where safe, execute independent operations concurrently
- **Network Efficiency**: Minimize package downloads through careful dependency management
- **Resource Usage**: Appropriate VM sizing for each distribution

### Compatibility Matrix

| Feature | Debian Bookworm | AlmaLinux 9 | Alpine 3.19 | Notes |
|---------|-----------------|-------------|-------------|-------|
| **Package Manager** | APT | DNF | APK | Native support |
| **Docker Installation** | Official repo | Fedora repo | Alpine packages | Full compatibility |
| **User Commands** | useradd/usermod | useradd/usermod | adduser/addgroup | Alpine uses different syntax |
| **Service Management** | systemctl | systemctl | service/rc-update | Alpine uses OpenRC |
| **Group Management** | groupadd | groupadd | addgroup | Full compatibility |
| **MTU Configuration** | ✅ | ✅ | ✅ | Universal support |

### Extension Possibilities

- **Configuration Management**: Ansible playbook generation
- **Monitoring Integration**: Prometheus/Grafana setup
- **Security Hardening**: CIS benchmark compliance
- **Container Orchestration**: Kubernetes cluster initialization
- **Backup Integration**: Automated backup configuration

---

**Project**: Exercise 01 - Shell Scripting  
**Course**: IKT114 - IT Orchestration  
**Institution**: University of Agder  
**Authors**: Yusef Said & Eirik André Lindseth

## Version History

- **v1.0**: Initial cross-platform shell script with Docker installation and user management
- **v1.1**: Added Alpine Linux support and shared folder configuration
- **v1.2**: Enhanced error handling and ShellCheck compliance