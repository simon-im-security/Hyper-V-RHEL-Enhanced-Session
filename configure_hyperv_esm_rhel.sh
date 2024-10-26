#!/bin/bash

# Title: Hyper-V Enhanced Session Mode Configuration for RHEL 9+
# Description: Sets up XRDP on RHEL 9 and newer to enable Hyper-V Enhanced Session Mode (ESM) with audio and graphical support.
# Author: Simon .I
# Version: 2024.10.27

echo "Initializing Hyper-V Enhanced Session Mode configuration for RHEL 9 and newer."

# Ensure the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then 
    echo "Error: This script must be run as root or with sudo privileges. Exiting..."
    exit 1
fi

# Verify OS version compatibility (RHEL 9+)
platform_version=$(grep '^VERSION_ID=' /etc/os-release | awk -F'=' '{ print $2 }' | tr -d '"')
major_version=$(echo "$platform_version" | cut -d '.' -f1)

# Ensure the major version is 9 or greater
if [ "$major_version" -lt 9 ]; then
    echo "Error: Unsupported OS version. This script is designed for RHEL 9 and newer only. Exiting..."
    exit 1
fi

# Install Hyper-V tools and XRDP components
echo "Installing required packages: hyperv-tools, XRDP, and associated components..."
dnf install -y hyperv-tools xrdp xrdp-selinux xorgxrdp

# Enable and start XRDP services
echo "Enabling and starting XRDP services for Enhanced Session Mode support..."
systemctl enable --now xrdp xrdp-sesman

# Modify XRDP configuration for Enhanced Session Mode with Hyper-V Sockets
echo "Applying XRDP configuration adjustments for Enhanced Session Mode..."
sed -i 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i 's/crypt_level=high/crypt_level=high/g' /etc/xrdp/xrdp.ini
sed -i 's/bitmap_compression=true/bitmap_compression=true/g' /etc/xrdp/xrdp.ini

# Add Xorg configuration for graphical XRDP sessions
echo "Configuring XRDP to support graphical sessions using Xorg..."
sed -i '/^\[Xorg\]/,/^$/c\[Xorg]\nname=Xorg\nlib=libxup.so\nusername=ask\npassword=ask\nport=-1\ncode=20' /etc/xrdp/xrdp.ini

# Configure Pipewire for XRDP audio support
echo "Installing dependencies for building Pipewire audio support for XRDP..."
dnf install -y git gcc make autoconf libtool automake pkgconfig pipewire-devel

# Clone, compile, and install the Pipewire module for XRDP
echo "Cloning and building the Pipewire module for XRDP..."
pushd /tmp
git clone https://github.com/neutrinolabs/pipewire-module-xrdp.git
cd pipewire-module-xrdp
./bootstrap
./configure
make
sudo make install
popd
rm -rf /tmp/pipewire-module-xrdp

echo "Configuration complete. Please reboot the system to apply all changes."

# Final instructions for enabling Enhanced Session Mode on Hyper-V
echo -e "\nTo finalize the Enhanced Session Mode setup on Windows Hyper-V:"
echo "1. Open the Hyper-V Manager on your Windows host machine."
echo "   a. Go to your VM's settings, navigate to **Management > Integration Services**, and enable 'Guest services'."
echo "2. After enabling 'Guest services', open PowerShell as Administrator and run the following command to set the Enhanced Session Transport Type to HVSocket:"
echo "   Set-VM -Name <VM_NAME> -EnhancedSessionTransportType HVSocket"
echo "   (Replace <VM_NAME> with the actual name of your VM.)"
