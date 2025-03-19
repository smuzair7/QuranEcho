@echo off
echo Checking ADB connection...
adb devices

echo.
echo Restarting ADB server...
adb kill-server
adb start-server

echo.
echo Checking for device...
adb devices

echo.
echo Setting installation permissions...
adb shell settings put global verifier_verify_adb_installs 0
adb shell settings put global package_verifier_enable 0

echo.
echo Checking wireless debugging status...
adb shell settings get global adb_wifi_enabled

echo.
echo Try installing app again with:
echo flutter run --verbose
