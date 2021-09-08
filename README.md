# car-thing-reverse-engineering

## Hardware 
https://fccid.io/2AP3D-YX5H6679

CPU: AMLOGIC s905d2  
RAM: NANYA nt5cc256m16er-eki  
EMMC: THGBMNG5D1LBAIL  

## U-boot
https://github.com/err4o4/car-thing-reverse-engineering/blob/main/u-boot.log

There is 2 UARTs. One shows complete mess due to looked bootloader (maybe I'm wrong) and another shows u-boot log. As far as I understand we need to enter recovery or disable secure boot. Tried different buttons/combination/shorted some testpads - no luck.

## Bluetooth 

## Firmware 
https://drive.google.com/file/d/1XgEtHngd14Z3Vhj1zarceuxAH7cjQDQ_/view?usp=sharing

Found SWU update link from sniffing bluetooth connection.

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


