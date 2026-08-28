#!/usr/bin/env bash
#
# Realme X2 Pro / samurai
# OrangeFox fox_12.1 / R12.0_1 build script
# GCP / Local Ubuntu
#
# Purpose:
#   Automate the proven manual OrangeFox build sequence without changing it.
#
# Important:
#   - Clear the host-configured ccache at script start.
#   - Do NOT override CCACHE_DIR.
#   - Do NOT set ccache size here.
#   - Do NOT create ccache inside the OrangeFox source tree.
#   - Pre-export the proven Keymaster 4.0 value.
#   - Do NOT use `set -e`; Android envsetup may return a harmless non-zero status
#     while still correctly defining lunch/mka.
#   - Do NOT add manifest patch logic.
#   - Do NOT git reset / git clean / auto-switch branches.
#

set -o pipefail

rm -rf /home/titan/fox_12.1
rm -rf /home/titan/OrangeFox_sync

HOME_DIR="${HOME}"
SYNC_PARENT="${HOME_DIR}/OrangeFox_sync"
SYNC_DIR="${SYNC_PARENT}/sync"
FOX_DIR="${HOME_DIR}/fox_12.1"
DEVICE_DIR="${FOX_DIR}/device/realme/samurai"

DEVICE_REPO="https://github.com/zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150.git"
DEVICE_BRANCH="fox-12.1"

BUILD_LOG="${HOME_DIR}/orangefox-samurai-build.log"

echo "============================================================"
echo " OrangeFox fox_12.1 / R12.0_1 Build - Realme X2 Pro / samurai"
echo "============================================================"
echo "HOME       : ${HOME_DIR}"
echo "FOX_DIR    : ${FOX_DIR}"
echo "DEVICE     : samurai"
echo "DT BRANCH  : ${DEVICE_BRANCH}"
echo "BUILD LOG  : ${BUILD_LOG}"
echo "============================================================"
echo

# ---------------------------------------------------------------------------
# 1. CLEAR THE EXISTING HOST CCACHE FIRST
# ---------------------------------------------------------------------------

export USE_CCACHE=1

if command -v ccache >/dev/null 2>&1; then
    echo "Current ccache configuration:"
    ccache -s || true
    echo

    echo "Clearing the complete configured ccache..."
    ccache -C
    CACHE_RC=$?

    if [ "${CACHE_RC}" -ne 0 ]; then
        echo "ERROR: ccache clear failed with exit code ${CACHE_RC}"
        exit "${CACHE_RC}"
    fi

    echo "ccache cleared."
    echo "The build will use the host's existing/default ccache configuration."
    echo
else
    echo "WARNING: ccache command not found."
    echo "Build will continue without ccache acceleration."
    unset USE_CCACHE
    echo
fi

# ---------------------------------------------------------------------------
# 2. ORANGEFOX SYNC HELPER
# ---------------------------------------------------------------------------

cd "${HOME_DIR}" || exit 1
mkdir -p OrangeFox_sync
cd "${SYNC_PARENT}" || exit 1

if [ ! -d sync/.git ]; then
    git clone https://gitlab.com/OrangeFox/sync.git
    CLONE_RC=$?
    [ "${CLONE_RC}" -eq 0 ] || exit "${CLONE_RC}"
fi

# IMPORTANT: run orangefox_sync.sh from its own directory.
cd "${SYNC_DIR}" || exit 1

./orangefox_sync.sh \
  --branch 12.1 \
  --path "${FOX_DIR}"

SYNC_RC=$?
if [ "${SYNC_RC}" -ne 0 ]; then
    echo "ERROR: OrangeFox sync failed with exit code ${SYNC_RC}"
    exit "${SYNC_RC}"
fi

# ---------------------------------------------------------------------------
# 3. VERIFY ORANGEFOX SOURCE
# ---------------------------------------------------------------------------

cd "${FOX_DIR}" || exit 1

pwd

ls -ld \
  .repo \
  build \
  bootable/recovery \
  vendor/recovery

VERIFY_RC=$?
if [ "${VERIFY_RC}" -ne 0 ]; then
    echo "ERROR: OrangeFox source verification failed."
    exit "${VERIFY_RC}"
fi

git -C bootable/recovery remote -v
git -C vendor/recovery remote -v

# ---------------------------------------------------------------------------
# 4. DEVICE TREE
# ---------------------------------------------------------------------------

cd "${FOX_DIR}" || exit 1
mkdir -p device/realme

if [ ! -d "${DEVICE_DIR}/.git" ]; then
    git clone \
      --branch "${DEVICE_BRANCH}" \
      --single-branch \
      "${DEVICE_REPO}" \
      "${DEVICE_DIR}"

    DT_RC=$?
    if [ "${DT_RC}" -ne 0 ]; then
        echo "ERROR: Device tree clone failed with exit code ${DT_RC}"
        exit "${DT_RC}"
    fi
