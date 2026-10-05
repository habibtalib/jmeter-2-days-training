#!/usr/bin/env bash
# =====================================================================
#  Ujian TERAGIH "berbilang lokasi" + laporan gabungan & per lokasi.
#  Simulasi DI SATU MESIN (localhost sahaja — etika: tiada sistem sebenar):
#
#    Lokasi KL     : SUT tiruan port 3000 (latensi lalai 40-180 ms)
#                    + ejen jmeter-server port RMI 1099  (-Jsite=KL -Jport=3000)
#    Lokasi PENANG : SUT tiruan port 3001 (latensi 300-900 ms, "rangkaian jauh")
#                    + ejen jmeter-server port RMI 1100  (-Jsite=PENANG -Jport=3001)
#    Controller    : jmeter -n ... -R 127.0.0.1:1099,127.0.0.1:1100
#
#  Langkah: mula SUT x2 -> mula ejen x2 -> controller jalankan 09 pada SEMUA ejen
#           -> laporan gabungan -> pecah JTL ikut [LOKASI] -> laporan per lokasi
#           -> jadual perbandingan (daripada statistics.json).
#
#  Prasyarat: Java + JMeter 5.6.x (jmeter pada PATH), Node.js, port 3000/3001/
#             1099/1100/4001/4002 bebas.
#
#  Penggunaan (dari mana-mana direktori):
#    ./run-berbilang-lokasi.sh                         # 10 pengguna x 3 gelung PER EJEN
#    PENGGUNA=20 GELUNG=5 ./run-berbilang-lokasi.sh
#    ./run-berbilang-lokasi.sh gabung                  # MOD 2: setiap lokasi jalan
#                                                      #  sendiri, kemudian gabung JTL
#
#  Output (dibersihkan setiap larian):
#    hasil/semua.jtl, hasil/KL.jtl, hasil/PENANG.jtl, hasil/*.log
#    laporan/gabungan/index.html, laporan/KL/index.html, laporan/PENANG/index.html
#
#  Ejen dimulakan dengan skrip `jmeter-server`, dicari mengikut tertib:
#    $JMETER_BIN/jmeter-server -> $JMETER_HOME/bin/jmeter-server -> PATH
#    -> $(brew --prefix jmeter)/libexec/bin/jmeter-server (Homebrew tidak memautkannya)
#    -> sandaran: `jmeter -s` (setara).
#  `jmeter-server` sudah menetapkan `-j jmeter-server.log` sendiri (tambah -j lagi =
#  "Duplicate options for -j"), jadi setiap ejen dijalankan dalam foldernya sendiri
#  (hasil/ejen-KL/, hasil/ejen-PENANG/) dan port RMI ditetapkan dengan SERVER_PORT.
# =====================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
PLAN="$ROOT/hari-2/test-plans/09-berbilang-lokasi.jmx"
DATA="$ROOT/hari-2/data"            # CSV mesti wujud pada SETIAP ejen
HASIL="$HERE/hasil"
LAPORAN="$HERE/laporan"
ALAT="$HERE/laporan-lokasi.js"
MOD="${1:-teragih}"

# Beban PER EJEN (jumlah pengguna = PENGGUNA x bilangan ejen)
PENGGUNA="${PENGGUNA:-10}"
RAMPUP="${RAMPUP:-5}"
GELUNG="${GELUNG:-3}"
# Ujian pendek -> graf "over time" perlukan butiran 1 saat (lalai 60000 ms)
GRAN="-Jjmeter.reportgenerator.overall_granularity=1000"
# Demo setempat: matikan SSL RMI (jika tidak, perlu rmi_keystore.jks — lihat README 3.9)
RMI="-Jserver.rmi.ssl.disable=true"

PIDS=()
bersih() {
  echo
  echo "Membersihkan ejen & SUT tiruan..."
  for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null || true; done
  # Skrip pelancar jmeter tidak 'exec' java, jadi bunuh proses java ejen ikut penanda -Jejen_id
  pkill -f -- "-Jejen_id=$HASIL/" 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -f -- "-Jejen_id=$HASIL/" > /dev/null || break; sleep 0.5; done
}
trap bersih EXIT INT TERM

