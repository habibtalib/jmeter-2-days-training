#!/usr/bin/env node
// =====================================================================
//  Pembantu laporan berbilang lokasi (dipanggil oleh run-berbilang-lokasi.sh/.bat)
//  Tiada pergantungan — hanya Node.js terbina.
//
//  node laporan-lokasi.js pisah   <semua.jtl> <dir_keluar> KL PENANG ...
//      Pecahkan JTL (CSV) ikut awalan label "[KL] ..." -> <dir_keluar>/KL.jtl
//      Header dikekalkan. Medan berpetik ("a,b" / "" dalam petikan) diurus dengan betul.
//  node laporan-lokasi.js gabung  <keluar.jtl> <a.jtl> <b.jtl> ...
//      Gabung beberapa JTL menjadi satu (header sekali sahaja; header MESTI sama).
//  node laporan-lokasi.js banding <dir_laporan> KL PENANG ...
//      Cetak jadual perbandingan daripada <dir_laporan>/<LOKASI>/statistics.json
// =====================================================================
const fs = require('fs');
const path = require('path');

// Pecah teks CSV kepada rekod mentah (rentetan asal) + medan, hormati petikan.
function rekodCsv(teks) {
  const rekod = [];
  let medan = [], cur = '', mula = 0, dalamPetik = false;
  for (let i = 0; i < teks.length; i++) {
    const c = teks[i];
    if (dalamPetik) {
      if (c === '"') {
        if (teks[i + 1] === '"') { cur += '"'; i++; } else dalamPetik = false;
      } else cur += c;
    } else if (c === '"') dalamPetik = true;
    else if (c === ',') { medan.push(cur); cur = ''; }
    else if (c === '\n' || c === '\r') {
      medan.push(cur);
      rekod.push({ mentah: teks.slice(mula, i), medan });
      if (c === '\r' && teks[i + 1] === '\n') i++;
      medan = []; cur = ''; mula = i + 1;
    } else cur += c;
  }
  if (mula < teks.length) { medan.push(cur); rekod.push({ mentah: teks.slice(mula), medan }); }
  return rekod.filter(r => r.mentah.length > 0);
}

function pisah(jtl, dirKeluar, lokasi) {
  const [header, ...baris] = rekodCsv(fs.readFileSync(jtl, 'utf8'));
  const iLabel = header.medan.indexOf('label');
  if (iLabel < 0) throw new Error('Tiada lajur "label" dalam header ' + jtl + ' (JTL mesti CSV dengan header)');
  fs.mkdirSync(dirKeluar, { recursive: true });
  for (const l of lokasi) {
    const awalan = '[' + l + ']';
    const pilih = baris.filter(r => (r.medan[iLabel] || '').startsWith(awalan));
    const keluar = path.join(dirKeluar, l + '.jtl');
    fs.writeFileSync(keluar, [header.mentah, ...pilih.map(r => r.mentah)].join('\n') + '\n');
    console.log(`  ${awalan.padEnd(10)} ${String(pilih.length).padStart(6)} sampel -> ${keluar}`);
  }
}

function gabung(keluar, input) {
  let headerPertama = null; const semua = [];
  for (const f of input) {
    const [header, ...baris] = rekodCsv(fs.readFileSync(f, 'utf8'));
    if (headerPertama === null) headerPertama = header.mentah;
    else if (header.mentah !== headerPertama)
      throw new Error('Header JTL tidak sama: ' + f + '\n  jangka: ' + headerPertama + '\n  dapat : ' + header.mentah);
    semua.push(...baris);
  }
  // Susun ikut timeStamp supaya graf masa (over time) betul
  const iTs = rekodCsv(headerPertama + '\n')[0].medan.indexOf('timeStamp');
  if (iTs >= 0) semua.sort((a, b) => Number(a.medan[iTs]) - Number(b.medan[iTs]));
  fs.writeFileSync(keluar, [headerPertama, ...semua.map(r => r.mentah)].join('\n') + '\n');
  console.log(`  ${semua.length} sampel daripada ${input.length} fail -> ${keluar}`);
}

function banding(dirLaporan, lokasi) {
  const n = (x, d = 0) => Number(x).toFixed(d);
  const baris = [];
  for (const l of lokasi) {
    const fail = path.join(dirLaporan, l, 'statistics.json');
    if (!fs.existsSync(fail)) { console.log('  (tiada ' + fail + ')'); continue; }
    const st = JSON.parse(fs.readFileSync(fail, 'utf8'));
    // Baris label dahulu (ikut nama), "Total" akhir sekali
    const kunci = Object.keys(st).filter(k => k !== 'Total').sort();
    for (const k of [...kunci, 'Total']) {
      const s = st[k]; if (!s) continue;
      baris.push([l, k === 'Total' ? 'TOTAL (sampel HTTP)' : k.replace('[' + l + '] ', ''),
        s.sampleCount, n(s.errorPct, 2), n(s.meanResTime), n(s.pct1ResTime), n(s.pct2ResTime), n(s.throughput, 2)]);
    }
  }
  const tajuk = ['Lokasi', 'Label', 'Sampel', 'Ralat %', 'Purata ms', 'p90 ms', 'p95 ms', 'TPS'];
  const lebar = tajuk.map((t, i) => Math.max(t.length, ...baris.map(b => String(b[i]).length)));
  const fmt = b => '| ' + b.map((x, i) => i < 2 ? String(x).padEnd(lebar[i]) : String(x).padStart(lebar[i])).join(' | ') + ' |';
  console.log(fmt(tajuk));
  console.log('|' + lebar.map((w, i) => (i < 2 ? '-' : '-').repeat(w + 1) + (i < 2 ? '-' : ':')).join('|') + '|');
  baris.forEach(b => console.log(fmt(b)));
}

const [cmd, ...a] = process.argv.slice(2);
try {
  if (cmd === 'pisah' && a.length >= 3) pisah(a[0], a[1], a.slice(2));
  else if (cmd === 'gabung' && a.length >= 2) gabung(a[0], a.slice(1));
  else if (cmd === 'banding' && a.length >= 2) banding(a[0], a.slice(1));
  else {
    console.error('Guna: node laporan-lokasi.js pisah <semua.jtl> <dir> KL PENANG | gabung <keluar.jtl> <a.jtl> <b.jtl> | banding <dir_laporan> KL PENANG');
    process.exit(2);
  }
} catch (e) { console.error('RALAT: ' + e.message); process.exit(1); }
