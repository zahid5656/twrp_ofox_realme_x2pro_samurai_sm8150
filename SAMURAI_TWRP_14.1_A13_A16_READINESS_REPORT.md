# Realme X2 Pro TWRP 14.1 Android 13-16 Readiness Report

## Scope

Repository: `device/realme/samurai`

Goal: bring the existing TWRP 12.1-derived recovery tree closer to a clean TWRP 14.1 base that can decrypt Android 13, Android 14, Android 15, and Android 16 AOSP/LineageOS-based ROM data partitions, while keeping the tree suitable for later OrangeFox bring-up.

This pass audited every text configuration file in the repository. Proprietary ELF blobs, firmware, the prebuilt kernel, and `dtbo.img` were identified but not reverse engineered.

## Current State

- Active product: `twrp_samurai`
- Device path: `device/realme/samurai`
- Platform: `msmnile`
- Recovery kernel: OpenELA 4.14.357 prebuilt `Image.gz-dtb` from the
  `openela-357-lineage-23.0-ksunext-susfs` Samurai kernel branch
- DTBO: matching QCOM SM8150 two-entry prebuilt `dtbo.img`
- Crypto stack: QCOM FBE metadata decrypt using `qcom_decrypt`, `qcom_decrypt_fbe`, keymaster 4.0, gatekeeper 1.0, and QSEECom blobs
- Current branch prepared for this pass: `twrp-14.1-a13-a16-decrypt-readiness`

## Changes Applied

### BoardConfig

- Declared `TARGET_RECOVERY_FSTAB` explicitly so TWRP 14.1 consumes `recovery/root/system/etc/recovery.fstab`.
- Removed the duplicate `BUILD_BROKEN_DUP_RULES` assignment from the platform section and kept it in the compatibility section.
- Removed the conflicting ext4 `BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE` assignment and kept f2fs as the default userdata image type while still allowing both ext4 and f2fs recovery mounts.
- Renamed the old `TWRP 12.1 requirements` comment to `TWRP 14.1 recovery-tree compatibility`.
- Removed obsolete `BOARD_BUILD_SYSTEM_ROOT_IMAGE` and deprecated
  `TARGET_USES_64_BIT_BINDER`; Android 14 uses system-as-root and 64-bit Binder
  by default.
- Added an idempotent TWRP 14.1 source compatibility patch for the recovery and
  libtar dependencies. Android 14 generates the `*-ndk` AIDL modules but not
  the obsolete `*-ndk_platform` aliases referenced by the current TeamWin
  `android-14.1` recovery branch.
- Added a second compatibility patch for Android 14's `fscrypt_policy` UAPI,
  which is a struct-tag macro rather than the typedef expected by TeamWin's
  libtar header and allocation sites.
- Restored the v1-only libtar policy accessors removed from Android 14 vold and
  aligned `lookup_ref_tar()` with its current descriptor-based signature. The
  scope is intentionally v1 because this device tree sets
  `TW_USE_FSCRYPT_POLICY := 1` for the existing Samurai encryption format.
- Added the Android 14 vold link dependencies that do not propagate through its
  static library: boot-control, netlink (`libsysutils`), and async-safe logging.
- Excluded TeamWin's removed legacy FDE `cryptfs_*` fallback only when
  `TW_INCLUDE_FBE` is enabled. Samurai remains on its metadata-FBE path; no
  placeholder cryptfs functions or fake-success stubs were added.
- Replaced the removed `delete_crypto_blk_dev()` call in the metadata-FBE
  format-data path with the current `libdm` `DeleteDeviceIfExists()` API, so
  the active `userdata` mapping is torn down before the physical partition is
  formatted.
- Declared `task_profiles.json` as a direct dependency of TeamWin's ramdisk
  module, preventing Ninja from racing the ramdisk copy before the Android 14
  prebuilt is installed.
- Declared Android 14 vold's non-propagating async-safe, boot-AIDL, and netlink
  libraries on the recovery executable as well as libtar, resolving the final
  static-vold link dependencies without broad link flags.

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

