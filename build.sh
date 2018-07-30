#!/bin/bash
# ----------------------------
# TGPKERNEL BUILD SCRIPT 6.1.9
# Created by @djb77
# ----------------------------

# Set Variables
export RDIR=$(pwd)
export KERNELNAME=TGPKernel
export VERSION_NUMBER=$(<build/version)
export ARCH=arm64
export BUILD_CROSS_COMPILE=~/android/toolchains/gcc-arm-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
WORK=.work
WORKDIR=$RDIR/$WORK
ZIPDIR=$RDIR/.work_zip
OUTPUT=$RDIR/.output
OUTDIR=$WORKDIR/arch/$ARCH/boot
KERNELCONFIG=$WORK/arch/arm64/configs/build_defconfig
KEEP=no
SILENT=no
BUILD960=yes
BUILD965=yes

########################################################################################################################################################
# Functions

# Clean Function
FUNC_CLEAN()
{
echo ""
echo "Deleting old work files ..."
echo ""
if [ -d $WORKDIR ]; then
	sudo chown 0:0 $WORKDIR 2>/dev/null
	sudo chmod -R 777 $WORKDIR
	sudo rm -rf $WORKDIR
fi
[ -d "$RDIR/net/wireguard" ] && rm -rf $RDIR/net/wireguard
[ -e "$RDIR/.wireguard-fetch-lock" ] && rm -f $RDIR/.wireguard-fetch-lock
find $RDIR/scripts/ -type d -name "__pycache__" -exec rm -rf {} +
}

# Full clean Function
FUNC_CLEAN_ALL()
{
FUNC_CLEAN
[ -d $ZIPDIR ] && rm -rf $ZIPDIR
[ -d $OUTPUT ] && rm -rf $OUTPUT
exit
}

# Clean ccache
FUNC_CLEAN_CCACHE()
{
echo ""
ccache -C
echo ""
exit
}

