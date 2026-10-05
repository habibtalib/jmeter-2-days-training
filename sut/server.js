// =====================================================================
//  Portal eJPJ (TIRUAN) — Sistem Under Test untuk latihan Apache JMeter
// ---------------------------------------------------------------------
//  Aplikasi TIRUAN yang meniru beberapa perkhidmatan dalam talian JPJ
//  (log masuk, semak kenderaan, bayar cukai jalan, semak & bayar saman).
//  Ia WUJUD SEMATA-MATA sebagai sasaran ujian prestasi tempatan supaya
//  peserta TIDAK PERNAH menyerang pelayan JPJ sebenar.
//
//  - Tiada pergantungan (dependency). Guna modul `http` terbina Node.js.
//  - Jalankan:  node server.js       (lalai port 3000)
//               PORT=8080 node server.js
//  - POST /api/chatbot = "Chatbot eJPJ tiruan": buat kerja CPU SEBENAR
//    (gelung aritmetik dalam worker thread) supaya CPU pelayan naik ikut
//    beban — untuk latihan PerfMon (CPU via ejen) dan p95/p99.
//
//  Data adalah SINTETIK/rekaan — bukan data rasmi JPJ.
// =====================================================================

const http = require('http');
const crypto = require('crypto');
const os = require('os');
const { Worker } = require('worker_threads');

const PORT = process.env.PORT || 3000;

// Latensi tiruan (ms) — supaya keputusan JMeter kelihatan realistik.
// Boleh laras dengan pembolehubah persekitaran untuk demo "sebelum vs selepas".
const LATENCY_MIN = Number(process.env.LATENCY_MIN || 40);
const LATENCY_MAX = Number(process.env.LATENCY_MAX || 180);
// Kadar ralat pelayan tiruan (5xx). 0.01 = 1% permintaan bayaran gagal.
const ERROR_RATE = Number(process.env.ERROR_RATE || 0.01);
// Chatbot tiruan: CHATBOT_KERJA = pengganda kerja CPU (1 = ~5 ms CPU setiap token;
// kebanyakan jawapan 60-180 token = ~300-900 ms, ~2.5% jawapan panjang 600-1200
// token = 3-6 s). CHATBOT_PEKERJA = saiz kolam worker thread (lalai = bilangan teras).
const CHATBOT_KERJA = Number(process.env.CHATBOT_KERJA || 1);
const CHATBOT_PEKERJA = Number(process.env.CHATBOT_PEKERJA || os.cpus().length);

// ---------------------------------------------------------------------
//  Data sintetik dalam memori
// ---------------------------------------------------------------------
const KENDERAAN = {
  '800101015500': [
    { no_pendaftaran: 'WXY1234', model: 'Perodua Myvi 1.5', tarikh_luput_cukai: '2026-02-14', amaun_cukai: 90.00 },
    { no_pendaftaran: 'VAB88',   model: 'Honda Civic 1.8',  tarikh_luput_cukai: '2026-03-01', amaun_cukai: 384.00 },
  ],
  '900202025600': [
    { no_pendaftaran: 'JQK7788', model: 'Proton X50 1.5T',  tarikh_luput_cukai: '2026-01-20', amaun_cukai: 130.00 },
  ],
  '850303035700': [
    { no_pendaftaran: 'BMT3030', model: 'Toyota Hilux 2.4', tarikh_luput_cukai: '2026-02-28', amaun_cukai: 837.00 },
    { no_pendaftaran: 'PKL909',  model: 'Perodua Axia 1.0', tarikh_luput_cukai: '2026-04-10', amaun_cukai: 20.00 },
  ],
};

