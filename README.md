Hyper-V Enhanced Session Mode Configuration for RHEL 9+
=======================================================

This repository contains a script to configure **Enhanced Session Mode** (ESM) on RHEL 9 and newer versions when running on **Microsoft Hyper-V**.

Benefits of Enhanced Session Mode
---------------------------------

Enhanced Session Mode on Hyper-V provides several key benefits for users running RHEL in a virtualized environment:

*   **Improved User Experience**: ESM enables full-screen and high-resolution display modes, making the VM feel more like a local machine.
*   **Clipboard and Drive Redirection**: Allows for easy sharing of text and files between the VM and the host system, improving productivity for development and testing.
*   **Audio Redirection**: Adds audio support, making it possible to stream sound from the VM, which is useful for multimedia applications or testing software with audio components.
*   **Simplified Device Access**: Enhanced Session Mode provides easy access to host devices such as USB drives and printers, directly from the VM session.

Prerequisites
-------------

*   **RHEL 9 or Newer**: This script is designed specifically for RHEL 9+ distributions. You can obtain RHEL for free as part of Red Hat’s developer program:  
    [Download RHEL Developer Edition](https://developers.redhat.com/products/rhel/download)
*   **Hyper-V Host**: This configuration is designed for VMs running on Microsoft Hyper-V, with Enhanced Session Mode enabled on the host machine.
*   **Administrator Access**: You will need `sudo` privileges to run this script on the VM and administrative access on the Hyper-V host to enable Enhanced Session Mode.

Installation Instructions
-------------------------

You can use the following command to download and execute the script directly:

    curl -o /tmp/configure_hyperv_esm_rhel.sh https://raw.githubusercontent.com/simon-im-security/Hyper-V-RHEL-Enhanced-Session/refs/heads/main/configure_hyperv_esm_rhel.sh && chmod +x /tmp/configure_hyperv_esm_rhel.sh && sudo /tmp/configure_hyperv_esm_rhel.sh

This command performs the following actions:

1.  **Downloads** the script to a temporary location (`/tmp/configure_hyperv_esm_rhel.sh`).
2.  **Makes the script executable**.
3.  **Runs the script with `sudo`** to ensure it has the necessary permissions.

What the Script Does
--------------------

The script performs the following configuration steps:

1.  **OS Compatibility Check**: Ensures the VM is running RHEL 9 or newer.
2.  **Package Installation**: Installs `hyperv-tools`, `xrdp`, `xrdp-selinux`, and `xorgxrdp` to provide RDP and graphical support.
3.  **XRDP Configuration**: Adjusts XRDP settings to use the Hyper-V socket (`vsock`) for Enhanced Session Mode, enabling:
    *   RDP protocol security
    *   High encryption level
    *   Bitmap compression for optimized graphics
4.  **Audio Support Configuration**: Installs and configures Pipewire for XRDP audio redirection.
5.  **Enables Services**: Enables and starts XRDP services for Enhanced Session Mode.

Post-Installation Setup
-----------------------

After running the script:

1.  **Configure Enhanced Session Mode on the Hyper-V Host**:
    *   Open the Hyper-V Manager, navigate to your VM settings, and enable **Guest Services** under **Management > Integration Services**.
    *   Open a PowerShell session as Administrator on the Hyper-V host and run the following command to set the Enhanced Session Transport Type to `HVSocket`:
        
            Set-VM <VM_NAME> -EnhancedSessionTransportType HVSocket
        
        Replace `<VM_NAME>` with the name of your VM.

2.  **Reboot the VM**: Rebooting ensures that all configuration changes are applied correctly.

---
