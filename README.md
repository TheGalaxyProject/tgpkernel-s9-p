# TGPKernel S9 (for Android Pie 9)

![TGPKernel Logo](https://github.com/TheGalaxyProject/tgpkernel-s9-p/blob/master/build/logo.png?raw=true)

A Custom Kernel for Samsung Galaxy S9 / S9+

* XDA Unified S9 / S9+ Forum: http://forum.xda-developers.com/showthread.php?t=3887308


Compiled using Google GCC 4.9 Toolchain

* URL: https://github.com/djb77/aarch64-linux-android-4.9

## How to use
Adjust the toolchain path in build.sh and Makefile to match the path on your system. 

Run build.sh with the following options, doesn't matter what order keep and silent are in.

For example: build.sh 960 -s

- **./build.sh** will build TGPKernel
- **./build.sh -k** will build TGPKernel and also copy the .img files to the .output folder
- **./build.sh -s** will build TGPKernel but only display warning and errors in the log
- **./build.sh -ks** will do both **-k** and **-s** at the same time
- **./build.sh 960** will only build the S9 Kernel
- **./build.sh 965** will only build the S9+ Kernel

When finished, the new files and logs will be created in the .output directory.

If Java is installed, the .zip file will be signed.


These commands can only be executed by themselves

- **./build.sh 0** will clear the workspace
- **./build.sh 00** will clear CCACHE
- **./build.sh configs** will regenerate the stock star(2)lte configs and overwrite the old ones


## Credit and Thanks to the following:
- [Samsung Open Source Release Center](http://opensource.samsung.com) for the Source code (my personal repo [here](https://github.com/djb77/samsung-kernel))
- [Google](https://android.googlesource.com/kernel/common) for AOSP Common Kernel Source
- @osm0sis for [Android Image Kitchen](https://github.com/osm0sis/Android-Image-Kitchen/tree/AIK-Linux) and [anykernel2](https://github.com/osm0sis/AnyKernel2)
- @farovitus, @Eamo5, and @Noxxxious for help and commits
- All the other kernel devs I have picked commits from to form this kernel

