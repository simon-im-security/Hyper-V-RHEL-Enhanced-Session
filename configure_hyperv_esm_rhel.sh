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
if [ ! -f /etc/os-release ]; then
    echo "File /etc/os-release not present, cannot determine OS. Exiting..."
    exit 1
fi

platform=$(grep '^PLATFORM_ID=' /etc/os-release | awk -F'=' '{ print $2 }' | tr -d '"' | awk -F':' '{ print $2 }')
platform_array=( $(grep -Eo '[^[:digit:]]+|[[:digit:]]+' <<< "$platform") )
platform_name=$(echo "${platform_array[0]}")
platform_version=$(echo "${platform_array[1]}")


if [ "$platform_name" == "el" ]; then
    if [ "$platform_version" -gt 8 ]; then
        echo "RHEL version ($platform_version) is supported. Proceeding..."
    else
        echo "RHEL version ($platform_version) is not supported, must be greater than 8. Exiting..."
        exit 1
    fi
else
    echo "Platform not supported. Exiting..."
    exit 1
fi

# Install EPEL repository if RHEL based
if [ "$platform_name" == "el" ]; then
    echo "Installing EPEL repository..."
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${platform_version}.noarch.rpm || { echo 'Failed to install EPEL repository. Exiting...'; exit 1; }
fi

# Install Hyper-V tools, XRDP components, and xrdp-selinux
echo "Installing required packages: hyperv-tools, XRDP, and associated components including xrdp-selinux..."
dnf install -y hyperv-tools xrdp xorgxrdp xrdp-selinux || { echo 'Failed to install required packages. Exiting...'; exit 1; }
# Enable and start XRDP services
echo "Enabling and starting XRDP services for Enhanced Session Mode support..."
systemctl enable --now xrdp xrdp-sesman || { echo 'Failed to enable XRDP services. One or both services may not exist. Exiting...'; exit 1; }

# Modify XRDP configuration for Enhanced Session Mode with Hyper-V Sockets
echo "Applying XRDP configuration adjustments for Enhanced Session Mode..."

# Change port from default 3389 to a virtual socket (-1:3389) for Enhanced Session Mode.
sed -i 's/port=3389/port=vsock:\/\/\-1:3389/g' /etc/xrdp/xrdp.ini

# Set security layer to RDP to ensure compatibility with Enhanced Session Mode.
sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini

# Set cryptographic level to "high" to maintain secure sessions.
sed -i 's/crypt_level=.*/crypt_level=high/g' /etc/xrdp/xrdp.ini

# Disable bitmap compression to potentially improve performance in Enhanced Session Mode.
sed -i 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Add Xorg configuration for graphical XRDP sessions
echo "Configuring XRDP to support graphical sessions using Xorg..."
sed -i '/^\[Xorg\]/,/^$/c\[Xorg]\nname=Xorg\nlib=libxup.so\nusername=ask\npassword=ask\nport=-1\ncode=20' /etc/xrdp/xrdp.ini

# Rename the redirected drives to 'shared-drives'
echo "Renaming redirected drives to 'shared-drives'..."
sed -i 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Change the allowed_users setting for Xwrapper
echo "Changing allowed_users to anybody in Xwrapper.config..."
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Open port for XRDP
echo "Opening port 3389 for XRDP..."
firewall-cmd --add-port=3389/tcp --permanent
firewall-cmd --reload


# Configure Pipewire for XRDP audio support
echo "Installing dependencies for building Pipewire audio support for XRDP..."
dnf install -y git gcc make autoconf libtool automake pkgconfig pipewire-devel || { echo 'Failed to install dependencies for Pipewire. Exiting...'; exit 1; }

# Clone, compile, and install the Pipewire module for XRDP
echo "Cloning and building the Pipewire module for XRDP..."
pushd /tmp
git clone https://github.com/neutrinolabs/pipewire-module-xrdp.git
cd pipewire-module-xrdp
./bootstrap || { echo 'Failed to bootstrap Pipewire module. Exiting...'; exit 1; }
./configure || { echo 'Failed to configure Pipewire module. Exiting...'; exit 1; }
make || { echo 'Failed to make Pipewire module. Exiting...'; exit 1; }
make install || { echo 'Failed to install Pipewire module. Exiting...'; exit 1; }
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
