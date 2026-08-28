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

load_RMX1931L1()
{
    set_device_variant "RMX1931L1"
    resetprop "ro.commonsoft.ota" "RMX1931L1"
    resetprop "ro.separate.soft" "19688"
    echo "Global variant detected"
}

load_RMX1931CN()
{
    set_device_variant "RMX1931CN"
    resetprop "ro.commonsoft.ota" "RMX1931"
    resetprop "ro.separate.soft" "19781"
    echo "Chinese variant detected"
}

project=$(cat /proc/oplusVersion/operatorName)
echo $project

case $project in
    "5") load_RMX1931L1 ;;
    "8") load_RMX1931CN ;;
esac

resetprop "ro.build.date.utc" "1000000000"
resetprop "ro.system.build.date.utc" "0000000000"
resetprop "ro.system_ext.build.date.utc" "0000000000"
resetprop "ro.vendor.build.date.utc" "0000000000"
resetprop "ro.odm.build.date.utc" "0000000000"
resetprop "ro.product.build.date.utc" "0000000000"

exit 0
