# TWRP Recovery Builder Report

## Status

SOURCE-VALIDATED

## Target

- Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
- Branch: `twrp-12.1-aosp`
- Device: Realme X2 Pro / `samurai` / RMX1931 family
- Recovery manifest: TWRP AOSP `twrp-12.1`
- Workflow: `.github/workflows/TWRP_Recovery_Builder.yml`
- Pre-fix branch HEAD: `40bc20a0bf0322d4d25fd5c8e41030501030c8b8`

## Failure history

### 1. Device makefile parser failure

The original external builder run `91554814121` failed before compilation:

```text
device/realme/samurai/device.mk:7: error: missing separator.
```

The invalid text line `Apex libraries` was corrected to `# Apex libraries`. No BoardConfig, kernel, DTBO, fstab, partition, or recovery runtime configuration was changed for that fix.

### 2. GitHub-hosted runner disk exhaustion

Standalone workflow run `33786099130` / job `100751149647` failed during `repo sync` with:

```text
System.IO.IOException: No space left on device
```

That was a runner-capacity failure, not a Samurai compile failure.

### 3. Private repository checkout failure

Workflow run `33788916143` / job `100760450278` used the disk-cleanup revision and made significantly more progress:

```text
before cleanup: 73G total, 59G used, 14G free
after cleanup:  73G total, 28G used, 45G free
repo sync:      completed successfully
post-sync:      11G free
workspace:      34G
.repo:          8.2G
```

The build still did not reach `lunch` or `mka`. It failed in the device-tree fetch step because the workflow attempted an anonymous HTTPS fetch from this private repository:

```text
git -C device/realme/samurai fetch --depth=1 origin <GITHUB_SHA>
fatal: could not read Username for 'https://github.com': No such device or address
```

Root cause: the workflow had `contents: write` and a valid `GITHUB_TOKEN`, but the manual `git fetch https://github.com/${GITHUB_REPOSITORY}.git` did not use that token.

## Corrected workflow design

The workflow is changed to use GitHub's native authenticated checkout for the private Samurai repository:

- `actions/checkout@v7`
- exact triggering `github.sha`
- `fetch-depth: 1`
- `persist-credentials: false`
- checkout goes to `$GITHUB_WORKSPACE/device-tree`
- after TWRP sync, files are copied into `device/realme/samurai` with `.git` excluded
- the checked-out commit is verified against `GITHUB_SHA`

No username, email, password, PAT, or embedded credential is required. The repository-scoped `GITHUB_TOKEN` is the correct credential for this workflow.

## Hosted-runner disk policy

The workflow removes only disposable/preinstalled GitHub-hosted-runner software and caches that the recovery build does not need. It does not delete GitHub repositories, remote branches, device source files, kernel prebuilts, DTBO, BoardConfig, fstab, or repository history.

Known disposable runner content includes:

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
- apt download/list caches

Slow recursive size scans were removed from the hot path. `df -hT`, RAM, and swap state remain as evidence.

## Swap and disk headroom

Run `33788916143` showed that `/mnt` and `$GITHUB_WORKSPACE` are both backed by `/dev/root`, so moving the build to `/mnt` does not create additional capacity on that runner image.

The workflow therefore:

1. uses a genuinely separate `/mnt` filesystem only if a future runner actually provides one;
2. attempts a 4 GiB zram swap device;
3. only after zram is successfully active, disables and removes GitHub's default `/swapfile` to reclaim its disk space;
4. keeps the default disk swap untouched if zram cannot be enabled.

This avoids trading build disk capacity for swap without a working replacement.

## Build cache

Compiler cache remains enabled for repeat-build speed, but its disk footprint is bounded aggressively because the TWRP source tree leaves limited headroom:

- `actions/cache@v6`
- compressed ccache
- maximum ccache size: 1 GiB
- cache restored after source synchronization, not before it
- cache keyed by OS, TWRP 12.1, Samurai, and exact workflow commit

This prevents a large restored ccache from causing `repo sync` to fail for lack of disk space.

## Source synchronization

The successful run proves the current lean sync settings are viable on the hosted runner:

- `--depth=1`
- partial clone
- `blob:limit=10M`
- current branch only (`-c`)
- no tags
- no clone bundles
- optimized fetch
- prune
- fail fast
- `repo sync -j4`

The source synchronization stage is therefore preserved instead of being rewritten again.

## Action runtime versions

- Preserve the user's current `actions/setup-java@v5` update.
- Use `actions/checkout@v7` for authenticated private checkout.
- Upgrade compiler cache handling from `actions/cache@v4` to `actions/cache@v6` to avoid the Node 20 deprecation path seen in the failed run.

## Build and release contract

The workflow validates the exact Samurai device tree and then executes:

```text
lunch twrp_samurai-eng
mka recoveryimage -j$(nproc --all)
```

A GitHub Release is created only when `out/target/product/samurai/recovery.img` exists and is non-empty. A successful release contains:

- `recovery.img`
- `recovery.img.sha256`

## Validation boundary

This workflow fix is SOURCE-VALIDATED only.

- `BUILD-VALIDATED`: requires a successful workflow run producing `recovery.img`.
- `BOOT-VALIDATED`: requires testing that exact `recovery.img` on RMX1931 hardware.

No workflow run is triggered by this report/source update itself.
