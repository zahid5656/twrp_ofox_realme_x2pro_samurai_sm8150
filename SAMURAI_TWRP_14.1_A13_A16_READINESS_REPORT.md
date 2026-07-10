# Realme X2 Pro TWRP 14.1 Android 13-16 Readiness Report

## Scope

Repository: `device/realme/samurai`

Goal: bring the existing TWRP 12.1-derived recovery tree closer to a clean TWRP 14.1 base that can decrypt Android 13, Android 14, Android 15, and Android 16 AOSP/LineageOS-based ROM data partitions, while keeping the tree suitable for later OrangeFox bring-up.

This pass audited every text configuration file in the repository. Proprietary ELF blobs, firmware, the prebuilt kernel, and `dtbo.img` were identified but not reverse engineered.

## Current State

- Active product: `twrp_samurai`
- Device path: `device/realme/samurai`
- Platform: `msmnile`
- Recovery kernel: prebuilt `Image.gz-dtb`
- DTBO: prebuilt `dtbo.img`
- Crypto stack: QCOM FBE metadata decrypt using `qcom_decrypt`, `qcom_decrypt_fbe`, keymaster 4.0, gatekeeper 1.0, and QSEECom blobs
- Current branch prepared for this pass: `twrp-14.1-a13-a16-decrypt-readiness`

## Changes Applied

### BoardConfig

- Declared `TARGET_RECOVERY_FSTAB` explicitly so TWRP 14.1 consumes `recovery/root/system/etc/recovery.fstab`.
- Removed the duplicate `BUILD_BROKEN_DUP_RULES` assignment from the platform section and kept it in the compatibility section.
- Removed the conflicting ext4 `BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE` assignment and kept f2fs as the default userdata image type while still allowing both ext4 and f2fs recovery mounts.
- Renamed the old `TWRP 12.1 requirements` comment to `TWRP 14.1 recovery-tree compatibility`.

### Recovery fstab

- Changed the system mount point from `/` to `/system_root` to match this system-as-root TWRP tree and the existing `twrp.flags` entry.
- Preserved both `/data` entries:
  - ext4 with metadata FBE v2 policy flags
  - f2fs with metadata FBE v2 policy flags, quota, formattable, UFS sysfs path, and checkpoint support

### TWRP flags

- Added an explicit metadata partition entry with display, wipe, and backup behavior.
- Replaced the old ext4-only `/data` entry with ext4 and f2fs `/data` entries.
- Aligned TWRP `/data` encryption flags with the Android recovery fstab:
  - `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized`
  - `keydirectory=/metadata/vold/metadata_encryption`
  - `quota`
  - `reservedsize=128M`

### Init scripts

- Removed duplicate OTG sysfs write in `init.recovery.qcom.rc`.
- Started the existing `variant-script` during recovery boot so RMX1931 global/CN property selection and timestamp reset logic actually runs.
- Removed invalid `g2` USB gadget mkdir commands from `init.recovery.usb.rc`; this recovery only creates and uses `g1`.

## Android 13-16 Decryption Readiness

Expected decryption path:

1. Recovery boots with the prebuilt samurai kernel and DTBO.
2. `/dev/block/bootdevice` symlink is created from `${ro.boot.bootdevice}`.
3. `/metadata` is mountable.
4. `/firmware` is mountable for decrypt-time firmware access.
5. QSEECom, keymaster, gatekeeper, RPMB, and QCOM crypto libraries are available from `recovery/root/system` and `recovery/root/vendor`.
6. TWRP sees both ext4 and f2fs `/data` candidates with metadata FBE keydirectory flags.
7. TWRP uses the metadata key path at `/metadata/vold/metadata_encryption`.

This is the correct local tree direction for Android 13-16 AOSP/LineageOS ROMs using metadata FBE v2 on this msmnile device. Final confirmation still requires a real TWRP 14.1 build and device-side tests against encrypted ROM installs.

