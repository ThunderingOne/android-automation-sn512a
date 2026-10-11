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
            # Start Shizuku server — verified recipe (subagent-confirmed):
            # correct class is rikka.shizuku.server.ShizukuService; native libs are
            # deflated inside the APK so they must be pushed to /data/local/tmp/szlib
            echo "[$(date)] Starting Shizuku service..." >> "$LOG"
            LIBDIR=./shizuku-libs
            if [ -d "$LIBDIR" ]; then
                adb shell 'mkdir -p /data/local/tmp/szlib' >> "$LOG" 2>&1
                adb push "$LIBDIR/libadb.so" "$LIBDIR/librish.so" "$LIBDIR/libshizuku.so" /data/local/tmp/szlib/ >> "$LOG" 2>&1
            fi
            APKPATH=$(adb shell "pm path moe.shizuku.privileged.api" | tr -d '\r' | sed 's/package://')
            adb shell "setsid /system/bin/app_process -Djava.class.path=$APKPATH -Djava.library.path=/data/local/tmp/szlib /system/bin --nice-name=shizuku_server rikka.shizuku.server.ShizukuService < /dev/null > /data/local/tmp/srv.log 2>&1 &" >> "$LOG" 2>&1
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
