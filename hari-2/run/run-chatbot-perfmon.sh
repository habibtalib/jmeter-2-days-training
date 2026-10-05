#!/usr/bin/env bash
# =====================================================================
#  Ujian beban CHATBOT eJPJ (tiruan) + CPU pelayan melalui ejen PerfMon.
#  Etika: sasaran localhost / persekitaran ujian SAHAJA.
#
#    1) Semak SUT (http://$HOST:$PORT) dan ServerAgent ($AGENT_HOST:$AGENT_PORT)
#    2) Jalankan 10b-chatbot-perfmon.jmx non-GUI:
#         -l hasil/<masa>/keputusan.jtl      (sampel HTTP -> HTML dashboard)
#         perfmon.jtl                        (metrik CPU/Memory daripada ejen)
#    3) HTML dashboard (-e -o hasil/<masa>/laporan)
#    4) JMeterPluginsCMD -> PNG: CPU (PerfMon), Response Times Over Time,
#       Active Threads Over Time + CSV PerfMon
#    5) Ringkasan: p50/p95/p99, Error %, CPU purata/maks
#
#  Prasyarat:
#    - JMeter 5.6.x + plugin (Plugins Manager): jpgc-perfmon, jpgc-cmd, jpgc-graphs-basic
#    - ServerAgent BERJALAN pada PELAYAN (bukan pada penjana beban):
#        ./startAgent.sh --udp-port 0 --tcp-port 4444
#    - SUT berjalan:  node sut/server.js    (atau MULA_SUT=1 — skrip mula SUT pada $PORT)
#    - Node.js (untuk ringkasan)
#
#  Penggunaan:
#    ./run-chatbot-perfmon.sh                            # 40 pengguna, ramp 120s, 180s
#    PENGGUNA=20 RAMPUP=60 TEMPOH=120 ./run-chatbot-perfmon.sh
#    AGENT_HOST=10.0.0.5 HOST=10.0.0.5 ./run-chatbot-perfmon.sh   # pelayan ujian lain
#    MULA_SUT=1 PORT=3001 ./run-chatbot-perfmon.sh       # skrip mula SUT sendiri (port 3001)
#
#  JMeter dicari: $JMETER_HOME/bin -> `jmeter` pada PATH -> Homebrew libexec/bin.
#  JMeterPluginsCMD.sh mesti berada dalam folder bin yang sama.
# =====================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
PLAN="$ROOT/hari-2/test-plans/10b-chatbot-perfmon.jmx"
STAMP="$(date +%Y%m%d-%H%M%S)"
HASIL="$HERE/hasil/$STAMP"

PENGGUNA="${PENGGUNA:-40}"
RAMPUP="${RAMPUP:-120}"
TEMPOH="${TEMPOH:-180}"
HOST="${HOST:-localhost}"
PORT="${PORT:-3000}"
SLA_MS="${SLA_MS:-3000}"
AGENT_HOST="${AGENT_HOST:-localhost}"
AGENT_PORT="${AGENT_PORT:-4444}"
GRAN="${GRAN:-5000}"               # butiran graf (ms) — lalai dashboard 60000 terlalu kasar
MULA_SUT="${MULA_SUT:-0}"

# ---- Cari jmeter + JMeterPluginsCMD.sh (folder bin yang sama) ----
JBIN=""
for c in "${JMETER_HOME:+$JMETER_HOME/bin}" \
         "$(command -v jmeter >/dev/null 2>&1 && cd "$(dirname "$(readlink -f "$(command -v jmeter)" 2>/dev/null || command -v jmeter)")" && pwd)" \
         "$(command -v brew >/dev/null 2>&1 && echo "$(brew --prefix jmeter 2>/dev/null)/libexec/bin")"; do
  if [ -n "$c" ] && [ -x "$c/jmeter" ]; then JBIN="$c"; break; fi
done
[ -n "$JBIN" ] || { echo "RALAT: jmeter tidak dijumpai. Set JMETER_HOME atau tambah jmeter pada PATH." >&2; exit 1; }
JMETER="$JBIN/jmeter"
PCMD="$JBIN/JMeterPluginsCMD.sh"

boleh_sambung() { (exec 3<>"/dev/tcp/$1/$2") 2>/dev/null; }

PID_SUT=""
bersih() { [ -n "$PID_SUT" ] && kill "$PID_SUT" 2>/dev/null || true; }
trap bersih EXIT INT TERM

mkdir -p "$HASIL"

