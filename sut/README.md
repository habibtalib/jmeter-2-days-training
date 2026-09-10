# Portal eJPJ (Tiruan) — Sistem Under Test (SUT)

Aplikasi **tiruan** yang meniru beberapa perkhidmatan dalam talian JPJ (log masuk, semak kenderaan, bayar cukai jalan, semak & bayar saman). Ia wujud **semata-mata sebagai sasaran ujian prestasi tempatan**, supaya sepanjang kursus ini kita **tidak sekali-kali** menghantar beban ke pelayan JPJ sebenar.

> ⚠️ **Etika & undang-undang:** Menjalankan ujian beban terhadap sistem awam/pengeluaran yang anda tidak miliki atau tidak diberi kebenaran bertulis adalah menyalahi undang-undang (setara serangan DoS). Kita menguji **salinan tempatan** ini sahaja. Data adalah **sintetik/rekaan** — bukan data rasmi JPJ.

## Keperluan

- **Node.js 18+** — itu sahaja. **Tiada** pergantungan (dependency); pelayan hanya guna modul `http` terbina Node.js. Tidak perlu `npm install`.

## Menjalankan

```bash
cd sut
node server.js
```

Anda akan nampak:

```
Portal eJPJ (TIRUAN) berjalan di  http://localhost:3000
  Latensi tiruan : 40-180 ms
  Kadar ralat    : 1.0%
```

Biarkan tetingkap ini terbuka sepanjang lab. Buka `http://localhost:3000` dalam pelayar untuk senarai endpoint.

### Laras kelakuan (untuk demo "sebelum vs selepas")

| Pembolehubah | Lalai | Kesan |
|--------------|-------|-------|
| `PORT` | `3000` | Port pelayan |
| `LATENCY_MIN` / `LATENCY_MAX` | `40` / `180` | Julat latensi tiruan (ms) setiap permintaan |
| `ERROR_RATE` | `0.01` | Kebarangkalian ralat 500 pada endpoint bayar cukai (0–1) |

Contoh — buat pelayan "perlahan" untuk menunjukkan kesan pada percentile & throughput:

```bash
LATENCY_MIN=200 LATENCY_MAX=800 ERROR_RATE=0.05 node server.js
```

## Endpoint

| Kaedah | Laluan | Perlu token? | Keterangan |
|--------|--------|:---:|------------|
| GET | `/` | – | Halaman info (HTML) |
| GET | `/api/health` | – | Semakan kesihatan `{status:"ok"}` |
| POST | `/api/log-masuk` | – | Badan `{no_kp, kata_laluan}` → `{token, csrf, nama}` |
| GET | `/api/kenderaan?no_kp=` | ✅ | Senarai kenderaan pengguna |
| GET | `/api/kenderaan/:no/cukai` | – | Sebut harga cukai `{amaun, tempoh_bulan}` |
| POST | `/api/kenderaan/:no/bayar-cukai` | ✅ | Badan `{csrf, tempoh_bulan, amaun}` → resit |
| GET | `/api/saman?no_kp=` | – | Senarai saman |
| POST | `/api/saman/:id/bayar` | ✅ | Badan `{csrf}` → resit |

**Pengesahan:** hantar header `Authorization: Bearer <token>` (token dari `/api/log-masuk`). Endpoint bayaran juga menyemak medan `csrf` dalam badan mesti sepadan dengan sesi — inilah nilai **dinamik** yang perlu di-**korelasi** pada Hari 2.

### Contoh cepat dengan `curl`

```bash
# 1) Log masuk — dapatkan token + csrf
curl -s -X POST http://localhost:3000/api/log-masuk \
  -H 'Content-Type: application/json' \
  -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}'

# 2) Senarai kenderaan (guna token dari langkah 1)
curl -s "http://localhost:3000/api/kenderaan?no_kp=800101015500" \
  -H "Authorization: Bearer <TOKEN>"

# 3) Sebut harga cukai
curl -s http://localhost:3000/api/kenderaan/WXY1234/cukai

# 4) Bayar cukai (guna token + csrf dari langkah 1)
curl -s -X POST http://localhost:3000/api/kenderaan/WXY1234/bayar-cukai \
  -H "Authorization: Bearer <TOKEN>" -H 'Content-Type: application/json' \
  -d '{"csrf":"<CSRF>","tempoh_bulan":12,"amaun":90}'
```

## Pengguna & kenderaan tiruan

| `no_kp` | Kenderaan (`no_pendaftaran`) |
|---------|------------------------------|
| `800101015500` | `WXY1234`, `VAB88` |
| `900202025600` | `JQK7788` |
| `850303035700` | `BMT3030`, `PKL909` |

Kata laluan: mock menerima **apa-apa** nilai bukan-kosong.
