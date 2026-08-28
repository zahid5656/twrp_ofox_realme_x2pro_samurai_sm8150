#!/system/bin/sh

load_RMX1931L1()
{
    resetprop "ro.product.device" "RMX1931L1"
    resetprop "ro.commonsoft.ota" "RMX1931L1"
    resetprop "ro.separate.soft" "19688"
    echo "Global variant detected"
}

load_RMX1931CN()
{
    resetprop "ro.product.device" "RMX1931CN"
    resetprop "ro.commonsoft.ota" "RMX1931"
    resetprop "ro.separate.soft" "19781"
    echo "Chinese variant detected"
}

project="$(cat /proc/oplusVersion/operatorName 2>/dev/null)"

case "$project" in
    "5") load_RMX1931L1 ;;
    "8") load_RMX1931CN ;;
    *) echo "Unknown operator variant; keeping samurai identity" ;;
esac

resetprop "ro.build.date.utc" "1000000000"
resetprop "ro.system.build.date.utc" "0000000000"
resetprop "ro.system_ext.build.date.utc" "0000000000"
resetprop "ro.vendor.build.date.utc" "0000000000"
resetprop "ro.odm.build.date.utc" "0000000000"
resetprop "ro.product.build.date.utc" "0000000000"

exit 0
