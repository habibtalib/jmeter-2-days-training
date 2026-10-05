@echo off
REM ====================================================================
REM  Ujian beban CHATBOT eJPJ (tiruan) + CPU pelayan via ejen PerfMon (Windows).
REM  Setara dengan run-chatbot-perfmon.sh — localhost / persekitaran ujian SAHAJA.
REM
REM  !! BELUM DIUJI pada Windows (ditulis teliti berdasarkan versi .sh yang
REM  !! telah diuji pada macOS + JMeter 5.6.3). Jika gagal, jalankan langkah
REM  !! secara manual — arahan sama seperti dalam README Hari 2, seksyen 3.10.
REM
REM  Prasyarat:
REM    - JMETER_HOME ditetapkan (cth C:\apache-jmeter-5.6.3) + plugin
REM      jpgc-perfmon, jpgc-cmd, jpgc-graphs-basic (Plugins Manager)
REM    - ServerAgent BERJALAN pada PELAYAN:  startAgent.bat --udp-port 0 --tcp-port 4444
REM    - SUT berjalan:  node sut\server.js   (atau set MULA_SUT=1)
REM    - Node.js (untuk ringkasan)
REM  Penggunaan:
REM    run-chatbot-perfmon.bat                       (40 pengguna, ramp 120s, 180s)
REM    set PENGGUNA=20 & set RAMPUP=60 & set TEMPOH=120 & run-chatbot-perfmon.bat
REM    set AGENT_HOST=10.0.0.5 & set HOST=10.0.0.5 & run-chatbot-perfmon.bat
REM ====================================================================
setlocal
set HERE=%~dp0
for %%I in ("%HERE%..\..") do set ROOT=%%~fI
set PLAN=%ROOT%\hari-2\test-plans\10b-chatbot-perfmon.jmx

if "%PENGGUNA%"=="" set PENGGUNA=40
if "%RAMPUP%"=="" set RAMPUP=120
if "%TEMPOH%"=="" set TEMPOH=180
if "%HOST%"=="" set HOST=localhost
if "%PORT%"=="" set PORT=3000
if "%SLA_MS%"=="" set SLA_MS=3000
if "%AGENT_HOST%"=="" set AGENT_HOST=localhost
if "%AGENT_PORT%"=="" set AGENT_PORT=4444
if "%GRAN%"=="" set GRAN=5000

REM jmeter.bat + JMeterPluginsCMD.bat dalam folder bin yang sama
set JBIN=
if defined JMETER_HOME if exist "%JMETER_HOME%\bin\jmeter.bat" set JBIN=%JMETER_HOME%\bin
if not defined JBIN for %%J in (jmeter.bat) do if not "%%~dp$PATH:J"=="" set JBIN=%%~dp$PATH:J
if not defined JBIN (
  echo RALAT: jmeter.bat tidak dijumpai. Set JMETER_HOME atau tambah %%JMETER_HOME%%\bin pada PATH.
  exit /b 1
)
if "%JBIN:~-1%"=="\" set JBIN=%JBIN:~0,-1%
set PCMD=%JBIN%\JMeterPluginsCMD.bat

for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set STAMP=%%a
set HASIL=%HERE%hasil\%STAMP%
mkdir "%HASIL%"

echo == 1) Semak SUT dan ejen PerfMon ==
if "%MULA_SUT%"=="1" (
  start "JMCHATBOT-SUT" /MIN cmd /c node "%ROOT%\sut\server.js" ^> "%HASIL%\sut.log" 2^>^&1
  timeout /t 3 /nobreak > nul
)
call :boleh_sambung %HOST% %PORT% || (
  echo RALAT: SUT tidak berjalan pada %HOST%:%PORT%. Mula: node sut\server.js ^(atau set MULA_SUT=1^).
  goto :gagal
)
echo   OK  SUT  http://%HOST%:%PORT%
call :boleh_sambung %AGENT_HOST% %AGENT_PORT% || (
  echo RALAT: ServerAgent tidak dapat dihubungi pada %AGENT_HOST%:%AGENT_PORT% ^(Connection refused^).
  echo        Pada PELAYAN: startAgent.bat --udp-port 0 --tcp-port %AGENT_PORT% - dan buka firewall untuk port itu.
  goto :gagal
)
echo   OK  ServerAgent %AGENT_HOST%:%AGENT_PORT%
if not exist "%PCMD%" echo AMARAN: %PCMD% tiada - PNG tidak akan dijana. Pasang: PluginsManagerCMD.bat install jpgc-cmd,jpgc-graphs-basic

