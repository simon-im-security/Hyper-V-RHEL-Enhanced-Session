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

Ensure you have `sudo` privileges before running the script. You can use the following command, which includes a `sudo` check at the beginning, to download, make executable, and execute the script directly:

```bash
sudo curl -o /tmp/configure_hyperv_esm_rhel.sh https://raw.githubusercontent.com/simon-im-security/Hyper-V-RHEL-Enhanced-Session/refs/heads/main/configure_hyperv_esm_rhel.sh && chmod +x /tmp/configure_hyperv_esm_rhel.sh && sudo /tmp/configure_hyperv_esm_rhel.sh
```

---
