# OrangeFox 12.1 correction report

Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
Branch: `fox-12.1-staging-backup`
Pre-change HEAD: `39aa14078c32492c4d2fee3d263fdfbbd1694b4f`

## Scope

- Make EXT4 the primary `/data` filesystem while retaining F2FS alternate support.
- Remove the duplicate `BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE` assignment.
- Make `vendor.qti.hardware.vibrator.service` executable.
- Correct OrangeFox build documentation and branch/lunch references.
- Point the local build script at `fox-12.1-staging-backup`.
- Replace the stale TWRP 14.1 CI workflow with a manual OrangeFox 12.1 build workflow for this branch.

## Preserved

- `twrp.flags` unchanged.
- Kernel, DTBO and recovery blobs unchanged.
- Crypto/Keymaster configuration unchanged.
- No workflow run, flash, wipe, force-push or destructive deletion performed.