echo.
echo == 2) Larian non-GUI: %PENGGUNA% pengguna ^| ramp-up %RAMPUP%s ^| tempoh %TEMPOH%s ^| SLA %SLA_MS% ms ==
echo    Hasil: %HASIL%
call "%JBIN%\jmeter.bat" -n -t "%PLAN%" ^
  -Jpengguna=%PENGGUNA% -Jrampup=%RAMPUP% -Jtempoh=%TEMPOH% ^
  -Jhost=%HOST% -Jport=%PORT% -Jsla_ms=%SLA_MS% ^
  -Jagent_host=%AGENT_HOST% -Jagent_port=%AGENT_PORT% "-Jperfmon_jtl=%HASIL%\perfmon.jtl" ^
  -Jjmeter.reportgenerator.overall_granularity=%GRAN% ^
  -l "%HASIL%\keputusan.jtl" -e -o "%HASIL%\laporan" ^
  -j "%HASIL%\jmeter.log"

if not exist "%HASIL%\perfmon.jtl" echo AMARAN: perfmon.jtl tiada - semak %HASIL%\jmeter.log ^(cari 'PerfMon'^).

if exist "%PCMD%" (
  echo.
  echo == 3^) Eksport graf dengan JMeterPluginsCMD ==
  call "%PCMD%" --generate-png "%HASIL%\cpu-perfmon.png" --input-jtl "%HASIL%\perfmon.jtl" --plugin-type PerfMon --width 1200 --height 600 --granulation %GRAN% --relative-times no --auto-scale no > "%HASIL%\pcmd-PerfMon.log" 2>&1
  call "%PCMD%" --generate-png "%HASIL%\response-times-over-time.png" --input-jtl "%HASIL%\keputusan.jtl" --plugin-type ResponseTimesOverTime --width 1200 --height 600 --granulation %GRAN% --relative-times no > "%HASIL%\pcmd-ResponseTimesOverTime.log" 2>&1
  call "%PCMD%" --generate-png "%HASIL%\active-threads.png" --input-jtl "%HASIL%\keputusan.jtl" --plugin-type ThreadsStateOverTime --width 1200 --height 600 --granulation %GRAN% --relative-times no > "%HASIL%\pcmd-ThreadsStateOverTime.log" 2>&1
  call "%PCMD%" --generate-csv "%HASIL%\perfmon.csv" --input-jtl "%HASIL%\perfmon.jtl" --plugin-type PerfMon --granulation %GRAN% --relative-times no > "%HASIL%\pcmd-csv.log" 2>&1
  dir /b "%HASIL%\*.png" "%HASIL%\perfmon.csv"
)

echo.
echo == 4) Ringkasan ==
node "%HERE%ringkasan-chatbot.js" "%HASIL%"

echo.
echo Laporan HTML : %HASIL%\laporan\index.html
echo PerfMon      : %HASIL%\perfmon.jtl  (+ cpu-perfmon.png, perfmon.csv)
call :henti_sut
endlocal
exit /b 0

:gagal
call :henti_sut
endlocal
exit /b 1

REM ---- :boleh_sambung <host> <port>  -> errorlevel 0 jika port menerima sambungan
:boleh_sambung
node -e "require('net').connect(%2,'%1').on('connect',()=>process.exit(0)).on('error',()=>process.exit(1))"
exit /b %errorlevel%

:henti_sut
if "%MULA_SUT%"=="1" taskkill /FI "WINDOWTITLE eq JMCHATBOT-SUT*" /T /F > nul 2>&1
exit /b 0
