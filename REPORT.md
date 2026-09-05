# OrangeFox 12.1 GitHub Actions build report

Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
Branch: `fox-12.1-staging-backup`
Pre-change HEAD: `ede373fc5c7da372417de960d95ff2878e8a3c46`
Canonical local/GCP build script: `build-orangefox-samurai.sh`
CI reference: `zahid5656/OrangeFox-Recovery-Builder-2024`, branch `OrangeFox`

## Result

The GitHub Actions workflow now follows the same OrangeFox build semantics as `build-orangefox-samurai.sh`. The external builder is used only for GitHub-runner support and release publishing where that does not conflict with the canonical script.

## Canonical build path preserved

- Sync OrangeFox 12.1 with `orangefox_sync.sh`.
- Clone `fox-12.1-staging-backup` into `device/realme/samurai`.
- Keep the required build environment:
  - `export FOX_BUILD_DEVICE=samurai`
  - `export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1`
  - `export OF_FORCE_PREBUILT_KERNEL=1`
  - `export OF_DEFAULT_KEYMASTER_VERSION=4.0`
  - `export OF_MAINTAINER="ETHICAL ∆ TITAN"`
  - `export FOX_MAINTAINER_PATCH_VERSION=1`
  - `source build/envsetup.sh`
  - `lunch twrp_samurai-eng`
- Keep the script-equivalent ccache directories.
- Build only with `mka recoveryimage`.
- Preserve build failure through the `tee` pipeline with `set -o pipefail`.

## GitHub free-runner additions

- Pin runner to Ubuntu 22.04 for the OrangeFox 12.1 build environment.
- Clean runner disk space using the reference builder action.
- Configure 24 GB swap.
- Install the OrangeFox Android build environment.
- Validate the synced OrangeFox source before building.
- Verify non-empty official outputs under `out/target/product/samurai`:
  - `OrangeFox*.img`
  - `OrangeFox*.zip`
  - `recovery.img`
- Publish those verified outputs directly to this repository's Releases section using the workflow run as a unique release tag.

## Removed conflicting/non-required builder behavior

- No `BUILD_TARGET` selection.
- No `make clean` or separate `mka adbd` build path.
- No boot/vendor_boot selection or image rename/copy logic.
- No `ALLOW_MISSING_DEPENDENCIES` override.
- No `DEVICE_NAME` input.
- No LDCheck step.
- No Samsung TAR handling.
- No recovery-installer mutation/download step.
- No Actions artifact dependency for downloading the final recovery outputs.

## Preserved source

`build-orangefox-samurai.sh`, BoardConfig, recovery fstab, `twrp.flags`, kernel, DTBO, crypto/Keymaster configuration and recovery blobs are unchanged.

## Validation

- Workflow/source configuration: `SOURCE-VALIDATED`.
- `BUILD-VALIDATED` requires a successful GitHub Actions run and successful Release publication of all verified outputs.
- No workflow run was triggered by this source update.

## Rollback

Reset `.github/workflows/TWRP_Recovery_Builder.yml` and `REPORT.md` to pre-change HEAD `ede373fc5c7da372417de960d95ff2878e8a3c46`.
