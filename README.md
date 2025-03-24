
# Build buildroot and kernel in 
See ./superbird/scripts

# Make ESP32s3 WiFi dongle for superbird 
See ./esp32-wifi-ncm

# Restore (unbrick)
Based on https://github.com/alexcaoys/notes-superbird


## Install superbird-tool
	git clone https://github.com/thinglabsoss/superbird-tool
    python3 -m venv .venv 
    source .venv/bin/activate
    python3 -m pip install git+https://github.com/superna9999/pyamlboot
    ./superbird_tool.py --find_device

## Restore partitions with unbrick tool
https://github.com/err4o4/spotify-car-thing-reverse-engineering/issues/30#issuecomment-2161567419

Power device with 1 and 4 buttons pressed

	./superbird_tool.py --burn_mode
	chmod +x ../files/Carthing/Unbrick/update
	../files/Carthing/Unbrick/update bulkcmd "mmc dev 1"
	../files/Carthing/Unbrick/update bulkcmd "amlmmc key"
	../files/Carthing/Unbrick/update mwrite ../files/Carthing/Unbrick/unbrick.bin mem 0x1080000 normal
	../files/Carthing/Unbrick/update bulkcmd "mmc write 0x1080000 0 125000"

Wait 10 sec and unplug

## Restore from dump
	 ./superbird_tool.py --restore_device ../files/dump/

Wait 10 sec and unplug

# Install Buildroot permanent 
## Partitioning
Tutorial from [here](https://github.com/alexcaoys/notes-superbird/blob/main/partitioning/PARTITIONING.md "here") 

### Save and decrypt dtb
 	./superbird_tool.py --burn_mode
 	./superbird_tool.py --enable_burn_mode
	./superbird_tool.py --disable_avb2 a

Uplug and plug back

	./superbird_tool.py --boot_adb_kernel a
	
Wait a bit

	adb pull /proc/device-tree ../files/dtb/device-tree
	dtc -I fs ../files/dtb/device-tree -o ../files/dtb/decrypted.dtb
	./superbird_tool.py --disable_burn_mode

### Boot into initrd
[Download](https://github.com/alexcaoys/notes-superbird/releases/tag/20240724 "Download")

	./superbird_tool.py --burn_mode
	cd ../files/boot_initrd/initrd/
	python3 ./amlogic_device.py --initrd ./env_initrd.txt ./Image_6.6.41 ./rootfs.cpio.uboot ./meson-g12a-superbird.dtb


### Setup host for g_ether
More info [here](https://github.com/alexcaoys/notes-superbird/blob/main/buildroot/BUILDROOT.md "here")

Create rule `/etc/udev/rules.d/99-usb-ether.rules`

	SUBSYSTEM=="net", ATTRS{idVendor}=="0525", ATTRS{idProduct}=="a4a2", NAME="usb_ether"

Update and reload rules 

	sudo udevadm control --reload-rules && sudo udevadm trigger

Update ip tables

	sudo sysctl net.ipv4.ip_forward=1
	sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	sudo iptables -A FORWARD -s 172.16.42.0/24 -j ACCEPT
	sudo iptables -A POSTROUTING -t nat -j MASQUERADE -s 172.16.42.0/24
	sudo iptables-save

Start g_ether and ssh into it (pwd: buildroot)

	sudo ip addr add 172.16.42.1/24 dev usb_ether
	sudo ip link set usb_ether up
	ssh root@172.16.42.2

### Backup bootloader and encrypted dtb

	dd if=/dev/mmcblk2 of=bootloader.img bs=1M count=4
	dd if=/dev/mmcblk2 of=stock_dtb.img bs=256K skip=160 count=2
	
	scp bootloader.img err4o4@172.16.42.1:'/home/err4o4/Desktop/Car Thing/files/bootloader/bootloader.img'
	scp stock_dtb.img err4o4@172.16.42.1:'/home/err4o4/Desktop/Car Thing/files/dtb/stock_dtb.img'

### Restore decrypted dtb 
	scp err4o4@172.16.42.1:'/home/err4o4/Desktop/Car Thing/files/dtb/decrypted.dtb' decrypted.dtb
	dd if=decrypted.dtb of=/dev/mmcblk2 bs=256K seek=160 conv=notrunc
	dd if=decrypted.dtb of=/dev/mmcblk2 bs=256K seek=161 conv=notrunc
	sync

### Save stock partitions with ampart
	./ampart-v1.4-aarch64-static /dev/mmcblk2 --mode esnapshot

Copy output to file ampart.txt for backup

### Restore the following snapshot using

	./ampart-v1.4-aarch64-static /dev/mmcblk2 --mode eclone bootloader:0B:4M:0 reserved:36M:64M:0 cache:108M:0B:0 env:116M:8M:0 fip_a:132M:4M:0 fip_b:144M:4M:0 data:156M:-1:4

### Create new MBR partition tables

	parted
	> unit MiB          # use sector as unit (easy to check)
	> print             # check if the mmc shows
	> mktable msdos     # create new mbr table
	> mkpart primary fat32 4MiB 36MiB       # Use the empty section as /boot
	> mkpart primary ext4 156MiB 3727MiB    # Change the end accordingly
	> quit

### Restore bootloader

	dd if=bootloader.img of=/dev/mmcblk2 conv=fsync,notrunc bs=1 count=444
	dd if=bootloader.img of=/dev/mmcblk2 conv=fsync,notrunc bs=512 skip=1 seek=1

### Format the partitions and mount the boot partition

	mkfs.fat -F 16 /dev/mmcblk2p1
	mkfs.ext4 /dev/mmcblk2p2 

### Restore rootfs

Download rootfs from [here](https://github.com/alexcaoys/notes-superbird/releases/tag/20240804 "here")

	./superbird_tool.py --burn_mode
	cd ../notes-superbird/
	 python3 amlogic_device.py -r 319488 '/home/err4o4/Desktop/Car Thing/files/buildroot/rootfs.ext4'

### Make bootable

Download kernel and dtb from [here](https://github.com/alexcaoys/linux-superbird-6.6.y/releases/tag/6.6.43_20240801 "here")

	./superbird_tool.py --burn_mode
	cd ../files/boot_initrd/initrd/
	python3 ./amlogic_device.py --initrd ./env_initrd.txt ./Image_6.6.41 ./rootfs.cpio.uboot ./meson-g12a-superbird.dtb
	
	sudo ip addr add 172.16.42.1/24 dev usb_ether
	sudo ip link set usb_ether up
	ssh root@172.16.42.2

	/root/init_resize2fs.sh
	mount /dev/mmcblk2p1 /boot
	
	scp err4o4@172.16.42.1:'/home/err4o4/Desktop/Car Thing/files/buildroot/Image' /boot
	scp err4o4@172.16.42.1:'/home/err4o4/Desktop/Car Thing/files/buildroot/meson-g12a-superbird.dtb' /boot/superbird.dtb
	scp err4o4@172.16.42.1:'/home/err4o4/Desktop/Car Thing/notes-superbird/uboot_envs/env_p2.txt' /boot/bootargs.txt

	./superbird_tool.py --send_full_env '/home/err4o4/Desktop/Car Thing/notes-superbird/uboot_envs/env_full_custom.txt'

Reboot