else
    echo
    echo "Existing device tree found:"
    echo "  ${DEVICE_DIR}"
    git -C "${DEVICE_DIR}" status --short --branch
    echo "Using existing device tree as-is."
    echo
fi

# ---------------------------------------------------------------------------
# 5. ORANGEFOX BUILD VARIABLES
# ---------------------------------------------------------------------------

cd "${FOX_DIR}" || exit 1

export FOX_BUILD_DEVICE=samurai
export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
export OF_FORCE_PREBUILT_KERNEL=1
export OF_DEFAULT_KEYMASTER_VERSION=4.0
export OF_MAINTAINER="ETHICAL △ TITAN"
export FOX_MAINTAINER_PATCH_VERSION=1

# RMX1931 / samurai is A-only.
# Do NOT set these OrangeFox A/B variables.
unset FOX_AB_DEVICE 2>/dev/null || true
unset FOX_VIRTUAL_AB_DEVICE 2>/dev/null || true
unset FOX_VERSION 2>/dev/null || true

# ---------------------------------------------------------------------------
# 6. ANDROID / ORANGEFOX BUILD ENVIRONMENT
# ---------------------------------------------------------------------------

cd "${FOX_DIR}" || exit 1

# Do NOT use `set -e` around Android envsetup.
# Some envsetup internals may return non-zero without making envsetup unusable.
source build/envsetup.sh
ENVSETUP_RC=$?

echo
echo "envsetup return code: ${ENVSETUP_RC}"

# What matters is whether the expected build functions were actually loaded.
if ! type lunch >/dev/null 2>&1; then
    echo "ERROR: lunch was not defined by build/envsetup.sh"
    exit 1
fi

if ! type mka >/dev/null 2>&1; then
    echo "ERROR: mka was not defined by build/envsetup.sh"
    exit 1
fi

gettop || true

echo
echo "TOP=${TOP:-}"
echo "ANDROID_BUILD_TOP=${ANDROID_BUILD_TOP:-}"
echo "FOX_MANIFEST_ROOT=${FOX_MANIFEST_ROOT:-}"
echo "FOX_BUILD_DEVICE=${FOX_BUILD_DEVICE}"
echo "OF_DEFAULT_KEYMASTER_VERSION=${OF_DEFAULT_KEYMASTER_VERSION}"
echo "FOX_MAINTAINER_PATCH_VERSION=${FOX_MAINTAINER_PATCH_VERSION}"
echo

# ---------------------------------------------------------------------------
# 7. LUNCH
# ---------------------------------------------------------------------------

lunch twrp_samurai-eng
LUNCH_RC=$?

if [ "${LUNCH_RC}" -ne 0 ]; then
    echo "ERROR: lunch failed with exit code ${LUNCH_RC}"
    exit "${LUNCH_RC}"
fi

echo
echo "TARGET_PRODUCT=${TARGET_PRODUCT:-}"
echo "TARGET_DEVICE=${TARGET_DEVICE:-}"
echo "ANDROID_PRODUCT_OUT=${ANDROID_PRODUCT_OUT:-}"
echo

# TARGET_DEVICE may legitimately be blank for the samurai alias/rebranded
# product setup. Do not fail only because TARGET_DEVICE is blank.

# ---------------------------------------------------------------------------
# 8. BUILD
# ---------------------------------------------------------------------------

cd "${FOX_DIR}" || exit 1

echo "============================================================"
echo " Starting OrangeFox recovery build"
echo "============================================================"
echo

mka recoveryimage 2>&1 | tee "${BUILD_LOG}"
BUILD_RC=${PIPESTATUS[0]}

if [ "${BUILD_RC}" -ne 0 ]; then
    echo
    echo "============================================================"
    echo " BUILD FAILED"
    echo "============================================================"
    echo "mka exit code: ${BUILD_RC}"
    echo "Build log:"
    echo "  ${BUILD_LOG}"
    exit "${BUILD_RC}"
fi

# ---------------------------------------------------------------------------
# 9. SHOW GENERATED ARTIFACTS
# ---------------------------------------------------------------------------

echo
echo "============================================================"
echo " BUILD FINISHED"
echo "============================================================"
echo "Product output:"
echo "  ${ANDROID_PRODUCT_OUT}"
echo

echo "Expected OrangeFox artifacts:"
echo "  OrangeFox-*.img"
echo "  OrangeFox-*.zip"
echo "  recovery.img"
echo
echo "Found:"

find "${ANDROID_PRODUCT_OUT}" -maxdepth 2 -type f \
  \( \
    -name 'OrangeFox-*.img' -o \
    -name 'OrangeFox-*.zip' -o \
    -name 'recovery.img' \
  \) \
  -print 2>/dev/null | sort || true

echo

if command -v ccache >/dev/null 2>&1; then
    echo "Final ccache statistics:"
    ccache -s || true
    echo
fi

echo "Build log:"
echo "  ${BUILD_LOG}"
echo "========================================================"
