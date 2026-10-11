#!/bin/bash
# Third-Party Connection Monitoring Automation
# Author: Terrell Russell
# Purpose: Monitor and analyze all third-party connections on Android device

DEVICE_ID=""
LOG_DIR="./monitoring-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create log directory
mkdir -p "$LOG_DIR"

# Function to check device connection
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

# Function to dump all system services
dump_system_services() {
    echo "[$(date)] Dumping all system services..."
    adb shell "dumpsys -l" > "$LOG_DIR/system_services_$TIMESTAMP.txt"
    echo "System services dumped to $LOG_DIR/system_services_$TIMESTAMP.txt"
}

# Function to analyze accessibility services
analyze_accessibility() {
    echo "[$(date)] Analyzing accessibility services..."
    adb shell "dumpsys accessibility" > "$LOG_DIR/accessibility_$TIMESTAMP.txt"
    adb shell "settings list global | grep accessibility" >> "$LOG_DIR/accessibility_$TIMESTAMP.txt"
    echo "Accessibility analysis saved to $LOG_DIR/accessibility_$TIMESTAMP.txt"
}

# Function to monitor network connections
monitor_network() {
    echo "[$(date)] Monitoring network connections..."
    adb shell "dumpsys connectivity" > "$LOG_DIR/connectivity_$TIMESTAMP.txt"
    adb shell "dumpsys netpolicy" > "$LOG_DIR/netpolicy_$TIMESTAMP.txt"
    adb shell "dumpsys network_stack" > "$LOG_DIR/network_stack_$TIMESTAMP.txt"
    echo "Network monitoring saved to $LOG_DIR/"
}

# Function to analyze all packages
analyze_packages() {
    echo "[$(date)] Analyzing all packages..."
    adb shell "pm list packages -f" > "$LOG_DIR/packages_$TIMESTAMP.txt"
    adb shell "pm list packages -3" > "$LOG_DIR/third_party_packages_$TIMESTAMP.txt"
    adb shell "pm list packages -s" > "$LOG_DIR/system_packages_$TIMESTAMP.txt"
    echo "Package analysis saved to $LOG_DIR/"
}

# Function to check for third-party connections
check_third_party_connections() {
    echo "[$(date)] Checking third-party connections..."
    adb shell "dumpsys package com.google.android.gms" > "$LOG_DIR/gms_connections_$TIMESTAMP.txt"
    adb shell "dumpsys package com.google.android.gsf" > "$LOG_DIR/gsf_connections_$TIMESTAMP.txt"
    adb shell "dumpsys package com.facebook.katana" > "$LOG_DIR/facebook_connections_$TIMESTAMP.txt"
    echo "Third-party connection analysis saved to $LOG_DIR/"
}

# Function to monitor app ops
monitor_app_ops() {
    echo "[$(date)] Monitoring app operations..."
    adb shell "dumpsys appops" > "$LOG_DIR/appops_$TIMESTAMP.txt"
    adb shell "dumpsys permission" > "$LOG_DIR/permissions_$TIMESTAMP.txt"
    echo "App ops monitoring saved to $LOG_DIR/"
}

# Function to analyze firmware
analyze_firmware() {
    echo "[$(date)] Analyzing firmware..."
    adb shell "getprop | grep -E 'ro.build|ro.product|ro.bootloader|ro.hardware'" > "$LOG_DIR/firmware_$TIMESTAMP.txt"
    adb shell "cat /proc/version" >> "$LOG_DIR/firmware_$TIMESTAMP.txt"
    echo "Firmware analysis saved to $LOG_DIR/firmware_$TIMESTAMP.txt"
}

# Function to check carrier services
check_carrier_services() {
    echo "[$(date)] Checking carrier services..."
    adb shell "dumpsys telephony.registry" > "$LOG_DIR/telephony_$TIMESTAMP.txt"
    adb shell "dumpsys carrier_config" > "$LOG_DIR/carrier_config_$TIMESTAMP.txt"
    adb shell "dumpsys iphonesubinfo" > "$LOG_DIR/carrier_info_$TIMESTAMP.txt"
    echo "Carrier services analysis saved to $LOG_DIR/"
}

# Function to check all third-party app permissions
check_app_permissions() {
    echo "[$(date)] Checking third-party app permissions..."
    adb shell "pm list packages -3" | cut -d: -f2 > /tmp/third_party_apps.txt
    while read -r package; do
        adb shell "dumpsys package $package" >> "$LOG_DIR/all_permissions_$TIMESTAMP.txt"
    done < /tmp/third_party_apps.txt
    echo "All permissions saved to $LOG_DIR/all_permissions_$TIMESTAMP.txt"
}

# Function to generate summary report
generate_report() {
    echo "[$(date)] Generating summary report..."
    cat > "$LOG_DIR/summary_$TIMESTAMP.txt" << EOF
# Android System Analysis Report
# Generated: $(date)
# Device: $DEVICE_ID

## Analysis Files:
- System Services: system_services_$TIMESTAMP.txt
- Accessibility: accessibility_$TIMESTAMP.txt
- Network: connectivity_$TIMESTAMP.txt, netpolicy_$TIMESTAMP.txt, network_stack_$TIMESTAMP.txt
- Packages: packages_$TIMESTAMP.txt, third_party_packages_$TIMESTAMP.txt, system_packages_$TIMESTAMP.txt
- Third-Party Connections: gms_connections_$TIMESTAMP.txt, gsf_connections_$TIMESTAMP.txt, facebook_connections_$TIMESTAMP.txt
- App Operations: appops_$TIMESTAMP.txt, permissions_$TIMESTAMP.txt
- Firmware: firmware_$TIMESTAMP.txt
- Carrier: telephony_$TIMESTAMP.txt, carrier_config_$TIMESTAMP.txt, carrier_info_$TIMESTAMP.txt
- All Permissions: all_permissions_$TIMESTAMP.txt

## Status:
Analysis complete. Review individual files for detailed information.
EOF
    echo "Summary report generated: $LOG_DIR/summary_$TIMESTAMP.txt"
}

# Main execution
main() {
    if check_device; then
        dump_system_services
        analyze_accessibility
        monitor_network
        analyze_packages
        check_third_party_connections
        monitor_app_ops
        analyze_firmware
        check_carrier_services
        check_app_permissions
        generate_report
        echo "[$(date)] Full analysis complete. Logs saved to $LOG_DIR"
    else
        echo "[$(date)] Error: No device connected. Please enable ADB and authorize the device."
        exit 1
    fi
}

main
