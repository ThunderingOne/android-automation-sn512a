#!/bin/bash
# Device Watcher — auto-runs full setup when device reconnects
LOG=./watcher.log
echo "[$(date)] Watcher started. Polling for device..." >> "$LOG"

while true; do
    STATE=$(adb get-state 2>/dev/null)
    if [ "$STATE" = "device" ]; then
        echo "[$(date)] DEVICE ONLINE" >> "$LOG"
        sleep 3  # let services settle

        # Verify auth
        adb devices | grep -w device >/dev/null || { sleep 2; continue; }

        echo "[$(date)] Running auto-setup..." >> "$LOG"

        # Re-verify core settings
        adb shell settings put global private_dns_mode hostname >> "$LOG" 2>&1
        adb shell settings put global private_dns_specifier dns.adguard.com >> "$LOG" 2>&1
        adb shell settings put global development_settings_enabled 1 >> "$LOG" 2>&1
        adb shell settings put global adb_enabled 1 >> "$LOG" 2>&1

        # Install Shizuku if present and not installed
        if [ -f ./shizuku.apk ]; then
            INSTALLED=$(adb shell pm list packages 2>/dev/null | grep -c shizuku)
            if [ "$INSTALLED" = "0" ]; then
                echo "[$(date)] Installing Shizuku..." >> "$LOG"
                adb install -r ./shizuku.apk >> "$LOG" 2>&1
            fi
            # Start Shizuku service directly via app_process + ServiceStarter
            # (verified working on SN512A — starts shizuku_server as shell uid 2000)
            echo "[$(date)] Starting Shizuku service..." >> "$LOG"
            APKPATH=$(adb shell "pm path moe.shizuku.privileged.api" | tr -d '\r' | sed 's/package://')
            adb shell "/system/bin/app_process -Djava.class.path=$APKPATH /system/bin --nice-name=shizuku_starter moe.shizuku.starter.ServiceStarter" >> "$LOG" 2>&1
            sleep 3
            adb shell "ps -A | grep shizuku_server" >> "$LOG" 2>&1
        fi

        # Run comprehensive tests
        echo "[$(date)] Running comprehensive tests..." >> "$LOG"
        bash ./comprehensive-testing.sh >> "$LOG" 2>&1

        echo "[$(date)] AUTO-SETUP COMPLETE" >> "$LOG"
        exit 0
    fi
    sleep 3
done
