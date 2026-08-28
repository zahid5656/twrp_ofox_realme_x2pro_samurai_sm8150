#
# Copyright (C) 2022 Team Win Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# Display
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_WIDTH := 1080

PRODUCT_SOONG_NAMESPACES += \
    vendor/qcom/opensource/commonsys-intf/display

# SHIPPING API
PRODUCT_SHIPPING_API_LEVEL := 28

# Assert
TARGET_OTA_ASSERT_DEVICE := samurai,RMX1931,RMX1931EX,RMX1931L1,RMX1931CN

# Crypto
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# Recovery
TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.gatekeeper@1.0 \
    android.hardware.keymaster@4.0 \
    android.hardware.keymaster@4.1 \
    libbase \
    libcrypto \
    libcutils \
    libhardware \
    libhidlbase \
    libion \
    liblog \
    libxml2 \
    libutils \
    vendor.display.config@1.0 \
    vendor.display.config@2.0 \
    libdisplayconfig.qti

TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.gatekeeper@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.keymaster@4.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.keymaster@4.1.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libbase.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libcrypto.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libcutils.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libhardware.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libhidlbase.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/liblog.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libxml2.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libutils.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/vendor.display.config@1.0.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/vendor.display.config@2.0.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/libdisplayconfig.qti.so
