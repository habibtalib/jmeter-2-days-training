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
//
//  Data adalah SINTETIK/rekaan — bukan data rasmi JPJ.
// =====================================================================

const http = require('http');
const crypto = require('crypto');

const PORT = process.env.PORT || 3000;

// Latensi tiruan (ms) — supaya keputusan JMeter kelihatan realistik.
// Boleh laras dengan pembolehubah persekitaran untuk demo "sebelum vs selepas".
const LATENCY_MIN = Number(process.env.LATENCY_MIN || 40);
const LATENCY_MAX = Number(process.env.LATENCY_MAX || 180);
// Kadar ralat pelayan tiruan (5xx). 0.01 = 1% permintaan bayaran gagal.
const ERROR_RATE = Number(process.env.ERROR_RATE || 0.01);

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
      '</ul>');
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

  // Tidak dijumpai
  return kirim(res, 404, { ralat: 'Laluan tidak dijumpai', laluan });
});

server.listen(PORT, () => {
  console.log(`Portal eJPJ (TIRUAN) berjalan di  http://localhost:${PORT}`);
  console.log(`  Latensi tiruan : ${LATENCY_MIN}-${LATENCY_MAX} ms`);
  console.log(`  Kadar ralat    : ${(ERROR_RATE * 100).toFixed(1)}%`);
  console.log('  Tekan Ctrl+C untuk berhenti.');
});
