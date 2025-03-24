if [ $(df -m /dev/mmcblk2p2  | tail -1 | awk '{print $4}') -lt 513 ]
then
    echo 'Not enough space for swapfile'
    exit 1
fi
dd if=/dev/zero of=/swapfile bs=1M count=512
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile	swap		swap	defaults	0	0' >> /etc/fstab
echo '/dev/mmcblk2p1	/boot		vfat	defaults,ro	0	2' >> /etc/fstab

# Add root user to pulse-access group
# https://unix.stackexchange.com/questions/397232/adduser-addgroup-group-in-use
sed -i '/^pulse-access:/s/\(.*\)/\1,root/;s/:,/:/' /etc/group

# Remove --disallow-module-loading so bluetooth can work on root
# https://raspberrypi.stackexchange.com/questions/42265/pulseaudio-a2dp-bluetooth-dont-work-in-system-mode-but-work-work-fine-under
if [ -e /etc/init.d/S50pulseaudio ]; then
    sed -i '/--disallow-module-loading/d' /etc/init.d/S50pulseaudio
fi

# https://github.com/dino/dino/issues/1024
gdk-pixbuf-query-loaders --update-cache

reboot