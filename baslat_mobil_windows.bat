@echo off
chcp 65001 > nul
title İş Takip Mobil Başlatıcı (Windows)
echo.
echo ========================================================
echo   İş Takip Mobil Uygulaması (Windows) Başlatılıyor...
echo ========================================================
echo.

set "PATH=C:\flutter\bin;C:\Users\ADIL CEVIK\AppData\Local\gh\bin;%PATH%"
cd /d "C:\Users\ADIL CEVIK\Desktop\istakipmobil"

flutter run -d windows

pause
