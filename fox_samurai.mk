#
# Copyright (C) 2022-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Release name
PRODUCT_RELEASE_NAME := samurai

# Inherit device configuration
$(call inherit-product, device/realme/samurai/device.mk) 

# Inherit from common AOSP config
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Inherit from OrangeFox product configuration
$(call inherit-product, vendor/fox/config/common.mk)

PRODUCT_DEVICE := samurai
PRODUCT_NAME := fox_samurai
PRODUCT_BRAND := realme
PRODUCT_MODEL := Realme X2 Pro
PRODUCT_MANUFACTURER := realme

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=RMX1931 \
    BUILD_PRODUCT=RMX1931 \
    TARGET_DEVICE=RMX1931

# ==========================================
# Consolidated OrangeFox Hardware & UI Flags
# ==========================================
# Flashlight configurations for realme X2 Pro (samurai)
OF_FL_PATH1 := "/sys/class/leds/led:torch_0"
OF_FL_PATH2 := "/sys/class/leds/led:torch_1"
OF_FL_INTENSITY := 255
OF_USE_GREEN_LED := 0

# Screen & Display Settings
OF_SCREEN_H := 2400
OF_STATUS_H := 80
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_CLOCK_POS := 1
OF_ALLOW_DISABLE_NAVBAR := 0

# Keymaster & Decryption
OF_DEFAULT_KEYMASTER_VERSION := 4.0
OF_KEEP_FORCED_KEYMASTER := true

# OrangeFox Features & Utilities
OF_DISABLE_MIUI_SPECIFIC_FEATURES := 1
OF_QUICK_BACKUP_LIST := /data;/boot;
OF_ENABLE_LPTOOLS := 1
OF_PATCH_AVB20 := 1
OF_SUPPORT_OZIP_DECRYPTION := 1