semak_port_bebas() {
  for p in "$@"; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then
      echo "RALAT: port $p sudah digunakan. Hentikan proses itu dahulu (lsof -i :$p)." >&2
      exit 1
    fi
  done
}

tunggu_port() {  # tunggu_port <port> <nama>
  for _ in $(seq 1 60); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; then echo "  OK  $2 mendengar pada port $1"; return 0; fi
    sleep 0.5
  done
  echo "RALAT: $2 tidak mendengar pada port $1 selepas 30s. Lihat $HASIL/*.log dan $HASIL/ejen-*/jmeter-server.log" >&2
  exit 1
}

rm -rf "$HASIL" "$LAPORAN"
mkdir -p "$HASIL" "$LAPORAN"

echo "== 1) Mula SUT tiruan untuk 2 'lokasi' =="
semak_port_bebas 3000 3001
PORT=3000 node "$ROOT/sut/server.js" > "$HASIL/sut-KL.log" 2>&1 & PIDS+=($!)
PORT=3001 LATENCY_MIN=300 LATENCY_MAX=900 node "$ROOT/sut/server.js" > "$HASIL/sut-PENANG.log" 2>&1 & PIDS+=($!)
tunggu_port 3000 "SUT KL"
tunggu_port 3001 "SUT PENANG (lambat)"

if [ "$MOD" = "gabung" ]; then
  # -------------------------------------------------------------------
  #  MOD 2: setiap lokasi menjalankan plan SECARA BERASINGAN (tanpa RMI),
  #  hantar JTL ke pusat, kemudian gabung + jana SATU laporan.
  #  (Di dunia sebenar: dua mesin, dua pasukan, masa mula diselaraskan.)
  # -------------------------------------------------------------------
  echo "== 2) MOD gabung: jalankan plan secara tempatan untuk setiap lokasi (serentak) =="
  jmeter -n -t "$PLAN" -Jsite=KL     -Jport=3000 -Jdata_dir="$DATA" \
    -Jpengguna="$PENGGUNA" -Jrampup="$RAMPUP" -Jgelung="$GELUNG" \
    -l "$HASIL/KL.jtl" -j "$HASIL/jmeter-KL.log" > "$HASIL/konsol-KL.log" 2>&1 & J1=$!
  jmeter -n -t "$PLAN" -Jsite=PENANG -Jport=3001 -Jdata_dir="$DATA" \
    -Jpengguna="$PENGGUNA" -Jrampup="$RAMPUP" -Jgelung="$GELUNG" \
    -l "$HASIL/PENANG.jtl" -j "$HASIL/jmeter-PENANG.log" > "$HASIL/konsol-PENANG.log" 2>&1 & J2=$!
  wait "$J1" "$J2"
  echo "== 3) Gabung JTL (header sekali sahaja; header mesti sama) =="
  node "$ALAT" gabung "$HASIL/gabung.jtl" "$HASIL/KL.jtl" "$HASIL/PENANG.jtl"
  echo "== 4) Jana laporan gabungan + per lokasi =="
  jmeter -g "$HASIL/gabung.jtl"  -o "$LAPORAN/gabung" $GRAN -j "$HASIL/rpt-gabung.log" > /dev/null
  jmeter -g "$HASIL/KL.jtl"      -o "$LAPORAN/KL"     $GRAN -j "$HASIL/rpt-KL.log" > /dev/null
  jmeter -g "$HASIL/PENANG.jtl"  -o "$LAPORAN/PENANG" $GRAN -j "$HASIL/rpt-PENANG.log" > /dev/null
  echo
  echo "== 5) Perbandingan lokasi =="
  node "$ALAT" banding "$LAPORAN" KL PENANG
  echo
  echo "Laporan: $LAPORAN/gabung/index.html | $LAPORAN/KL/index.html | $LAPORAN/PENANG/index.html"
  exit 0
