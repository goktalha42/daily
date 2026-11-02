@echo off
echo ===================================================
echo   Daily Games (Zuhtu) - Yerel API Sunucusu
echo   Wi-Fi Erisim IP: http://192.168.1.108:8000
echo   Localhost:       http://127.0.0.1:8000
echo ===================================================
php artisan serve --host=0.0.0.0 --port=8000
pause