This is the correct local tree direction for Android 13-16 AOSP/LineageOS ROMs using metadata FBE v2 on this msmnile device. The TWRP 14.1 image now builds successfully; final compatibility confirmation still requires device-side tests against encrypted ROM installs.

## OrangeFox Readiness

The tree now keeps the critical partition, crypto, init, and fstab pieces in a shape OrangeFox can inherit later.

Before enabling OrangeFox-specific flags, validate:

- TWRP 14.1 recovery image builds successfully. Completed.
- Touch, brightness, MTP, ADB, USB-OTG, backup, restore, image flashing, and f2fs/ext4 format flows work.
- Android 13, 14, 15, and 16 encrypted `/data` mount and decrypt on-device.
- The OrangeFox source branch supports this exact TWRP 14.1 crypto stack and does not require additional `OF_*` flags for FBE metadata.

## Known Risks

- Full Android 13-16 decryption cannot be proven from the device tree alone. It depends on the updated OpenELA 4.14.357 kernel, inline crypto behavior, QSEE/keymaster/gatekeeper blobs, and the ROM encryption footer/metadata layout.
- The vendor and RealmeParts repositories were not present beside this checkout, so sysfs/API sync could not be verified locally.
- `vendor/etc/vintf/manifest.xml` includes broad stock HAL declarations and Xiaomi HAL declarations that are suspicious in a Realme recovery tree. They were left untouched in this pass because removing VINTF entries without a TWRP 14.1 build/test cycle can create unrelated service-manager regressions.
- The recovery still uses proprietary Android 10-era QCOM keymaster/gatekeeper/QSEE blobs. They may work for current FBE metadata, but Android 15/16 ROM testing is mandatory.
- `ALLOW_MISSING_DEPENDENCIES` and broken-build compatibility flags are still enabled. They are acceptable during migration but should be reduced after a clean TWRP 14.1 source build.

## Completed Build Test

### Pinned prebuilt set

- `Image.gz-dtb`: 20,157,238 bytes,
  SHA-256 `45e5ea4fc32962c208a27e310307c56bf6ceb7469b4866b0760f270c2a5d294f`
- Appended base DTB: `sm8150-v2.dtb`, 503,410 bytes
- `dtbo.img`: 494,691 bytes,
  SHA-256 `a290198e41bc6911b7d256a0cd4f674584f76999a74b8b627bb9d3ee0f721fa0`
- DTBO header: Android DT table magic `d7b7ab1e`, 2 entries, 4096-byte page

The device-tree inputs were restored byte-for-byte from the known-booted
Lineage 23 Samurai baseline before the clean kernel build. The TWRP build
wrapper validates `prebuilt/SHA256SUMS`, the gzip stream, the appended FDT
header and size, and the complete DTBO header before it enters the Android
build system.

The produced `recovery.img` was unpacked with Android's
`unpack_bootimg.py`. Its extracted kernel and recovery DTBO match the pinned
files byte-for-byte. The header is version 1, the ramdisk passes gzip integrity,
and the 83,886,080-byte image fits the configured 83,886,080-byte recovery
partition. The recovery image SHA-256 is
`08dfb88cbb70b89db41821be1a48c9415ee1db4755e377c3b34bf4c8e8c1a090`.

This proves a successful TWRP 14.1 source build and matched Samurai payloads.
It does not yet prove recovery boot or Android 13-16 decryption on physical
hardware.

Use a clean TWRP 14.1 tree:

```sh
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
repo sync
git clone https://github.com/zahid5656/twrp_device_realme_RMX1931.git -b twrp-14.1-a13-a16-decrypt-readiness device/realme/samurai
. build/envsetup.sh
lunch twrp_samurai-ap2a-eng
mka recoveryimage
```

Built artifact:

```text
dist/twrp-14.1-samurai-recovery.img
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

1. Boot the recovery image temporarily on-device with `fastboot boot`.
2. Run the decryption matrix above.
3. After TWRP 14.1 is verified, add OrangeFox-specific flags in a separate commit.
