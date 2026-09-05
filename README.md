# OrangeFox 12.1 — Realme X2 Pro (samurai)

Device tree for Realme X2 Pro RMX1931 / RMX1931L1 / RMX1931CN, unified as `samurai`.

## Target profile

- Platform: Qualcomm SM8150 / msmnile
- Partition layout: A-only / non-A/B
- Dedicated recovery partition
- Prebuilt kernel: `prebuilt/Image.gz-dtb`
- Prebuilt DTBO: `prebuilt/dtbo.img`
- Boot image header: v1
- Userdata support: F2FS primary + EXT4 alternate
- QCOM FBE / metadata encryption support enabled
- Keymaster default: 4.0

## OrangeFox 12.1 build

Use the branch-specific build script:

```bash
chmod +x build-orangefox-samurai.sh
./build-orangefox-samurai.sh
```

Or follow:

```text
OrangeFox_recovery_build_manual.md
```

The declared lunch target is:

```bash
lunch twrp_samurai-eng
```

## Validation status

This branch is user-verified BOOT-VALIDATED. Current edits are tuning-only and must preserve that known-good boot baseline.

Further tuning validation should re-check decryption, userdata handling, MTP, USB OTG, haptics, backup/restore and flashing after each change.
