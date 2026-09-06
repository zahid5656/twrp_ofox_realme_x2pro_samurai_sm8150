#!/system/bin/sh

set_device_variant()
{
    for prop in \
        ro.product.device \
        ro.product.odm.device \
        ro.product.product.device \
        ro.product.system.device \
        ro.product.vendor.device \
        ro.product.vendor_dlkm.device; do
        resetprop "$prop" "$1"
    done
}

project="$(cat /proc/oppoVersion/operatorName 2>/dev/null)"

case "$project" in
    "5") set_device_variant "RMX1931L1"; echo "Global variant detected" ;;
    "8") set_device_variant "RMX1931CN"; echo "Chinese variant detected" ;;
    *) echo "Unknown operator variant; keeping samurai identity" ;;
esac

exit 0
