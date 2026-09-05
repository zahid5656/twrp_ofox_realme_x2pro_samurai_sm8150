# OrangeFox 12.1 tuning report

Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
Branch: `fox-12.1-staging-backup`
Pre-change HEAD: `4db6a0f3ea9a87eb0151648ffbc77e5065c8d137`

## Evidence

- User-verified baseline: this branch lineage is BOOT-VALIDATED.
- Current tuning policy: AOSP userdata is F2FS-primary while EXT4 remains supported as alternate.
- OrangeFox build environment explicitly pins Keymaster 4.0.

## Scope

- Restore `BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs`.
- Restore F2FS-first `/data` ordering in `recovery.fstab`.
- Keep EXT4 as alternate userdata filesystem.
- Restore `OF_DEFAULT_KEYMASTER_VERSION=4.0` and `OF_DISABLE_MIUI_SPECIFIC_FEATURES=1` in both build script and manual build guide.
- Keep `vendor.qti.hardware.vibrator.service` executable (`100755`).
- Update README to match the boot-proven F2FS-primary tuning baseline.

## Preserved

- `twrp.flags` unchanged.
- Kernel, DTBO, recovery blobs, crypto/Keymaster payload and AVB configuration unchanged.
- No workflow run, flash, wipe, branch deletion or unrelated source modification.

## Rollback

Reset `fox-12.1-staging-backup` to `4db6a0f3ea9a87eb0151648ffbc77e5065c8d137`.
