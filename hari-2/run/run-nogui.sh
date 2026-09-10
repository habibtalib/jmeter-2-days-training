#!/usr/bin/env bash
# =====================================================================
#  Larian ujian beban JMeter dalam mod non-GUI + jana laporan HTML.
#  Guna untuk BEBAN SEBENAR (GUI hanya untuk membina/nyahpepijat plan).
#
#  Prasyarat:
#    1) Pelayan tiruan berjalan:  (dalam tetingkap lain)  node ../../sut/server.js
#    2) JMeter ada pada PATH:      jmeter --version
#
#  Penggunaan:
#    ./run-nogui.sh                       # lalai: 50 pengguna, ramp 30s, 120s
#    PENGGUNA=200 TEMPOH=300 ./run-nogui.sh
# =====================================================================
set -euo pipefail

# Direktori skrip ini, supaya laluan relatif sentiasa betul
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAN="$HERE/../test-plans/06-ujian-beban-nogui.jmx"
STAMP="$(date +%Y%m%d-%H%M%S)"
HASIL="$HERE/hasil/$STAMP"
mkdir -p "$HASIL"

# Parameter beban (boleh ganti dengan pembolehubah persekitaran)
PENGGUNA="${PENGGUNA:-50}"
RAMPUP="${RAMPUP:-30}"
TEMPOH="${TEMPOH:-120}"
HOST="${HOST:-localhost}"
PORT="${PORT:-3000}"

echo "Menjalankan ujian beban:"
echo "  Plan     : $PLAN"
echo "  Pengguna : $PENGGUNA  |  Ramp-up: ${RAMPUP}s  |  Tempoh: ${TEMPOH}s"
echo "  Sasaran  : http://$HOST:$PORT"
echo "  Hasil    : $HASIL"
echo

jmeter -n -t "$PLAN" \
  -Jpengguna="$PENGGUNA" -Jrampup="$RAMPUP" -Jtempoh="$TEMPOH" \
  -Jhost="$HOST" -Jport="$PORT" \
  -l "$HASIL/results.jtl" \
  -e -o "$HASIL/laporan" \
  -j "$HASIL/jmeter.log"

echo
echo "Selesai. Buka laporan HTML:"
echo "  $HASIL/laporan/index.html"
