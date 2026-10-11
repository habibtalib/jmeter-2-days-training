@echo off
REM ====================================================================
REM  Ujian TERAGIH "berbilang lokasi" + laporan gabungan & per lokasi (Windows).
REM  Setara dengan run-berbilang-lokasi.sh — localhost SAHAJA (etika).
REM  Disemak baris demi baris dengan versi .sh (diuji pada macOS + JMeter 5.6.3),
REM  tetapi BELUM diuji pada mesin Windows sebenar.
REM  Jika satu langkah gagal, jalankan langkah itu secara manual — arahan sama
REM  seperti dalam README Hari 2, seksyen 3.9. Dalam Git Bash, guna versi .sh.
REM
REM    Lokasi KL     : SUT port 3000 + ejen RMI 1099 (-Jsite=KL -Jport=3000)
REM    Lokasi PENANG : SUT port 3001 (latensi 300-900ms) + ejen RMI 1100
REM    Controller    : jmeter -n ... -R 127.0.0.1:1099,127.0.0.1:1100
REM
REM  Prasyarat: Java + JMeter 5.6.x (jmeter.bat pada PATH), Node.js, port
REM             3000/3001/1099/1100/4001/4002 bebas.
REM  Penggunaan:
REM    run-berbilang-lokasi.bat              (10 pengguna x 3 gelung PER EJEN)
REM    set "PENGGUNA=20" & set "GELUNG=5" & run-berbilang-lokasi.bat
REM    run-berbilang-lokasi.bat gabung       (MOD 2: setiap lokasi jalan sendiri
REM                                           serentak, kemudian gabung JTL)
REM    run-berbilang-lokasi.bat henti        (hentikan ejen/SUT jika skrip
REM                                           diganggu dengan Ctrl+C)
REM  Ejen & SUT dibuka dalam tetingkap minimum bertajuk JMLOKASI-*; skrip
REM  menutupnya di akhir (taskkill ikut tajuk tetingkap).
REM  Ejen: jmeter -s (setara jmeter-server.bat), log ke hasil\ejen-*\jmeter-server.log.
REM  Semua "call jmeter" dibekalkan stdin <nul: jmeter.bat buat "pause" bila ralat,
REM  dan tanpa <nul skrip akan tergantung menunggu kekunci.
REM ====================================================================
setlocal
set "RC=0"
set HERE=%~dp0
for %%I in ("%HERE%..\..") do set ROOT=%%~fI
set PLAN=%ROOT%\hari-2\test-plans\09-berbilang-lokasi.jmx
set DATA=%ROOT%\hari-2\data
set HASIL=%HERE%hasil
set LAPORAN=%HERE%laporan
set ALAT=%HERE%laporan-lokasi.js
set MOD=%1
if "%MOD%"=="" set MOD=teragih

if "%PENGGUNA%"=="" set PENGGUNA=10
if "%RAMPUP%"=="" set RAMPUP=5
if "%GELUNG%"=="" set GELUNG=3
set GRAN=-Jjmeter.reportgenerator.overall_granularity=1000
set RMI=-Jserver.rmi.ssl.disable=true

if /I "%MOD%"=="henti" goto :henti

if exist "%HASIL%" rmdir /S /Q "%HASIL%"
if exist "%LAPORAN%" rmdir /S /Q "%LAPORAN%"
mkdir "%HASIL%"
mkdir "%LAPORAN%"

echo == 1) Mula SUT tiruan untuk 2 'lokasi' ==
call :port_bebas 3000 || goto :gagal
call :port_bebas 3001 || goto :gagal
REM Proses anak mewarisi pembolehubah persekitaran semasa 'start'
set PORT=3000
start "JMLOKASI-SUT-KL" /MIN cmd /c node "%ROOT%\sut\server.js" ^> "%HASIL%\sut-KL.log" 2^>^&1
set PORT=3001
set LATENCY_MIN=300
set LATENCY_MAX=900
start "JMLOKASI-SUT-PENANG" /MIN cmd /c node "%ROOT%\sut\server.js" ^> "%HASIL%\sut-PENANG.log" 2^>^&1
set PORT=
set LATENCY_MIN=
set LATENCY_MAX=
call :tunggu 3000 "SUT KL" || goto :gagal
call :tunggu 3001 "SUT PENANG (lambat)" || goto :gagal