const SAMAN = {
  '800101015500': [
    { id: 'JPJ2026A001', seksyen: 'Kaedah 11 LN 166/59', amaun: 150.00, status: 'BELUM BAYAR' },
  ],
  '900202025600': [
    { id: 'JPJ2026A014', seksyen: 'Seksyen 70(3) APJ 1987', amaun: 300.00, status: 'BELUM BAYAR' },
    { id: 'JPJ2026A015', seksyen: 'Kaedah 11 LN 166/59',    amaun: 150.00, status: 'BELUM BAYAR' },
  ],
  '850303035700': [],
};

// Token sesi yang sah (dikeluarkan semasa log masuk).
const SESI = new Map(); // token -> { no_kp, csrf }

// ---------------------------------------------------------------------
//  Pembantu (helpers)
// ---------------------------------------------------------------------
function delay() {
  const ms = LATENCY_MIN + Math.random() * Math.max(0, LATENCY_MAX - LATENCY_MIN);
  return new Promise((r) => setTimeout(r, ms));
}

function kirim(res, kod, objek) {
  const badan = JSON.stringify(objek);
  res.writeHead(kod, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(badan),
    'Cache-Control': 'no-store',
  });
  res.end(badan);
}

function bacaBadan(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (c) => (data += c));
    req.on('end', () => {
      if (!data) return resolve({});
      try { resolve(JSON.parse(data)); } catch { resolve({ _mentah: data }); }
    });
  });
}

function tokenDari(req) {
  const h = req.headers['authorization'] || '';
  return h.startsWith('Bearer ') ? h.slice(7).trim() : null;
}

function sesiSah(req) {
  const t = tokenDari(req);
  return t && SESI.has(t) ? SESI.get(t) : null;
}

function tarikhTambahBulan(bulan) {
  const d = new Date();
  d.setMonth(d.getMonth() + Number(bulan || 12));
  return d.toISOString().slice(0, 10);
}

// ---------------------------------------------------------------------
//  Chatbot eJPJ tiruan — "jana token" = kerja CPU sebenar (gelung
//  aritmetik xorshift, JS tulen) dalam kolam worker thread. Bila semua worker sibuk, soalan
//  BERATUR -> CPU tepu, response time & p95/p99 naik. Kolam dicipta
//  hanya pada soalan pertama (endpoint lain tidak terjejas).
// ---------------------------------------------------------------------
// JS tulen (bukan crypto) supaya kerja berskala linear merentas teras.
function kerjaCpu(ulangan, x) {
  for (let i = 0; i < ulangan; i++) { x ^= x << 13; x ^= x >>> 17; x ^= x << 5; }
  return x;
}
const KOD_PEKERJA = `
const { parentPort } = require('worker_threads');
${kerjaCpu.toString()}
let x = 2463534242;
parentPort.on('message', ({ id, ulangan }) => {
  x = kerjaCpu(ulangan, x) || 1;
  parentPort.postMessage({ id, x });
});`;

let ulanganSetiapMs = 0;  // ditentukur sekali: berapa ulangan = 1 ms CPU pada mesin ini
function tentukur() {
  let x = 88172645;
  const ukur = (ms) => {
    let n = 0;
    const mula = process.hrtime.bigint();
    while (process.hrtime.bigint() - mula < BigInt(ms) * 1000000n) {
      x = kerjaCpu(100000, x) || 1;
      n += 100000;
    }
    return n / ms;
  };
  ukur(300);                                          // panaskan JIT dahulu
  ulanganSetiapMs = Math.max(1, Math.round(ukur(200)));
}

const KOLAM = { pekerja: [], lapang: [], giliran: [], tugas: new Map(), id: 0 };
function jalankanKerja(ulangan) {
  if (!KOLAM.pekerja.length) {
    tentukur();
    for (let i = 0; i < Math.max(1, CHATBOT_PEKERJA); i++) {
      const w = new Worker(KOD_PEKERJA, { eval: true });
      w.on('message', ({ id }) => {
        const selesai = KOLAM.tugas.get(id);
        KOLAM.tugas.delete(id);
        KOLAM.lapang.push(w);
        agih();
        selesai();
      });
      KOLAM.pekerja.push(w);
      KOLAM.lapang.push(w);
    }
  }
  return new Promise((selesai) => {
    const id = ++KOLAM.id;
    KOLAM.tugas.set(id, selesai);
    KOLAM.giliran.push({ id, ulangan });
    agih();
  });
}
function agih() {
  while (KOLAM.lapang.length && KOLAM.giliran.length) KOLAM.lapang.pop().postMessage(KOLAM.giliran.shift());
}

