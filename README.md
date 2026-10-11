# Android Device Automation Framework

**Author**: Terrell Russell
**Purpose**: Comprehensive system accessibility analysis, third-party connection monitoring, and automated device setup including unlock methods

## Overview

This framework provides automated tools to:
1. Analyze all system features, services, tools, programs, software, and firmware
2. Monitor and audit third-party connections
3. Automate device setup for semi-root capabilities and custom app support
4. Prepare device for carrier unlock and multi-provider support
5. Implement bootloader unlock methods (AT&T official, MTKClient, ChimeraTool)
6. Provide semi-root alternatives (Shizuku, ADB over network)

## Prerequisites

- ADB installed and configured
- Android device with ADB debugging enabled
- Git Bash or similar shell environment (for .sh scripts)
- Windows Command Prompt (for .bat script)
- Python 3.8+ (for MTKClient method)
- MediaTek USB drivers (for bootloader unlock)

## Quick Start

### Step 1: Enable ADB on Device
1. Navigate to **Settings > System > Developer Options**
2. Enable **USB Debugging**
3. Connect device via USB
4. Accept authorization prompt on device

### Step 2: Run Master Automation

**Windows (Command Prompt):**
```cmd
cd C:\Users\Terrell\android-automation
master-automation.bat
```

**Windows (Git Bash):**
```bash
cd /c/Users/Terrell/android-automation
./improved-master-automation.sh
```

## Scripts Description

### 1. `accessibility-analysis.sh`
Comprehensive analysis of:
- System features and accessibility services
- All system services (connectivity, telephony, wifi, bluetooth, location, etc.)
- System tools (binaries in /system/bin, /system/xbin, /vendor/bin)
- All programs (system and third-party packages)
- Software versions and build properties
- Firmware information
- Third-party connections and permissions
- Network connections
- Background processes

**Output**: `accessibility-analysis/` directory with detailed analysis files

### 2. `third-party-monitor.sh`
Monitoring and auditing of:
- All system services
- Accessibility services
- Network connections and policies
- All installed packages
- Third-party app connections (GMS, GSF, Facebook, etc.)
- App operations and permissions
- Firmware details
- Carrier services
- All third-party app permissions

**Output**: `monitoring-logs/` directory with monitoring data

### 3. `automated-setup.sh`
Automated device configuration:
- Enable developer options
- Enable ADB debugging
- Enable unknown sources (sideloading)
- Install Shizuku (semi-root)
- Check carrier lock status
- Enable browser installation
- Disable carrier restrictions
- Verify DNS configuration
- Check bootloader status
- Grant additional permissions
- Setup custom APN configuration

**Output**: `setup-logs/` directory with setup details

### 4. `unlock-methods.sh` (NEW)
Bootloader and carrier unlock methods:
- AT&T official carrier unlock instructions
- MTKClient bootloader unlock preparation
- ChimeraTool commercial unlock option
- Exploit options analysis
- Semi-root alternatives (Shizuku, ADB over network)
- Fastboot unlock test
- Comprehensive unlock instructions

**Output**: `unlock-logs/` directory with unlock methods

### 5. `improved-master-automation.sh` (NEW)
Enhanced master script that executes all automation including unlock methods:
1. Accessibility analysis
2. Third-party monitoring
3. Automated setup
4. Bootloader & carrier unlock methods

**Output**: `automation-logs/` directory with master report

## Unlock Methods Implemented

### Method 1: Official AT&T Carrier Unlock
- **Purpose**: Use device with other carriers (T-Mobile, Verizon, etc.)
- **Method**: Submit unlock request at https://att.com/deviceunlock
- **Requirements**: 60+ days (postpaid) or 6+ months (prepaid) on AT&T
- **Time**: 24-48 hours for approval
- **Result**: 16-digit unlock code
- **Safety**: Official method, no warranty void
- **Risk**: Low

### Method 2: MTKClient Bootloader Unlock
- **Purpose**: Install custom ROM, gain root access
- **Method**: BROM exploit for MediaTek chipset (MT6835)
- **Requirements**: Python 3.8+, MediaTek USB drivers
- **Time**: 5-10 minutes
- **Result**: Unlocked bootloader
- **Safety**: Void warranty, erases all data
- **Risk**: Medium (may brick device if interrupted)

**Commands**:
```bash
# Boot to BROM mode (Vol Up + Vol Down + Power, then USB)
python mtk.py e metadata,userdata,md_udc
python mtk.py da seccfg unlock
```

### Method 3: ChimeraTool (Commercial)
- **Purpose**: Professional bootloader unlock and device repair
- **Method**: Commercial tool for AT&T Motivate
- **Requirements**: Credits/license, device drivers
- **Time**: Varies
- **Result**: Unlocked bootloader, IMEI repair, firmware update
- **Safety**: Paid service, professional support
- **Risk**: Low-Medium

### Method 4: Fastboot Unlock (Likely to Fail)
- **Purpose**: Attempt bootloader unlock via fastboot
- **Method**: Standard Android unlock commands
- **Requirements**: ADB, fastboot
- **Time**: 1-2 minutes
- **Result**: Usually fails on AT&T devices
- **Safety**: Low risk
- **Risk**: Low (likely fails)

