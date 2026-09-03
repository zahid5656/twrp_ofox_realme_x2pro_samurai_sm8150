#!/usr/bin/env bash

###############################################################################
# REALME X2 PRO (RMX1931 / samurai)
# ORANGEFOX RECOVERY — GCP BUILD SCRIPT
#
# OrangeFox base       : fox_12.1
# Device tree          : zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150
# Device tree branch   : ofox-12.1
###############################################################################

cd /home/titan
mkdir -p OrangeFox_sync
cd OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd /home/titan/OrangeFox_sync/sync

./orangefox_sync.sh \
  --branch 12.1 \
  --path /home/titan/fox_12.1

cd /home/titan/fox_12.1
pwd

ls -ld \
  .repo \
  build \
  bootable/recovery \
  vendor/recovery

git -C bootable/recovery remote -v
git -C vendor/recovery remote -v

cd /home/titan/fox_12.1
mkdir -p device/realme
rm -rf device/realme/samurai

git clone \
  --branch ofox-12.1 \
  --single-branch \
  https://github.com/zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150.git \
  device/realme/samurai

cd /home/titan/fox_12.1
export FOX_BUILD_DEVICE=samurai
export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
export OF_FORCE_PREBUILT_KERNEL=1
export OF_DEFAULT_KEYMASTER_VERSION=4.0
export OF_MAINTAINER="ETHICAL ∆ TITAN"
export FOX_MAINTAINER_PATCH_VERSION=1

source build/envsetup.sh

gettop
echo "TOP=$TOP"
echo "ANDROID_BUILD_TOP=$ANDROID_BUILD_TOP"
echo "FOX_MANIFEST_ROOT=$FOX_MANIFEST_ROOT"
echo "FOX_BUILD_DEVICE=$FOX_BUILD_DEVICE"

lunch twrp_samurai-eng

echo "TARGET_PRODUCT=$TARGET_PRODUCT"
echo "TARGET_DEVICE=$TARGET_DEVICE"
echo "ANDROID_PRODUCT_OUT=$ANDROID_PRODUCT_OUT"

mkdir -p /home/titan/fox_12.1/.ccache/tmp
export CCACHE_DIR=/home/titan/fox_12.1/.ccache
export CCACHE_TEMPDIR=/home/titan/fox_12.1/.ccache/tmp

mka recoveryimage 2>&1 | tee /home/titan/orangefox-samurai-build.log
