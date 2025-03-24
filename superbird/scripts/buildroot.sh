#!/bin/bash

# Based on https://github.com/alexcaoys/notes-superbird

# Get the directory of the script
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR=$SCRIPTS_DIR/../

# Get buildroot 2024.02.4
echo 'Cloning buildroot 2024.02.4'
cd "$WORK_DIR"
git clone https://github.com/buildroot/buildroot.git
cd buildroot
git checkout 2024.02.4

# Get kernel 6.6.43 tarball
echo 'Downloading kernel 6.6.43'
cd "$WORK_DIR"
wget https://github.com/alexcaoys/linux-superbird-6.6.y/archive/refs/tags/6.6.43_20240801.tar.gz

# Copy buildroot config
cp "$WORK_DIR/config_buildroot/config_buildroot_sway" "$WORK_DIR/buildroot/.config"

# Copy patched sway and keyd
echo 'Copying patched sway'
rm -r "$WORK_DIR/buildroot/package/sway"
cp -r "$WORK_DIR/config_buildroot/package/sway" "$WORK_DIR/buildroot/package/"
cp -r "$WORK_DIR/config_buildroot/package/keyd" "$WORK_DIR/buildroot/package/"

#rm "$WORK_DIR/buildroot/package/Config.in"
#cp "$WORK_DIR/config_buildroot/package/Config.in" "$WORK_DIR/buildroot/package/Config.in" 

# Done
echo 'Ready for buildroot'
echo 'Go to buildroot dir and run make -j$(nproc)'

echo 'Do not forget to copy new kernel to the device, since uinput is build to kernel and not as module'
echo 'If you do not want to copy kernel to the device, build uinput as module'
echo 'make linux-menuconfig'
echo 'Device Drivers → Input device support → Miscellaneous devices → User level driver support (uinput) -> M'
echo 'Check if Buildroot is configured to install kernel modules'
echo 'make menuconfig'
echo 'Target packages → Kernel → [*] Install kernel modules'
