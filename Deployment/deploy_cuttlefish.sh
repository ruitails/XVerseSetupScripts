#!/bin/bash

# XVerse Deployment Script
# This script rsyncs Cuttlefish artifacts and install script to multiple remote machines
# Usage: ./deploy_cuttlefish.sh [config_file]

set -e  # Exit on any error

# Default configuration file
CONFIG_FILE="${1:-remotes.conf}"

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

# Function to check if rsync is installed
check_rsync() {
    if ! command -v rsync &> /dev/null; then
        print_error "rsync is not installed. Please install it first:"
        echo "  sudo apt install rsync"
        exit 1
    fi
}

# Function to validate configuration file
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file '$CONFIG_FILE' not found."
        echo "Please create a configuration file with the following format:"
        echo "  # Format: user@hostname:port:remote_path"
        echo "  # Example: ubuntu@192.168.1.100:22:/home/ubuntu"
        echo "  # Example: user@server.example.com:2222:/opt/cuttlefish"
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

# Function to check if source files exist
check_source_files() {
    local missing_files=()
    
    if [[ ! -f "Cuttlefish/install_cuttlefish.sh" ]]; then
        missing_files+=("Cuttlefish/install_cuttlefish.sh")
    fi
    
    if [[ ! -d "Cuttlefish/artifacts" ]]; then
        missing_files+=("Cuttlefish/artifacts/")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files/directories:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        echo "Please ensure you're running this script from the project root directory."
        exit 1
    fi
    
    print_success "All source files found"
}

# Function to parse remote configuration
parse_remote() {
    local line="$1"
    local user host port remote_path
    
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
}

# Function to deploy to a single remote
deploy_to_remote() {
    local user="$1"
    local host="$2"
    local port="$3"
    local remote_path="$4"
    local remote_id="${user}@${host}:${port}"
    
    print_status "Deploying to $remote_id..."
    
    # Create remote directory if it doesn't exist
    print_status "Creating remote directory structure..."
    ssh -p "$port" "$user@$host" "mkdir -p '$remote_path/Cuttlefish/artifacts'" || {
        print_error "Failed to create remote directory on $remote_id"
        return 1
    }
    
    # Sync install script
    print_status "Syncing install script..."
    rsync -avz -e "ssh -p $port" \
        "Cuttlefish/install_cuttlefish.sh" \
        "$user@$host:$remote_path/Cuttlefish/" || {
        print_error "Failed to sync install script to $remote_id"
        return 1
    }
    
    # Sync artifacts directory
    print_status "Syncing artifacts..."
    rsync -avz -e "ssh -p $port" \
        "Cuttlefish/artifacts/" \
        "$user@$host:$remote_path/Cuttlefish/artifacts/" || {
        print_error "Failed to sync artifacts to $remote_id"
        return 1
    }
    
    # Make script executable on remote
    print_status "Making script executable on remote..."
    ssh -p "$port" "$user@$host" "chmod +x '$remote_path/Cuttlefish/install_cuttlefish.sh'" || {
        print_warning "Failed to make script executable on $remote_id (non-critical)"
    }
    
    print_success "Successfully deployed to $remote_id"
    return 0
}

# Function to deploy to all remotes
deploy_to_all() {
    local success_count=0
    local total_count=0
    local failed_remotes=()
    
    print_status "Starting deployment to all remotes..."
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
        
        IFS='|' read -r user host port remote_path <<< "$parsed"
        
        # Deploy to this remote
        if deploy_to_remote "$user" "$host" "$port" "$remote_path"; then
            success_count=$((success_count + 1))
        else
            failed_remotes+=("$user@$host:$port")
        fi
        
        echo ""  # Add spacing between deployments
        
    done < "$CONFIG_FILE"
    
    # Print summary
    echo "=========================================="
    print_status "Deployment Summary:"
    echo "  Total remotes: $total_count"
    echo "  Successful: $success_count"
    echo "  Failed: ${#failed_remotes[@]}"
    
    if [[ ${#failed_remotes[@]} -gt 0 ]]; then
        echo ""
        print_error "Failed remotes:"
        for remote in "${failed_remotes[@]}"; do
            echo "  - $remote"
        done
        return 1
    else
        print_success "All deployments completed successfully!"
        return 0
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "XVerse Cuttlefish Deployment Script"
    echo "=========================================="
    echo ""
    
    # Pre-flight checks
    check_rsync
    validate_config
    check_source_files
    
    echo ""
    print_status "Configuration file: $CONFIG_FILE"
    print_status "Source directory: $(pwd)"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    echo ""
    
    # Deploy to all remotes
    if deploy_to_all; then
        echo ""
        print_success "Deployment completed successfully!"
        print_status "You can now SSH to each remote and run:"
        echo "  cd Cuttlefish && ./install_cuttlefish.sh"
    else
        echo ""
        print_error "Deployment completed with errors"
        exit 1
    fi
}

# Run main function
main "$@"
