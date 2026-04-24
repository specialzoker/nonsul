@echo off
echo raw.csv → data.js 변환 중...
powershell -ExecutionPolicy Bypass -File "%~dp0generate-data.ps1"
echo.
echo 완료! index.html 을 브라우저에서 열어보세요.
pause