### Method 5: Shizuku (Semi-Root, No Bootloader)
- **Purpose**: Get root-like capabilities without unlocking bootloader
- **Method**: Install Shizuku app and enable wireless debugging
- **Requirements**: Developer options enabled, wireless debugging
- **Time**: 5 minutes
- **Result**: ADB-like privileges for apps
- **Safety**: Safe, no warranty void
- **Risk**: Very low

**Installation**:
```
Download: https://shizuku.rikka.app/
Install: adb install shizuku.apk
Enable: Settings > Developer Options > Wireless debugging
```

## Recommended Approach by Use Case

### Use Case 1: Use with Other Carriers (T-Mobile, Verizon, etc.)
**Recommended Method**: Official AT&T carrier unlock (Method 1)
- Submit unlock request at https://att.com/deviceunlock
- Wait for approval and receive unlock code
- Insert non-AT&T SIM and enter code
- Device permanently unlocked for all carriers

### Use Case 2: Install Custom ROM or Root
**Recommended Method**: MTKClient bootloader unlock (Method 2)
- Backup all data first
- Install MTKClient and dependencies
- Boot to BROM mode (Vol Up + Vol Down + Power)
- Execute unlock commands
- Install custom recovery and ROM

### Use Case 3: Semi-Root Without Unlock
**Recommended Method**: Shizuku (Method 5)
- Download and install Shizuku APK
- Enable wireless debugging
- Apps get ADB-like privileges
- No bootloader unlock required

## Device Configuration After Automation

### Semi-Root Capabilities
- ✅ Developer options enabled
- ✅ ADB debugging enabled
- ✅ Unknown sources enabled (sideloading)
- ⏳ Shizuku: Manual installation required
- ✅ ADB over network enabled (wireless debugging)

### Custom App Support
- ✅ Sideloading enabled
- ✅ Browser installation enabled
- ✅ Package verification disabled
- ✅ Install permissions granted

### Carrier Unlock Preparation
- ✅ Carrier restrictions disabled (where possible)
- ✅ Custom APN configuration enabled
- ✅ Carrier lock status documented
- ✅ Unlock methods prepared

### Bootloader Unlock
- ✅ Multiple methods documented
- ✅ Instructions provided
- ⚠️ Requires manual execution
- ⚠️ May void warranty, erase data

### Multi-Provider Support
- ✅ Custom APN configuration enabled
- ✅ Ready for manual APN configuration
- ⚠️ Requires carrier unlock to use other SIMs

## Manual Steps Required

### For Carrier Unlock (Multi-Provider):
1. **Check eligibility**: Visit https://att.com/deviceunlock
2. **Submit request**: Enter IMEI (check via *#06#)
3. **Wait for approval**: 24-48 hours
4. **Receive code**: 16-digit unlock code via email
5. **Apply code**: Insert non-AT&T SIM and enter code

### For Bootloader Unlock (Custom ROM):
1. **Backup data**: All data will be erased
2. **Install MTKClient**: Download from https://github.com/bkerler/mtkclient
3. **Boot to BROM**: Vol Up + Vol Down + Power, then USB
4. **Execute unlock**: Run mtkclient commands
5. **Install custom ROM**: Download and flash ROM

### For Semi-Root (Immediate):
1. **Download Shizuku**: https://shizuku.rikka.app/
2. **Install APK**: `adb install shizuku.apk` or direct install
3. **Enable wireless debugging**: Settings > Developer Options > Wireless debugging
4. **Activate Shizuku**: Follow app instructions

## Log Locations

- **Accessibility Analysis**: `./accessibility-analysis/`
- **Monitoring Logs**: `./monitoring-logs/`
- **Setup Logs**: `./setup-logs/`
- **Unlock Logs**: `./unlock-logs/`
- **Master Report**: `./automation-logs/master_report_*.txt`

## Security Considerations

- All data is kept local (no off-system sharing)
- Minimal logging to essential operational data only
- Telemetry disabled
- Cloud services used with discretion only
- Data containment mandatory
- **Unlock methods may void warranty**
- **Bootloader unlock erases all data**
- **Some methods may brick device if interrupted**

## Troubleshooting

### Device Not Connected
- Ensure USB debugging is enabled
- Check USB cable connection
- Accept authorization prompt on device
- Try `adb kill-server && adb start-server`

### Scripts Not Executing
- Ensure Git Bash is installed
- Check file permissions: `chmod +x *.sh`
- Use Windows .bat script if preferred

### Fastboot Not Working
- Try holding Vol Up + Vol Down + Power
- Check if BROM mode is supported
- Use MTKClient method instead

### Shizuku Not Working
- Ensure wireless debugging is enabled
- Check developer options are enabled
- Restart device after installation

### Unlock Failed
- Check device eligibility for carrier unlock
- Verify chipset is MT6835 for MTKClient
- Try alternative methods (ChimeraTool)
- Check logs for error messages

## Future Enhancements

- Continuous monitoring daemon
- Automated alert system for suspicious connections
- Integration with Shizuku for app-level control
- Automated unlock execution (where possible)
- Custom ROM compatibility checks
- Firmware update monitoring
- Carrier unlock automation
- Root detection and management

## Authorization

All work performed under authorized cybersecurity clearance:
- Legal Status: Authorized
- Scope: Cybersecurity research, penetration testing, forensics
- Trust Level: High
- Cloud Services: Allowed with discretion
- Preferred IDE: GitHub Codespaces

## Contact

For questions or issues, refer to device-specific logs in the respective log directories.
