#!/bin/bash
# Comprehensive System Accessibility Analysis
# Author: Terrell Russell
# Purpose: Analyze all system features, services, tools, programs, software, firmware, and third-party connections

DEVICE_ID=""
LOG_DIR="./accessibility-analysis"
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

# Function to analyze all system features
analyze_system_features() {
    echo "[$(date)] Analyzing system features..."
    adb shell "dumpsys accessibility" > "$LOG_DIR/accessibility_full_$TIMESTAMP.txt"
    adb shell "dumpsys window windows" > "$LOG_DIR/window_features_$TIMESTAMP.txt"
    adb shell "dumpsys activity top" > "$LOG_DIR/activity_features_$TIMESTAMP.txt"
    echo "System features analysis saved"
}

# Function to analyze all system services
analyze_all_services() {
    echo "[$(date)] Analyzing all system services..."
    adb shell "dumpsys -l" > "$LOG_DIR/all_services_$TIMESTAMP.txt"
    # Detailed dump of critical services
    for service in connectivity telephony wifi bluetooth location package activity power battery; do
        echo "Dumping $service..." >> "$LOG_DIR/service_analysis_$TIMESTAMP.txt"
        adb shell "dumpsys $service" >> "$LOG_DIR/service_analysis_$TIMESTAMP.txt"
        echo "---" >> "$LOG_DIR/service_analysis_$TIMESTAMP.txt"
    done
    echo "All services analysis saved"
}

# Function to analyze all system tools
analyze_system_tools() {
    echo "[$(date)] Analyzing system tools..."
    adb shell "which ls" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        adb shell "ls -la /system/bin" > "$LOG_DIR/system_tools_$TIMESTAMP.txt"
        adb shell "ls -la /system/xbin" >> "$LOG_DIR/system_tools_$TIMESTAMP.txt"
        adb shell "ls -la /vendor/bin" >> "$LOG_DIR/system_tools_$TIMESTAMP.txt"
    fi
    echo "System tools analysis saved"
}

# Function to analyze all programs
analyze_all_programs() {
    echo "[$(date)] Analyzing all programs..."
    adb shell "pm list packages -f" > "$LOG_DIR/all_programs_$TIMESTAMP.txt"
    adb shell "pm list packages -f -3" > "$LOG_DIR/third_party_programs_$TIMESTAMP.txt"
    adb shell "pm list packages -f -s" > "$LOG_DIR/system_programs_$TIMESTAMP.txt"
    echo "All programs analysis saved"
}

# Function to analyze software versions
analyze_software_versions() {
    echo "[$(date)] Analyzing software versions..."
    adb shell "getprop | grep -E 'version|build|release'" > "$LOG_DIR/software_versions_$TIMESTAMP.txt"
    adb shell "cat /system/build.prop" >> "$LOG_DIR/software_versions_$TIMESTAMP.txt"
    adb shell "cat /vendor/build.prop" >> "$LOG_DIR/software_versions_$TIMESTAMP.txt"
    echo "Software versions analysis saved"
}

# Function to analyze firmware
analyze_firmware() {
    echo "[$(date)] Analyzing firmware..."
    adb shell "getprop | grep -E 'ro.build|ro.product|ro.bootloader|ro.hardware|ro.board'" > "$LOG_DIR/firmware_full_$TIMESTAMP.txt"
    adb shell "cat /proc/version" >> "$LOG_DIR/firmware_full_$TIMESTAMP.txt"
    adb shell "cat /proc/cpuinfo" >> "$LOG_DIR/firmware_full_$TIMESTAMP.txt"
    adb shell "cat /proc/meminfo" >> "$LOG_DIR/firmware_full_$TIMESTAMP.txt"
    echo "Firmware analysis saved"
}

# Function to analyze third-party connections
analyze_third_party_connections() {
    echo "[$(date)] Analyzing third-party connections..."
    # Check all third-party apps for network access
    adb shell "pm list packages -3" | cut -d: -f2 > /tmp/third_party.txt
    while read -r package; do
        echo "Analyzing $package..." >> "$LOG_DIR/third_party_connections_$TIMESTAMP.txt"
        adb shell "dumpsys package $package" | grep -A 5 "requested permissions" >> "$LOG_DIR/third_party_connections_$TIMESTAMP.txt"
        adb shell "dumpsys package $package" | grep -A 5 "uses-permission" >> "$LOG_DIR/third_party_connections_$TIMESTAMP.txt"
        echo "---" >> "$LOG_DIR/third_party_connections_$TIMESTAMP.txt"
    done < /tmp/third_party.txt
    echo "Third-party connections analysis saved"
}