## OrangeFox Readiness

The tree now keeps the critical partition, crypto, init, and fstab pieces in a shape OrangeFox can inherit later.

Before enabling OrangeFox-specific flags, validate:

- TWRP 14.1 recovery image builds successfully.
- Touch, brightness, MTP, ADB, USB-OTG, backup, restore, image flashing, and f2fs/ext4 format flows work.
- Android 13, 14, 15, and 16 encrypted `/data` mount and decrypt on-device.
- The OrangeFox source branch supports this exact TWRP 14.1 crypto stack and does not require additional `OF_*` flags for FBE metadata.

## Known Risks

- Full Android 13-16 decryption cannot be proven from the device tree alone. It depends on the updated OpenELA 4.14.356 kernel, inline crypto behavior, QSEE/keymaster/gatekeeper blobs, and the ROM encryption footer/metadata layout.
- The vendor and RealmeParts repositories were not present beside this checkout, so sysfs/API sync could not be verified locally.
- `vendor/etc/vintf/manifest.xml` includes broad stock HAL declarations and Xiaomi HAL declarations that are suspicious in a Realme recovery tree. They were left untouched in this pass because removing VINTF entries without a TWRP 14.1 build/test cycle can create unrelated service-manager regressions.
- The recovery still uses proprietary Android 10-era QCOM keymaster/gatekeeper/QSEE blobs. They may work for current FBE metadata, but Android 15/16 ROM testing is mandatory.
- `ALLOW_MISSING_DEPENDENCIES` and broken-build compatibility flags are still enabled. They are acceptable during migration but should be reduced after a clean TWRP 14.1 source build.

## Required Build Test

Use a clean TWRP 14.1 tree:

```sh
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
repo sync
git clone https://github.com/zahid5656/twrp_device_realme_RMX1931.git -b twrp-14.1-a13-a16-decrypt-readiness device/realme/samurai
. build/envsetup.sh
lunch twrp_samurai-eng
mka recoveryimage
```

Expected artifact:

```text
out/target/product/samurai/recovery.img
```

If the build system instead emits under `RMX1931`, check `PRODUCT_DEVICE`, `PRODUCT_BUILD_PROP_OVERRIDES`, and recovery output path handling before changing partition config.

## Required Device Test Matrix

- Boot recovery with `fastboot boot recovery.img`.
- Confirm ADB shell and MTP.
- Confirm `/metadata` mounts.
- Confirm `/firmware` mounts before decrypt.
- Confirm encrypted `/data` decrypts on Android 13.
- Confirm encrypted `/data` decrypts on Android 14.
- Confirm encrypted `/data` decrypts on Android 15.
- Confirm encrypted `/data` decrypts on Android 16.
- Test both ext4 and f2fs userdata if ROMs support both.
- Confirm backup and restore for boot, dtbo, modem, EFS, persist, vendor image, odm image, and system image.
- Confirm format data recreates a bootable encrypted userdata layout.

## Vendor/RealmeParts Sync Checklist

When the related repositories are available locally, verify:

- `proprietary_vendor_realme_samurai` init and ueventd files for `/metadata`, `/firmware`, keymaster, gatekeeper, QSEECom, and fingerprint nodes.
- RealmeParts sysfs paths for vibration, display, high brightness, touch, charging, thermal, and alert slider or device-specific controls if present.
- Fingerprint node ownership for `/dev/qbt1000` and any Goodix-specific sysfs/proc paths.
- SELinux labels and permissions for keymaster/gatekeeper/QSEE services.
- Whether current Android 15/16 ROMs use ext4 or f2fs userdata by default.

## Next Steps

1. Build this branch in a clean TWRP 14.1 source tree.
2. Fix any build failures without broad new warning suppression.
3. Boot the recovery image on-device.
4. Run the decryption matrix above.
5. After TWRP 14.1 is verified, add OrangeFox-specific flags in a separate commit.
