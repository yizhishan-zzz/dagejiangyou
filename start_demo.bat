@echo off
setlocal
cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -File "%~dp0start_demo.ps1"
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" (
  echo Demo launcher failed. Please review the messages above.
) else (
  echo Demo launcher finished. Backend and frontend should keep running in their own windows.
)
echo.
pause
exit /b %EXITCODE%
