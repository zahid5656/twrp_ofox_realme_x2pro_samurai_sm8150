# TWRP Recovery Builder Report

## Status

SOURCE-VALIDATED

## Target

- Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
- Branch: `twrp-12.1-aosp`
- Audited HEAD: `8fd5fee11108a991a99fb009471d13dc7e6d0c21`
- Device: Realme X2 Pro / `samurai` / RMX1931 family
- Recovery manifest: TWRP AOSP `twrp-12.1`

## Failure evidence

Uploaded GitHub Actions run `91554814121` reached the build step and failed while parsing the device tree:

```text
device/realme/samurai/device.mk:7: error: missing separator.
```

The current `device.mk` contains an uncommented text line, `Apex libraries`, immediately before `PRODUCT_COPY_FILES`. Make treats that line as invalid syntax, so `lunch twrp_samurai-eng` cannot load the product configuration.

## Approved scope

1. Change only `Apex libraries` to `# Apex libraries` in `device.mk`.
2. Add a standalone workflow at `.github/workflows/TWRP_Recovery_Builder.yml`.
3. Keep `BoardConfig.mk`, kernel prebuilts, DTBO, fstab, recovery sources, and product definitions otherwise unchanged.
4. Build `recovery.img` from the repository's exact triggering commit against the TWRP AOSP `twrp-12.1` minimal manifest.
5. Fail immediately on build/configuration errors and verify that `recovery.img` exists and is non-empty.
6. Publish successful `recovery.img` plus its SHA-256 file to this repository's GitHub Releases section.

## Workflow safety

- Manual `workflow_dispatch` only; no automatic build is triggered by pushes.
- Release creation occurs only after a successful `recoveryimage` build and artifact verification.
- The device tree is fetched by exact `GITHUB_SHA`, preventing an unrelated moving branch tip from being built.
- `contents: write` is scoped to the workflow because GitHub Releases require tag/release creation.

## Validation boundary

This change is SOURCE-VALIDATED only. It is not BUILD-VALIDATED until the new workflow completes successfully, and it is not BOOT-VALIDATED until the produced `recovery.img` is tested on RMX1931 hardware.

## Rollback

Revert the commit that adds the workflow and comments the invalid `device.mk` line. No partition, kernel, DTBO, fstab, or recovery runtime configuration is changed by this task.
