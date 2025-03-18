Based on https://github.com/alexcaoys/notes-superbird

# Restore (unbrick)

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





# car-thing-reverse-engineering

## Hardware 
https://fccid.io/2AP3D-YX5H6679

CPU: AMLOGIC s905d2  
RAM: NANYA nt5cc256m16er-eki  
EMMC: THGBMNG5D1LBAIL  

## U-boot
https://github.com/err4o4/car-thing-reverse-engineering/blob/main/u-boot.log

There are 2 UARTs. One shows complete mess due to locked bootloader (maybe I'm wrong) and another shows u-boot log. As far as I understand we need to enter recovery or disable secure boot. Tried different buttons/combination/shorted some testpads - no luck.

## Bluetooth 

## Firmware 
https://drive.google.com/file/d/1XgEtHngd14Z3Vhj1zarceuxAH7cjQDQ_/view?usp=sharing

Found SWU update link from sniffing bluetooth connection.

The .xdpatch files use VCDIFF (RFC 3284) compression. You can use xdelta3 or other VCDIFF tools to manapulate them. But the format is targeted for binary files and does not generate human readable output.

```
binwalk 5.2.6.swu

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             ASCII cpio archive (SVR4 with CRC) file name: "sw-description", file name length: "0x0000000F", file size: "0x00000D88"
3592          0xE08           ASCII cpio archive (SVR4 with CRC) file name: "sw-description.sig", file name length: "0x00000013", file size: "0x00000100"
3980          0xF8C           ASCII cpio archive (SVR4 with CRC) file name: "preinstall.sh", file name length: "0x0000000E", file size: "0x00000573"
4104          0x1008          Executable script, shebang: "/bin/sh"
5500          0x157C          ASCII cpio archive (SVR4 with CRC) file name: "vbmeta.img.xdpatch", file name length: "0x00000013", file size: "0x00000221"
5691          0x163B          xz compressed data
6099          0x17D3          xz compressed data
6180          0x1824          ASCII cpio archive (SVR4 with CRC) file name: "postinstall.sh", file name length: "0x0000000F", file size: "0x00000282"
6308          0x18A4          Executable script, shebang: "/bin/sh"
6952          0x1B28          ASCII cpio archive (SVR4 with CRC) file name: "rootfs.ext2.xdpatch", file name length: "0x00000014", file size: "0x0143753C"
7149          0x1BED          xz compressed data
8217          0x2019          xz compressed data
9866          0x268A          xz compressed data
21205224      0x14390E8       ASCII cpio archive (SVR4 with CRC) file name: "boot.img.xdpatch", file name length: "0x00000011", file size: "0x00549619"
21205414      0x14391A6       xz compressed data
21339700      0x1459E34       xz compressed data
21394309      0x1467385       xz compressed data
26748804      0x1982784       ASCII cpio archive (SVR4 with CRC) file name: "TRAILER!!!", file name length: "0x0000000B", file size: "0x00000000"
```

```
ls -l

total 52264
-rw-r--r-- 1 err4o4 err4o4  5543449 сен  7 11:35 boot.img.xdpatch
-rwxr-xr-x 1 err4o4 err4o4      642 сен  7 11:35 postinstall.sh
-rwxr-xr-x 1 err4o4 err4o4     1395 сен  7 11:35 preinstall.sh
-rw-r--r-- 1 err4o4 err4o4 21198140 сен  7 11:35 rootfs.ext2.xdpatch
-rw-r--r-- 1 err4o4 err4o4     3464 сен  7 11:35 sw-description
-rw-r--r-- 1 err4o4 err4o4      256 сен  7 11:35 sw-description.sig
-rw-r--r-- 1 err4o4 err4o4      545 сен  7 11:35 vbmeta.img.xdpatch
```

```
binwalk boot.img.xdpatch 

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
62            0x3E            xz compressed data
134348        0x20CCC         xz compressed data
188957        0x2E21D         xz compressed data


binwalk rootfs.ext2.xdpatch

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
65            0x41            xz compressed data
1133          0x46D           xz compressed data
2782          0xADE           xz compressed data


binwalk vbmeta.img.xdpatch 

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
59            0x3B            xz compressed data
467           0x1D3           xz compressed data
```

https://github.com/spsgsb/uboot/tree/bf8ab892a2c52e3fedc4dfbc569ebc1003aece75/board/amlogic/superbird_production
https://github.com/forkbabu/Spotify/tree/74290449d2482a08b21d570e245c9402c7624871/sources/com/spotify/music/superbird
https://dn.odroid.com/S905/DataSheet/S905_Public_Datasheet_V1.1.4.pdf

