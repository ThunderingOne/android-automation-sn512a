#!/bin/bash
# Bootloader Unlock Runbook — SN512A / MT6835
# Phase 1: Backup partitions  |  Phase 2: seccfg unlock  |  Phase 3: verify
PY="/c/Users/Terrell/AppData/Local/Programs/Python/Python312/python.exe"
MTK="/c/Users/Terrell/android-automation/tools/mtkclient/mtk.py"
PL="/c/Users/Terrell/android-automation/tools/BraX3-repair-tools/preloader_k6835v1_64_patched.bin"
DA="/c/Users/Terrell/android-automation/tools/BraX3-repair-tools/DA_BR_patched.bin"
BK="/c/Users/Terrell/android-automation/backups"
LOG="$BK/unlock.log"
mkdir -p "$BK"

echo "[$(date)] === SN512A Bootloader Unlock ===" | tee "$LOG"

# Step 0 — device must be in preloader/BROM.
# Try adb reboot edl if booted; else user powers off + plugs in.
if adb get-state 2>/dev/null | grep -q device; then
    echo "[*] Device online — rebooting into preloader (adb reboot edl)" | tee -a "$LOG"
    adb reboot edl 2>&1 | tee -a "$LOG"
    sleep 5
fi

# Wait for MTK preloader COM port (VID_0E8D&PID_2000)
echo "[*] Waiting for preloader port (max 120s)..." | tee -a "$LOG"
for i in $(seq 1 40); do
    PORT=$(powershell -NoProfile -Command \
      "Get-PnpDevice -Class Ports | Where-Object { \$_.FriendlyName -match 'MediaTek' } | Select-Object -First 1 -ExpandProperty FriendlyName" 2>/dev/null | tr -d '\r')
    [ -n "$PORT" ] && { echo "[+] Found: $PORT" | tee -a "$LOG"; break; }
    sleep 3
done

# Step 1 — print GPT (validates connection before writes)
echo "[*] printgpt (connectivity check)..." | tee -a "$LOG"
"$PY" "$MTK" printgpt --preloader "$PL" --loader "$DA" --plstage --stock 2>&1 | tee -a "$LOG" | tail -60

# Step 2 — backup critical partitions
echo "[*] Backing up partitions..." | tee -a "$LOG"
for P in seccfg boot_a boot_b init_boot_a init_boot_b vbmeta_a vbmeta_b para nvram persist proinfo frp; do
    "$PY" "$MTK" r "$P" "$BK/$P.bin" --preloader "$PL" --loader "$DA" --plstage --stock \
        >> "$LOG" 2>&1 && echo "  [+] $P" | tee -a "$LOG" || echo "  [-] $P failed/skipped" | tee -a "$LOG"
done

# Step 3 — the unlock
echo "[*] da seccfg unlock ..." | tee -a "$LOG"
"$PY" "$MTK" da seccfg unlock --preloader "$PL" --loader "$DA" --plstage --stock 2>&1 | tee -a "$LOG" | tail -25

# Step 4 — reset and verify
echo "[*] Resetting device..." | tee -a "$LOG"
"$PY" "$MTK" reset --preloader "$PL" --loader "$DA" --plstage --stock 2>&1 | tail -3
sleep 10
adb wait-for-device 2>/dev/null
adb shell 'getprop ro.boot.verifiedbootstate; getprop sys.oem_unlock_allowed' | tee -a "$LOG"
echo "[$(date)] Done. See $LOG" | tee -a "$LOG"
