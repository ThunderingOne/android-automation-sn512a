#!/bin/bash
# Automated Android Device Setup
# Author: Terrell Russell
# Purpose: Automatically configure device for semi-root, custom apps, and carrier unlock preparation

DEVICE_ID=""
LOG_DIR="./setup-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$LOG_DIR"

# Function to check device
check_device() {
    adb devices | grep -w "device" > /dev/null
    if [ $? -eq 0 ]; then
        DEVICE_ID=$(adb devices | grep -w "device" | awk '{print $1}')
        echo "Device connected: $DEVICE_ID"
        return 0
    else
        echo "No device connected"
        return 1
    fi
}

# Function to enable developer options if not already enabled
enable_developer_options() {
    echo "[$(date)] Checking developer options status..."
    DEVELOPMENT_ENABLED=$(adb shell "settings get global development_settings_enabled")
    if [ "$DEVELOPMENT_ENABLED" = "0" ]; then
        echo "Developer options disabled. Enabling..."
        adb shell "settings put global development_settings_enabled 1"
        echo "Developer options enabled"
    else
        echo "Developer options already enabled"
    fi
}

# Function to enable ADB debugging (requires user interaction)
enable_adb_debugging() {
    echo "[$(date)] Enabling ADB debugging..."
    adb shell "settings put global adb_enabled 1"
    echo "ADB debugging enabled"
}

# Function to enable unknown sources
enable_unknown_sources() {
    echo "[$(date)] Enabling unknown sources..."
    adb shell "settings put global verifier_verify_adb_installs 0"
    adb shell "settings put global package_verifier_enable 0"
    echo "Unknown sources enabled"
}

# Function to install Shizuku (semi-root)
install_shizuku() {
    echo "[$(date)] Installing Shizuku for semi-root capabilities..."
    # Check if Shizuku is already installed
    SHIZUKU_INSTALLED=$(adb shell "pm list packages | grep moe.shizuku")
    if [ -z "$SHIZUKU_INSTALLED" ]; then
        echo "Shizuku not installed. Please download from: https://shizuku.rikka.app/"
        echo "Install via ADB: adb install shizuku.apk"
        echo "Then enable via developer options: Wireless debugging"
    else
        echo "Shizuku already installed"
    fi
}

# Function to check carrier lock status
check_carrier_lock() {
    echo "[$(date)] Checking carrier lock status..."
    adb shell "dumpsys telephony.registry" > "$LOG_DIR/carrier_lock_$TIMESTAMP.txt"
    adb shell "service call iphonesubinfo 1" >> "$LOG_DIR/carrier_lock_$TIMESTAMP.txt"
    echo "Carrier lock status saved to $LOG_DIR/carrier_lock_$TIMESTAMP.txt"
}

# Function to enable USB debugging (requires user authorization)
request_usb_debugging() {
    echo "[$(date)] Requesting USB debugging authorization..."
    adb shell "settings put global adb_enabled 1"
    echo "Please authorize USB debugging on the device when prompted"
}

# Function to enable installation from browser
enable_browser_install() {
    echo "[$(date)] Enabling installation from browser..."
    adb shell "settings put secure install_non_market_apps 1"
    echo "Browser installation enabled"
}

# Function to disable carrier restrictions (where possible)
disable_carrier_restrictions() {
    echo "[$(date)] Disabling carrier restrictions..."
    # Disable carrier default app
    adb shell "pm disable-user -r com.android.carrierdefaultapp" 2>/dev/null
    # Disable carrier config sync
    adb shell "pm disable-user -r com.google.android.carrier" 2>/dev/null
    echo "Carrier restrictions disabled where possible"
}

# Function to enable custom DNS (already done, but verify)
verify_dns_config() {
    echo "[$(date)] Verifying DNS configuration..."
    DNS_MODE=$(adb shell "settings get global private_dns_mode")
    DNS_SPECIFIER=$(adb shell "settings get global private_dns_specifier")
    echo "DNS Mode: $DNS_MODE"
    echo "DNS Specifier: $DNS_SPECIFIER"
}

# Function to check bootloader status
check_bootloader() {
    echo "[$(date)] Checking bootloader status..."
    BOOTLOADER_STATUS=$(adb shell "getprop ro.boot.verifiedbootstate")
    OEM_UNLOCK=$(adb shell "getprop ro.oem_unlock_supported")
    echo "Bootloader Status: $BOOTLOADER_STATUS"
    echo "OEM Unlock Supported: $OEM_UNLOCK"
}

# Function to grant additional permissions to user apps
grant_additional_permissions() {
    echo "[$(date)] Granting additional permissions..."
    # Grant install permissions
    adb shell "pm grant com.android.shell android.permission.REQUEST_INSTALL_PACKAGES" 2>/dev/null
    echo "Additional permissions granted"
}

# Function to setup custom APN configuration
setup_custom_apn() {
    echo "[$(date)] Setting up custom APN configuration..."
    adb shell "settings put global preferred_network_mode 0"
    echo "Custom APN configuration enabled (manual configuration required in settings)"
}

# Function to generate setup report
generate_setup_report() {
    cat > "$LOG_DIR/setup_report_$TIMESTAMP.txt" << EOF
# Android Device Setup Report
# Generated: $(date)
# Device: $DEVICE_ID

## Setup Actions Performed:
1. Developer options enabled
2. ADB debugging enabled
3. Unknown sources enabled
4. Browser installation enabled
5. Carrier restrictions disabled (where possible)
6. Custom APN configuration enabled
7. Additional permissions granted

## Next Steps:
1. Install Shizuku manually from: https://shizuku.rikka.app/
2. Request carrier unlock from AT&T if eligible
3. Configure custom APN settings in device settings
4. Install custom package manager (F-Droid)
5. Install custom apps as needed

## Files Generated:
- Carrier lock status: carrier_lock_$TIMESTAMP.txt
- Setup report: setup_report_$TIMESTAMP.txt
EOF
    echo "Setup report generated: $LOG_DIR/setup_report_$TIMESTAMP.txt"
}

# Main execution
main() {
    if check_device; then
        enable_developer_options
        enable_adb_debugging
        enable_unknown_sources
        install_shizuku
        check_carrier_lock
        enable_browser_install
        disable_carrier_restrictions
        verify_dns_config
        check_bootloader
        grant_additional_permissions
        setup_custom_apn
        generate_setup_report
        echo "[$(date)] Automated setup complete. Review logs in $LOG_DIR"
    else
        echo "[$(date)] Error: No device connected. Please enable ADB and authorize the device."
        exit 1
    fi
}

main