// Soalan lazim (FAQ) sintetik — padanan kata kunci ringkas, BUKAN jawapan rasmi JPJ.
const FAQ = [
  [/cukai|lkm|roadtax|road tax/i, 'Cukai jalan boleh diperbaharui dalam talian melalui Portal eJPJ (tiruan) selepas insurans kenderaan sah. Semak amaun di menu Kenderaan Saya.'],
  [/lesen|ldl|cdl|psv|gdl/i, 'Lesen memandu boleh diperbaharui 1 hingga 10 tahun. Pastikan tiada saman tertunggak dan rekod perubatan (jika perlu) dikemas kini.'],
  [/saman|kompaun|denda/i, 'Saman JPJ boleh disemak dengan No. KP di menu Saman. Bayaran kompaun dalam talian dikemas kini dalam 1 hari bekerja (data sintetik).'],
  [/hak milik|tukar milik|pindah milik|jual/i, 'Pertukaran hak milik memerlukan pengesahan biometrik pembeli dan penjual di kaunter atau ejen yang dibenarkan.'],
  [/nombor|no\. pendaftaran|plat|bidaan/i, 'Nombor pendaftaran pilihan boleh dibida melalui sistem bidaan dalam talian (tiruan). Keputusan bidaan diumumkan selepas tempoh tutup.'],
  [/myjpj|aplikasi|daftar akaun|kata laluan/i, 'Akaun boleh didaftar menggunakan No. KP dan e-mel aktif. Jika terlupa kata laluan, guna pautan "Lupa kata laluan".'],
];
const JAWAPAN_LALAI = 'Maaf, saya chatbot TIRUAN untuk latihan JMeter. Sila cuba soalan tentang cukai jalan, lesen, saman atau hak milik kenderaan.';

function tokenUntukDijana() {
  // Taburan ekor panjang (long tail): kebanyakan jawapan pendek, sedikit sangat panjang
  return Math.random() < 0.025
    ? 600 + Math.floor(Math.random() * 601)   // ~2.5%: jawapan panjang (3-6 s)
    : 60 + Math.floor(Math.random() * 121);   // biasa: 60-180 token (0.3-0.9 s)
}

// ---------------------------------------------------------------------
//  Portal web (borang HTML) — untuk latihan RAKAMAN melalui browser.
//  Sesi guna cookie SESI_EJPJ; borang bayar ada medan tersembunyi `csrf`.
// ---------------------------------------------------------------------
const SESI_WEB = new Map(); // id cookie -> { no_kp, csrf }

function cookieSesi(req) {
  const c = req.headers['cookie'] || '';
  const m = c.match(/(?:^|;\s*)SESI_EJPJ=([^;]+)/);
  return m && SESI_WEB.has(m[1]) ? { id: m[1], ...SESI_WEB.get(m[1]) } : null;
}

function bacaBorang(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (c) => (data += c));
    req.on('end', () => resolve(Object.fromEntries(new URLSearchParams(data))));
  });
}

