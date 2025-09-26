#!/bin/bash

# XVerse Connection Test Script
# This script tests SSH connections to remote machines before deployment
# Usage: ./test_connections.sh [config_file] [--password]

set -e  # Exit on any error

# Default configuration file
CONFIG_FILE="${1:-remotes.conf}"

# Check if password authentication is requested
USE_PASSWORD=false
if [[ "$2" == "--password" ]] || [[ "$1" == "--password" ]]; then
    USE_PASSWORD=true
    # Remove --password from arguments if it was the first argument
    if [[ "$1" == "--password" ]]; then
        CONFIG_FILE="${2:-remotes.conf}"
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check dependencies
check_dependencies() {
    if ! command -v ssh &> /dev/null; then
        print_error "SSH client is not installed. Please install it first:"
        echo "  sudo apt install openssh-client"
        exit 1
    fi
    
    if [[ "$USE_PASSWORD" == true ]]; then
        if ! command -v sshpass &> /dev/null; then
            print_error "sshpass is not installed. Please install it first:"
            echo "  sudo apt install sshpass"
            exit 1
        fi
        print_status "Using password authentication (sshpass)"
    else
        print_status "Using SSH key authentication"
    fi
}

# Function to validate configuration file
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file '$CONFIG_FILE' not found."
        echo "Please create a configuration file with the following format:"
        if [[ "$USE_PASSWORD" == true ]]; then
            echo "  # Format: user@hostname:port:remote_path:password"
            echo "  # Example: ubuntu@192.168.1.100:22:/home/ubuntu:mypassword"
        else
            echo "  # Format: user@hostname:port:remote_path"
            echo "  # Example: ubuntu@192.168.1.100:22:/home/ubuntu"
        fi
        exit 1
    fi
    
    # Check if config file has valid entries
    local valid_entries=$(grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | wc -l)
    if [[ $valid_entries -eq 0 ]]; then
        print_error "No valid entries found in configuration file '$CONFIG_FILE'"
        exit 1
    fi
    
    print_success "Configuration file validated: $valid_entries remote(s) found"
}

# Function to parse remote configuration
parse_remote() {
    local line="$1"
    local user host port remote_path password
    
    if [[ "$USE_PASSWORD" == true ]]; then
        # Parse format: user@hostname:port:remote_path:password
        if [[ $line =~ ^([^@]+)@([^:]+):([0-9]+):(.+):(.+)$ ]]; then
            user="${BASH_REMATCH[1]}"
            host="${BASH_REMATCH[2]}"
            port="${BASH_REMATCH[3]}"
            remote_path="${BASH_REMATCH[4]}"
            password="${BASH_REMATCH[5]}"
        else
            print_error "Invalid format in config line: $line"
            print_error "Expected format: user@hostname:port:remote_path:password"
            return 1
        fi
        echo "$user|$host|$port|$remote_path|$password"
    else
        # Parse format: user@hostname:port:remote_path
        if [[ $line =~ ^([^@]+)@([^:]+):([0-9]+):(.+)$ ]]; then
            user="${BASH_REMATCH[1]}"
            host="${BASH_REMATCH[2]}"
            port="${BASH_REMATCH[3]}"
            remote_path="${BASH_REMATCH[4]}"
        else
            print_error "Invalid format in config line: $line"
            print_error "Expected format: user@hostname:port:remote_path"
            return 1
        fi
        echo "$user|$host|$port|$remote_path"
    fi
}

# Function to test connection to a single remote
test_connection() {
    local user="$1"
    local host="$2"
    local port="$3"
    local remote_path="$4"
    local password="$5"
    local remote_id="${user}@${host}:${port}"
    
    print_status "Testing connection to $remote_id..."
    
    # Set up SSH command based on authentication method
    local ssh_cmd
    if [[ "$USE_PASSWORD" == true ]]; then
        ssh_cmd="sshpass -p '$password' ssh -p $port -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes"
    else
        ssh_cmd="ssh -p $port -o ConnectTimeout=10 -o BatchMode=yes"
    fi
    
    # Test basic connection
    print_status "  Testing SSH connection..."
    if $ssh_cmd "$user@$host" "echo 'Connection successful'" &>/dev/null; then
        print_success "  ✓ SSH connection successful"
    else
        print_error "  ✗ SSH connection failed"
        return 1
    fi
    
    # Test directory access
    print_status "  Testing directory access..."
    if $ssh_cmd "$user@$host" "test -d '$remote_path' || mkdir -p '$remote_path'" &>/dev/null; then
        print_success "  ✓ Directory access successful"
    else
        print_error "  ✗ Directory access failed"
        return 1
    fi
    
    # Test write permissions
    print_status "  Testing write permissions..."
    if $ssh_cmd "$user@$host" "touch '$remote_path/test_write_$$' && rm '$remote_path/test_write_$$'" &>/dev/null; then
        print_success "  ✓ Write permissions confirmed"
    else
        print_error "  ✗ Write permissions denied"
        return 1
    fi
    
    # Test rsync if available
    print_status "  Testing rsync availability..."
    if $ssh_cmd "$user@$host" "command -v rsync" &>/dev/null; then
        print_success "  ✓ rsync is available on remote"
    else
        print_warning "  ⚠ rsync not found on remote (will be needed for deployment)"
    fi
    
    print_success "All tests passed for $remote_id"
    return 0
}

# Function to test all connections
test_all_connections() {
    local success_count=0
    local total_count=0
    local failed_remotes=()
    
    print_status "Starting connection tests..."
    echo ""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        total_count=$((total_count + 1))
        
        # Parse remote configuration
        local parsed=$(parse_remote "$line")
        if [[ $? -ne 0 ]]; then
            failed_remotes+=("$line (parse error)")
            continue
        fi
        
        IFS='|' read -r user host port remote_path password <<< "$parsed"
        
        # Test this remote
        if test_connection "$user" "$host" "$port" "$remote_path" "$password"; then
            success_count=$((success_count + 1))
        else
            failed_remotes+=("$user@$host:$port")
        fi
        
        echo ""  # Add spacing between tests
        
    done < "$CONFIG_FILE"
    
    # Print summary
    echo "=========================================="
    print_status "Connection Test Summary:"
    echo "  Total remotes: $total_count"
    echo "  Successful: $success_count"
    echo "  Failed: ${#failed_remotes[@]}"
    
    if [[ ${#failed_remotes[@]} -gt 0 ]]; then
        echo ""
        print_error "Failed connections:"
        for remote in "${failed_remotes[@]}"; do
            echo "  - $remote"
        done
        echo ""
        print_status "Troubleshooting tips:"
        echo "  1. Check if SSH service is running on remote machines"
        echo "  2. Verify firewall settings allow SSH connections"
        echo "  3. Confirm username and password are correct"
        echo "  4. Check if remote machines are accessible from your network"
        echo "  5. Try manual SSH connection: ssh -p PORT user@host"
        return 1
    else
        print_success "All connections successful! Ready for deployment."
        return 0
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "XVerse Connection Test Script"
    echo "=========================================="
    echo ""
    
    # Pre-flight checks
    check_dependencies
    validate_config
    
    echo ""
    print_status "Configuration file: $CONFIG_FILE"
    echo ""
    
    # Test all connections
    if test_all_connections; then
        echo ""
        print_success "All connections are working! You can now run the deployment script."
    else
        echo ""
        print_error "Some connections failed. Please fix the issues before deploying."
        exit 1
    fi
}

# Run main function
main "$@"
