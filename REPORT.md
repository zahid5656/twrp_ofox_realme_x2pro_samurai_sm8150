# TWRP Recovery Builder Report

## Status

SOURCE-VALIDATED

## Target

- Repository: `zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150`
- Branch: `twrp-12.1-aosp`
- Device: Realme X2 Pro / `samurai` / RMX1931 family
- Recovery manifest: TWRP AOSP `twrp-12.1`
- Workflow: `.github/workflows/TWRP_Recovery_Builder.yml`
- Audited pre-fix HEAD: `a903161e1e665c5852d4cae160eff538b195ff35`

## Failure history

### 1. Device makefile parser failure

The original external builder run `91554814121` failed before compilation:

```text
device/realme/samurai/device.mk:7: error: missing separator.
```

The invalid text line `Apex libraries` was corrected to `# Apex libraries`.

### 2. GitHub-hosted runner disk exhaustion

Standalone workflow run `33786099130` / job `100751149647` failed during `repo sync` with `No space left on device`.

The cleanup policy was then changed to remove only disposable GitHub-hosted-runner software. A later run proved that this changes the runner from roughly 14 GiB free to roughly 44-45 GiB free before source synchronization.

### 3. Private repository checkout failure

Run `33788916143` / job `100760450278` completed TWRP source sync but failed because the workflow attempted an anonymous HTTPS fetch from this private repository.

That was corrected by using authenticated `actions/checkout` with the job-scoped `GITHUB_TOKEN` and exact `github.sha`.

### 4. Android envsetup / nounset failure

Run `33792416438` / job `100771931484` successfully completed all of the following:

- private Samurai checkout;
- runner cleanup;
- dependency installation;
- TWRP 12.1 `repo init`;
- TWRP 12.1 `repo sync`;
- exact Samurai device-tree installation;
- Samurai prebuilt kernel and DTBO validation.

It then failed immediately while sourcing Android/TWRP `build/envsetup.sh`:

```text
build/envsetup.sh: line 877: TOP: unbound variable
build/envsetup.sh: line 388: ZSH_VERSION: unbound variable
```

Root cause: the workflow executed the build step with `set -u` (`nounset`). Android's `envsetup.sh` intentionally references shell variables that may be unset. This is a CI-shell bug, not a Samurai source compile failure.

Fix: use `set -eo pipefail` for the Android build shell and do not enable `nounset` while sourcing/running Android build functions.

## Runner cleanup and swap correction

Run `33792416438` also exposed this non-fatal workflow bug:

```text
swapon: option '--output-all' doesn't allow an argument
```

The workflow no longer depends on that `swapon --output=NAME` form. Swap presence is checked through `/proc/swaps`, which is stable on the Ubuntu runner.

The cleanup step continues to remove only disposable/preinstalled hosted-runner content. It explicitly does not remove `$GITHUB_WORKSPACE`, the TWRP workspace, `.repo`, device sources, Git history/branches, kernel prebuilts, DTBO, BoardConfig, or fstab.

If zram cannot be created, GitHub's existing disk-backed `/swapfile` is preserved. The swapfile is removed only if zram is actually active first.

## Persistent TWRP source strategy

A GitHub-hosted runner is an ephemeral VM. Files on its local filesystem do not survive after a job finishes, regardless of whether the workflow deletes them. Therefore a locally synced 34 GiB TWRP workspace cannot simply be "kept" on the next hosted runner.

Run `33788916143` measured approximately:

```text
TWRP workspace: ~34 GiB total
.repo:          ~8.2 GiB
```

The correct free-tier-oriented persistence strategy is to cache only the expensive `.repo` Git object database instead of the full working tree.

The workflow now uses `actions/cache/restore@v6` and `actions/cache/save@v6` for:

```text
$GITHUB_WORKSPACE/workspace/.repo
```

Design:

1. Restore a fixed TWRP 12.1 source seed cache before `repo init`.
2. Always run `repo init` and `repo sync` so the restored source metadata is verified and brought current.
3. On the first cache miss, save `.repo` immediately after a successful sync, even if a later compile fails.
4. On cache hits, do not create another multi-gigabyte source cache entry.
5. Never delete `.repo` in the workflow.

The static seed cache is intentionally immutable. It provides a known TWRP 12.1 object base; subsequent runs fetch only upstream deltas during `repo sync`. The cache version can be bumped deliberately if a new seed is ever required.

GitHub's current default repository Actions-cache storage limit is 10 GiB. Because `.repo` is already about 8.2 GiB, the compiler cache is restricted to 512 MiB and uses a single static seed key to avoid cache thrashing.

The full ~34 GiB TWRP workspace is not cached because it would exceed the default cache budget and would create large restore/save overhead.

## Source synchronization

The already proven sync settings are preserved:

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

With a restored `.repo` cache, this remains a correctness check/update operation rather than a full network download on every run.

## Private repository handling

The Samurai repository is checked out with `actions/checkout@v7` at exact `github.sha`, with `persist-credentials: false`. No username, email, password, PAT, or embedded credential is required.

The checked-out SHA is verified before the device-tree files are copied into `device/realme/samurai`.

## Build cache

Compiler caching remains enabled but bounded to 512 MiB to preserve build disk headroom and stay below the repository cache budget alongside the ~8.2 GiB TWRP source seed.

The ccache cache uses a static seed key rather than generating a new large cache for every commit.

## Build and release contract

The workflow validates the Samurai inputs, then executes Android build functions with nounset disabled:

```text
source build/envsetup.sh
lunch twrp_samurai-eng
mka recoveryimage -j$(nproc --all)
```

A GitHub Release is created only when `out/target/product/samurai/recovery.img` exists and is non-empty. Successful releases contain:

- `recovery.img`
- `recovery.img.sha256`

## Validation boundary

This update is SOURCE-VALIDATED only.

- `BUILD-VALIDATED`: requires a successful workflow run producing `recovery.img`.
- `BOOT-VALIDATED`: requires testing that exact `recovery.img` on RMX1931 hardware.

No repository or branch deletion is part of this workflow. No workflow run is triggered by this source update itself.
