# Samurai TWRP 14.1 Build Report

## Result

- Status: PASS
- Build target: `twrp_samurai-ap2a-eng`
- Source manifest: minimal TeamWin AOSP `twrp-14.1`
- Builder: Google Compute Engine `n2-standard-16`, 16 vCPU, 64 GB RAM
- Output: `dist/twrp-14.1-samurai-recovery.img`
- Output size: 83,886,080 bytes (exactly the configured recovery partition size)
- Output SHA-256:
  `08dfb88cbb70b89db41821be1a48c9415ee1db4755e377c3b34bf4c8e8c1a090`

## Recovery Image Verification

Android's `unpack_bootimg.py` successfully unpacked the produced image:

- Boot magic: `ANDROID!`
- Boot image header: version 1
- Page size: 4096
- Kernel size: 20,157,238 bytes
- Ramdisk size: 27,274,552 bytes; gzip integrity PASS
- Embedded recovery DTBO size: 494,691 bytes
- Image size check: 83,886,080 / 83,886,080 bytes, PASS

The extracted kernel matched `prebuilt/Image.gz-dtb` byte-for-byte:

```text
45e5ea4fc32962c208a27e310307c56bf6ceb7469b4866b0760f270c2a5d294f
```

The extracted recovery DTBO matched `prebuilt/dtbo.img` byte-for-byte:

```text
a290198e41bc6911b7d256a0cd4f674584f76999a74b8b627bb9d3ee0f721fa0
```

The build wrapper now performs these checks automatically after every
successful `recoveryimage` build and fails if either embedded payload differs
from the pinned Samurai prebuilt set.

## Android 14 Source Compatibility

Eight small, idempotent patches are applied by `build.sh` to the TeamWin
`android-14.1` recovery checkout. They:

1. use current Android 14 AIDL NDK module names;
2. align libtar with Android 14's fscrypt policy struct;
3. restore the v1 fscrypt accessors used by this Samurai configuration;
4. link libtar's non-propagating Android 14 vold dependencies;
5. omit removed legacy FDE entry points only for the metadata-FBE build;
6. tear down the FBE `userdata` device-mapper target through current libdm;
7. order `task_profiles.json` before ramdisk assembly; and
8. link recovery's non-propagating Android 14 vold dependencies.

No fake cryptfs success stubs and no global warning suppression were added.

## Logs and Warnings

- Full successful link/image build: `dist/twrp-14.1-samurai-full-build.log`
- No-work reproducibility and payload validation:
  `dist/twrp-14.1-samurai-validation.log`
- Artifact checksums: `dist/SHA256SUMS`

The successful build retained two inherited TeamWin C++ unused-variable
warnings plus build-system/license metadata warnings. There were no final
compile errors, linker errors, or image-generation errors.

## Remaining Device Validation

This result proves source buildability and exact payload composition. It does
not prove physical boot, touch, MTP, or Android 13-16 data decryption because
no RMX1931 was attached during the build. Use `fastboot boot recovery.img`
first; do not permanently flash this first validation build.
