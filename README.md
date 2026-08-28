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
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync
https://github.com/zahid5656/twrp_device_realme_RMX1931.git -b twrp-12.1 device/realme/samurai

```

Finally execute these:

```
. build/envsetup.sh
lunch twrp_samurai-eng
mka recoveryimage

```

To test it:

```
fastboot boot out/target/product/RMX1931/recovery.img
```
