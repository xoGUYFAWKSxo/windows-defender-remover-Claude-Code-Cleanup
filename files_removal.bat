@echo off
setlocal EnableExtensions

:: ============================================================
::   Defender file removal
::   Takes ownership of and deletes the Windows Defender
::   platform folders. This is destructive and irreversible;
::   run only after the registry removal step, and only if you
::   intend to fully remove Defender.
::
::   Note: this does NOT touch the component store (WinSxS), so
::   "sfc /scannow" / "DISM /RestoreHealth" can still restore
::   these files later (see Restore_Defender).
:: ============================================================

set "LogFile=%~dp0DefenderRemover.log"
echo Please wait, removing Windows Defender platform files...

:: Administrators group via locale-independent SID (S-1-5-32-544).
set "AdminsSid=*S-1-5-32-544"

call :removeDir "%ProgramData%\Microsoft\Windows Defender"
call :removeDir "%ProgramFiles%\Windows Defender"
call :removeDir "%ProgramW6432%\Windows Defender"
call :removeDir "%ProgramFiles(x86)%\Windows Defender"
call :removeDir "%ProgramFiles%\Windows Defender Advanced Threat Protection"
call :removeDir "%ProgramW6432%\Windows Defender Advanced Threat Protection"

echo Done.
goto :eof

:: ------------------------------------------------------------
:: Take ownership of a directory and delete it, with guards.
:removeDir
set "dir=%~1"
if "%dir%"=="" goto :eof
if "%dir%"=="\Windows Defender" goto :eof
if not exist "%dir%\" (
    call :log "[skip] not present: %dir%"
    goto :eof
)
call :log "[remove] %dir%"
takeown /f "%dir%" /r /d y >nul 2>&1
icacls "%dir%" /grant "%AdminsSid%":F /t >nul 2>&1
rd /s /q "%dir%" 2>nul
if exist "%dir%\" (
    call :log "[warn] could not fully remove %dir% (some files may be in use)"
) else (
    call :log "[ok] removed %dir%"
)
goto :eof

:: ------------------------------------------------------------
:log
echo [%date% %time%] %~1>>"%LogFile%"
echo %~1
goto :eof
