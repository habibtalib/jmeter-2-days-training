@echo off
REM ====================================================================
REM  Larian ujian beban JMeter (non-GUI) + laporan HTML — untuk Windows.
REM  Prasyarat: pelayan tiruan berjalan (node ..\..\sut\server.js) &
REM             jmeter ada pada PATH.
REM  Penggunaan:  run-nogui.bat            (lalai 50 pengguna / 120s)
REM               set "PENGGUNA=200" & set "TEMPOH=300" & run-nogui.bat
REM  (Git Bash: guna run-nogui.sh — PENGGUNA=200 TEMPOH=300 ./run-nogui.sh)
REM ====================================================================
setlocal
if "%PENGGUNA%"=="" set PENGGUNA=50
if "%RAMPUP%"=="" set RAMPUP=30
if "%TEMPOH%"=="" set TEMPOH=120
if "%HOST%"=="" set HOST=localhost
if "%PORT%"=="" set PORT=3000

set HERE=%~dp0
REM Cap masa yyyyMMdd-HHmmss (wmic sudah tiada pada Windows 11 terkini)
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set STAMP=%%a
if "%STAMP%"=="" set STAMP=%RANDOM%%RANDOM%
set HASIL=%HERE%hasil\%STAMP%
mkdir "%HASIL%"

echo Menjalankan ujian beban:
echo   Plan     : %HERE%..\test-plans\06-ujian-beban-nogui.jmx
echo   Pengguna : %PENGGUNA%  ^|  Ramp-up: %RAMPUP%s  ^|  Tempoh: %TEMPOH%s
echo   Sasaran  : http://%HOST%:%PORT%
echo   Hasil    : %HASIL%
echo.

REM "call" wajib: tanpanya jmeter.bat tidak kembali ke skrip ini
call jmeter -n -t "%HERE%..\test-plans\06-ujian-beban-nogui.jmx" ^
  -Jpengguna=%PENGGUNA% -Jrampup=%RAMPUP% -Jtempoh=%TEMPOH% ^
  -Jhost=%HOST% -Jport=%PORT% ^
  -l "%HASIL%\results.jtl" ^
  -e -o "%HASIL%\laporan" ^
  -j "%HASIL%\jmeter.log" <nul

echo.
echo Selesai. Buka laporan HTML:
echo   %HASIL%\laporan\index.html
endlocal
