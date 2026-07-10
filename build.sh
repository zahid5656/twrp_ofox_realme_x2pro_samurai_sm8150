#!/usr/bin/env bash
#
# Build TWRP recovery for Realme X2 Pro (samurai).
# Run from the TWRP source root or from device/realme/samurai.

set -euo pipefail

DEVICE="samurai"
PRODUCT="twrp_samurai"
VARIANT="${VARIANT:-eng}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 8)}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  twrp-14.1
EOF
    exit 1
fi

cd "${top}"

log_dir="${LOG_DIR:-${top}/out/build-logs}"
mkdir -p "${log_dir}"
log_file="${log_dir}/twrp_${DEVICE}_$(date +%Y%m%d-%H%M%S).log"

echo "TWRP source root : ${top}"
echo "Device           : ${DEVICE}"
echo "Lunch target     : ${PRODUCT}-${VARIANT}"
echo "Jobs             : ${JOBS}"
echo "Build log        : ${log_file}"
echo

{
    set -euo pipefail
    source build/envsetup.sh
    lunch "${PRODUCT}-${VARIANT}"

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
