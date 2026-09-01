@echo off
setlocal
cd /d "%~dp0"
call "%~dp0start_demo.bat"
exit /b %ERRORLEVEL%
