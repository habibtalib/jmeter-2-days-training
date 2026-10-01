# Lab Hari 1 — Asas JMeter & Ujian Beban

Selesaikan latihan ini untuk mengukuhkan kemahiran Hari 1. Pastikan **pelayan tiruan berjalan** dahulu:

```bash
cd sut && node server.js      # biarkan terbuka
```

Fail rujukan (jawapan) ada dalam `hari-1/test-plans/`. Cuba bina sendiri dahulu sebelum membukanya.

---

## Latihan 1 — Test Plan pertama anda

1. Buka JMeter (GUI). Tambah **Thread Group** (1 pengguna, 1 gelung).
2. Tambah **HTTP Request Defaults**: server `localhost`, port `3000`.
3. Tambah **HTTP Request** → `GET /api/health`.
4. Tambah **Listener → View Results Tree**.
5. Jalankan (▶). Sahkan respons `{"status":"ok"}` dan kod **200**.

> Bandingkan dengan `test-plans/01-hello-jpj.jmx`.

### ✅ Checkpoint

- [ ] Test Plan berjalan dan View Results Tree menunjukkan kod **200** dengan respons `{"status":"ok"}`
- [ ] Struktur plan sepadan dengan `test-plans/01-hello-jpj.jmx` (Thread Group → HTTP Request Defaults → HTTP Request → Listener)

## Latihan 2 — Ujian beban + assertion + timer

1. Tukar Thread Group kepada **20 pengguna**, **ramp-up 10s**, **5 gelung**.
2. Sampler: `GET /api/kenderaan/WXY1234/cukai`.
3. Tambah **Response Assertion** — Text Response mengandungi `amaun`.
4. Tambah **Duration Assertion** — 2000 ms.
5. Tambah **Constant Timer** 300 ms (think time).
6. Tambah **Summary Report** dan **Aggregate Report**.
7. Jalankan. Catat: **Throughput**, **Average**, **Error %**.

> **Soalan:** Berapa jumlah permintaan dijangka? (20 × 5 = 100). Sahkan.
> Bandingkan dengan `test-plans/02-cukai-beban.jmx`.

### ✅ Checkpoint

- [ ] Thread Group ditetapkan 20 pengguna, ramp-up 10s, 5 gelung
- [ ] Response Assertion (`amaun`) dan Duration Assertion (2000 ms) ditambah, serta Constant Timer 300 ms
- [ ] Summary Report menunjukkan **100** permintaan dengan Error % 0%
- [ ] Nilai **Throughput**, **Average** dan **Error %** dicatat

## Latihan 3 — Parameterisasi dengan CSV

1. Tambah **CSV Data Set Config** membaca `../data/kenderaan.csv`
   (variable names: `no_pendaftaran,model`; recycle: **True**).
2. Ubah path sampler kepada `/api/kenderaan/${no_pendaftaran}/cukai`.
3. Jalankan (10 pengguna × 10 gelung). Dalam View Results Tree, sahkan
   setiap permintaan guna nombor pendaftaran berlainan.

> Bandingkan dengan `test-plans/03-csv-berparameter.jmx`.

### ✅ Checkpoint

- [ ] CSV Data Set Config membaca `../data/kenderaan.csv` dengan pembolehubah `no_pendaftaran,model`
- [ ] Path sampler menggunakan `${no_pendaftaran}`
- [ ] View Results Tree menunjukkan nombor pendaftaran berlainan bagi setiap permintaan

## Latihan 4 — Buat assertion GAGAL (belajar dari kegagalan)

1. Tambah satu baris palsu pada `hari-1/data/kenderaan.csv`, cth: `ABC0000,Kereta Hantu`.
2. Jalankan semula Latihan 3. Perhatikan permintaan `ABC0000` **gagal**
   assertion (`amaun` tiada — endpoint pulangkan **404**).
3. Lihat **Error %** meningkat dalam Summary Report. Buang baris palsu selepas selesai.

### ✅ Checkpoint

- [ ] Permintaan `ABC0000` gagal assertion (endpoint pulangkan **404**)
- [ ] Error % dalam Summary Report meningkat
- [ ] Baris palsu dibuang dari `kenderaan.csv` selepas selesai

