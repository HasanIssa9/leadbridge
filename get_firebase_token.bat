@echo off
echo =============================================
echo   Firebase Login - احصل على CI Token
echo =============================================
echo.
echo سيفتح المتصفح لتسجيل الدخول بـ Google...
echo بعد التسجيل، انسخ الـ Token وأعطيه لـ Claude
echo.
"%USERPROFILE%\Downloads\firebase-tools.exe" login:ci
echo.
echo انسخ الـ Token من الأعلى (يبدأ بـ 1//)
pause