if /I "%MOD%"=="gabung" goto :mod_gabung

echo == 2) Mula 2 ejen jmeter-server (satu per lokasi) ==
for %%P in (1099 1100 4001 4002) do call :port_bebas %%P || goto :gagal
REM Pada Windows, ejen dimulakan dengan "jmeter -s" terus (bukan jmeter-server.bat:
REM skrip itu cd ke folder bin sendiri, jadi log-nya tidak masuk ke hasil\). Setiap
REM ejen dijalankan dalam foldernya sendiri dengan log -j dan port RMI -Dserver_port.
echo   Ejen: jmeter -s (log: %HASIL%\ejen-KL\jmeter-server.log, %HASIL%\ejen-PENANG\jmeter-server.log)
set EJEN_ARGS=%RMI% -Djava.rmi.server.hostname=127.0.0.1 "-Jdata_dir=%DATA%"
mkdir "%HASIL%\ejen-KL"
mkdir "%HASIL%\ejen-PENANG"
pushd "%HASIL%\ejen-KL"
start "JMLOKASI-EJEN-KL" /MIN cmd /c jmeter -s -Dserver_port=1099 -j "%HASIL%\ejen-KL\jmeter-server.log" %EJEN_ARGS% -Jserver.rmi.localport=4001 -Jsite=KL -Jport=3000
popd
pushd "%HASIL%\ejen-PENANG"
start "JMLOKASI-EJEN-PENANG" /MIN cmd /c jmeter -s -Dserver_port=1100 -j "%HASIL%\ejen-PENANG\jmeter-server.log" %EJEN_ARGS% -Jserver.rmi.localport=4002 -Jsite=PENANG -Jport=3001
popd
call :tunggu 1099 "Ejen KL" || goto :gagal
call :tunggu 1100 "Ejen PENANG" || goto :gagal

echo == 3) Controller: jalankan 09 pada SEMUA ejen (-R) + laporan gabungan ==
set /a JUMLAH=%PENGGUNA%*2
echo    Beban per ejen: %PENGGUNA% pengguna x %GELUNG% gelung (jumlah pengguna = %PENGGUNA% x 2 ejen = %JUMLAH%)
REM -G = hantar sifat ke SEMUA ejen (beban sama); -J = sifat controller sahaja
call jmeter -n -t "%PLAN%" -R 127.0.0.1:1099,127.0.0.1:1100 %RMI% ^
  -Gpengguna=%PENGGUNA% -Grampup=%RAMPUP% -Ggelung=%GELUNG% ^
  -l "%HASIL%\semua.jtl" -e -o "%LAPORAN%\gabungan" %GRAN% ^
  -j "%HASIL%\controller.log" <nul

echo.
echo == 4) Pecah JTL ikut awalan label [LOKASI] ==
node "%ALAT%" pisah "%HASIL%\semua.jtl" "%HASIL%" KL PENANG || goto :gagal

echo == 5) Jana laporan per lokasi ==
for %%L in (KL PENANG) do (
  call jmeter -g "%HASIL%\%%L.jtl" -o "%LAPORAN%\%%L" %GRAN% -j "%HASIL%\rpt-%%L.log" <nul >nul
  echo   OK  "%LAPORAN%\%%L\index.html"
)

echo.
echo == 6) Perbandingan lokasi (daripada laporan\^<LOKASI^>\statistics.json) ==
node "%ALAT%" banding "%LAPORAN%" KL PENANG
echo.
echo Laporan gabungan : %LAPORAN%\gabungan\index.html
echo Laporan KL       : %LAPORAN%\KL\index.html
echo Laporan PENANG   : %LAPORAN%\PENANG\index.html
goto :henti

