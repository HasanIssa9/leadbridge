@echo off
echo ============================================
echo    LeadBridge Backend - Quick Deploy
echo ============================================
echo.

REM Check if Node.js exists
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js غير مثبت!
    echo حمّله من: https://nodejs.org/en/download
    echo ثم شغّل هذا الملف مجدداً
    pause
    exit /b 1
)

echo [OK] Node.js موجود:
node --version
echo.

REM Install Railway CLI
echo تثبيت Railway CLI...
npm install -g @railway/cli
echo.

REM Login to Railway
echo تسجيل الدخول لـ Railway...
echo سيفتح المتصفح تلقائياً
railway login
echo.

REM Deploy
echo رفع الـ Backend...
cd /d "%~dp0backend"
railway up --service leadbridge-api
echo.

echo ============================================
echo تم الرفع! انسخ الـ URL وأعطيه لـ Claude
echo ============================================
pause
