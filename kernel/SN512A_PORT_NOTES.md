# SN512A GhostLock Port Notes

Kernel: `5.15.197-android13-8-00005-g2d8ad9139b89`
= certified GKI `android13-5.15-2026-03_r2` (commit 2d8ad9139b89, CI build 15063902)
vmlinux: `C:\Users\Terrell\android-automation\kernel\vmlinux` (aarch64, DWARF + .BTF)
KIMAGE_TEXT_BASE: `0xffffffc008000000`

Analysis scripts left in `kernel/`: `disasm_probe.py`, `dump_range.py`,
`dwarf_structs.py`, `extract_btf.py` (reused), `cfijt.txt` (CFI jump-table map).

## Tracefs slide anchors (sched_blocked_reason)

`caller` field = `__get_wchan(task)` — verified: `bl __get_wchan` inside
`trace_event_raw_event_sched_blocked_reason` at +0x144 (and
`perf_trace_sched_blocked_reason` +0x13c). Anchor = first return address
outside `__sched_text` = `[0xffffffc009775438, 0xffffffc009783f28)` in this
image.

| Field | iQOO | SN512A | Derivation | Confidence |
|---|---|---|---|---|
| `SLIDE_TRACEFS_WORKER_CALLER_OFF` | 0x194758 | **0x17934c** | `worker_thread`: `bl schedule` @ 0xffffffc008179348 → ret 0xffffffc00817934c. Sole `bl schedule` in the function (idle-worker sleep path, reached via `b worker_thread+0x70` from `worker_enter_idle`). | verified-by-disasm |
| `SLIDE_TRACEFS_VFORK_CALLER_OFF` | 0x14d098 | **0x131fb4** | `wait_for_vfork_done`: `bl wait_for_common` @ 0xffffffc008131fb0 → ret 0xffffffc008131fb4. `wait_for_common` (0xffffffc009777444) is inside __sched_text so the unwind lands in wait_for_vfork_done itself (same landing-frame model as iQOO). | verified-by-disasm |
| `SLIDE_TRACEFS_SCHED_CALLER_OFF` | 0x178e52c | **0x17762cc** | `schedule`: single `bl __schedule` @ 0xffffffc0097762c8 → ret 0xffffffc0097762cc (PAC-unwind fallback anchor). | verified-by-disasm |
| `SLIDE_TRACEFS_EVENT_ID` | 108 | 108 | Trace event IDs are assigned at boot by registration order; identical GKI family → expected same. | needs-ondevice-check (`cat /sys/kernel/tracing/events/sched/sched_blocked_reason/id`) |

Secondary (unwired) worker caller: `worker_thread` also contains
`bl schedule_timeout(250)` @ 0xffffffc00817948c → wchan 0x179490 for that
rare polling path. Not added to the anchor array; available if the primary
worker anchor ever misses.

## Stack-write geometry

Depth = bytes below the C syscall-entry SP; a local at `sp+N` is at
depth `frame_total - N`.

### Stale futex waiter (shared by both writers)

`__arm64_sys_futex(sub sp,#0xa0)` → `bl do_futex(sub sp,#0x140)` →
`bl futex_wait_requeue_pi(sub sp,#0x1b0)`. `rt_mutex_wait_proxy_lock` is
**inlined**; `rt_waiter` is passed as `add x3, sp, #0x98` to
`rt_mutex_slowlock_block` / `try_to_take_rt_mutex` / `remove_waiter`.
Stale-waiter (tree_entry) depth = 0xa0+0x140+0x1b0 − 0x98 = **0x2f8**
(identical to iQOO).

### MCAST carrier

Chain verified end-to-end for `socket(AF_INET6, SOCK_DGRAM)`:
`inet6_dgram_ops+0x70 = sock_common_setsockopt.cfi_jt`,
`udpv6_prot+0x48 = udpv6_setsockopt.cfi_jt`,
`udpv6_setsockopt+0xbc = bl do_ipv6_setsockopt` (level == IPPROTO_IPV6).

| Hop | Frame |
|---|---|
| `__arm64_sys_setsockopt` | 0x10 (`stp x29,x30,[sp,#-0x10]!`) |
| `__sys_setsockopt` | 0x80 (`sub`) |
| `sock_common_setsockopt` | 0x40 (`sub`; `blr` sk->sk_prot->setsockopt) |
| `udpv6_setsockopt` | 0x50 (`sub`; **`bl`**, not a tail call) |
| `do_ipv6_setsockopt` | 0x60 + 0x260 = 0x2c0 |

Native `group_source_req greqs` = `sp+0x40` (0x108-byte `_copy_from_user`
@ do_ipv6_setsockopt+0x168; the 0x104 copy at `sp+0x148` is the compat
path — `tbnz w24,#0` selects). greqs depth = 0x3e0 − 0x40 = **0x3a0**.

| Field | iQOO | SN512A | Confidence |
|---|---|---|---|
| `MCAST_WAITER_OFF` | 0x98 | **0xa8** (0x3a0 − 0x2f8) | verified-by-disasm; fits carrier (0xa8+0x58=0x100 ≤ 0x108) |

