# OrangeFox 12.1 GitHub Actions sync failure report

Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
Branch: `fox-12.1-staging-backup`
Pre-change HEAD: `dfdf62ebbab3b8b29dc107507abb18b03af275b6`
Canonical local/GCP build script: `build-orangefox-samurai.sh`
CI reference: `zahid5656/OrangeFox-Recovery-Builder-2024`, branch `OrangeFox`

## Result

The failed GitHub Actions run stopped during OrangeFox source sync before device-tree clone or compilation. The failure was not caused by `FOX_MAINTAINER_PATCH_VERSION`.

Observed failure:

`I cannot find the patch file: .../patches/patch-manifest-fox_12.1.diff`

## Root cause

The workflow cloned `https://gitlab.com/OrangeFox/sync.git` into `$FOX_SYNC_ROOT/sync` but invoked `orangefox_sync.sh` by absolute path while the shell remained in the GitHub workspace root. The sync script resolves its `patches/` files from its current working directory, so it searched the wrong path.

The canonical local/GCP script and the OrangeFox-Recovery-Builder-2024 reference both enter the cloned `sync` directory before running `./orangefox_sync.sh`.

## Exact fix

Change only the sync invocation to:

```bash
cd "$FOX_SYNC_ROOT/sync"
./orangefox_sync.sh \
  --branch 12.1 \
  --path "$FOX_ROOT"
```

## Preserved

- `export FOX_BUILD_DEVICE=samurai`
- `export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1`
- `export OF_FORCE_PREBUILT_KERNEL=1`
- `export OF_DEFAULT_KEYMASTER_VERSION=4.0`
- `export OF_MAINTAINER="ETHICAL ∆ TITAN"`
- `export FOX_MAINTAINER_PATCH_VERSION=1`
- `source build/envsetup.sh`
- `lunch twrp_samurai-eng`
- `mka recoveryimage`
- 24 GB swap, output verification, and direct GitHub Release publication remain unchanged.
- `build-orangefox-samurai.sh`, BoardConfig, fstab, kernel, DTBO, crypto/Keymaster and recovery source are unchanged.

## Validation

- Root-cause and workflow correction: `SOURCE-VALIDATED`.
- `BUILD-VALIDATED` requires a new successful GitHub Actions run and Release publication of the verified outputs.
- No workflow run is triggered by this source update.

## Rollback

Reset `REPORT.md` and `.github/workflows/TWRP_Recovery_Builder.yml` to pre-change HEAD `dfdf62ebbab3b8b29dc107507abb18b03af275b6`.