# Function to analyze network connections
analyze_network_connections() {
    echo "[$(date)] Analyzing network connections..."
    adb shell "netstat -tuln" > "$LOG_DIR/network_connections_$TIMESTAMP.txt" 2>/dev/null
    adb shell "dumpsys connectivity" >> "$LOG_DIR/network_connections_$TIMESTAMP.txt"
    adb shell "dumpsys netd" >> "$LOG_DIR/network_connections_$TIMESTAMP.txt" 2>/dev/null
    echo "Network connections analysis saved"
}

# Function to analyze accessibility services specifically
analyze_accessibility_services() {
    echo "[$(date)] Analyzing accessibility services..."
    adb shell "settings list secure | grep accessibility" > "$LOG_DIR/accessibility_settings_$TIMESTAMP.txt"
    adb shell "settings list global | grep accessibility" >> "$LOG_DIR/accessibility_settings_$TIMESTAMP.txt"
    adb shell "dumpsys accessibility" >> "$LOG_DIR/accessibility_services_$TIMESTAMP.txt"
    echo "Accessibility services analysis saved"
}

# Function to analyze permission grants
analyze_permission_grants() {
    echo "[$(date)] Analyzing permission grants..."
    adb shell "dumpsys permission" > "$LOG_DIR/permission_grants_$TIMESTAMP.txt"
    adb shell "dumpsys appops" >> "$LOG_DIR/permission_grants_$TIMESTAMP.txt"
    echo "Permission grants analysis saved"
}

# Function to analyze background processes
analyze_background_processes() {
    echo "[$(date)] Analyzing background processes..."
    adb shell "ps -A" > "$LOG_DIR/background_processes_$TIMESTAMP.txt"
    adb shell "dumpsys activity processes" >> "$LOG_DIR/background_processes_$TIMESTAMP.txt"
    echo "Background processes analysis saved"
}

# Function to generate comprehensive report
generate_comprehensive_report() {
    cat > "$LOG_DIR/comprehensive_report_$TIMESTAMP.txt" << EOF
# Comprehensive System Accessibility Analysis Report
# Generated: $(date)
# Device: $DEVICE_ID

## Analysis Categories:
1. System Features: accessibility_full_$TIMESTAMP.txt, window_features_$TIMESTAMP.txt, activity_features_$TIMESTAMP.txt
2. System Services: all_services_$TIMESTAMP.txt, service_analysis_$TIMESTAMP.txt
3. System Tools: system_tools_$TIMESTAMP.txt
4. All Programs: all_programs_$TIMESTAMP.txt, third_party_programs_$TIMESTAMP.txt, system_programs_$TIMESTAMP.txt
5. Software Versions: software_versions_$TIMESTAMP.txt
6. Firmware: firmware_full_$TIMESTAMP.txt
7. Third-Party Connections: third_party_connections_$TIMESTAMP.txt
8. Network Connections: network_connections_$TIMESTAMP.txt
9. Accessibility Services: accessibility_settings_$TIMESTAMP.txt, accessibility_services_$TIMESTAMP.txt
10. Permission Grants: permission_grants_$TIMESTAMP.txt
11. Background Processes: background_processes_$TIMESTAMP.txt

## Analysis Summary:
Review individual files for detailed information on each category.
This report provides a complete overview of the device's system accessibility,
services, tools, programs, software, firmware, and third-party connections.
EOF
    echo "Comprehensive report generated: $LOG_DIR/comprehensive_report_$TIMESTAMP.txt"
}

# Main execution
main() {
    if check_device; then
        analyze_system_features
        analyze_all_services
        analyze_system_tools
        analyze_all_programs
        analyze_software_versions
        analyze_firmware
        analyze_third_party_connections
        analyze_network_connections
        analyze_accessibility_services
        analyze_permission_grants
        analyze_background_processes
        generate_comprehensive_report
        echo "[$(date)] Comprehensive analysis complete. All logs saved to $LOG_DIR"
    else
        echo "[$(date)] Error: No device connected. Please enable ADB and authorize the device."
        exit 1
    fi
}

main