### SIGRETURN carrier

`__arm64_sys_rt_sigreturn(0x50)` → `bl restore_sigframe(0x50)` →
`bl restore_sve_fpsimd_context(0x40+0x230)` (direct call @
restore_sigframe+0x6fc; parse_user_sigctx inlined). The `fpsimd`
local is at `sp+0x10` (`memset(sp+0x10,0,0x210)` then
`__arch_copy_from_user(sp+0x10,..,0x200)`). Depth = 0x50+0x50+0x270−0x10
= **0x300** (identical to iQOO). Grown SVE Z-reg copy target =
`current->thread.sve_state` (`ldr x21,[x22,#0x1060]`, heap) — same as iQOO.

| Field | iQOO | SN512A | Confidence |
|---|---|---|---|
| `SIGRETURN_FPSIMD_WAITER_OFF` | 0x08 | **0x08** (0x300 − 0x2f8) | verified-by-disasm |
| `SIGRETURN_SVE_WAITER_OFF` | 0x8 | **0x8** | carried-over (SVE record lands on heap, kept harmless) |
| `SIGRETURN_SVE_ZREGS_OFF` | 0x10 | 0x10 | carried-over (user-side buffer layout, kernel-agnostic) |

## Struct offsets

task_struct / mm_struct are FWD-only in .BTF → verified against DWARF
(first full def, CU 25; size 0x1200 / 0x3e0).

| Field | iQOO | SN512A (DWARF) | Confidence |
|---|---|---|---|
| task_struct.usage (`FAKE_TASK_USAGE_OFF`) | 0x38 | 0x38 | verified-DWARF |
| task_struct.prio | 0x7c | 0x7c | verified-DWARF |
| task_struct.normal_prio | 0x84 | 0x84 | verified-DWARF |
| task_struct.sched_task_group (`FAKE_TASK_TASK_GROUP_OFF`) | 0x400 | 0x400 | verified-DWARF |
| task_struct.pi_lock | 0x884 | 0x884 | verified-DWARF |
| task_struct.pi_waiters | 0x898 | 0x898 | verified-DWARF |
| task_struct.pi_top_task | 0x8a8 | 0x8a8 | verified-DWARF |
| task_struct.pi_blocked_on | 0x8b0 | 0x8b0 | verified-DWARF |
| task_struct.real_cred | 0x790 | 0x790 | verified-DWARF |
| task_struct.cred | 0x798 | 0x798 | verified-DWARF |
| task_struct.{pid,tgid,real_parent,atomic_flags,comm,tasks,mm,seccomp,thread} | — | 0x5d8, 0x5dc, 0x5e8, 0x598, 0x7a8, 0x4d0, 0x520, 0x860, 0xdc0 | verified-DWARF (info only) |
| mm_struct.owner | — | 0x348 (size 0x3e0 ≤ MM_STRUCT_SZ 0x400) | verified-DWARF |
| rt_mutex_waiter {tree_entry,pi_tree_entry,task,lock,wake_state,prio,deadline,ww_ctx} size 0x58 | {0,0x18,0x30,0x38,0x40,0x44,0x48,0x50} | identical | verified-BTF |
| workqueue_struct.dfl_pwq (`WQ_DFL_PWQ_OFF`) | 0xb0 | 0xb0 | verified-BTF |
| pool_workqueue {pool,wq,work_color,refcnt,nr_in_flight,nr_active,max_active} | {0,8,0x10,0x18,0x1c,0x5c,0x60} | identical | verified-BTF |
| worker_pool {worklist,nr_idle} | {0x20,0x34} | identical | verified-BTF |
| work_struct {data,entry,func} | {0,8,0x18} | identical | verified-BTF |
| configfs_buffer {page,needs_read_fill,bin_buffer,bin_buffer_size,cb_max_size} | {0x10,0x50,0x58,0x60,0x64} | identical | verified-BTF |
| file_operations {owner,llseek,read,write,read_iter,write_iter,unlocked_ioctl,compat_ioctl,mmap,open,release,splice_read,show_fdinfo} | {0,8,0x10,0x18,0x20,0x28,0x50,0x58,0x60,0x70,0x80,0xc8,0xe0} | identical | verified-BTF |
| struct page (size 0x40; unions @0x8/@0x30 → compound_head 0x8, slab_cache 0x18, page_type 0x30) | 0x40/0x08/0x18/0x30 | identical | verified-BTF |

## Carried-over / unchanged

| Field | Value | Note |
|---|---|---|
| `P0_PHYS_OFFSET` / `P0_KERNEL_PHYS_LOAD` | 0x40000000 / 0x44000000 | standard MTK; needs-ondevice-check vs /proc/iomem |
| `KMALLOC_CGROUP_TYPE` / `KMALLOC_CACHE_TYPES` | 1 / 3 | CONFIG_MEMCG_KMEM=y → cg/rcl/normal caches; same android13-8 family rule as iQOO |
| `MM_STRUCT_SZ` | 0x400 | mm_struct real size 0x3e0 (DWARF) — allocation size, keep |
| `SLIDE_TRACEFS_EVENT_ID` | 108 | needs-ondevice-check |
| all `*_OFF` symbol offsets (INIT_TASK …) | as previously re-patched | untouched — extracted from our System.map |

