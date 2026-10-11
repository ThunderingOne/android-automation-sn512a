# Firmware & Research Toolchain

**Device**: SN512A (AT&T Motivate Pro 2 5G) — Coosea
**SoC**: MediaTek MT6835 (Dimensity 6100+ family, `ro.hardware=mt6835`)
**Verified facts from device**:
- `ro.treble.enabled=true` → GSI-compatible
- `ro.build.ab_update=true` → A/B slots (seamless updates)
- `ro.product.cpu.abi=arm64-v8a` → ARM64 GSI images only
- `persist.sys.oem_unlock_allowed=0` → fastboot unlock blocked by carrier
- Android 15, SDK 35

## Toolchain (cloned into `tools/`)

| Repo | Purpose |
|------|---------|
| `bkerler/mtkclient` | MTK firmware read/write, seccfg unlock, partition dump |
| `davdiv/mtkclient` (branch `plstage`) | Required for `--plstage` flag (patched-preloader upload flow) |
| `davdiv/BraX3-repair-tools` | **MT6835-specific** patched preloader + DA |
| `cfig/Android_boot_image_editor` | Unpack/repack boot.img + vbmeta + dtbo |
| `RikkaApps/Shizuku` (APK in repo root, gitignored) | Semi-root service |

## Key MT6835 assets

- `tools/BraX3-repair-tools/preloader_k6835v1_64_patched.bin`
  — drops watchdog-reset + crypto-auth gates for MT6835V1
- `tools/BraX3-repair-tools/DA_BR_patched.bin`
  — drops `Security deny`/`img_auth_required` SBC gates on `mtk w`
- `tools/mtkclient/mtkclient/Loader/MTK_DA_V6.bin`
  — V6 protocol DA (MT6835 likely uses V6/preloader mode, not BROM buttons)

## Usage (davdiv patched flow)

```bash
cd tools/mtkclient          # must be on 'plstage' branch
python mtk.py r <partition> out.bin \
    --preloader ../BraX3-repair-tools/preloader_k6835v1_64_patched.bin \
    --loader    ../BraX3-repair-tools/DA_BR_patched.bin \
    --plstage --stock
```

Backup first: `seccfg`, `boot`, `init_boot`, `vbmeta`, `super`, `para`, `nvram`, `persist`, `proinfo`.

## Bootloader unlock path (SN512A)

1. `fastboot flashing unlock` → **fails** (`Unlock key verify failed`; same on SN512C per XDA — identical hardware per FCC 2A28USN512)
2. mtkclient `da seccfg unlock` via plstage flow → **the real path**
   - `lock_state=3`, `critical_lock_state=1` (seccfg V4)
3. After unlock: flash vbmeta with `--disable-verity --disable-verification`, then ARM64 A/B GSI (Android 15) — device is `treble + ab_update`.

## Known caveats (from BraX3/iode community, same SoC)

- Unlocking MTK A/B devices can corrupt slot_b → OTA/sideload updates fail; use SP Flash / fastboot full-image updates instead.
- `adb reboot edl` may reactivate preloader mode if hw buttons don't reach it.
- Windows needs MediaTek USB VCOM driver (MediaTek-SP-Driver-v5.2307).

## Custom ROM options for MT6835

- **iodéOS** (Android 15, privacy/deGoogled) — BraX3 build exists; device tree is BraX3-specific but proves the SoC runs custom AOSP.
- **AOSP/TrebleDroid GSI** (phhusson `treble_experimentations`) — generic ARM64; most realistic first flash.
- **Google Android 15 GSI** — with/without GMS variants.

## Carrier unlock (independent of bootloader)

- Official: https://att.com/deviceunlock (IMEI, eligibility-gated)
- No verified unofficial SIM-unlock found for SN512A.

## Research sources

- XDA SN512C unlock thread: unlock key verify failed, `unlock_ability=true`
- braxtech community: MT6835 unlock/slot-b bug confirmed
- FCC 2A28USN512: SN512A/C/CC identical hardware
- DevCheck: SN512C = MT6835, codename `sn512c`

---

## Verified live findings (subagent + direct)

- Fastboot-verified: `unlocked:no`, `secure:yes`, `unlock_ability is FALSE`, `sys.oem_unlock_allowed=0`
- PreLoader port reachable: `VID_0E8D&PID_2000` (COM3 when enumerated)
- **eSIM-only** — AT&T eSIM + Trustonic DLC rules + `DeviceLockControllerGoogle` (financing lock)
- `ADB_AUTOFIX` SYSTEM task on host: auto-binds WinUSB+GUID for MediaTek ADB on reconnect
- Shizuku v13.6.0 confirmed running (adb mode) — restart recipe in `device-watcher.sh`
- F-Droid installed OK; `install_non_market_apps=1`, `package_verifier_enable=0`

## Complete pipeline (all staged, armed)

```
device appears (adb)          device appears (preloader COM)
      |                              |
 adb reboot edl              mtkclient printgpt
   ↳ fails → reboot -p             |
      |                      backup 12 partitions → ./backups/
      └──────────► mtkclient ◄─────┘
                   da seccfg unlock → reset → fastboot
                         |
              fastboot --disable-verity --disable-verification flash vbmeta_a/b
              fastboot reboot fastboot (fastbootd)
              fastboot flash system_a gsi/aosp-arm64-ab-gapps.img
              fastboot -w → reboot
```

Staged assets:
- `gsi/aosp-arm64-ab-gapps.img` — Android 15 ARM64 A/B GSI **with Google apps + Play Integrity spoof** (ponces/treble_aosp v2025.05.13, r32 base)
- `backups/` — partition backups land here pre-unlock
- `tools/mtkclient` @ plstage + `tools/BraX3-repair-tools` k6835v1 patches
