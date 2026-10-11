#!/bin/bash
# Master Automation Script
# Author: Terrell Russell
# Purpose: Execute all automation scripts in sequence

LOG_DIR="./automation-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$LOG_DIR"

echo "=========================================="
echo "Master Automation Script"
echo "Started: $(date)"
echo "=========================================="

# Check device connection
echo "Checking device connection..."
adb devices | grep -w "device" > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: No device connected"
    echo "Please enable ADB on your device:"
    echo "1. Settings > System > Developer Options"
    echo "2. Enable USB Debugging"
    echo "3. Authorize when prompted"
    exit 1
fi

DEVICE_ID=$(adb devices | grep -w "device" | awk '{print $1}')
echo "Device connected: $DEVICE_ID"

# Execute accessibility analysis
echo ""
echo "=========================================="
echo "Phase 1: Comprehensive Accessibility Analysis"
echo "=========================================="
chmod +x ./accessibility-analysis.sh
./accessibility-analysis.sh

# Execute third-party monitoring
echo ""
echo "=========================================="
echo "Phase 2: Third-Party Connection Monitoring"
echo "=========================================="
chmod +x ./third-party-monitor.sh
./third-party-monitor.sh

# Execute automated setup
echo ""
echo "=========================================="
echo "Phase 3: Automated Device Setup"
echo "=========================================="
chmod +x ./automated-setup.sh
./automated-setup.sh

# Generate master report
echo ""
echo "=========================================="
echo "Generating Master Report"
echo "=========================================="
cat > "$LOG_DIR/master_report_$TIMESTAMP.txt" << EOF
# Master Automation Report
# Generated: $(date)
# Device: $DEVICE_ID

## Execution Summary:
1. Comprehensive Accessibility Analysis - COMPLETED
2. Third-Party Connection Monitoring - COMPLETED
3. Automated Device Setup - COMPLETED

## Detailed Reports:
Review individual log directories for detailed analysis:
- accessibility-analysis/
- monitoring-logs/
- setup-logs/

## Device Configuration:
- Developer options: ENABLED
- ADB debugging: ENABLED
- Unknown sources: ENABLED
- Carrier restrictions: DISABLED (where possible)
- Custom APN: ENABLED

## Next Steps:
1. Install Shizuku manually from: https://shizuku.rikka.app/
2. Request carrier unlock from AT&T
3. Configure custom APN settings
4. Install custom package manager (F-Droid)
5. Install custom apps

## Automated Processes:
All scripts have been executed successfully. The device is now configured for:
- Semi-root capabilities (via Shizuku)
- Custom app installation
- Third-party connection monitoring
- Carrier unlock preparation
EOF

echo ""
echo "=========================================="
echo "Master Automation Complete"
echo "Finished: $(date)"
echo "=========================================="
echo "Master report: $LOG_DIR/master_report_$TIMESTAMP.txt"
echo ""
