#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="zImage"
DTBIMAGE="boot.img-dtb"
BOOTIMAGE="boot.img-zImage"
DEFCONFIG="ak_bacon_defconfig"

# Kernel Details
BASE_AK_VER="ak"
VER=".004.onepone"
AK_VER="$BASE_AK_VER$VER"

# Vars
export LOCALVERSION=~`echo $AK_VER`
export CROSS_COMPILE=${HOME}/android/AK-linaro/4.7.3-2013.04.20130415/bin/arm-linux-gnueabihf-
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=ak
export KBUILD_BUILD_HOST=kernel

# Paths
KERNEL_DIR=`pwd`
REPACK_DIR="${HOME}/android/AK-OnePone-Ramdisk"
SPLITIMG_DIR="${HOME}/android/AK-OnePone-Ramdisk/split_img"
MODULES_DIR="${HOME}/android/AK-OnePone-Ramdisk/cwm/system/lib/modules"
ZIP_DIR="${HOME}/android/AK-OnePone-Ramdisk/zip"
ZIP_MOVE="${HOME}/android/AK-releases"
ZIMAGE_DIR="${HOME}/android/AK-OnePone/arch/arm/boot"
CWM_DIR="${HOME}/android/AK-OnePone-Ramdisk/cwm"

# Ramdisk Details
RAMDISK_DIR="${HOME}/android/AK-OnePone-Ramdisk/ramdisk"
PS=2048
BASE=0x00000000
RAMDISK_OFFSET=0x02000000
TAGS_OFFSET=0x01e00000
CMDLINE="console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3"

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		rm -rf $ZIP_DIR/*
		rm -rf $CWM_DIR/boot.img*
		rm -rf $REPACK_DIR/*.gz
		rm -rf $REPACK_DIR/*.img
		rm -rf $ZIMAGE_DIR/zImage*
		make clean && make mrproper
}

function make_kernel {
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL $SPLITIMG_DIR/$BOOTIMAGE
}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$REPACK_DIR/dtbToolCM -2 -o $SPLITIMG_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/
}

function make_boot {
		cd $REPACK_DIR
		./repackimg.sh
		mv image-new.img cwm/boot.img
		rm -rf ramdisk-new.cpio.gz
		cd $KERNEL_DIR
}

function make_zip {
		cd $CWM_DIR
		zip -r `echo $AK_VER`.zip *
		mv  `echo $AK_VER`.zip $ZIP_DIR
		cp -vr $ZIP_DIR/`echo $AK_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")

echo -e "${green}"
echo "AK Kernel Creation Script:"
echo "    _____                         "
echo "   (, /  |              /)   ,    "
echo "     /---| __   _   __ (/_     __ "
echo "  ) /    |_/ (_(_(_/ (_/(___(_(_(_"
echo " ( /                              "
echo " _/                               "
echo

echo "---------------"
echo "Kernel Version:"
echo "---------------"

echo -e "${red}"; echo -e "${blink_red}"; echo "$AK_VER"; echo -e "${restore}";

echo -e "${green}"
echo "-----------------"
echo "Making AK Kernel:"
echo "-----------------"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		make_modules
		make_boot
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

