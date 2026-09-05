###############################################################################
# REALME X2 PRO (RMX1931 / samurai)
# ORANGEFOX RECOVERY — COMPLETE CLEAN BUILD GUIDE
#
# OrangeFox base       : fox_12.1
# Device tree          : zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150
# Device tree branch   : fox-12.1-staging-backup
# Physical device      : Realme X2 Pro / RMX1931
# Rebranded codename   : samurai
#
# IMPORTANT:
# - RMX1931 = A-only
# - Dedicated recovery partition
# - Prebuilt kernel
# - Do NOT set FOX_AB_DEVICE
# - Do NOT set FOX_VIRTUAL_AB_DEVICE
# - Do NOT set FOX_VERSION
###############################################################################

```bash
rm -rf /home/titan/fox_12.1
rm -rf /home/titan/OrangeFox_sync
ccache -C

cd /home/titan
mkdir -p OrangeFox_sync
cd OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd /home/titan/OrangeFox_sync/sync

./orangefox_sync.sh \
  --branch 12.1 \
  --path /home/titan/fox_12.1

cd /home/titan/fox_12.1
mkdir -p device/realme
rm -rf device/realme/samurai

git clone \
  --branch fox-12.1-staging-backup \
  --single-branch \
  https://github.com/zahid5656/twrp_ofox_realme_x2pro_samurai_sm8150.git \
  device/realme/samurai

export FOX_BUILD_DEVICE=samurai
export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
export OF_FORCE_PREBUILT_KERNEL=1
export OF_DEFAULT_KEYMASTER_VERSION=4.0
export OF_MAINTAINER="ETHICAL ∆ TITAN"
export FOX_MAINTAINER_PATCH_VERSION=1

source build/envsetup.sh
lunch twrp_samurai-eng

mkdir -p /home/titan/fox_12.1/.ccache/tmp
export CCACHE_DIR=/home/titan/fox_12.1/.ccache
export CCACHE_TEMPDIR=/home/titan/fox_12.1/.ccache/tmp

mka recoveryimage 2>&1 | tee /home/titan/orangefox-samurai-build.log
```
