## TWRP Device configuration for Realme X2 Pro (samurai) ##

## Features

Works:
- ADB
- Decryption of /data
- Screen brightness settings
- Correct screenshot color
- MTP
- Flashing (opengapps, roms, images and so on)
- Backup/Restore
- USB OTG
- Realme OZIP decryption (stock-to-custom recovery)

## Compilation Procedure:

# First Make a directory to build recovery image:
```
mkdir twrp-12.1
cd twrp-12.1
```
# After that checkout minimal twrp source with shallow repo sync to save time:
```
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync
git clone --depth=1 -b twrp-12.1-aosp https://github.com/zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150.git device/realme/samurai
```
# Finally execute these:
```
cd device/realme/samurai 
cd /home/titan/twrp-12.1
```
# Start Compiling: 
```
. build/envsetup.sh
lunch twrp_samurai-eng
mka recoveryimage
```

# Short single block command step to start compiling:
```
source build/envsetup.sh && lunch twrp_samurai-eng && mka recoveryimage
 ```
 
# To test it (reboot to fastboot / bootloader):
```
fastboot flash recovery "/out/target/product/samurai/recovery.img"
```

## Some extra command for faster debugging build:

# Single Block Command-1:
```
cd device/realme/samurai
git clean -fdx
git pull --ff-only
```
# Single Block Command-2:
```
cd ~/twrp-12.1 && \
rm -rf out && \
mkdir -p out/.ccache/tmp && \
export CCACHE_DIR="$PWD/out/.ccache" && \
export CCACHE_TEMPDIR="$PWD/out/.ccache/tmp" && \
source build/envsetup.sh && \
lunch twrp_samurai-eng && \
mka recoveryimage
```

`Extra Note:` This tree keeps the OpenELA 4.14.357 `Image.gz-dtb` and matching
`dtbo.img` as pinned prebuilts. A successful build is not a substitute for
booting the recovery and testing decryption on an RMX1931.
