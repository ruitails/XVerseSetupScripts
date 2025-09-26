#!/bin/bash

# Cuttlefish Installation Script for Ubuntu 22.04 LTS
# This script installs Cuttlefish Android emulator on Ubuntu systems
# Expected to be run from within the Cuttlefish directory containing artifacts/

set -e  # Exit on any error

echo "Starting Cuttlefish installation..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Check if we're in the correct directory
if [[ ! -d "artifacts" ]]; then
    echo "Error: artifacts/ directory not found. Please run this script from the Cuttlefish directory."
    exit 1
fi

# Check KVM support
echo "Checking KVM support..."
KVM_CHECK=$(grep -c -w "vmx\|svm" /proc/cpuinfo)
if [[ $KVM_CHECK -eq 0 ]]; then
    echo "Warning: KVM support not detected. Cuttlefish may not work properly."
    echo "Please ensure virtualization is enabled in BIOS/UEFI settings."
else
    echo "KVM support detected: $KVM_CHECK features found"
fi

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y git devscripts equivs config-package-dev debhelper-compat golang curl

# Clone and build Cuttlefish
echo "Cloning Android Cuttlefish repository..."
if [[ -d "android-cuttlefish" ]]; then
    echo "android-cuttlefish directory already exists. Removing it..."
    rm -rf android-cuttlefish
fi

git clone https://github.com/google/android-cuttlefish
cd android-cuttlefish

echo "Building Cuttlefish packages..."
tools/buildutils/build_packages.sh

# Install Cuttlefish packages
echo "Installing Cuttlefish packages..."
sudo dpkg -i ./cuttlefish-base_*_*64.deb || sudo apt-get install -f
sudo dpkg -i ./cuttlefish-user_*_*64.deb || sudo apt-get install -f

# Add user to required groups
echo "Adding user to required groups..."
sudo usermod -aG kvm,cvdnetwork,render $USER

# Create cf directory in home and extract artifacts
echo "Creating cf directory and extracting artifacts..."
mkdir -p ~/cf

# Extract artifacts if they exist
if [[ -f "../artifacts/*.tar.gz" ]] || [[ -f "../artifacts/*.tar" ]]; then
    echo "Extracting cvd host tools artifacts..."
    tar -xzf ../artifacts/*.tar.gz -C ~/cf/ 2>/dev/null || tar -xf ../artifacts/*.tar -C ~/cf/ 2>/dev/null || echo "No tarball found or extraction failed"
fi

if [[ -f "../artifacts/*.zip" ]]; then
    echo "Extracting image artifacts..."
    unzip -o ../artifacts/*.zip -d ~/cf/ 2>/dev/null || echo "No zip file found or extraction failed"
fi

# Clean up
cd ..
rm -rf android-cuttlefish

echo "Cuttlefish installation completed successfully!"
echo ""
echo "IMPORTANT: You need to reboot your system for the group changes to take effect."
echo "After rebooting, you can start using Cuttlefish."
echo ""
echo "To reboot now, run: sudo reboot"
echo "To reboot later, remember to log out and log back in for group changes to take effect."

# Ask user if they want to reboot now
read -p "Do you want to reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds... Press Ctrl+C to cancel"
    sleep 5
    sudo reboot
else
    echo "Please remember to reboot or log out/in for group changes to take effect."
fi
