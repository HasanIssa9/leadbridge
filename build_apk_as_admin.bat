@echo off
echo Adding Windows Defender exclusions...
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Program Files\Android\Android Studio\jbr'"
powershell -Command "Add-MpPreference -ExclusionPath '%USERPROFILE%\.gradle'"
echo Exclusions added!
echo.
echo Building APK...
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%
set ANDROID_HOME=C:\Android\Sdk
cd /d "C:\Users\Hasan Issa\Documents\leadbridge\flutter_app"
flutter build apk --release --dart-define=API_URL=https://leadbridge-api.onrender.com/api
echo.
if exist "build\app\outputs\flutter-apk\app-release.apk" (
  echo SUCCESS! APK is at: build\app\outputs\flutter-apk\app-release.apk
  explorer "build\app\outputs\flutter-apk"
) else (
  echo Build failed. Check output above.
)
pause
