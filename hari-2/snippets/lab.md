# Lab Hari 2 — JMeter Lanjutan, Analisis & CI

Pastikan **pelayan tiruan berjalan**:

```bash
cd sut && node server.js
```

Fail rujukan ada dalam `hari-2/test-plans/`. Cuba bina sendiri dahulu.

---

## Latihan 1 — Korelasi token + csrf

1. Tambah **CSV Data Set Config** → `../data/pengguna.csv` (`no_kp,kata_laluan`).
2. Sampler **POST `/api/log-masuk`** dengan Body Data JSON:
   ```json
   { "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }
   ```
   (Tambah **HTTP Header Manager** → `Content-Type: application/json`.)
3. Tambah **JSON Extractor** (JSON Extractor) sebagai anak sampler:
   - Names: `token;csrf`
   - JSON Path expressions: `$.token;$.csrf`
   - Match No.: `1;1` · Default: `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`
4. Sampler **GET `/api/kenderaan?no_kp=${no_kp}`** dengan Header Manager
   `Authorization: Bearer ${token}`.
5. Sampler **POST `/api/kenderaan/WXY1234/bayar-cukai`** — Header `Authorization: Bearer ${token}`, Body `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": 90 }`.
6. Assertion respons mengandungi `BERJAYA`. Jalankan; sahkan bayaran berjaya.

> **Eksperimen:** Padamkan `${csrf}` (guna nilai tetap salah). Perhatikan **403** — inilah sebab korelasi diperlukan.
> Bandingkan dengan `test-plans/04-korelasi-log-masuk.jmx`.

## Latihan 2 — Transaction Controller + If Controller

1. Bungkus 4 sampler (log masuk → senarai → sebut harga → bayar) dalam satu
   **Transaction Controller** bernama `Pembaharuan Cukai Jalan`.
2. Ekstrak kenderaan pertama dari respons senarai:
   `$.kenderaan[0].no_pendaftaran` dan `$.kenderaan[0].amaun_cukai`.
3. Bungkus sebut-harga + bayar dalam **If Controller** dengan syarat:
   ```
   ${__groovy(vars.get("no_pendaftaran") != "NONE")}
   ```
4. Tambah **Uniform Random Timer** (1–3s) sebagai think time.
5. Jalankan (10 pengguna × 2 gelung). Perhatikan masa **transaksi** (jumlah 4 langkah).

> Bandingkan dengan `test-plans/05-transaksi-penuh.jmx`.

## Latihan 3 — JSR223 (Groovy)

1. Tambah **JSR223 PostProcessor** (Language: `groovy`) di bawah sampler log masuk.
2. Salin blok "PostProcessor" dari `jsr223-groovy.groovy` — sahkan token wujud,
   tandakan sampel gagal jika tiada.
3. Jalankan; cuba matikan pelayan seketika untuk lihat sampel ditandakan gagal.

## Latihan 4 — Larian non-GUI + laporan HTML

1. **Buang semua GUI listener** dari plan (atau guna `06-ujian-beban-nogui.jmx`).
2. Jalankan:
   ```bash
   cd hari-2/run
   ./run-nogui.sh                       # atau: PENGGUNA=100 TEMPOH=180 ./run-nogui.sh
   ```
   Setara arahan penuh:
   ```bash
   jmeter -n -t ../test-plans/06-ujian-beban-nogui.jmx \
     -Jpengguna=100 -Jrampup=30 -Jtempoh=180 \
     -l hasil/results.jtl -e -o hasil/laporan
   ```
3. Buka `hasil/<cap-masa>/laporan/index.html`. Terokai:
   **APDEX**, **Response Times Percentiles**, **Throughput**, **Errors**.

## Latihan 5 — Cari titik pecah (breaking point)

1. Mulakan pelayan "perlahan": `LATENCY_MIN=200 LATENCY_MAX=800 ERROR_RATE=0.05 node server.js`.
2. Jalankan `run-nogui.sh` dengan beban menaik: `PENGGUNA=50`, kemudian `150`, kemudian `400`.
3. Bagi setiap larian, catat **95th percentile** dan **Error %** dalam laporan HTML.

> **Soalan analisis:** Pada bilangan pengguna berapa 95th percentile melebihi 2000 ms
> atau Error % melebihi 1%? Itulah anggaran **kapasiti** sistem di bawah keadaan ini.

---

## Cabaran — tetapkan SLA & luluskan/gagalkan

Takrifkan NFR: **95th percentile < 1500 ms** dan **Error % < 1%**. Tambah
**Duration Assertion** dan semak laporan. Bincang: bagaimana anda akan
**automasikan** semakan ini dalam **CI/CD** (cth. gagalkan *build* jika ambang dilanggar)?
