#!/bin/bash
# Unlock Hunter — watches for SN512A in adb or preloader mode and acts fast
PY="/c/Users/Terrell/AppData/Local/Programs/Python/Python312/python.exe"
MTK="/c/Users/Terrell/android-automation/tools/mtkclient/mtk.py"
PL="/c/Users/Terrell/android-automation/tools/BraX3-repair-tools/preloader_k6835v1_64_patched.bin"
DA="/c/Users/Terrell/android-automation/tools/BraX3-repair-tools/DA_BR_patched.bin"
BK="/c/Users/Terrell/android-automation/backups"
LOG="$BK/hunter.log"
mkdir -p "$BK"

edl_issued=0
echo "[$(date)] Hunter armed. Polling adb + preloader..." | tee "$LOG"

while true; do
    # State A: device in adb mode → send it to preloader.
    #   attempt 1: adb reboot edl   (works if edl hook exists)
    #   attempt 2: adb shell reboot -p  (power off; MTK preloader enumerates on USB)
    #   attempt 3+: wait for manual preloader (power off + cable)
    if adb get-state 2>/dev/null | grep -q device; then
        if [ $edl_issued -eq 0 ]; then
            echo "[$(date)] ADB online — 'adb reboot edl'" | tee -a "$LOG"
            adb reboot edl >> "$LOG" 2>&1
            edl_issued=1
            sleep 15
            # if device came back to adb (edl unsupported), escalate to power-off
            if adb get-state 2>/dev/null | grep -q device; then edl_issued=2; fi
            continue
        elif [ $edl_issued -eq 2 ]; then
            echo "[$(date)] edl unsupported — powering off (reboot -p) for preloader" | tee -a "$LOG"
            adb shell 'reboot -p' >> "$LOG" 2>&1 || adb shell 'setprop sys.powerctl shutdown' >> "$LOG" 2>&1
            edl_issued=3
            sleep 8
            continue
        else
            sleep 5; continue
        fi
    fi

    # State B: MTK device present (COM port OR raw UsbDk) → run mtkclient NOW
    MTKPORT=$(powershell -NoProfile -Command \
      "(Get-PnpDevice -Class Ports -PresentOnly | Where-Object { \$_.InstanceId -match 'VID_0E8D' } | Select -First 1 -Expand FriendlyName) -replace '.*\((COM[0-9]+)\).*','\$1'" 2>/dev/null | tr -d '\r')
    RAWMTK=$(powershell -NoProfile -Command \
      "(Get-PnpDevice -PresentOnly | Where-Object { \$_.InstanceId -match 'VID_0E8D' } | Select -First 1 -Expand FriendlyName)" 2>/dev/null | tr -d '\r')
    if [[ "$MTKPORT" =~ ^COM[0-9]+$ ]] || [ -n "$RAWMTK" ]; then
        echo "[$(date)] MTK device present (port=$MTKPORT raw=$RAWMTK) — launching mtkclient" | tee -a "$LOG"

        # 1) GPT read test — try UsbDk auto-detect first (better handshake), fall back to COM
        if [ -n "$RAWMTK" ] && [ -z "$MTKPORT" ]; then
            "$PY" "$MTK" printgpt --loader "$DA" 2>&1 | tee -a "$LOG" | tail -50
        else
            "$PY" "$MTK" printgpt --serialport "$MTKPORT" --loader "$DA" 2>&1 | tee -a "$LOG" | tail -50
        fi

        # 2) backup critical partitions
        for P in seccfg boot_a boot_b init_boot_a init_boot_b vbmeta_a vbmeta_b para nvram persist proinfo frp; do
            "$PY" "$MTK" r "$P" "$BK/$P.bin" --serialport "$MTKPORT" --loader "$DA" >> "$LOG" 2>&1 \
                && echo "[+] $P backed up" | tee -a "$LOG" \
                || echo "[-] $P failed" | tee -a "$LOG"
        done

        # 3) the unlock
        echo "[$(date)] Executing da seccfg unlock..." | tee -a "$LOG"
        "$PY" "$MTK" da seccfg unlock --serialport "$MTKPORT" --loader "$DA" 2>&1 | tee -a "$LOG" | tail -25

        # 4) reset → device lands in fastboot for unlock confirmation
        "$PY" "$MTK" reset --serialport "$MTKPORT" --loader "$DA" >> "$LOG" 2>&1
        echo "[$(date)] Unlock done. Waiting for fastboot to disable verity + flash GSI..." | tee -a "$LOG"

        # 5) fastboot stage — disable AVB then flash GSI to system_a (fastbootd)
        for i in $(seq 1 60); do
            fastboot devices 2>/dev/null | grep -q fastboot && break; sleep 3
        done
        if fastboot devices 2>/dev/null | grep -q fastboot; then
            echo "[$(date)] Fastboot up — disabling verified boot" | tee -a "$LOG"
            fastboot --disable-verity --disable-verification flash vbmeta_a "$BK/vbmeta_a.bin" >> "$LOG" 2>&1
            fastboot --disable-verity --disable-verification flash vbmeta_b "$BK/vbmeta_b.bin" >> "$LOG" 2>&1
            GSI=$(ls gsi/*.img 2>/dev/null | head -1)
            if [ -n "$GSI" ]; then
                echo "[$(date)] Entering fastbootd + flashing $GSI" | tee -a "$LOG"
                fastboot reboot fastboot >> "$LOG" 2>&1; sleep 8
                fastboot flash system_a "$GSI" >> "$LOG" 2>&1
                fastboot -w >> "$LOG" 2>&1
                fastboot reboot >> "$LOG" 2>&1
            else
                echo "[$(date)] No GSI image staged — leaving stock" | tee -a "$LOG"
                fastboot reboot >> "$LOG" 2>&1
            fi
        else
            echo "[$(date)] No fastboot seen — device may need manual boot to bootloader" | tee -a "$LOG"
        fi

        echo "[$(date)] HUNTER COMPLETE" | tee -a "$LOG"
        exit 0
    fi

    sleep 2
done
