# System for LicheePi Zero Dock

## system usage

to run quadruped robot wbc+mpc program or reinforcement learning deployment program.
for robot gamepad controller with LCD screen.

## compiling environment

use docker container as compiling environment.

```shell
docker build -t licheepi:latest .
docker run -it --rm -v ./:/home/user/licheepi --name licheepi licheepi:latest
```

## u-boot

```shell
git clone https://github.com/Lichee-Pi/u-boot.git -b v3s-current
```

add the following content to `u-boot/include/sun8i.h`.

```c
#define CONFIG_BOOTCOMMAND  "setenv bootm_boot_mode sec; " \
                            "load mmc 0:1 0x41000000 zImage; "  \
                            "load mmc 0:1 0x41800000 sun8i-v3s-licheepi-zero-dock.dtb; " \
                            "bootz 0x41000000 - 0x41800000;"
#define CONFIG_BOOTARGS      "console=ttyS0,115200 panic=5 rootwait root=/dev/mmcblk0p2 earlyprintk rw  vt.global_cursor_default=0"
```

then build u-boot.

```shell
cd u-boot
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LicheePi_Zero_800x480LCD_defconfig
#or make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LicheePi_Zero_480x272LCD_defconfig
#or make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LicheePi_Zero_defconfig
make ARCH=arm menuconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
cp ./u-boot-sunxi-with-spl.bin ../output/
```

## mainline linux kernel

```shell
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.1.tar.xz
tar -xf linux-6.10.1.tar.xz
cp ./licheepi_zero_defconfig linux-6.10.1/arch/arm/configs/
cd linux-6.10.1/
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- licheepi_zero_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j
cp ./arch/arm/boot/dts/allwinner/sun8i-v3s-licheepi-zero-dock.dtb ../output/ && \
cp ./drivers/staging/rtl8723bs/r8723bs.ko ../output/ && \
cp ./arch/arm/boot/zImage ../output/
```

## emdebian

```shell
sudo apt-get install multistrap qemu qemu-user-static binfmt-support dpkg-cross
```

insert `$config_str .= " -o Acquire::AllowInsecureRepositories=true";` to line 320 of /usr/sbin/multistrap

```shell
sudo multistrap -a armhf -f emdebian.conf
sudo cp /usr/bin/qemu-arm-static rootfs/usr/bin
sudo mount -o bind /dev/ rootfs/dev/
sudo LC_ALL=C LANGUAGE=C LANG=C chroot rootfs dpkg --configure -a
```

you are required to choose area and whether to use dash as default shell during dpkg configuration, just choose where you live and no to dash.

```shell
sudo chroot rootfs
# change password
passwd
groupadd -g 1000 user
useradd -g 1000 -u 1000 -m -s /usr/sbin/nologin user
passwd user
apt update
# install extra software packages
apt install -y xxxxxxxx
# exit target rootfs
exit
sudo umount rootfs/dev/  #最后记得卸载
sudo rm rootfs/usr/bin/qemu-arm-static
sudo sh ./configure.sh
```

## setup sdcard

format sdcard to 2 part.
part1: system boot partition; 1MB unused space before part1; fat32 format; 16MB size.
part2: root file system partition; ext4 format; rest of the space after part1

put `sun8i-v3s-licheepi-zero-dock.dtb` and `zImage` to partition 1.

assume your sdcard is recognized as /dev/sda. then execute the following command to flash u-boot binary.
this command flash u-boot binary to 8KB offset of sdcard, which is the required offset location of u-boot binary of allwinner V3S SoC.

```shell
sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sda bs=1024 seek=8
```

copy emdebian root file system to partition 2.

```shell
cd emdebian/rootfs
sudo cp -r -a ./ /media/<you-user-name>/rootfs
sudo cp -r -a ./ /media/<you-user-name>/rootfs
```

use `file /media/<your-user-name>/rootfs/lib/systemd/systemd` to examine the file integrity of system init program. it must be like this:

```shell
$ file /media/<your-user-name>/rootfs/lib/systemd/systemd
file /media/<your-user-name>/rootfs/lib/systemd/systemd: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=a57af37f5291a5be31f8950caf7eb43d379782c4, stripped
```

if systemd is empty like the following info, `sudo cp -r -a ./ /media/<you-user-name>/rootfs` twice.