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

# Install EPEL repository
echo "Installing EPEL repository..."
echo 'Downloading and installing EPEL repository manually...'
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -O /tmp/epel-release-latest.rpm || { echo 'Failed to download EPEL release. Exiting...'; exit 1; }
dnf install -y /tmp/epel-release-latest.rpm || { echo 'Failed to install EPEL release from downloaded package. Exiting...'; exit 1; }
rm -f /tmp/epel-release-latest.rpm
    dnf install -y /tmp/epel-release-latest.rpm || { echo 'Failed to install EPEL release from downloaded package. Exiting...'; exit 1; }
    rm -f /tmp/epel-release-latest.rpm
}

# Install Hyper-V tools
echo "Installing Hyper-V tools..."
dnf install -y hyperv-tools || { echo 'Failed to install Hyper-V tools. Exiting...'; exit 1; }

# Install XRDP components
echo "Installing XRDP and associated components..."
dnf install -y xrdp xorgxrdp || { echo 'Failed to install XRDP components. Exiting...'; exit 1; }

dnf install -y hyperv-tools xrdp xorgxrdp

# Check and install xrdp-selinux if available
echo "Attempting to install xrdp-selinux..."
if ! dnf install -y xrdp-selinux; then
    echo "xrdp-selinux package not found in repositories. Attempting to build and install manually..."
    # Clone, compile, and install xrdp-selinux manually
    pushd /tmp
    git clone https://github.com/neutrinolabs/xrdp.git
    cd xrdp
    dnf install -y selinux-policy-devel || { echo 'Failed to install selinux-policy-devel. Exiting...'; exit 1; }
    make -f selinux/Makefile || { echo 'Failed to build xrdp-selinux. Exiting...'; exit 1; }
    semodule -i selinux/xrdp.pp || { echo 'Failed to install xrdp-selinux module. Exiting...'; exit 1; }
    popd
    rm -rf /tmp/xrdp
fi

# Verify and install missing hyperv-tools if not found in the default repo
echo "Checking installation of hyperv-tools..."
if ! rpm -q hyperv-tools; then
    echo "hyperv-tools not found in repositories. Attempting to install from alternative source..."
    dnf install -y hyperv-daemons hyperv-daemons-license hyperv-daemons-tools || { echo 'Failed to install alternative Hyper-V tools. Exiting...'; exit 1; }
fi

# Verify and install xrdp and xorgxrdp if they are not found
if ! rpm -q xrdp; then
    echo "xrdp package not found. Attempting to build and install manually..."
    pushd /tmp
    git clone https://github.com/neutrinolabs/xrdp.git
    cd xrdp
    ./bootstrap || { echo 'Failed to bootstrap. Exiting...'; exit 1; }
    ./configure || { echo 'Failed to configure. Exiting...'; exit 1; }
    make || { echo 'Failed to make xrdp. Exiting...'; exit 1; }
    make install || { echo 'Failed to install xrdp. Exiting...'; exit 1; }
    popd
    rm -rf /tmp/xrdp
fi

if ! rpm -q xorgxrdp; then
    echo "xorgxrdp package not found. Attempting to build and install manually..."
    pushd /tmp
    git clone https://github.com/neutrinolabs/xorgxrdp.git
    cd xorgxrdp
    ./bootstrap || { echo 'Failed to bootstrap xorgxrdp. Exiting...'; exit 1; }
    ./configure || { echo 'Failed to configure xorgxrdp. Exiting...'; exit 1; }
    make || { echo 'Failed to make xorgxrdp. Exiting...'; exit 1; }
    make install || { echo 'Failed to install xorgxrdp. Exiting...'; exit 1; }
    popd
    rm -rf /tmp/xorgxrdp
fi

# Enable and start XRDP services
echo "Enabling and starting XRDP services for Enhanced Session Mode support..."
if systemctl list-unit-files | grep -q '^xrdp.service'; then
    systemctl enable --now xrdp xrdp-sesman || { echo 'Failed to enable XRDP services. Exiting...'; exit 1; }
else
    echo "Error: XRDP services not found. Please check the installation. Exiting..."
    exit 1
fi

# Modify XRDP configuration for Enhanced Session Mode with Hyper-V Sockets
echo "Applying XRDP configuration adjustments for Enhanced Session Mode..."
sed -i 's/port=3389/port=vsock:\/\/\-1:3389/g' /etc/xrdp/xrdp.ini
sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i 's/crypt_level=high/crypt_level=high/g' /etc/xrdp/xrdp.ini
sed -i 's/bitmap_compression=true/bitmap_compression=true/g' /etc/xrdp/xrdp.ini

# Add Xorg configuration for graphical XRDP sessions
echo "Configuring XRDP to support graphical sessions using Xorg..."
sed -i '/^\[Xorg\]/,/^$/c\[Xorg]\nname=Xorg\nlib=libxup.so\nusername=ask\npassword=ask\nport=-1\ncode=20' /etc/xrdp/xrdp.ini

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
