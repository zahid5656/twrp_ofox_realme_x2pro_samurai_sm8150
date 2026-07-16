#!/usr/bin/env bash
#
# Build TWRP recovery for Realme X2 Pro (samurai).
# Run from the TWRP source root or from device/realme/samurai.

set -euo pipefail

DEVICE="samurai"
PRODUCT="twrp_samurai"
RELEASE="${RELEASE:-ap2a}"
VARIANT="${VARIANT:-eng}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 8)}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate_prebuilts() {
    local prebuilt_dir="${script_dir}/prebuilt"

    for file in Image.gz-dtb dtbo.img SHA256SUMS; do
        if [[ ! -s "${prebuilt_dir}/${file}" ]]; then
            echo "error: missing or empty recovery prebuilt: ${prebuilt_dir}/${file}" >&2
            exit 1
        fi
    done

    echo "Validating recovery kernel and DTBO prebuilts..."
    (cd "${prebuilt_dir}" && sha256sum -c SHA256SUMS)

    python3 - "${prebuilt_dir}/Image.gz-dtb" "${prebuilt_dir}/dtbo.img" <<'PY'
import os
import struct
import sys
import zlib

kernel_path, dtbo_path = sys.argv[1:]

with open(kernel_path, "rb") as stream:
    kernel = stream.read()
if not (8 * 1024 * 1024 <= len(kernel) < 64 * 1024 * 1024):
    raise SystemExit("error: Image.gz-dtb size is outside the expected range")
if kernel[:2] != b"\x1f\x8b":
    raise SystemExit("error: Image.gz-dtb has no gzip header")

decompressor = zlib.decompressobj(16 + zlib.MAX_WBITS)
decompressor.decompress(kernel)
decompressor.flush()
if not decompressor.eof:
    raise SystemExit("error: Image.gz-dtb contains a truncated gzip stream")
appended_dtb = decompressor.unused_data
if len(appended_dtb) < 40 or appended_dtb[:4] != b"\xd0\x0d\xfe\xed":
    raise SystemExit("error: Image.gz-dtb has no valid appended FDT")
dtb_total_size = struct.unpack(">I", appended_dtb[4:8])[0]
if dtb_total_size != len(appended_dtb):
    raise SystemExit(
        f"error: appended FDT size mismatch: header={dtb_total_size} actual={len(appended_dtb)}"
    )

with open(dtbo_path, "rb") as stream:
    header = stream.read(32)
if len(header) != 32:
    raise SystemExit("error: dtbo.img has a truncated header")
(
    magic,
    total_size,
    header_size,
    entry_size,
    entry_count,
    entries_offset,
    page_size,
    version,
) = struct.unpack(">8I", header)
actual_size = os.path.getsize(dtbo_path)
expected = (0xD7B7AB1E, actual_size, 32, 32, 2, 32, 4096, 0)
actual = (
    magic,
    total_size,
    header_size,
    entry_size,
    entry_count,
    entries_offset,
    page_size,
    version,
)
if actual != expected:
    raise SystemExit(f"error: unexpected DTBO header: {actual!r}; expected {expected!r}")

print(
    f"Prebuilt structure: PASS (kernel={len(kernel)} bytes, "
    f"appended_dtb={len(appended_dtb)} bytes, dtbo_entries={entry_count})"
)
PY

    grep -Fqx 'BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb' "${script_dir}/BoardConfig.mk"
    grep -Fqx 'TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb' \
        "${script_dir}/BoardConfig.mk"
    grep -Fqx 'BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img' \
        "${script_dir}/BoardConfig.mk"
}

validate_prebuilts

validate_built_recovery() {
    local top="$1"
    local recovery_img="$2"
    local prebuilt_dir="${script_dir}/prebuilt"
    local unpack_script="${top}/system/tools/mkbootimg/unpack_bootimg.py"
    local verify_dir
    local image_size
    local partition_size

    if [[ ! -f "${unpack_script}" ]]; then
        echo "error: Android unpack_bootimg.py was not found: ${unpack_script}" >&2
        return 1
    fi

    image_size="$(stat -c '%s' "${recovery_img}")"
    partition_size="$(awk '$1 == "BOARD_RECOVERYIMAGE_PARTITION_SIZE" && $2 == ":=" { print $3; exit }' "${script_dir}/BoardConfig.mk")"
    if [[ ! "${partition_size}" =~ ^[0-9]+$ ]]; then
        echo "error: could not read BOARD_RECOVERYIMAGE_PARTITION_SIZE" >&2
        return 1
    fi
    if (( image_size > partition_size )); then
        echo "error: recovery image (${image_size}) exceeds partition size (${partition_size})" >&2
        return 1
    fi

    verify_dir="$(mktemp -d "${top}/out/recovery-verify.XXXXXX")"
    trap 'rm -rf "${verify_dir}"' RETURN

    echo "Validating built recovery image..."
    python3 "${unpack_script}" \
        --boot_img "${recovery_img}" \
        --out "${verify_dir}" \
        --format info

    for file in kernel ramdisk recovery_dtbo; do
        if [[ ! -s "${verify_dir}/${file}" ]]; then
            echo "error: recovery image did not contain ${file}" >&2
            return 1
        fi
    done

    if ! cmp -s "${verify_dir}/kernel" "${prebuilt_dir}/Image.gz-dtb"; then
        echo "error: embedded recovery kernel does not match pinned Image.gz-dtb" >&2
        return 1
    fi
    if ! cmp -s "${verify_dir}/recovery_dtbo" "${prebuilt_dir}/dtbo.img"; then
        echo "error: embedded recovery DTBO does not match pinned dtbo.img" >&2
        return 1
    fi
    gzip -t "${verify_dir}/ramdisk"

    echo "Recovery image structure: PASS"
    echo "Recovery image size     : ${image_size}/${partition_size} bytes"
    echo "Recovery image SHA-256  : $(sha256sum "${recovery_img}" | awk '{print $1}')"
    echo "Embedded kernel SHA-256 : $(sha256sum "${verify_dir}/kernel" | awk '{print $1}')"
    echo "Embedded DTBO SHA-256   : $(sha256sum "${verify_dir}/recovery_dtbo" | awk '{print $1}')"
}

