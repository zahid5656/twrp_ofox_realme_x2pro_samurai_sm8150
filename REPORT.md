# TWRP Recovery Builder Report

## Status

SOURCE-VALIDATED

## Target

- Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
- Branch: `twrp-12.1-aosp`
- Device: Realme X2 Pro / `samurai` / RMX1931 family
- Recovery manifest: TWRP AOSP `twrp-12.1`
- Workflow: `.github/workflows/TWRP_Recovery_Builder.yml`

## Source parser failure fixed

The original external builder run `91554814121` failed while parsing the device tree:

```text
device/realme/samurai/device.mk:7: error: missing separator.
```

The invalid line `Apex libraries` was changed only to `# Apex libraries`. No BoardConfig, kernel, DTBO, fstab, partition, or recovery runtime configuration was changed for that fix.

## Hosted-runner disk failure

Standalone workflow run `33786099130` / job `100751149647` failed during `Sync TWRP source`, before the device tree build stage. The runner itself exhausted its filesystem and even the GitHub runner diagnostic log could no longer be written:

```text
System.IO.IOException: No space left on device
/home/runner/actions-runner/cached/2.337.0/_diag/Worker_20260903-174212-utc.log
```

This is a build-environment capacity failure, not evidence of a Samurai source compile failure.

## Runner cleanup policy

The workflow now prints filesystem and memory/swap state before cleanup and again after cleanup/sync/build. It removes only disposable/preinstalled GitHub-hosted-runner software and caches that this Android recovery build does not use:

- `/usr/local/lib/android`
- `/opt/hostedtoolcache/*`
- `/usr/share/dotnet`
- `/opt/ghc`
- `/usr/local/.ghcup`
- `/usr/share/swift`
- `/usr/local/share/boost`
- `/usr/local/share/chromium`
- `/opt/microsoft`
- `/opt/az`
- Docker/containerd image and layer state
- `/home/runner/.cache/*`
- apt package/list caches

The workflow explicitly does not delete `$GITHUB_WORKSPACE`, Android/TWRP source repositories, `.repo`, device sources, Git refs/branches, kernel prebuilts, DTBO, BoardConfig, fstab, or repository history.

No repository or branch deletion is part of this workflow.

## Disk-aware build placement and swap

The workflow compares the free space and backing filesystem for `$GITHUB_WORKSPACE` and `/mnt`.

- If `/mnt` is a distinct filesystem and has more free space, the TWRP workspace is placed there.
- Otherwise the normal GitHub workspace filesystem is used.
- Swap never blindly consumes the same filesystem that holds the Android source tree.
- Existing swap is reused when available.
- Compressed zram swap is attempted first because it consumes no filesystem capacity.
- A 4 GiB `/mnt` swap file is only used as a fallback when `/mnt` is a separate filesystem with more than 40 GiB free.

## Build-time cache

The workflow uses GitHub Actions `actions/cache@v4` for a compressed ccache directory:

- cache directory: `/home/runner/.ccache`
- maximum ccache size: 4 GiB
- compression enabled, level 6
- cache keyed by OS, TWRP 12.1, Samurai, and device-tree commit
- older compatible Samurai/TWRP ccache entries may be restored using the prefix key

This accelerates repeat compilation without caching the complete Android source tree.

## Source synchronization

The TWRP sync is configured to reduce network, object, and temporary pack pressure:

- shallow history (`--depth=1`)
- partial clone
- `blob:limit=10M` clone filter
- current branch only during sync (`-c`)
- no tags
- no clone bundles
- optimized fetch
- prune stale project refs
- fail fast
- `repo sync -j4` to avoid excessive simultaneous Git pack expansion

The exact triggering repository commit is still fetched into `device/realme/samurai` before build.

## Build and release contract

The workflow validates the Samurai product files, then executes:

```text
lunch twrp_samurai-eng
mka recoveryimage -j$(nproc --all)
```

A release is created only if `out/target/product/samurai/recovery.img` exists and is non-empty. Successful releases contain:

- `recovery.img`
- `recovery.img.sha256`

## Validation boundary

The updated workflow is SOURCE-VALIDATED only.

- `BUILD-VALIDATED`: requires a successful workflow build producing `recovery.img`.
- `BOOT-VALIDATED`: requires testing that exact `recovery.img` on RMX1931 hardware.

The workflow has not been re-run as part of this source update.
