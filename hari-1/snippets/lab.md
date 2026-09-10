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

## Latihan 3 — Parameterisasi dengan CSV

1. Tambah **CSV Data Set Config** membaca `../data/kenderaan.csv`
   (variable names: `no_pendaftaran,model`; recycle: **True**).
2. Ubah path sampler kepada `/api/kenderaan/${no_pendaftaran}/cukai`.
3. Jalankan (10 pengguna × 10 gelung). Dalam View Results Tree, sahkan
   setiap permintaan guna nombor pendaftaran berlainan.

> Bandingkan dengan `test-plans/03-csv-berparameter.jmx`.

## Latihan 4 — Buat assertion GAGAL (belajar dari kegagalan)

1. Tambah satu baris palsu pada `hari-1/data/kenderaan.csv`, cth: `ABC0000,Kereta Hantu`.
2. Jalankan semula Latihan 3. Perhatikan permintaan `ABC0000` **gagal**
   assertion (`amaun` tiada — endpoint pulangkan **404**).
3. Lihat **Error %** meningkat dalam Summary Report. Buang baris palsu selepas selesai.

## Latihan 5 — Kesan latensi terhadap prestasi

1. Hentikan pelayan (Ctrl+C). Mulakan semula dengan latensi tinggi:
   ```bash
   LATENCY_MIN=300 LATENCY_MAX=900 node server.js
   ```
2. Jalankan semula Latihan 2. Bandingkan **Average** dan **Throughput** dengan larian asal.

> **Soalan reflektif:** Mengapa throughput jatuh apabila latensi naik walaupun bilangan pengguna sama? (Petunjuk: setiap thread menunggu lebih lama sebelum boleh menghantar permintaan seterusnya.)

---

## Cabaran

Bina **satu Test Plan** dengan **dua sampler** (`/api/health` dan `/api/saman?no_kp=900202025600`) di bawah Thread Group yang sama, setiap satu dengan Response Assertion tersendiri. Susun elemen dengan betul (Config → Sampler → Assertion → Listener) dan terangkan **skop** setiap elemen kepada rakan sebelah anda.
