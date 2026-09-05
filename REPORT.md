# OrangeFox 12.1 in-tree workflow report

Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
Branch: `fox-12.1-staging-backup`
Pre-change HEAD: `848d1d7dd29d4310812c9f44d0aaa52b853ffa23`
Reference builder workflow: `zahid5656/OrangeFox-Recovery-Builder-2024`, branch `OrangeFox`, `.github/workflows/OrangeFox-Recovery-Builder.yml`

## Scope

- Port the external OrangeFox builder's core build system into this branch's own GitHub Actions workflow.
- Keep a 24 GB swap configuration.
- Sync OrangeFox 12.1 using `orangefox_sync.sh`.
- Clone `fox-12.1-staging-backup` into `device/realme/samurai`.
- Keep the requested build environment exactly:
  - `export FOX_BUILD_DEVICE=samurai`
  - `export OF_FORCE_PREBUILT_KERNEL=1`
  - `export OF_MAINTAINER="ETHICAL ∆ TITAN"`
  - `export FOX_MAINTAINER_PATCH_VERSION=1`
  - `source build/envsetup.sh`
  - `lunch twrp_samurai-eng`
- Keep `ALLOW_MISSING_DEPENDENCIES=true` as in the external builder flow.
- Build with `make clean` followed by `mka adbd recoveryimage`.
- Fail the workflow if no non-empty recovery image is produced, then upload the produced OrangeFox artifacts.

## Preserved

- Device source, BoardConfig, recovery fstab, `twrp.flags`, kernel, DTBO, crypto/Keymaster configuration and recovery blobs are unchanged.
- No release creation, recovery-installer download, tar packaging or builder-repository-specific LDCheck step is included.
- No workflow run is performed by this source update.

## Validation

- Workflow/source configuration: SOURCE-VALIDATED.
- BUILD-VALIDATED requires a successful GitHub Actions run and a non-empty generated recovery image.

## Rollback

Reset `fox-12.1-staging-backup` to `848d1d7dd29d4310812c9f44d0aaa52b853ffa23`.
