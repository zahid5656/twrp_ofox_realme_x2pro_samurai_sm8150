TWRP Device configuration for realme X2 Pro (samurai)

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

## Compile

First checkout minimal twrp source:

```
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
repo sync
git clone https://github.com/zahid5656/twrp_device_realme_RMX1931.git -b twrp-14.1-a13-a16-decrypt-readiness device/realme/samurai

```

Finally execute these:

```
. build/envsetup.sh
lunch twrp_samurai-ap2a-eng
mka recoveryimage

```

To test it:

```
fastboot boot out/target/product/samurai/recovery.img
```

The build wrapper verifies the SHA-256 checksums and binary structure of the
OpenELA 4.14.357 `Image.gz-dtb` and its matching two-entry `dtbo.img` before
starting the Android build. It applies the included, idempotent TWRP 14.1
source-compatibility patch set. After the build it unpacks `recovery.img`,
checks the partition-size limit and ramdisk integrity, and requires the
embedded kernel and recovery DTBO to match the pinned prebuilts byte-for-byte.
A successful build is not a substitute for booting the recovery and testing
decryption on an RMX1931.