# Copy files to work locations
FUNC_COPY()
{
echo "Copying work files ..."
mkdir -p $WORKDIR/arch
mkdir -p $WORKDIR/firmware
mkdir -p $WORKDIR/include
mkdir -p $WORKDIR/init
mkdir -p $WORKDIR/kernel
mkdir -p $WORKDIR/net
mkdir -p $WORKDIR/ramdisk/ramdisk
sudo chown 0:0 $WORKDIR/ramdisk/ramdisk 2>/dev/null
mkdir -p $WORKDIR/scripts
mkdir -p $WORKDIR/security
cp -rf $RDIR/arch/arm/ $WORKDIR/arch/
cp -rf $RDIR/arch/arm64/ $WORKDIR/arch/
cp -rf $RDIR/arch/x86 $WORKDIR/arch/
cp -rf $RDIR/firmware $WORKDIR/
cp -rf $RDIR/include $WORKDIR/
cp -rf $RDIR/init $WORKDIR/
cp -rf $RDIR/kernel $WORKDIR/
cp -rf $RDIR/net $WORKDIR/
cp -rf $RDIR/build/aik/* $WORKDIR/ramdisk
cp -rf $RDIR/scripts $WORKDIR/
cp -rf $RDIR/security $WORKDIR/
sudo cp -rf $RDIR/build/ramdisk/* $WORKDIR/ramdisk 
}

# Build zimage Function
FUNC_BUILD_KERNEL()
{
echo "Preparing configuration ..."
cp -f $WORKDIR/arch/arm64/configs/tgpkernel_defconfig $KERNELCONFIG
if [ $MODEL = "S9" ]; then
	cat $WORKDIR/arch/arm64/configs/starlte_defconfig >> $KERNELCONFIG
	sed -i -- 's/star2lte_defconfig/starlte_defconfig/g' $WORKDIR/kernel/Makefile
fi
[ $MODEL = "S9+" ] && cat $WORKDIR/arch/arm64/configs/star2lte_defconfig >> $KERNELCONFIG
cd $WORKDIR
sudo find . -name \.placeholder -type f -delete
cd $RDIR
echo "Loading configuration ..."
echo ""
if [ $SILENT = "no" ]; then
	make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
else
	make -s -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
fi
echo "Compiling zImage and dtb ..."
echo ""
if [ $SILENT = "no" ]; then
	make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
else
	make -s -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
fi
echo ""
echo "Compiling Ramdisk ..."
sudo cp $WORKDIR/arch/$ARCH/boot/Image $WORKDIR/ramdisk/split_img/boot.img-zImage
sudo cp $WORKDIR/arch/$ARCH/boot/dtb.img $WORKDIR/ramdisk/split_img/boot.img-dt
[ $MODEL = "S9" ] && sudo sed -i -- 's/SRPQH16A007KU/SRPQH16B007KU/g' $WORKDIR/ramdisk/split_img/boot.img-board
cd $WORKDIR/ramdisk
./repackimg.sh
echo ""
}

# Build boot.img Function
FUNC_BUILD_BOOTIMG()
{
	(
	FUNC_CLEAN
	FUNC_COPY
	FUNC_BUILD_KERNEL
	) 2>&1	 | tee -a $LOGFILE
}

# Build config files seperately
FUNC_CONFIGS()
{
# Config for S9
MODEL=S9
FUNC_CLEAN
FUNC_COPY
KERNELCONFIG=$WORK/arch/arm64/configs/exynos9810-starlte_defconfig
make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
mv -f $WORKDIR/.config $RDIR/arch/arm64/configs/exynos9810-starlte_defconfig
# Config for S9+
MODEL=S9+
FUNC_CLEAN
FUNC_COPY
KERNELCONFIG=$WORK/arch/arm64/configs/exynos9810-star2lte_defconfig
make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
mv -f $WORKDIR/.config $RDIR/arch/arm64/configs/exynos9810-star2lte_defconfig
# Clean up
FUNC_CLEAN
exit
}

# Build Zip Function
FUNC_BUILD_ZIP()
{
echo "Preparing Zip File  ..."
echo ""
echo "- Building anykernel2.zip file ..."
cd $ZIPDIR/tgpkernel/anykernel2
rm -f $ZIPDIR/tgpkernel/anykernel2/.git.zip
[ -d $ZIPDIR/tgpkernel/anykernel2/.git ] && rm -rf $ZIPDIR/tgpkernel/anykernel2/.git
zip -9gq anykernel2.zip -r * -x "*~"
if [ -n `which java` ]; then
	echo "  Java detected, signing zip"
	AK2_NAME=anykernel2.zip
	mv $AK2_NAME unsigned-$AK2_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 unsigned-$AK2_NAME $AK2_NAME
	rm unsigned-$AK2_NAME
fi
echo "  Deleting unwanted files"
rm -rf META-INF tgpkernel patch tools anykernel.sh README.md
echo "- Building final zip ..."
cd $ZIPDIR
zip -9gq $ZIP_NAME -r META-INF/ -x "*~"
zip -9gq $ZIP_NAME -r tgpkernel/ -x "*~" 
if [ -n `which java` ]; then
	echo "  Java detected, signing zip"
	mv $ZIP_NAME unsigned-$ZIP_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 unsigned-$ZIP_NAME $ZIP_NAME
	rm unsigned-$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $OUTPUT/$ZIP_NAME
cd $RDIR
}

########################################################################################################################################################
# Main script

# Check command line for switches
[ "$1" = "0" ] && FUNC_CLEAN_ALL
[ "$1" = "00" ] && FUNC_CLEAN_CCACHE
[ "$1" = "configs" ] && FUNC_CONFIGS
[ "$1" = "960" ] || [ "$2" = "960" ] || [ "$3" = "960" ] || [ "$4" = "960" ] && export BUILD965=no
[ "$1" = "965" ] || [ "$2" = "965" ] || [ "$3" = "965" ] || [ "$4" = "965" ] && export BUILD960=no
[ "$1" = "-ks" ] || [ "$2" = "-ks" ] || [ "$3" = "-ks" ] || [ "$4" = "-ks" ] && export SILENT=yes && export KEEP=yes
[ "$1" = "-k" ] || [ "$2" = "-k" ] || [ "$3" = "-k" ] || [ "$4" = "-k" ] && export KEEP=yes
[ "$1" = "-s" ] || [ "$2" = "-s" ] || [ "$3" = "-s" ] || [ "$4" = "-s" ] && export SILENT=yes

# Start Script
clear
echo ""
echo "+-----------------------------------------+"
echo "-                                         -"
echo "-     @@@@@@@@@@    @@@@@  @@@@@@@@       -"
echo "-     @@@@@@@@@@ @@@@@@@@@ @@@@@@@@@@     -"
echo "-        @@@@  '@@@@@@@@@@ @@@@@@@@@@     -"
echo "-        @@@@   @@@@@@@     @@@   @@@     -"
echo "-        @@@@   @@@@@       @@@  @@@@     -"
echo "-        @@@@   @@@@@  @@@@ @@@@@@@@      -"
echo "-        @@@@    @@@@@ @@@@ @@@@@@@       -"
echo "-        @@@@    @@@@@@@@@@ @@@@          -"
echo "-        @@@@     @@@@@@@@ @@@@@          -"
echo "-                    @@@@@                -"
echo "-                                         -"
echo "-     TGPKernel Build Script by djb77     -"
echo "-                                         -"
echo "+-----------------------------------------+"
echo ""
sudo echo ""
[ -d "$WORKDIR" ] && rm -rf $WORKDIR
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ -d "$OUTPUT" ] && rm -rf $OUTPUT
[ -d "$RDIR/net/wireguard" ] && rm -rf $RDIR/net/wireguard
mkdir $ZIPDIR
mkdir $OUTPUT
cp -rf $RDIR/build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/kernels

START_TIME=`date +%s`

# Build S9 img files
if [ $BUILD960 = "yes" ]; then
	MODEL=S9
	echo "---------------------"
	echo "Building S9 .img file"
	echo "---------------------"
	export KERNELTITLE=$KERNELNAME.$MODEL.$VERSION_NUMBER
	LOGFILE=$OUTPUT/build-960.log
	FUNC_BUILD_BOOTIMG
	mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot-960.img
fi
if [ $BUILD965 = "yes" ]; then
	MODEL=S9+
	echo "----------------------"
	echo "Building S9+ .img file"
	echo "----------------------"
	export KERNELTITLE=$KERNELNAME.$MODEL.$VERSION_NUMBER
	LOGFILE=$OUTPUT/build-965.log
	FUNC_BUILD_BOOTIMG
	mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot-965.img
fi

# Final archiving
echo "---------------"
echo "Final archiving"
echo "---------------"
echo ""
if [ $KEEP = "yes" ]; then
	echo "Copying .img files to output folder ..."
	cp -f $ZIPDIR/tgpkernel/kernels/boot-960.img $OUTPUT/boot-960.img
	cp -f $ZIPDIR/tgpkernel/kernels/boot-965.img $OUTPUT/boot-965.img
	echo ""
fi
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G96xx.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
FUNC_CLEAN
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo "You will find your logs and files in the .output folder"
echo ""
exit

