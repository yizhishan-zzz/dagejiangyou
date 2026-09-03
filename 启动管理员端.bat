@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo   Dajiangyou - Admin Console Launcher
echo ============================================
echo.

rem ======== PostgreSQL connection (EDIT these if needed) ========
if "%DATABASE_URL%"=="" set "DATABASE_URL=jdbc:postgresql://localhost:5432/community_micro_logistics"
if "%DATABASE_USERNAME%"=="" set "DATABASE_USERNAME=postgres"
if "%DATABASE_PASSWORD%"=="" set "DATABASE_PASSWORD=postgres"
rem ===============================================================

rem --- 1. Start backend (PostgreSQL) ---
if not exist "backend\gradlew.bat" (
    echo [ERROR] backend\gradlew.bat not found.
    pause
    exit /b 1
)
start "Dajiangyou-Backend" /D "%~dp0backend" cmd /k "gradlew.bat bootRun"
echo [1/3] Backend starting  (PostgreSQL)...

rem --- 2. Start admin static server ---
start "Dajiangyou-Admin" /D "%~dp0" cmd /k "python -m http.server 4100 --bind 127.0.0.1"
echo [2/3] Admin server starting  (port 4100)...

rem --- 3. Wait, then open browser ---
echo [3/3] Waiting 40 seconds for backend to boot, then opening browser...
timeout /t 40 /nobreak >nul
start "" "http://127.0.0.1:4100/admin.html"

echo.
echo Done. Browser should open:  http://127.0.0.1:4100/admin.html
echo Login:  13800000099  /  demo123456
echo.
echo NOTE: Keep the two new windows (Backend / Admin) open.
echo       If the page is not loaded yet, wait a few seconds and refresh.
echo.
pause
exit /b 0
