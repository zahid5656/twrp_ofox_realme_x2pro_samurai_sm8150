#
# Copyright (C) 2022 Team Win Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/fox_samurai.mk \
    $(LOCAL_DIR)/twrp_samurai.mk

COMMON_LUNCH_CHOICES := \
    fox_samurai-eng \
    fox_samurai-userdebug \
    twrp_samurai-eng