:mod_gabung
REM MOD 2: setiap lokasi menjalankan plan SECARA BERASINGAN (tanpa RMI),
REM hantar JTL ke pusat, kemudian gabung + jana SATU laporan.
echo == 2) MOD gabung: jalankan plan secara tempatan untuk setiap lokasi (serentak) ==
REM Kedua-dua larian bermula serentak di latar (start /b); fail *.siap ditulis apabila
REM setiap larian tamat, dan skrip menunggu kedua-duanya (setara 'wait' dalam .sh).
start "" /b cmd /c call jmeter -n -t "%PLAN%" -Jsite=KL -Jport=3000 "-Jdata_dir=%DATA%" -Jpengguna=%PENGGUNA% -Jrampup=%RAMPUP% -Jgelung=%GELUNG% -l "%HASIL%\KL.jtl" -j "%HASIL%\jmeter-KL.log" ^<nul ^> "%HASIL%\konsol-KL.log" 2^>^&1 ^& type nul ^> "%HASIL%\KL.siap"
start "" /b cmd /c call jmeter -n -t "%PLAN%" -Jsite=PENANG -Jport=3001 "-Jdata_dir=%DATA%" -Jpengguna=%PENGGUNA% -Jrampup=%RAMPUP% -Jgelung=%GELUNG% -l "%HASIL%\PENANG.jtl" -j "%HASIL%\jmeter-PENANG.log" ^<nul ^> "%HASIL%\konsol-PENANG.log" 2^>^&1 ^& type nul ^> "%HASIL%\PENANG.siap"
:tunggu_gabung
ping -n 2 127.0.0.1 >nul
if not exist "%HASIL%\KL.siap" goto :tunggu_gabung
if not exist "%HASIL%\PENANG.siap" goto :tunggu_gabung
echo == 3) Gabung JTL (header sekali sahaja; header mesti sama) ==
node "%ALAT%" gabung "%HASIL%\gabung.jtl" "%HASIL%\KL.jtl" "%HASIL%\PENANG.jtl" || goto :gagal
echo == 4) Jana laporan gabungan + per lokasi ==
call jmeter -g "%HASIL%\gabung.jtl" -o "%LAPORAN%\gabung" %GRAN% -j "%HASIL%\rpt-gabung.log" <nul >nul
for %%L in (KL PENANG) do call jmeter -g "%HASIL%\%%L.jtl" -o "%LAPORAN%\%%L" %GRAN% -j "%HASIL%\rpt-%%L.log" <nul >nul
echo.
echo == 5) Perbandingan lokasi ==
node "%ALAT%" banding "%LAPORAN%" KL PENANG
echo.
echo Laporan: %LAPORAN%\gabung\index.html ^| %LAPORAN%\KL\index.html ^| %LAPORAN%\PENANG\index.html
goto :henti

:gagal
set "RC=1"
echo RALAT: langkah gagal. Lihat log dalam %HASIL%

:henti
echo.
echo Membersihkan ejen ^& SUT tiruan...
for %%T in (JMLOKASI-EJEN-KL JMLOKASI-EJEN-PENANG JMLOKASI-SUT-KL JMLOKASI-SUT-PENANG) do (
  taskkill /FI "WINDOWTITLE eq %%T*" /T /F >nul 2>&1
)
endlocal & exit /b %RC%

REM ---- :port_bebas <port>  -> ralat jika port sudah digunakan
:port_bebas
node -e "require('net').connect(%1,'127.0.0.1').on('connect',()=>process.exit(1)).on('error',()=>process.exit(0))"
if errorlevel 1 (
  echo RALAT: port %1 sudah digunakan. Hentikan proses itu dahulu: Ctrl+C dalam
  echo        terminalnya / Task Manager, atau cari PID ^(lajur terakhir pada baris LISTENING^):
  echo        netstat -ano ^| findstr ":%1 "    lalu: taskkill /PID ^<PID^> /F
  exit /b 1
)
exit /b 0

REM ---- :tunggu <port> <nama>  -> tunggu sehingga ~60s
REM Dalam blok ( ) setiap laluan/nama daripada pemboleh ubah mesti bertanda petik: ")" dalam
REM nilai (cth folder "...-main (1)" atau "SUT PENANG (lambat)") menutup blok itu.
REM ping (bukan timeout): timeout gagal serta-merta jika stdin bukan konsol (cth dari Git Bash)
:tunggu
for /L %%i in (1,1,60) do (
  node -e "require('net').connect(%1,'127.0.0.1').on('connect',()=>process.exit(0)).on('error',()=>process.exit(1))" && (
    echo   OK  "%~2" mendengar pada port %1
    exit /b 0
  )
  ping -n 2 127.0.0.1 >nul
)
echo RALAT: %~2 tidak mendengar pada port %1. Lihat %HASIL%\*.log dan %HASIL%\ejen-*\jmeter-server.log
exit /b 1
