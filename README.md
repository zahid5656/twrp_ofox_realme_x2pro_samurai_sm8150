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
git clone --depth=1 -b twrp-12.1L-staging https://github.com/zahid5656/twrp_device_realme_RMX1931.git device/realme/samurai
```
# Finally execute these:
```
cd device/realme/samurai 
export ALLOW_MISSING_DEPENDENCIES=true
cd /home/titan/twrp-12.1L-staging
```
# Start Compiling: 
```
. build/envsetup.sh
lunch twrp_samurai-eng
mka recoveryimage
```

# Short single block command step to start compiling:
```
export ALLOW_MISSING_DEPENDENCIES=true && source build/envsetup.sh && lunch twrp_samurai-eng && mka recoveryimage
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
export ALLOW_MISSING_DEPENDENCIES=true && \
source build/envsetup.sh && \
lunch twrp_samurai-eng && \
mka recoveryimage
```

`Extra Note:` The build wrapper verifies the binary structure of the
OpenELA 4.14.357 `Image.gz-dtb` and its matching two-entry `dtbo.img` before
starting the Android build. It applies the included, idempotent TWRP 14.1
source-compatibility patch set. After the build it unpacks `recovery.img`,
checks the partition-size limit and ramdisk integrity, and requires the
embedded kernel and recovery DTBO to match the pinned prebuilts byte-for-byte.
A successful build is not a substitute for booting the recovery and testing
decryption on an RMX1931.

# OrangeFox Build:

```bash
repo init --depth=1 -u https://gitlab.com/OrangeFox/manifest.git -b fox_12.1
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

# OR Script:
```
chmod +x build-orangefox-samurai.sh
./build-orangefox-samurai.sh
```

# OR Manual:
```
OrangeFox_recovery_build_manual.md
```