## Latihan 5 — Kesan latensi terhadap prestasi

1. Hentikan pelayan (Ctrl+C). Mulakan semula dengan latensi tinggi:
   ```bash
   LATENCY_MIN=300 LATENCY_MAX=900 node server.js
   ```
2. Jalankan semula Latihan 2. Bandingkan **Average** dan **Throughput** dengan larian asal.

> **Soalan reflektif:** Mengapa throughput jatuh apabila latensi naik walaupun bilangan pengguna sama? (Petunjuk: setiap thread menunggu lebih lama sebelum boleh menghantar permintaan seterusnya.)

### ✅ Checkpoint

- [ ] Pelayan dimulakan semula dengan `LATENCY_MIN=300 LATENCY_MAX=900`
- [ ] Average dan Throughput dibandingkan dengan larian asal Latihan 2
- [ ] Boleh menerangkan mengapa throughput jatuh apabila latensi naik

## Latihan 6 — Rakam Test Plan & lihat ia gagal main balik

1. **Klik kanan Test Plan → Add → Non-Test Elements → HTTP(S) Test Script Recorder.**
   Tambah **Recording Controller** di bawah Thread Group dan set sebagai **Target Controller** perakam.
2. Pada perakam: **Requests Filtering → Excludes** → tambah regex aset statik
   `(?i).*\.(bmp|css|js|gif|ico|jpe?g|png|swf|eot|otf|ttf|mp4|woff|woff2)([?;].*)?`.
3. Klik **Start**. Hantar satu permintaan melalui proxy JMeter (port 8888):
   ```bash
   curl -s -x http://localhost:8888 -H 'Content-Type: application/json' \
     -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}' \
     http://localhost:3000/api/log-masuk
   curl -s -x http://localhost:8888 -H 'Authorization: Bearer TOKEN_PALSU' \
     'http://localhost:3000/api/kenderaan?no_kp=800101015500'
   ```
4. Klik **Stop**. Lihat sampler yang dirakam dalam Recording Controller.
5. **Main balik** (Run). Perhatikan permintaan berkumpul → **401** kerana token dirakam
   sudah luput / palsu.

> **Soalan analisis:** Nilai manakah yang **berubah setiap sesi** dan perlu **dikorelasi**
> (bukan dikeras-kod)? Bandingkan dengan rujukan siap
> [`test-plans/04-rakaman-mentah.jmx`](../test-plans/04-rakaman-mentah.jmx) — pembetulannya
> ada di Hari 2 (korelasi `token` + `csrf`).
>
> **Panduan hujung-ke-hujung langkah demi langkah:** [`rakaman-e2e.md`](./rakaman-e2e.md).

### ✅ Checkpoint

- [ ] HTTP(S) Test Script Recorder dan Recording Controller (Target Controller) disediakan, dengan regex aset statik dalam Excludes
- [ ] Sampler `/api/log-masuk` dan `/api/kenderaan` dirakam dalam Recording Controller
- [ ] Main balik menunjukkan **401** kerana token dirakam sudah luput / palsu
- [ ] Boleh menerangkan nilai yang berubah setiap sesi dan perlu dikorelasi (`token`, `csrf`)

---

## Cabaran

Bina **satu Test Plan** dengan **dua sampler** (`/api/health` dan `/api/saman?no_kp=900202025600`) di bawah Thread Group yang sama, setiap satu dengan Response Assertion tersendiri. Susun elemen dengan betul (Config → Sampler → Assertion → Listener) dan terangkan **skop** setiap elemen kepada rakan sebelah anda.

## Semakan kendiri

- [ ] Saya boleh membina Test Plan dengan Thread Group, HTTP Request Defaults, sampler dan listener
- [ ] Saya boleh menambah Response Assertion, Duration Assertion dan Timer
- [ ] Saya boleh memparameter permintaan dengan CSV Data Set Config
- [ ] Saya boleh membaca Throughput, Average, Error % dan percentile dalam Summary / Aggregate Report
- [ ] Saya boleh merakam Test Plan dengan HTTP(S) Test Script Recorder
