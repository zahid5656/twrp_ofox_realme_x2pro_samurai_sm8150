# OrangeFox 12.1 in-tree workflow report

Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
Branch: `fox-12.1-staging-backup`
Pre-change HEAD: `106ba4bc2702c2ce5e625eb45dfa0fdb3e0fe053`
Reference builder workflow: `zahid5656/OrangeFox-Recovery-Builder-2024`, branch `OrangeFox`, `.github/workflows/OrangeFox-Recovery-Builder.yml`

## Scope

- Restore the external OrangeFox-Recovery-Builder-2024 workflow structure in-tree instead of the previously simplified workflow.
- Keep 24 GB swap.
- Keep OrangeFox Android build-environment setup and `orangefox_sync.sh --branch 12.1` source sync.
- Default the device tree to this repository and `fox-12.1-staging-backup` at `device/realme/samurai`.
- Keep the requested Samurai build environment:
  - `export FOX_BUILD_DEVICE=samurai`
  - `export OF_FORCE_PREBUILT_KERNEL=1`
  - `export OF_DEFAULT_KEYMASTER_VERSION=4.0`
  - `export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1`
  - `export OF_MAINTAINER="ETHICAL ∆ TITAN"`
  - `export FOX_MAINTAINER_PATCH_VERSION=1`
  - `source build/envsetup.sh`
  - `lunch twrp_samurai-eng`
- Keep `ALLOW_MISSING_DEPENDENCIES=true`, `make clean`, and `mka adbd recoveryimage` for OrangeFox 12.1.
- Keep recovery output detection, rename/release metadata, optional recovery-installer handling, GitHub Release publishing, ramdisk-recovery release handling, and an Actions artifact upload.
- Remove `DEVICE_NAME` workflow input and hardcode `samurai` where the reference builder used that input.
- Remove the `LDCHECK` input and the entire LDCheck step.
- Remove the `RECOVERY_TAR` input and all Samsung TAR creation/release references.

## Preserved

- Device source, BoardConfig, recovery fstab, `twrp.flags`, kernel, DTBO, crypto/Keymaster configuration and recovery blobs are unchanged.
- No workflow run is performed by this source update.

## Validation

- Workflow/source configuration can only be SOURCE-VALIDATED by this write.
- BUILD-VALIDATED requires a successful GitHub Actions run and a non-empty generated recovery image.

## Rollback

Reset `.github/workflows/TWRP_Recovery_Builder.yml` and `REPORT.md` to pre-change HEAD `106ba4bc2702c2ce5e625eb45dfa0fdb3e0fe053`.
