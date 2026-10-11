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
    # State A: device in adb mode → send it to preloader via edl (once)
    if [ $edl_issued -eq 0 ] && adb get-state 2>/dev/null | grep -q device; then
        echo "[$(date)] ADB online — issuing 'adb reboot edl'" | tee -a "$LOG"
        adb reboot edl >> "$LOG" 2>&1 || adb reboot bootloader >> "$LOG" 2>&1
        edl_issued=1
        sleep 4
        continue
    fi

    # State B: MTK port present → run mtkclient NOW (handshake window)
    MTKPORT=$(powershell -NoProfile -Command \
      "(Get-PnpDevice -Class Ports -PresentOnly | Where-Object { \$_.InstanceId -match 'VID_0E8D' } | Select -First 1 -Expand FriendlyName) -replace '.*\((COM[0-9]+)\).*','\$1'" 2>/dev/null | tr -d '\r')
    if [[ "$MTKPORT" =~ ^COM[0-9]+$ ]]; then
        echo "[$(date)] MTK port $MTKPORT — launching mtkclient" | tee -a "$LOG"

        # 1) GPT read test
        "$PY" "$MTK" printgpt --serialport "$MTKPORT" --loader "$DA" 2>&1 | tee -a "$LOG" | tail -50

        # 2) backup critical partitions
        for P in seccfg boot_a boot_b init_boot_a init_boot_b vbmeta_a vbmeta_b para nvram persist proinfo frp; do
            "$PY" "$MTK" r "$P" "$BK/$P.bin" --serialport "$MTKPORT" --loader "$DA" >> "$LOG" 2>&1 \
                && echo "[+] $P backed up" | tee -a "$LOG" \
                || echo "[-] $P failed" | tee -a "$LOG"
        done

        # 3) the unlock
        echo "[$(date)] Executing da seccfg unlock..." | tee -a "$LOG"
        "$PY" "$MTK" da seccfg unlock --serialport "$MTKPORT" --loader "$DA" 2>&1 | tee -a "$LOG" | tail -25

        # 4) reset
        "$PY" "$MTK" reset --serialport "$MTKPORT" --loader "$DA" >> "$LOG" 2>&1
        echo "[$(date)] HUNTER COMPLETE" | tee -a "$LOG"
        exit 0
    fi

    sleep 2
done