fi

echo "== 2) Mula 2 ejen jmeter-server (satu per lokasi) =="
semak_port_bebas 1099 1100 4001 4002
JSERVER=""
for c in "${JMETER_BIN:+$JMETER_BIN/jmeter-server}" "${JMETER_HOME:+$JMETER_HOME/bin/jmeter-server}" \
         "$(command -v jmeter-server 2>/dev/null || true)" \
         "$(command -v brew >/dev/null 2>&1 && echo "$(brew --prefix jmeter 2>/dev/null)/libexec/bin/jmeter-server")"; do
  if [ -n "$c" ] && [ -x "$c" ]; then JSERVER="$c"; break; fi
done
echo "  Ejen: ${JSERVER:-jmeter -s (sandaran; jmeter-server tidak dijumpai)}"

mula_ejen() {  # mula_ejen <LOKASI> <port_rmi> <port_objek> <port_sut>
  local dir="$HASIL/ejen-$1"; mkdir -p "$dir"
  # -Jsite / -Jport / -Jdata_dir : sifat TEMPATAN ejen (berbeza setiap lokasi)
  # server.rmi.localport         : port objek RMI tetap (mudah buka firewall: 1099 + 4001)
  # java.rmi.server.hostname     : alamat yang ejen umumkan kepada controller
  # ejen_id                      : penanda untuk pembersihan sahaja
  local args=($RMI -Jserver.rmi.localport="$3" -Djava.rmi.server.hostname=127.0.0.1
              -Jsite="$1" -Jport="$4" -Jdata_dir="$DATA" -Jejen_id="$dir")
  if [ -n "$JSERVER" ]; then
    (cd "$dir" && SERVER_PORT="$2" exec "$JSERVER" "${args[@]}") > "$HASIL/konsol-ejen-$1.log" 2>&1 &
  else
    (cd "$dir" && exec jmeter -s -Dserver_port="$2" -j jmeter-server.log "${args[@]}") > "$HASIL/konsol-ejen-$1.log" 2>&1 &
  fi
  PIDS+=($!)
}
mula_ejen KL     1099 4001 3000
mula_ejen PENANG 1100 4002 3001
tunggu_port 1099 "Ejen KL"
tunggu_port 1100 "Ejen PENANG"

echo "== 3) Controller: jalankan 09 pada SEMUA ejen (-R) + laporan gabungan =="
echo "   Beban per ejen: $PENGGUNA pengguna x $GELUNG gelung (jumlah pengguna = $PENGGUNA x 2 ejen = $((PENGGUNA * 2)))"
# -G = hantar sifat ke SEMUA ejen (beban sama); -J = sifat controller sahaja
jmeter -n -t "$PLAN" -R 127.0.0.1:1099,127.0.0.1:1100 $RMI \
  -Gpengguna="$PENGGUNA" -Grampup="$RAMPUP" -Ggelung="$GELUNG" \
  -l "$HASIL/semua.jtl" -e -o "$LAPORAN/gabungan" $GRAN \
  -j "$HASIL/controller.log"

echo
echo "== 4) Pecah JTL ikut awalan label [LOKASI] =="
node "$ALAT" pisah "$HASIL/semua.jtl" "$HASIL" KL PENANG

echo "== 5) Jana laporan per lokasi =="
for L in KL PENANG; do
  jmeter -g "$HASIL/$L.jtl" -o "$LAPORAN/$L" $GRAN -j "$HASIL/rpt-$L.log" > /dev/null
  echo "  OK  $LAPORAN/$L/index.html"
done

echo
echo "== 6) Perbandingan lokasi (daripada laporan/<LOKASI>/statistics.json) =="
node "$ALAT" banding "$LAPORAN" KL PENANG

echo
echo "Laporan gabungan : $LAPORAN/gabungan/index.html"
echo "Laporan KL       : $LAPORAN/KL/index.html"
echo "Laporan PENANG   : $LAPORAN/PENANG/index.html"
