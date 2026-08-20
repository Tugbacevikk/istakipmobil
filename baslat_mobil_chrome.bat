@echo off
title Is Takip Mobil (Sabit Port 8080)
echo ========================================================
echo   Is Takip Mobil Uygulamasi (Sabit Port 8080) Baslatiliyor...
echo ========================================================
echo.

set "PATH=C:\flutter\bin;C:\Users\ADIL CEVIK\AppData\Local\gh\bin;%PATH%"
cd /d "C:\Users\ADIL CEVIK\Desktop\istakipmobil"

echo http://localhost:8080 adresinde sabit port ile aciliyor...
flutter run -d chrome --web-port=8080

pause
