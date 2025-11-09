#!/usr/bin/env bash

# -------------------------------------------------------------------
# Script: init.sh
# Description: This script installs the required packages
# Author: Walid A.
# Date: 09/11/2025
# Usage: ./init.sh
# -------------------------------------------------------------------

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
set -e
set -u
set -o pipefail

#--------------------------------------------------------------------------------
# Install required packages
#--------------------------------------------------------------------------------
echo "-> Installing build tools"
sudo apt update && sudo apt upgrade -y
sudo apt install live-build debootstrap squashfs-tools xorriso isolinux syslinux-utils wget qemu-system-x86 qemu-utils -y