## Deltas vs iQOO that matter

1. All three tracefs anchors shifted (different build → different text layout).
2. MCAST carrier chain goes through `udpv6_setsockopt` (0x50 frame, real
   `bl`) rather than iQOO's ipv6_setsockopt hop; net result MCAST_WAITER_OFF
   0x98 → **0xa8**. Still fits the 0x108 carrier (0x100 used).
3. Everything else (waiter depth 0x2f8, fpsimd depth 0x300, all struct
   offsets, KMI-frozen task_struct region) is identical to iQOO.

## 2026-10-11 — ROOT + KernelSU COMPLETE

Exploit chain fully working (first attempt with MCAST writer):
- `STACK_WRITER=1` (MCAST) — MT6835 is Cortex-A76/A55 (ARMv8.2-A), NO SVE.
  The sigreturn/FPSIMD writer's forged SVE record is rejected (-EINVAL badframe)
  by parse_user_sigframe → write never lands → deterministic `cfi misc_fops
  mismatch` step=4 (and one kernel panic in rb_erase fixup). Do not use sigreturn.
- `ASHMEM_MISC_FOPS = 0x02ca1e00` — .fops slot (+0x10) of ashmem_misc miscdevice
  @0x02ca1df0. ASHMEM_FOPS=0x02109988.
- `configfs_read_once_raw` + ERANGE→physmap-alias fallback in util.c — canonical
  .fops addrs can't always encode in `page = target - pos` (zero byte) → read the
  slot via the direct-map alias (data_direct_addr, 0xffffff80...) instead.

Correct run order (README): `cve-2026-43499-root --run-payload <app.so> <root> <log>`
then `cve-2026-43499-root --late-load`. Result: uid 0, SELinux permissive→KSU
restores Enforcing, KernelSU LKM live (version=32601, uapi=2).

### Post-late-load su access (resolved)
- temp_su daemon socket (/data/local/tmp/temp_su.sock) becomes UNREACHABLE after
  ksud late-load: created pre-KSU under kernel-context label; once KSU sepolicy
  loads + enforcing=1, shell domain gets EACCES on getattr/connectto. Expected —
  daemon is bootstrap transport only, not the product su.
- Working root paths after KernelSU manager (me.weishu.kernelsu v3.3.0) install
  (auto-rooted by LKM signature check):
    * Manager → Settings → **ADB Root** → adbd restarts uid=0 → `adb shell` = root
      (context=u:r:ksu:s0). THIS IS THE FASTEST PATH.
    * Classic SU (enabled by default): /system/bin/su overlay appears only for
      allowlisted domains; from the ksu-domain adb shell, `su` resolves and works.
    * `/data/adb/ksu/bin/` has busybox, ksud, resetprop, bootctl.
- ksud from shell (non-root) can only parse/validate (sepolicy patch is a no-op);
  all real control requires the manager or a root context.

### Root grants + Termux (verified working)
- KSU auto-seeded allowlist: moe.shizuku.privileged.api, org.fdroid.fdroid,
  com.android.shell — all with allow_su, context u:r:ksu:s0.
- .allowlist format: magic "USK\x7f" + u32 version(=4) + N x 0x310-byte records:
  [u32 recver=4][package 256B][uid u32][4 flags u32][pad][se_context 32B]
  [pad][u32][u32]. File is persistence only — live kernel list is updated via
  manager (prctl CMD_SET_APP_PROFILE); file edits apply on next late-load.
- Termux (com.termux v0.118.3 github-debug arm64) granted via manager
  Superuser tab -> app -> Superuser toggle -> `su -c id` in Termux = uid 0.
- Termux/RUN_COMMAND permission exists for future scripting:
  pm grant com.termux com.termux.permission.RUN_COMMAND (untested).

### KernelSU modules installed (session: LKM-loaded, overlays bind at post-fs-data)
- busybox-ndk v1.36.1, nano-ndk v9.2, AdGuardDNS4Magisk v2.7f,
  ssh v0.16 (OpenSSH 9.3 + rsync — sshd listening :22 after `ksud services`),
  rclone.mount v1.14 (needs /sdcard/.rclone/rclone.conf), fdroid-priv-ext (2120).
- SSH keys: /data/ssh/root/.ssh/authorized_keys + /data/ssh/shell/.ssh/authorized_keys
  (local private key: devin-ssh-key in repo dir — no passphrase).
- Module install via: adb push zip; /data/adb/ksud module install <zip>;
  then `ksud post-fs-data` (finalize extraction) + `ksud services` (start service.sh).
- customize.sh "can't create /proc/self/fd/0" warnings are benign (installer quirk).
- /system overlays only materialize after a re-root + late-load cycle;
  binaries are directly runnable from /data/adb/modules/<id>/ meanwhile.
