#!/bin/bash
# GhostLock (CVE-2026-43499) readiness probe for SN512A.
# Non-destructive: only reads device state to validate exploit prerequisites.
# Kernel: 5.15.197-android13-8-00005-g2d8ad9139b89 (GKI 2026-03_r2, vulnerable:
# rtmutex fix landed in 5.15.212; we are 5.15.197).

cd "$(dirname "$0")"
R="ghostlock-probe-$(date +%Y%m%d-%H%M%S).log"
mkdir -p unlock-logs

{
echo "=== GhostLock readiness probe $(date) ==="
echo "--- kernel ---"
adb shell 'uname -r'
echo "--- vulnerable version check: need <5.15.212 on 5.15.y ---"

echo "--- /proc/iomem (verify P0_PHYS 0x40000000 / kernel load 0x44000000) ---"
adb shell 'cat /proc/iomem 2>/dev/null | head -30'

echo "--- tracefs sched_blocked_reason event id (expect ~108) ---"
adb shell 'cat /sys/kernel/tracing/events/sched/sched_blocked_reason/id 2>/dev/null || cat /sys/kernel/debug/tracing/events/sched/sched_blocked_reason/id 2>/dev/null'

echo "--- BTF availability ---"
adb shell 'ls -la /sys/kernel/btf/vmlinux 2>/dev/null'

echo "--- kallsyms readability (kptr_restrict) ---"
adb shell 'cat /proc/sys/kernel/kptr_restrict 2>/dev/null; head -3 /proc/kallsyms'

echo "--- seccomp/nnp status of shell ---"
adb shell 'grep -E "NoNewPrivs|Seccomp" /proc/self/status'

echo "--- CPU features (PAC/SVE/MTE runtime) ---"
adb shell 'grep -E "Features|paca|sve|mte" /proc/cpuinfo 2>/dev/null | sort -u | head -5'

echo "--- MTE state ---"
adb shell 'cat /sys/kernel/debug/mte/stats 2>/dev/null; getprop ro.arm64.memtag.bootctl 2>/dev/null; getprop persist.arm64.memtag.default 2>/dev/null'

echo "--- futex PI reachable (syscall smoke test) ---"
adb shell 'cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null; echo "futex test deferred to payload"'

echo "--- current selinux state ---"
adb shell 'getenforce; cat /proc/self/attr/current'
} 2>&1 | tee "unlock-logs/$R"

echo "saved: unlock-logs/$R"
