#!/usr/bin/env bash

# -------------------------------------------------------------------
# Script: build.sh
# Description: This script build the os
# Author: Walid A.
# Date: 09/11/2025
# Usage: ./build.sh
# -------------------------------------------------------------------

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
set -e # Exit immediately if any command exits with a non-zero status
set -u # Treat unset variables as an error and exit immediately
set -o pipefail # Make pipelines fail if any command in the pipeline fails (not just the last one)

#--------------------------------------------------------------------------------
# Configs
#--------------------------------------------------------------------------------
BUILD_DIR="$(pwd)/build"
DISTRO="trixie"
ARCH="amd64"

#--------------------------------------------------------------------------------
# ensure running on same distro as target
#--------------------------------------------------------------------------------
echo "-> Ensuring we are on Debian ${DISTRO}"
. /etc/os-release
if [ "$VERSION_CODENAME" != "${DISTRO}" ]; then
  echo "-> ERROR: You are not running Debian ${DISTRO}. Exiting."
  exit 1
fi
echo "-> You are running Debian ${DISTRO}."

#--------------------------------------------------------------------------------
# Set Up the Working Directory
#--------------------------------------------------------------------------------
echo "-> Set Up the Working Directory"
rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

#--------------------------------------------------------------------------------
# Configure the Build 
#--------------------------------------------------------------------------------
echo "-> Configure the Build"
lb config \
  --distribution bookworm \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer live

# --distribution: Specifies the Debian release.
# --binary-images iso-hybrid: Generates an ISO that can be burned to a CD/DVD or written to a USB stick.
# --archive-areas: Includes optional areas of the Debian archive.
# --debian-installer: Includes the Debian installer for installation options.

#--------------------------------------------------------------------------------
# Add Custom Packages
#--------------------------------------------------------------------------------
echo "-> Add Custom Packages"
mkdir -p config/package-lists
cat > config/package-lists/custom.list.chroot << 'EOF'
vim
curl
git
net-tools
coreutils 
EOF

#--------------------------------------------------------------------------------
# Add Preseed Configuration
#--------------------------------------------------------------------------------
echo "-> Add Preseed Configuration"
mkdir -p config/includes.installer
cat > config/includes.installer/preseed.cfg << 'EOF'
d-i debian-installer/locale string en_US
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/layoutcode string us
EOF

#--------------------------------------------------------------------------------
# Include Custom Files
#--------------------------------------------------------------------------------
echo "-> Add Preseed Configuration"
mkdir -p config/includes.chroot/etc/skel
echo "This is Embedded Linux - Debian based" > config/includes.chroot/etc/skel/osinfo 
# place a osinfo in every new user’s home directory.

#--------------------------------------------------------------------------------
# Add Boot Message (display when system boots or user logs in)
#--------------------------------------------------------------------------------
echo "-> Add Boot Message"
mkdir -p config/includes.chroot/etc/profile.d
cat > config/includes.chroot/etc/profile.d/boot-message.sh << 'EOF'
#!/bin/bash
echo "Booting ..."
echo "=================================================="
echo "Embedded Linux - Debian based"
echo "by Walid A. "                                                                                                          
echo "=================================================="
EOF

chmod +x config/includes.chroot/etc/profile.d/boot-message.sh

#--------------------------------------------------------------------------------
# Add Hooks for the build process (scripts that run during the build process)
#--------------------------------------------------------------------------------
echo "-> Add Hooks for the build process"
mkdir -p config/hooks
cat > config/hooks/00-custom-setup.chroot << 'EOF'
#!/bin/bash
echo "Running custom setup..."
apt-get update
apt-get install -y htop
EOF

chmod +x config/hooks/00-custom-setup.chroot

#--------------------------------------------------------------------------------
# Build the ISO Image
#--------------------------------------------------------------------------------
echo "-> Running the build"
sudo lb build

#--------------------------------------------------------------------------------
# Locate the resulting ISO image
#--------------------------------------------------------------------------------
echo "-> Produced ISO"
find . -type f -name "*.iso" -print
ISO_PATH=$(find . -type f -name "*.iso" | head -n 1)
if [[ -n "$ISO_PATH" ]]; then
  echo "-> ISO image path:"
  echo "   $(realpath "$ISO_PATH")"
else
  echo "-> ERROR: No ISO file found."
  exit 1
fi

#--------------------------------------------------------------------------------
# done
#--------------------------------------------------------------------------------
echo "-> the build done."