echo "== 1) Semak SUT dan ejen PerfMon =="
if [ "$MULA_SUT" = "1" ]; then
  if boleh_sambung "$HOST" "$PORT"; then echo "RALAT: port $PORT sudah digunakan (MULA_SUT=1)." >&2; exit 1; fi
  PORT="$PORT" node "$ROOT/sut/server.js" > "$HASIL/sut.log" 2>&1 & PID_SUT=$!
  for _ in $(seq 1 20); do boleh_sambung "$HOST" "$PORT" && break; sleep 0.5; done
fi
boleh_sambung "$HOST" "$PORT" || { echo "RALAT: SUT tidak berjalan pada $HOST:$PORT. Mula: node sut/server.js (atau MULA_SUT=1)." >&2; exit 1; }
echo "  OK  SUT  http://$HOST:$PORT"
if ! boleh_sambung "$AGENT_HOST" "$AGENT_PORT"; then
  echo "RALAT: ServerAgent tidak dapat dihubungi pada $AGENT_HOST:$AGENT_PORT (Connection refused)." >&2
  echo "       Pada PELAYAN: ./startAgent.sh --udp-port 0 --tcp-port $AGENT_PORT  — dan buka firewall untuk port itu." >&2
  exit 1
fi
echo "  OK  ServerAgent $AGENT_HOST:$AGENT_PORT"
if [ ! -x "$PCMD" ]; then
  echo "AMARAN: $PCMD tiada — PNG tidak akan dijana. Pasang: PluginsManagerCMD.sh install jpgc-cmd,jpgc-graphs-basic"
fi

echo
echo "== 2) Larian non-GUI: $PENGGUNA pengguna | ramp-up ${RAMPUP}s | tempoh ${TEMPOH}s | SLA ${SLA_MS} ms =="
echo "   Hasil: $HASIL"
"$JMETER" -n -t "$PLAN" \
  -Jpengguna="$PENGGUNA" -Jrampup="$RAMPUP" -Jtempoh="$TEMPOH" \
  -Jhost="$HOST" -Jport="$PORT" -Jsla_ms="$SLA_MS" \
  -Jagent_host="$AGENT_HOST" -Jagent_port="$AGENT_PORT" -Jperfmon_jtl="$HASIL/perfmon.jtl" \
  -Jjmeter.reportgenerator.overall_granularity="$GRAN" \
  -l "$HASIL/keputusan.jtl" -e -o "$HASIL/laporan" \
  -j "$HASIL/jmeter.log"

if [ ! -s "$HASIL/perfmon.jtl" ] || [ "$(wc -l < "$HASIL/perfmon.jtl")" -le 1 ]; then
  echo "AMARAN: perfmon.jtl kosong — semak $HASIL/jmeter.log (cari 'PerfMon')." >&2
fi

if [ -x "$PCMD" ]; then
  echo
  echo "== 3) Eksport graf dengan JMeterPluginsCMD =="
  png() {  # png <fail.png> <input.jtl> <plugin-type> [opsyen tambahan...]
    local out="$1" in="$2" jenis="$3"; shift 3
    "$PCMD" --generate-png "$HASIL/$out" --input-jtl "$HASIL/$in" --plugin-type "$jenis" \
      --width 1200 --height 600 --granulation "$GRAN" --relative-times no "$@" > "$HASIL/pcmd-$jenis.log" 2>&1 \
      && echo "  OK  $out" || echo "  GAGAL $out (lihat $HASIL/pcmd-$jenis.log)"
  }
  png cpu-perfmon.png             perfmon.jtl   PerfMon --auto-scale no
  png response-times-over-time.png keputusan.jtl ResponseTimesOverTime
  png active-threads.png           keputusan.jtl ThreadsStateOverTime
  "$PCMD" --generate-csv "$HASIL/perfmon.csv" --input-jtl "$HASIL/perfmon.jtl" --plugin-type PerfMon \
    --granulation "$GRAN" --relative-times no > "$HASIL/pcmd-csv.log" 2>&1 && echo "  OK  perfmon.csv" || echo "  GAGAL perfmon.csv"
fi

echo
echo "== 4) Ringkasan =="
node "$HERE/ringkasan-chatbot.js" "$HASIL"

echo
echo "Laporan HTML : $HASIL/laporan/index.html"
echo "PerfMon      : $HASIL/perfmon.jtl  (+ cpu-perfmon.png, perfmon.csv)"
