// =====================================================================
//  Ringkasan larian chatbot + PerfMon (dipanggil oleh run-chatbot-perfmon.{sh,bat}).
//    node ringkasan-chatbot.js <folder hasil>
//  Baca <folder>/laporan/statistics.json (p50/p90/p95/p99, Error %, TPS) dan
//  <folder>/perfmon.jtl (CPU/Memory: purata & maks). Tiada pergantungan.
// =====================================================================
const fs = require('fs'), path = require('path');
const dir = process.argv[2];
if (!dir) { console.error('Guna: node ringkasan-chatbot.js <folder hasil>'); process.exit(1); }
const st = JSON.parse(fs.readFileSync(path.join(dir, 'laporan', 'statistics.json'), 'utf8'));
const f = (n) => (n == null ? '-' : Math.round(n));
console.log('Label'.padEnd(36), 'Sampel', ' Err%', '  p50', '  p90', '  p95', '  p99', '   Maks', 'TPS');
for (const [k, s] of Object.entries(st)) {
  console.log(k.slice(0, 36).padEnd(36), String(s.sampleCount).padStart(6), s.errorPct.toFixed(2).padStart(5),
    ...[s.medianResTime, s.pct1ResTime, s.pct2ResTime, s.pct3ResTime].map((v) => String(f(v)).padStart(5)),
    String(f(s.maxResTime)).padStart(7), s.throughput.toFixed(2));
}
// perfmon.jtl: elapsed = nilai metrik x 1000 (cth 85432 = 85.432 %)
const pm = path.join(dir, 'perfmon.jtl');
if (fs.existsSync(pm)) {
  const baris = fs.readFileSync(pm, 'utf8').trim().split('\n').slice(1);
  const ikut = {};
  for (const b of baris) {
    const c = b.split(',');
    (ikut[c[2]] = ikut[c[2]] || []).push(Number(c[1]) / 1000);
  }
  for (const [label, v] of Object.entries(ikut)) {
    const purata = v.reduce((a, b) => a + b, 0) / v.length;
    console.log(`${label}: purata ${purata.toFixed(1)} % | maks ${Math.max(...v).toFixed(1)} % (${v.length} titik)`);
  }
}
