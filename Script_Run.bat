@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ============================================================
::   Defender Remover - main launcher
::   Disables / removes Windows Defender and related security
::   components. A System Restore point or full backup is
::   strongly recommended before running.
:: ============================================================

set "DefenderRemoverVer=13.1"
set "ScriptDir=%~dp0"
set "LogFile=%ScriptDir%DefenderRemover.log"
set "AutoReboot=1"
set "Action="

:: --- Ensure we are running elevated; relaunch (forwarding args) if not ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    if "%~1"=="" (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    ) else (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '%*'"
    )
    exit /b
)

cd /d "%ScriptDir%"

:: --- Choose how to apply changes. PowerRun grants TrustedInstaller
::     rights, which are required to delete some protected keys. ---
if exist "%ScriptDir%PowerRun.exe" (
    set "HavePowerRun=1"
    set "RegApply=PowerRun.exe regedit.exe /s"
    set "PsRun=PowerRun.exe powershell.exe -NoProfile -ExecutionPolicy Bypass -File"
) else (
    set "HavePowerRun=0"
    set "RegApply=regedit.exe /s"
    set "PsRun=powershell.exe -NoProfile -ExecutionPolicy Bypass -File"
)

:: --- Parse command-line arguments. Flags first, action last. ---
:parseargs
if "%~1"=="" goto dispatch
set "arg=%~1"
if /I "%arg%"=="/r"        set "Action=removedef"
if /I "%arg%"=="/a"        set "Action=removeantivirus"
if /I "%arg%"=="/s"        set "Action=removalfiles"
if /I "%arg%"=="/restore"  set "Action=restore"
if /I "%arg%"=="/n"        set "AutoReboot=0"
if /I "%arg%"=="/noreboot" set "AutoReboot=0"
if /I "%arg%"=="/?"        set "Action=help"
if /I "%arg%"=="/help"     set "Action=help"
shift
goto parseargs

:dispatch
if defined Action goto %Action%

:: --------------------------------------------------------------
:menu
cls
echo ============================================================
echo   Defender Remover - version %DefenderRemoverVer%
echo ============================================================
echo.
if "%HavePowerRun%"=="0" echo [!] PowerRun.exe not found - some protected keys may not be removable.
if "%HavePowerRun%"=="0" echo.
echo A System Restore point or full backup is STRONGLY recommended.
echo These changes are difficult to reverse. After applying, a reboot
echo is required.
echo.
echo   [Y] Remove Windows Defender Antivirus + Windows Security App
echo   [A] Remove Windows Defender Antivirus only (Security App stays;
echo       it will return after a Windows update)
echo   [S] Remove leftover Defender files (run AFTER option Y or A)
echo   [R] Restore / re-enable Windows Defender (best-effort)
echo   [Q] Quit without making changes
echo.
choice /C YASRQ /N /M "Select an option [Y/A/S/R/Q]: "
if errorlevel 5 goto quit
if errorlevel 4 goto restore
if errorlevel 3 goto removalfiles
if errorlevel 2 goto removeantivirus
if errorlevel 1 goto removedef
goto menu

:: --------------------------------------------------------------
:removedef
call :log "=== Remove Defender + Windows Security App: started ==="
cls
call :log "Removing Windows Security UWP App (SecHealthUI)..."
%PsRun% "%ScriptDir%RemoveSecHealthApp.ps1"
call :log "Applying Defender registry changes..."
call :applyRegDir "%ScriptDir%Remove_Defender"
call :log "Applying Windows Security component registry changes..."
call :applyRegDir "%ScriptDir%Remove_SecurityComp"
call :log "=== Remove Defender + Windows Security App: finished ==="
goto reboot

:: --------------------------------------------------------------
:removeantivirus
call :log "=== Remove Antivirus only: started ==="
cls
call :log "Applying Defender registry changes (keeping Windows Security App)..."
call :applyRegDir "%ScriptDir%Remove_Defender"
call :log "=== Remove Antivirus only: finished ==="
goto reboot

:: --------------------------------------------------------------
:removalfiles
call :log "=== Defender file removal: started ==="
if "%HavePowerRun%"=="1" (
    PowerRun.exe cmd.exe /c ""%ScriptDir%files_removal.bat""
) else (
    call "%ScriptDir%files_removal.bat"
)
call :log "=== Defender file removal: finished ==="
goto reboot

:: --------------------------------------------------------------
:restore
call :log "=== Restore Defender: started ==="
if "%HavePowerRun%"=="1" (
    PowerRun.exe cmd.exe /c ""%ScriptDir%Restore_Defender\Restore_Defender.bat""
) else (
    call "%ScriptDir%Restore_Defender\Restore_Defender.bat"
)
:: Restore_Defender.bat performs its own reboot prompt.
goto end

:: --------------------------------------------------------------
:reboot
if "%AutoReboot%"=="0" (
    call :log "Changes applied. Automatic reboot skipped (/noreboot). Reboot manually to finish."
    echo.
    pause
    goto end
)
call :log "A reboot is required to finish applying changes. Restarting in 60 seconds."
echo Run  shutdown /a  to cancel the restart.
shutdown /r /t 60 /c "Defender Remover: restarting to finish applying changes."
goto end

:: --------------------------------------------------------------
:help
echo Usage: Script_Run.bat [option]
echo.
echo   /r          Remove Defender antivirus + Windows Security App
echo   /a          Remove Defender antivirus only
echo   /s          Remove leftover Defender files
echo   /restore    Restore / re-enable Defender (best-effort)
echo   /n  /noreboot   Do not reboot automatically
echo(  /help, /?    Show this help
echo.
echo With no option, an interactive menu is shown.
goto end

:: --------------------------------------------------------------
:quit
echo No changes were made.
goto end

:: ==============================================================
::  Subroutines
:: ==============================================================

:: Apply every .reg file under the given folder (recursively).
:applyRegDir
set "regdir=%~1"
if not exist "%regdir%\" (
    call :log "  [skip] folder not found: %regdir%"
    goto :eof
)
for /r "%regdir%" %%f in (*.reg) do (
    call :log "  applying %%~nxf"
    %RegApply% "%%f"
)
goto :eof

:: Append a timestamped line to the log and echo it to the console.
:log
echo [%date% %time%] %~1>>"%LogFile%"
echo %~1
goto :eof

:end
endlocal
