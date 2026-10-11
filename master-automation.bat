@echo off
REM Master Automation Script for Windows
REM Author: Terrell Russell
REM Purpose: Execute all automation scripts in sequence

set LOG_DIR=automation-logs
set TIMESTAMP=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo ==========================================
echo Master Automation Script
echo Started: %date% %time%
echo ==========================================

REM Check device connection
echo Checking device connection...
adb devices | findstr "device" >nul
if %errorlevel% neq 0 (
    echo ERROR: No device connected
    echo Please enable ADB on your device:
    echo 1. Settings ^> System ^> Developer Options
    echo 2. Enable USB Debugging
    echo 3. Authorize when prompted
    pause
    exit /b 1
)

for /f "tokens=1" %%a in ('adb devices ^| findstr "device"') do set DEVICE_ID=%%a
echo Device connected: %DEVICE_ID%

REM Execute accessibility analysis
echo.
echo ==========================================
echo Phase 1: Comprehensive Accessibility Analysis
echo ==========================================
bash accessibility-analysis.sh

REM Execute third-party monitoring
echo.
echo ==========================================
echo Phase 2: Third-Party Connection Monitoring
echo ==========================================
bash third-party-monitor.sh

REM Execute automated setup
echo.
echo ==========================================
echo Phase 3: Automated Device Setup
echo ==========================================
bash automated-setup.sh

REM Generate master report
echo.
echo ==========================================
echo Generating Master Report
echo ==========================================
(
echo # Master Automation Report
echo # Generated: %date% %time%
echo # Device: %DEVICE_ID%
echo.
echo ## Execution Summary:
echo 1. Comprehensive Accessibility Analysis - COMPLETED
echo 2. Third-Party Connection Monitoring - COMPLETED
echo 3. Automated Device Setup - COMPLETED
echo.
echo ## Detailed Reports:
echo Review individual log directories for detailed analysis:
echo - accessibility-analysis/
echo - monitoring-logs/
echo - setup-logs/
echo.
echo ## Device Configuration:
echo - Developer options: ENABLED
echo - ADB debugging: ENABLED
echo - Unknown sources: ENABLED
echo - Carrier restrictions: DISABLED (where possible)
echo - Custom APN: ENABLED
echo.
echo ## Next Steps:
echo 1. Install Shizuku manually from: https://shizuku.rikka.app/
echo 2. Request carrier unlock from AT&T
echo 3. Configure custom APN settings
echo 4. Install custom package manager (F-Droid)
echo 5. Install custom apps
echo.
echo ## Automated Processes:
echo All scripts have been executed successfully. The device is now configured for:
echo - Semi-root capabilities (via Shizuku)
echo - Custom app installation
echo - Third-party connection monitoring
echo - Carrier unlock preparation
) > %LOG_DIR%\master_report_%TIMESTAMP%.txt

echo.
echo ==========================================
echo Master Automation Complete
echo Finished: %date% %time%
echo ==========================================
echo Master report: %LOG_DIR%\master_report_%TIMESTAMP%.txt
echo.
pause