function halaman(res, kod, tajuk, isi, headers = {}) {
  const html = `<!doctype html><html lang="ms"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>${tajuk} · Portal eJPJ (TIRUAN)</title>
<link rel="stylesheet" href="/portal/gaya.css"><link rel="icon" href="/portal/favicon.svg"></head><body>
<header><b>Portal eJPJ</b> <span class="tiruan">TIRUAN · latihan JMeter</span></header>
<main><h1>${tajuk}</h1>${isi}</main>
<footer>Data sintetik — bukan sistem atau data rasmi JPJ.</footer></body></html>`;
  res.writeHead(kod, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store', ...headers });
  res.end(html);
}

function lencong(res, ke, headers = {}) {
  res.writeHead(302, { Location: ke, 'Cache-Control': 'no-store', ...headers });
  res.end();
}

function cariKenderaan(no) {
  for (const senarai of Object.values(KENDERAAN)) {
    const k = senarai.find((x) => x.no_pendaftaran === no);
    if (k) return k;
  }
  return null;
}

const GAYA = `body{font-family:system-ui,Segoe UI,Arial,sans-serif;margin:0;background:#f4f6fa;color:#14213d}
header{background:#0b2a6b;color:#fff;padding:12px 20px}header .tiruan{background:#ffc20e;color:#14213d;border-radius:4px;padding:2px 8px;margin-left:8px;font-size:12px}
main{max-width:720px;margin:24px auto;background:#fff;padding:24px;border-radius:8px;box-shadow:0 1px 4px rgba(0,0,0,.08)}
label{display:block;margin:12px 0 4px;font-weight:600}input,select{padding:8px;width:100%;box-sizing:border-box;border:1px solid #c7d0e0;border-radius:6px}
button,.butang{margin-top:16px;background:#0b2a6b;color:#fff;border:0;padding:10px 18px;border-radius:6px;text-decoration:none;display:inline-block;cursor:pointer}
table{width:100%;border-collapse:collapse;margin-top:12px}td,th{border-bottom:1px solid #e3e8f0;padding:8px;text-align:left}
.ralat{background:#fde8e8;color:#9b1c1c;padding:10px;border-radius:6px}.berjaya{background:#e6f6ec;color:#14532d;padding:10px;border-radius:6px}
footer{text-align:center;color:#6b7280;font-size:12px;margin:24px}`;
const FAVICON = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><rect width="16" height="16" rx="3" fill="#0b2a6b"/><text x="8" y="12" font-size="10" text-anchor="middle" fill="#ffc20e">J</text></svg>';

// ---------------------------------------------------------------------
//  Penghala (router)
// ---------------------------------------------------------------------
const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const laluan = url.pathname;
  const method = req.method;

  await delay(); // setiap permintaan menanggung latensi tiruan

  // Halaman info / semakan kesihatan
  if (method === 'GET' && (laluan === '/' || laluan === '/api/health')) {
    if (laluan === '/api/health') return kirim(res, 200, { status: 'ok', masa: new Date().toISOString() });
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    return res.end(
      '<h1>Portal eJPJ (TIRUAN)</h1>' +
      '<p>Sistem Under Test untuk latihan Apache JMeter. Data sintetik, bukan rasmi JPJ.</p>' +
      '<ul>' +
      '<li>POST /api/log-masuk</li>' +
      '<li>GET  /api/kenderaan?no_kp=800101015500</li>' +
      '<li>GET  /api/kenderaan/:no_pendaftaran/cukai</li>' +
      '<li>POST /api/kenderaan/:no_pendaftaran/bayar-cukai</li>' +
      '<li>GET  /api/saman?no_kp=800101015500</li>' +
      '<li>POST /api/saman/:id/bayar</li>' +
      '<li>POST /api/chatbot  {"soalan":"..."} — chatbot tiruan (kerja CPU sebenar)</li>' +
      '</ul>' +
      '<p><b>Portal web (untuk latihan rakaman melalui browser):</b> <a href="/portal">/portal</a></p>');
  }

  // ---- Log masuk: pulangkan token + csrf (untuk latihan korelasi) ----
  if (method === 'POST' && laluan === '/api/log-masuk') {
    const badan = await bacaBadan(req);
    const no_kp = String(badan.no_kp || '').trim();
    const kata_laluan = String(badan.kata_laluan || '').trim();
    if (!no_kp || !kata_laluan) {
      return kirim(res, 401, { ralat: 'No. KP atau kata laluan tidak sah' });
    }
    const token = crypto.randomUUID();
    const csrf = crypto.randomBytes(16).toString('hex');
    SESI.set(token, { no_kp, csrf });
    return kirim(res, 200, {
      token,
      csrf,                         // <-- peserta perlu EKSTRAK nilai dinamik ini
      nama: 'Pengguna ' + no_kp.slice(-4),
      mesej: 'Log masuk berjaya',
    });
  }

  // ---- Senarai kenderaan (perlu token) ----
  if (method === 'GET' && laluan === '/api/kenderaan') {
    const sesi = sesiSah(req);
    if (!sesi) return kirim(res, 401, { ralat: 'Token tidak sah atau tamat tempoh' });
    const no_kp = url.searchParams.get('no_kp') || sesi.no_kp;
    return kirim(res, 200, { no_kp, kenderaan: KENDERAAN[no_kp] || [] });
  }

  // ---- Sebut harga cukai untuk satu kenderaan ----
  let m = laluan.match(/^\/api\/kenderaan\/([^/]+)\/cukai$/);
  if (method === 'GET' && m) {
    const no = decodeURIComponent(m[1]);
    for (const senarai of Object.values(KENDERAAN)) {
      const k = senarai.find((x) => x.no_pendaftaran === no);
      if (k) return kirim(res, 200, { no_pendaftaran: no, amaun: k.amaun_cukai, tempoh_bulan: 12 });
    }
    return kirim(res, 404, { ralat: 'Kenderaan tidak dijumpai' });
  }

  // ---- Bayar cukai jalan (perlu token + csrf yang betul) ----
  m = laluan.match(/^\/api\/kenderaan\/([^/]+)\/bayar-cukai$/);
  if (method === 'POST' && m) {
    const sesi = sesiSah(req);
    if (!sesi) return kirim(res, 401, { ralat: 'Token tidak sah atau tamat tempoh' });
    const badan = await bacaBadan(req);
    if (!badan.csrf || badan.csrf !== sesi.csrf) {
      return kirim(res, 403, { ralat: 'Token CSRF tidak sah — sila log masuk semula' });
    }
    // Ralat pelayan tiruan (untuk demo peratus ralat & assertion)
    if (Math.random() < ERROR_RATE) {
      return kirim(res, 500, { ralat: 'Ralat pelayan dalaman — sila cuba lagi' });
    }
    const no = decodeURIComponent(m[1]);
    return kirim(res, 200, {
      no_resit: 'RJPJ' + Date.now().toString().slice(-9),
      no_pendaftaran: no,
      amaun: badan.amaun || null,
      tarikh_luput_baru: tarikhTambahBulan(badan.tempoh_bulan || 12),
      status: 'BERJAYA',
    });
  }

  // ---- Semak saman ----
  if (method === 'GET' && laluan === '/api/saman') {
    const no_kp = url.searchParams.get('no_kp') || '';
    return kirim(res, 200, { no_kp, saman: SAMAN[no_kp] || [] });
  }

  // ---- Bayar saman (perlu csrf) ----
  m = laluan.match(/^\/api\/saman\/([^/]+)\/bayar$/);
  if (method === 'POST' && m) {
    const sesi = sesiSah(req);
    if (!sesi) return kirim(res, 401, { ralat: 'Token tidak sah atau tamat tempoh' });
    const badan = await bacaBadan(req);
    if (!badan.csrf || badan.csrf !== sesi.csrf) {
      return kirim(res, 403, { ralat: 'Token CSRF tidak sah' });
    }
    return kirim(res, 200, { no_resit: 'SJPJ' + Date.now().toString().slice(-9), id: m[1], status: 'BAYAR' });
  }

  // ---- Chatbot eJPJ tiruan: kerja CPU sebenar, masa ikut "token dijana" ----
  if (method === 'POST' && laluan === '/api/chatbot') {
    const badan = await bacaBadan(req);
    const soalan = String(badan.soalan || '').trim();
    if (!soalan) return kirim(res, 400, { ralat: 'Medan soalan diperlukan' });
    const mula = Date.now();
    const token_dijana = tokenUntukDijana();
    await jalankanKerja(Math.round(token_dijana * 5 * CHATBOT_KERJA * ulanganSetiapMs || 1));
    if (Math.random() < ERROR_RATE) {
      return kirim(res, 500, { ralat: 'Chatbot tidak dapat menjana jawapan — sila cuba lagi' });
    }
    const padan = FAQ.find(([re]) => re.test(soalan));
    return kirim(res, 200, {
      jawapan: padan ? padan[1] : JAWAPAN_LALAI,
      token_dijana,
      masa_ms: Date.now() - mula,
    });
  }

  // =================== Portal web (borang) ===================
  if (method === 'GET' && (laluan === '/portal' || laluan === '/portal/')) return lencong(res, '/portal/log-masuk');
  if (method === 'GET' && laluan === '/portal/gaya.css') {
    res.writeHead(200, { 'Content-Type': 'text/css; charset=utf-8', 'Cache-Control': 'max-age=3600' });
    return res.end(GAYA);
  }
  if (method === 'GET' && laluan === '/portal/favicon.svg') {
    res.writeHead(200, { 'Content-Type': 'image/svg+xml', 'Cache-Control': 'max-age=3600' });
    return res.end(FAVICON);
  }

  // Borang log masuk
  if (method === 'GET' && laluan === '/portal/log-masuk') {
    return halaman(res, 200, 'Log Masuk', `
<form method="post" action="/portal/log-masuk">
  <label for="no_kp">No. Kad Pengenalan</label><input id="no_kp" name="no_kp" value="800101015500" required>
  <label for="kata_laluan">Kata laluan</label><input id="kata_laluan" name="kata_laluan" type="password" value="rahsia123" required>
  <button type="submit">Log masuk</button>
</form>
<p>Pengguna contoh: 800101015500 · 900202025600 · 850303035700 (kata laluan apa-apa).</p>`);
  }
  if (method === 'POST' && laluan === '/portal/log-masuk') {
    const b = await bacaBorang(req);
    const no_kp = String(b.no_kp || '').trim();
    if (!no_kp || !String(b.kata_laluan || '').trim()) {
      return halaman(res, 401, 'Log Masuk', '<p class="ralat">No. KP atau kata laluan tidak sah.</p><a class="butang" href="/portal/log-masuk">Cuba lagi</a>');
    }
    const id = crypto.randomUUID();
    SESI_WEB.set(id, { no_kp, csrf: crypto.randomBytes(16).toString('hex') });
    return lencong(res, '/portal/kenderaan', { 'Set-Cookie': `SESI_EJPJ=${id}; Path=/portal; HttpOnly; SameSite=Lax` });
  }
  if (method === 'GET' && laluan === '/portal/log-keluar') {
    const s = cookieSesi(req);
    if (s) SESI_WEB.delete(s.id);
    return lencong(res, '/portal/log-masuk', { 'Set-Cookie': 'SESI_EJPJ=; Path=/portal; Max-Age=0' });
  }

  // Senarai kenderaan (perlu cookie sesi)
  if (method === 'GET' && laluan === '/portal/kenderaan') {
    const s = cookieSesi(req);
    if (!s) return lencong(res, '/portal/log-masuk');
    const baris = (KENDERAAN[s.no_kp] || []).map((k) =>
      `<tr><td>${k.no_pendaftaran}</td><td>${k.model}</td><td>${k.tarikh_luput_cukai}</td><td>RM ${k.amaun_cukai.toFixed(2)}</td>` +
      `<td><a class="butang" href="/portal/kenderaan/${encodeURIComponent(k.no_pendaftaran)}/bayar">Bayar cukai</a></td></tr>`).join('');
    return halaman(res, 200, 'Kenderaan Saya', `<p>No. KP: <b>${s.no_kp}</b> · <a href="/portal/log-keluar">Log keluar</a></p>
<table><tr><th>No. Pendaftaran</th><th>Model</th><th>Luput cukai</th><th>Amaun</th><th></th></tr>${baris}</table>`);
  }

  // Borang bayar cukai: medan tersembunyi csrf (nilai dinamik untuk korelasi)
  m = laluan.match(/^\/portal\/kenderaan\/([^/]+)\/bayar$/);
  if (m && method === 'GET') {
    const s = cookieSesi(req);
    if (!s) return lencong(res, '/portal/log-masuk');
    const no = decodeURIComponent(m[1]);
    const k = cariKenderaan(no);
    if (!k) return halaman(res, 404, 'Bayar Cukai Jalan', '<p class="ralat">Kenderaan tidak dijumpai.</p>');
    return halaman(res, 200, 'Bayar Cukai Jalan', `
<form method="post" action="/portal/kenderaan/${encodeURIComponent(no)}/bayar">
  <input type="hidden" name="csrf" value="${s.csrf}">
  <input type="hidden" name="amaun" value="${k.amaun_cukai.toFixed(2)}">
  <p>Kenderaan <b>${no}</b> (${k.model}) · Amaun <b>RM ${k.amaun_cukai.toFixed(2)}</b></p>
  <label for="tempoh_bulan">Tempoh</label>
  <select id="tempoh_bulan" name="tempoh_bulan"><option value="12" selected>12 bulan</option><option value="6">6 bulan</option></select>
  <button type="submit">Bayar sekarang</button>
</form>`);
  }
  if (m && method === 'POST') {
    const s = cookieSesi(req);
    if (!s) return lencong(res, '/portal/log-masuk');
    const b = await bacaBorang(req);
    if (!b.csrf || b.csrf !== s.csrf) {
      return halaman(res, 403, 'Bayar Cukai Jalan', '<p class="ralat">Token CSRF tidak sah — sila log masuk semula.</p>');
    }
    if (Math.random() < ERROR_RATE) {
      return halaman(res, 500, 'Ralat', '<p class="ralat">Ralat pelayan dalaman — sila cuba lagi.</p>');
    }
    const no = decodeURIComponent(m[1]);
    const resit = 'RJPJ' + Date.now().toString().slice(-9);
    return halaman(res, 200, 'Pembayaran Berjaya', `<p class="berjaya">Status: <b>BERJAYA</b></p>
<table><tr><th>No. Resit</th><td id="no_resit">${resit}</td></tr><tr><th>Kenderaan</th><td>${no}</td></tr>
<tr><th>Amaun</th><td>RM ${b.amaun || '-'}</td></tr><tr><th>Luput baharu</th><td>${tarikhTambahBulan(b.tempoh_bulan || 12)}</td></tr></table>
<a class="butang" href="/portal/kenderaan">Kembali ke senarai kenderaan</a>`);
  }

  // Tidak dijumpai
  return kirim(res, 404, { ralat: 'Laluan tidak dijumpai', laluan });
});

server.listen(PORT, () => {
  console.log(`Portal eJPJ (TIRUAN) berjalan di  http://localhost:${PORT}`);
  console.log(`  Latensi tiruan : ${LATENCY_MIN}-${LATENCY_MAX} ms`);
  console.log(`  Kadar ralat    : ${(ERROR_RATE * 100).toFixed(1)}%`);
  console.log(`  Portal web     : http://localhost:${PORT}/portal  (untuk rakaman browser)`);
  console.log(`  Chatbot        : POST /api/chatbot  (kerja x${CHATBOT_KERJA}, ${CHATBOT_PEKERJA} worker thread)`);
  console.log('  Tekan Ctrl+C untuk berhenti.');
});
