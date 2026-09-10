@echo off
REM ====================================================================
REM  Larian ujian beban JMeter (non-GUI) + laporan HTML — untuk Windows.
REM  Prasyarat: pelayan tiruan berjalan (node ..\..\sut\server.js) &
REM             jmeter ada pada PATH.
REM  Penggunaan:  run-nogui.bat            (lalai 50 pengguna / 120s)
REM               set PENGGUNA=200 & set TEMPOH=300 & run-nogui.bat
REM ====================================================================
setlocal
if "%PENGGUNA%"=="" set PENGGUNA=50
if "%RAMPUP%"=="" set RAMPUP=30
if "%TEMPOH%"=="" set TEMPOH=120
if "%HOST%"=="" set HOST=localhost
if "%PORT%"=="" set PORT=3000

set HERE=%~dp0
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set DT=%%a
set STAMP=%DT:~0,8%-%DT:~8,6%
set HASIL=%HERE%hasil\%STAMP%
mkdir "%HASIL%"

echo Menjalankan ujian beban: %PENGGUNA% pengguna, ramp %RAMPUP%s, tempoh %TEMPOH%s
jmeter -n -t "%HERE%..\test-plans\06-ujian-beban-nogui.jmx" ^
  -Jpengguna=%PENGGUNA% -Jrampup=%RAMPUP% -Jtempoh=%TEMPOH% ^
  -Jhost=%HOST% -Jport=%PORT% ^
  -l "%HASIL%\results.jtl" ^
  -e -o "%HASIL%\laporan" ^
  -j "%HASIL%\jmeter.log"

echo.
echo Selesai. Buka: %HASIL%\laporan\index.html
endlocal