apply_source_compat_patches() {
    local top="$1"
    local patch_dir="${script_dir}/patches/twrp-14.1"
    local patch

    if [[ ! -d "${top}/bootable/recovery/.git" && ! -f "${top}/bootable/recovery/.git" ]]; then
        echo "error: bootable/recovery is not a Git checkout under ${top}" >&2
        exit 1
    fi

    for patch in "${patch_dir}"/*.patch; do
        if git -C "${top}/bootable/recovery" apply --check "${patch}" 2>/dev/null; then
            echo "Applying TWRP 14.1 source compatibility patch: $(basename "${patch}")"
            git -C "${top}/bootable/recovery" apply "${patch}"
        elif git -C "${top}/bootable/recovery" apply --reverse --check "${patch}" 2>/dev/null; then
            echo "TWRP 14.1 source compatibility patch already applied: $(basename "${patch}")"
        else
            echo "error: source compatibility patch does not match this TWRP tree: ${patch}" >&2
            exit 1
        fi
    done
}

find_top() {
    local dir

    if [[ -n "${ANDROID_BUILD_TOP:-}" && -f "${ANDROID_BUILD_TOP}/build/envsetup.sh" ]]; then
        printf '%s\n' "${ANDROID_BUILD_TOP}"
        return 0
    fi

    dir="${script_dir}"
    while [[ "${dir}" != "/" ]]; do
        if [[ -f "${dir}/build/envsetup.sh" ]]; then
            printf '%s\n' "${dir}"
            return 0
        fi
        dir="$(dirname "${dir}")"
    done

    return 1
}

top="$(find_top || true)"

if [[ -z "${top}" ]]; then
    cat >&2 <<'EOF'
error: TWRP source root not found.

Place this repository at:
  device/realme/samurai

Then run:
  ./device/realme/samurai/build.sh

Expected source branch:
  twrp-14.1-a13-a16-decrypt-readiness
EOF
    exit 1
fi

cd "${top}"

apply_source_compat_patches "${top}"

log_dir="${LOG_DIR:-${top}/out/build-logs}"
mkdir -p "${log_dir}"
log_file="${log_dir}/twrp_${DEVICE}_$(date +%Y%m%d-%H%M%S).log"

echo "TWRP source root : ${top}"
echo "Device           : ${DEVICE}"
echo "Lunch target     : ${PRODUCT}-${RELEASE}-${VARIANT}"
echo "Jobs             : ${JOBS}"
echo "Build log        : ${log_file}"
echo

{
    # Android's envsetup and lunch functions intentionally probe many unset
    # variables, so nounset cannot remain enabled inside the sourced build
    # environment. Keep errexit and pipefail for the actual build commands.
    set -eo pipefail
    set +u
    source build/envsetup.sh
    lunch "${PRODUCT}-${RELEASE}-${VARIANT}"

    if command -v mka >/dev/null 2>&1; then
        mka recoveryimage
    else
        make -j"${JOBS}" recoveryimage
    fi
} 2>&1 | tee "${log_file}"

build_status="${PIPESTATUS[0]}"
if [[ "${build_status}" -ne 0 ]]; then
    echo
    echo "Build failed. Log: ${log_file}" >&2
    exit "${build_status}"
fi

recovery_img="${top}/out/target/product/${DEVICE}/recovery.img"

echo
if [[ -f "${recovery_img}" ]]; then
    echo "Build complete: ${recovery_img}"
else
    echo "Build finished, but ${recovery_img} was not found." >&2
    echo "Check the product output directory and build log: ${log_file}" >&2
    exit 1
fi

validate_built_recovery "${top}" "${recovery_img}" | tee -a "${log_file}"
