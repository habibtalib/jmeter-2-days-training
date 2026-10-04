# Lab Hari 2 — Korelasi, Logic Controllers, Non-GUI & Analisis SLA

[⬅️ README Hari 2](../README.md) · [🎤 Nota Penceramah](../nota-penceramah.md) · [🗂️ Test plans rujukan](../test-plans/) · [🧩 Contoh Groovy](./jsr223-groovy.groovy)

> **Peraturan lab:** Dua tetingkap sentiasa terbuka — **Terminal A**: pelayan tiruan (`cd sut && node server.js`, jangan tutup), **Terminal B / JMeter GUI**: latihan. Bila sesuatu "tidak berfungsi", lihat mengikut tertib: (1) log Terminal A, (2) View Results Tree → tab **Request** & **Response data**, (3) Debug Sampler, (4) `jmeter.log` (ikon ⚠️ kuning di penjuru kanan atas GUI).

> ⚠️ **Etika:** semua latihan **hanya** menyasarkan `http://localhost:3000` (Portal eJPJ tiruan, data sintetik). Setiap kali anda membuka plan, semak **HTTP Request Defaults → Server Name or IP = `localhost`, Port = `3000`** sebelum menekan Start.

> 💡 Simpan plan latihan anda dalam `hari-2/test-plans/` (cth. `latihan-01-korelasi.jmx`) supaya laluan CSV `../data/pengguna.csv` sah. Cuba bina sendiri dahulu; plan rujukan ialah "kunci jawapan".

| Latihan | Sesi | Plan rujukan | Hasil |
|---------|------|--------------|-------|
| 1 — Korelasi token + csrf | S1 | `04-korelasi-log-masuk.jmx` | Bayaran `BERJAYA`, 0% ralat; `csrf` salah → 403 |
| 2 — Transaction, If & ForEach | S2 | `05-transaksi-penuh.jmx`, `08-foreach-kenderaan.jmx` | Baris transaksi dalam Summary Report; 5 kenderaan dibayar |
| 3 — JSR223 Groovy & fungsi | S2 | `snippets/jsr223-groovy.groovy` | Sampel ditanda gagal dengan mesej tersuai |
| 4 — Non-GUI + laporan HTML | S3 | `06-ujian-beban-nogui.jmx` | `laporan/index.html` |
| 5 — Titik pecah | S3 | `06-ujian-beban-nogui.jmx` | Jadual 50/150/400 pengguna |
| 6 — Senario puncak JPJ | S3 | `07-beban-puncak-cukai.jmx` | `-Jsla_ms=2000` vs `150` |
| 7 — Gerbang SLA lulus/gagal untuk CI | S4 | `07-beban-puncak-cukai.jmx` | Skrip gerbang keluar `0`/`1` |

---

## Latihan 1 — Korelasi token + csrf

**Sesi:** S1

### 🎯 Objektif
- Mengekstrak `token` dan `csrf` dinamik dari respons `POST /api/log-masuk` dengan JSON Extractor (O2)
- Menggunakan nilai itu dalam header `Authorization: Bearer ${token}` dan badan `bayar-cukai`
- Membuktikan mengapa korelasi wajib (403 / 401) (O1)

### Prasyarat
- SUT berjalan: `cd sut && node server.js` → <http://localhost:3000/api/health> memulangkan `{"status":"ok",...}`
- README §1.1–1.7; kemahiran Hari 1: HTTP Request Defaults, Header Manager, CSV Data Set Config

### Langkah
1. **File → New**. **Klik kanan Test Plan → Add → Threads (Users) → Thread Group**: Number of Threads `5`, Ramp-up `3`, Loop Count `3`. **File → Save As** → `hari-2/test-plans/latihan-01-korelasi.jmx`.
2. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, Server `localhost`, Port `3000`.
3. **Add → Config Element → HTTP Header Manager** → Add: `Content-Type` = `application/json`.
4. **Add → Config Element → CSV Data Set Config**: Filename `../data/pengguna.csv`, Variable Names `no_kp,kata_laluan`, Ignore first line `True`, Recycle on EOF `True`, Sharing mode `All threads`.
5. **Add → Sampler → HTTP Request** bernama `POST /api/log-masuk`: Method `POST`, Path `/api/log-masuk`, tab **Body Data**:
   ```json
   { "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }
   ```
6. **Klik kanan sampler log masuk → Add → Post Processors → JSON Extractor** (`Ekstrak token + csrf`):
   - Names of created variables: `token;csrf`
   - JSON Path expressions: `$.token;$.csrf`
   - Match No. (0 for Random): `1;1` · Default Values: `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`
7. **Klik kanan Thread Group → Add → Sampler → Debug Sampler** (letak terus selepas log masuk).
8. **Add → Sampler → HTTP Request** `GET /api/kenderaan`: Method `GET`, Path `/api/kenderaan`, Parameters → Add: `no_kp` = `${no_kp}`. **Klik kanan sampler ini → Add → Config Element → HTTP Header Manager**: `Authorization` = `Bearer ${token}`.
9. **Add → Sampler → HTTP Request** `POST /api/kenderaan/WXY1234/bayar-cukai`: Method `POST`, Body Data:
   ```json
   { "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": 90 }
   ```
   Anak sampler: **HTTP Header Manager** `Authorization` = `Bearer ${token}` dan **Add → Assertions → Response Assertion** (Text Response, Substring, pattern `BERJAYA`).
10. **Klik kanan Thread Group → Add → Listener → View Results Tree.** Save, kemudian **Start** ▶.
11. Klik **Debug Sampler** → Response data: cari `token=` (UUID) dan `csrf=` (32 aksara hex). Klik sampler bayar → tab **Request**: sahkan header dan badan mengandungi nilai sebenar.
12. **Eksperimen A:** ganti `${csrf}` dengan `abc123` → Start → perhatikan **403** `Token CSRF tidak sah — sila log masuk semula`. Pulihkan.
13. **Eksperimen B:** pada Header Manager `GET /api/kenderaan`, tukar nilai kepada `Bearer abc` → **401** `Token tidak sah atau tamat tempoh`. Pulihkan.

> Bandingkan dengan [`test-plans/04-korelasi-log-masuk.jmx`](../test-plans/04-korelasi-log-masuk.jmx).

### ✅ Checkpoint
- [ ] Debug Sampler menunjukkan `token` (UUID) dan `csrf` (32 aksara hex) — bukan `TOKEN_TAK_JUMPA`
- [ ] `GET /api/kenderaan` memulangkan 200 dengan senarai `kenderaan` bagi `${no_kp}`
- [ ] Permintaan `bayar-cukai` berjaya dan assertion `BERJAYA` lulus (0% ralat bagi 15 bayaran)
- [ ] Eksperimen `csrf` salah menunjukkan **403**, dan token salah menunjukkan **401**
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Semua sampler `Non HTTP response code: java.net.ConnectException` | SUT tidak berjalan | Terminal A: `cd sut && node server.js` |
| `${no_kp}` dihantar secara literal | CSV tidak dijumpai — plan belum disimpan atau disimpan di folder lain | Simpan `.jmx` dalam `hari-2/test-plans/`; atau guna laluan penuh |
| Log masuk **401** `No. KP atau kata laluan tidak sah` | Badan kosong / tiada `Content-Type: application/json` | Semak Header Manager (aras Thread Group) dan Body Data |
| `Bearer TOKEN_TAK_JUMPA` dalam tab Request | JSON Extractor bukan anak sampler log masuk, atau path salah | Seret extractor ke bawah sampler log masuk; uji `$.token` dengan JSON Path Tester |
| `token` betul tetapi bayar **403** | `csrf` tidak diekstrak / ejaan `${csrf}` salah | Names `token;csrf` dan Paths `$.token;$.csrf` mesti sama bilangan |
| GET kenderaan **401** walaupun token betul | Header Manager `Authorization` tiada perkataan `Bearer ` | Nilai mesti `Bearer ${token}` (dengan ruang) |

### ⭐ Cabaran
1. Gantikan JSON Extractor dengan **Regular Expression Extractor**: Name `token`, Regular Expression `"token":"([^"]+)"`, Template `$1$`, Match No. `1`, Default `TOKEN_TAK_JUMPA`. Ulang untuk `csrf`. Hasil mesti sama.
2. Cuba **Boundary Extractor**: Left Boundary `"csrf":"`, Right Boundary `"`. Bandingkan kebolehbacaan tiga cara.
3. Tambah sampler `GET /api/saman?no_kp=${no_kp}` dan `POST /api/saman/<id>/bayar` (badan `{ "csrf": "${csrf}" }`) — ekstrak `id` saman pertama dengan `$.saman[0].id`.

---

## Latihan 2 — Transaction, If & ForEach Controller

**Sesi:** S2

### 🎯 Objektif
- Membungkus perjalanan pengguna dalam **Transaction Controller** `Pembaharuan Cukai Jalan` (O3)
- Mengawal langkah bayar dengan **If Controller** `${__groovy(...)}` (O3)
- Membayar cukai **semua** kenderaan dengan Match No. `-1` + **ForEach Controller** (O4)

### Prasyarat
- Latihan 1 selesai (plan anda mengekstrak `token` + `csrf`)
- README §2.1–2.5

### Langkah

**Bahagian A — transaksi penuh (plan `05`)**

1. Salin plan Latihan 1 → **Save As** `latihan-02-transaksi.jmx`. Padam Debug Sampler dan sampler bayar `WXY1234`.
2. **Klik kanan Thread Group → Add → Logic Controller → Transaction Controller**, nama `Pembaharuan Cukai Jalan`. Biarkan *Generate parent sample* dan *Include duration of timer…* **tidak ditanda**.
3. Seret `POST /api/log-masuk` dan `GET /api/kenderaan` **ke dalam** controller. Namakan semula `1. POST /api/log-masuk`, `2. GET /api/kenderaan`.
4. **Klik kanan `2. GET /api/kenderaan` → Add → Post Processors → JSON Extractor** (`Ekstrak kenderaan pertama`): Names `no_pendaftaran;amaun`, Paths `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai`, Match No. `1;1`, Default `NONE;0`.
5. **Klik kanan Transaction Controller → Add → Logic Controller → If Controller** (`Jika ada kenderaan`). Condition:
   ```
   ${__groovy(vars.get("no_pendaftaran") != "NONE" && vars.get("token") != "TOKEN_TAK_JUMPA")}
   ```
   Pastikan **Interpret Condition as Variable Expression?** ditanda; **Evaluate for all children?** tidak ditanda.
6. Dalam If Controller:
   - `3. GET /api/kenderaan/${no_pendaftaran}/cukai`
   - `4. POST /api/kenderaan/${no_pendaftaran}/bayar-cukai` — Body `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": ${amaun} }` + Header Manager `Authorization: Bearer ${token}` + Response Assertion `BERJAYA`
7. **Klik kanan Thread Group → Add → Timer → Uniform Random Timer** (`Think Time (1-3s)`): Random Delay Maximum `2000`, Constant Delay Offset `1000`.
8. Thread Group: 10 pengguna, ramp `10`, Loop Count `2`. Gantikan View Results Tree dengan **Add → Listener → Summary Report**. Start.

**Bahagian B — semua kenderaan (plan `08`)**

9. Buka [`test-plans/08-foreach-kenderaan.jmx`](../test-plans/08-foreach-kenderaan.jmx). Kaji: JSON Extractor `Ekstrak SEMUA no_pendaftaran (Match -1)` → `$.kenderaan[*].no_pendaftaran`, Match No. `-1`.
10. Klik `ForEach — setiap kenderaan`: Input variable prefix `no_pendaftaran`, Output variable name `no_semasa`, **Add "_" before number?** ditanda.
11. Tambah **Debug Sampler** selepas `2. GET /api/kenderaan (semua)` dan **View Results Tree**. Start (3 pengguna).
12. Dalam Debug Sampler pengguna `800101015500`: cari `no_pendaftaran_1=WXY1234`, `no_pendaftaran_2=VAB88`, `no_pendaftaran_matchNr=2`.
13. **Eksperimen:** nyahtanda *Add "_" before number?* → Start → perhatikan **tiada** sampler 3/4 berjalan. Pulihkan.

> Bandingkan dengan [`test-plans/05-transaksi-penuh.jmx`](../test-plans/05-transaksi-penuh.jmx) dan `08-foreach-kenderaan.jmx`.

### ✅ Checkpoint
- [ ] Empat sampler dibungkus dalam Transaction Controller `Pembaharuan Cukai Jalan`
- [ ] If Controller membungkus sebut harga + bayar dengan syarat `${__groovy(...)}`
- [ ] Larian 10 pengguna × 2 gelung menunjukkan baris transaksi `Pembaharuan Cukai Jalan` dalam Summary Report
- [ ] Plan `08`: 3 pengguna → **5** sampel `4. POST …/bayar-cukai` berjaya (16 sampel HTTP, 0 ralat)
- [ ] Lulus **Kuiz S2** (sekurang-kurangnya separuh betul) (Kuiz S2)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Sampler 3 & 4 tidak pernah berjalan | Syarat If tidak menilai `true` (cth. tiada `${__groovy(...)}`, petikan salah) | Salin syarat tepat dari README; uji dengan Debug Sampler bahawa `no_pendaftaran` ≠ `NONE` |
| Laluan menjadi `/api/kenderaan/NONE/cukai` → 404 | Extractor kenderaan bukan anak `2. GET /api/kenderaan` atau path salah | Path `$.kenderaan[0].no_pendaftaran` |
| `bayar-cukai` 400/500 dengan `"amaun": ${amaun}` literal | Pembolehubah `amaun` tidak wujud | Names `no_pendaftaran;amaun` (dua nama, dua path) |
| Tiada baris transaksi dalam laporan | Sampler tidak berada **di dalam** Transaction Controller | Seret sampler ke atas nama controller (bukan di bawahnya) |
| ForEach 0 lelaran | *Add "_" before number?* tidak ditanda, atau Match No. bukan `-1` | Tanda kotak; Match No. `-1` |
| Kadang-kadang 1 ralat 500 | `ERROR_RATE` lalai SUT 1% — sengaja | Jangkaan normal; untuk larian bersih `ERROR_RATE=0 node server.js` |

### ⭐ Cabaran
1. Tandakan *Generate parent sample* dan bandingkan Summary Report — apa yang hilang, apa yang kekal?
2. Tambah **Throughput Controller** (Percent Executions `30`) yang membungkus bayaran saman, supaya hanya ~30% lelaran membayar saman.

---

## Latihan 3 — JSR223 (Groovy) & fungsi JMeter

**Sesi:** S2

### 🎯 Objektif
- Menulis JSR223 PostProcessor yang menanda sampel gagal dengan mesej tersuai (O5)
- Menjana data unik dengan JSR223 PreProcessor dan fungsi `__UUID`, `__Random`, `__time` (O5)

### Prasyarat
- Plan Latihan 1 atau 2
- [`snippets/jsr223-groovy.groovy`](./jsr223-groovy.groovy) dibuka dalam editor

### Langkah
1. **Klik kanan sampler log masuk → Add → Post Processors → JSR223 PostProcessor.** Language `groovy`; tandakan **Cache compiled script if available**.
2. Salin blok **"2) JSR223 PostProcessor"** dari `jsr223-groovy.groovy` (bermula `import groovy.json.JsonSlurper`) ke ruang Script.
3. Start → semua log masuk hijau. Dalam Debug Sampler, cari `panjang_token=36`.
4. **Uji kegagalan:** tukar Path sampler log masuk kepada `/api/log-masukX` → Start → View Results Tree: sampel merah dengan *Response message* `Log masuk mengembalikan kod 404`. Pulihkan. (Alternatif: hentikan SUT seketika dengan Ctrl+C dan perhatikan mesej `Log masuk mengembalikan kod Non HTTP response code: …`; kemudian hidupkan semula.)
5. **Klik kanan sampler bayar → Add → Pre Processors → JSR223 PreProcessor** (groovy, cache ditanda). Salin blok **"1) JSR223 PreProcessor"**. Tukar badan bayar kepada `"tempoh_bulan": ${tempoh_bulan}`. Jalankan; dalam `jmeter.log` cari `Menyediakan bayaran: rujukan=REF-… tempoh=6` atau `12`.
6. **Fungsi:** pada Header Manager sampler bayar, tambah `X-Rujukan` = `${__UUID}` dan `X-Tarikh` = `${__time(yyyy-MM-dd)}`. Pada Debug Sampler, tukar nama kepada `Debug ${__Random(1,1000)}`. Jalankan dan sahkan nilai berbeza dalam tab Request.
7. Buka Thread Group dan tukar Number of Threads kepada `${__P(pengguna,5)}`. Simpan, kemudian dari terminal dalam folder `hari-2/test-plans`: `jmeter -n -t latihan-02-transaksi.jmx -Jpengguna=8 -l /tmp/l3.jtl` → sahkan `Started: 8 Finished: 8` dalam baris `summary +`.

### ✅ Checkpoint
- [ ] JSR223 PostProcessor (Groovy, *Cache compiled script* ditanda) ditambah di bawah sampler log masuk
- [ ] Sampel ditanda gagal dengan mesej tersuai apabila log masuk tidak memulangkan 200/token
- [ ] Header `X-Rujukan` memaparkan UUID berbeza bagi setiap permintaan
- [ ] `-Jpengguna=8` mengubah bilangan thread tanpa mengedit `.jmx`
- [ ] Lulus **Kuiz S2** (sekurang-kurangnya separuh betul) (Kuiz S2)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `groovy.json.JsonException: Unable to determine the current character` | Respons bukan JSON (HTML 404 / kosong) | Semak `prev.getResponseCode()` sebelum parse — seperti blok contoh |
| `No such property: json` / ralat sintaks | Blok disalin separuh | Salin seluruh blok, termasuk `import` |
| Skrip tiada kesan | Language bukan `groovy` (cth. `beanshell`) | Pilih `groovy` dalam dropdown Language |
| `${__P(pengguna,5)}` diabaikan dalam GUI | Property hanya dari `-J` | Dalam GUI, nilai lalai `5` dipakai — betul |
| CPU penjana beban tinggi dengan banyak JSR223 | Cache tidak ditanda / `${}` dalam skrip | Tanda cache; baca dengan `vars.get()` |

### ⭐ Cabaran
1. Tulis **JSR223 Assertion** yang gagal jika `amaun` dalam respons bayar ≠ `vars.get("amaun")`.
2. Cuba blok **"3) JSR223 Sampler"** — sampler tempatan tanpa HTTP. Bila ia berguna dalam ujian sebenar?

---

## Latihan 4 — Larian non-GUI + laporan HTML

**Sesi:** S3

### 🎯 Objektif
- Menjalankan plan `06` dalam mod non-GUI dengan property `-J` (O6)
- Menjana dan menerokai HTML dashboard (O7)

### Prasyarat
- JMeter pada PATH: `jmeter --version` memaparkan 5.6.x
- SUT berjalan; **tutup JMeter GUI** (atau sekurang-kurangnya hentikan semua larian GUI)

### Langkah
1. Buka `06-ujian-beban-nogui.jmx` di GUI sekali sahaja untuk melihat: tiada listener; Thread Group `Beban Pembaharuan Cukai` menggunakan `${__P(pengguna,50)}`, `${__P(rampup,30)}`, `${__P(tempoh,120)}`; HTTP Request Defaults `${__P(host,localhost)}` / `${__P(port,3000)}`. Tutup GUI.
2. Jalankan wrapper:
   ```bash
   cd hari-2/run
   ./run-nogui.sh                       # atau: PENGGUNA=100 TEMPOH=180 ./run-nogui.sh
   ```
   Windows: `run-nogui.bat`.
   Setara arahan penuh (dari `hari-2/run`):
   ```bash
   jmeter -n -t ../test-plans/06-ujian-beban-nogui.jmx \
     -Jpengguna=100 -Jrampup=30 -Jtempoh=180 \
     -l hasil/manual/results.jtl -e -o hasil/manual/laporan
   ```
3. Semasa ujian berjalan, perhatikan baris `summary +` setiap 30 saat dalam terminal (throughput & Err semasa).
4. Buka `hasil/<cap-masa>/laporan/index.html`. Terokai: **APDEX**, **Statistics** (90th/95th/99th pct), **Errors**, **Charts → Over Time → Response Times Over Time / Active Threads Over Time**, **Charts → Throughput → Transactions Per Second**.
5. Catat dalam jadual: # Samples, 95th pct transaksi `Pembaharuan Cukai Jalan`, Throughput, Error %, APDEX.

### ✅ Checkpoint
- [ ] Test Plan dijalankan dalam mod non-GUI (`run-nogui.sh` atau `jmeter -n`) tanpa ralat proses
- [ ] Laporan HTML dijana dan `index.html` dibuka
- [ ] APDEX, Response Times Percentiles, Throughput dan Errors diterokai dalam laporan
- [ ] Nilai 95th pct transaksi `Pembaharuan Cukai Jalan` dicatat
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `Cannot write to '…/laporan' as folder is not empty` | Direktori `-o` sudah wujud | Guna folder baharu (wrapper guna cap masa) atau padam folder lama |
| `jmeter: command not found` | JMeter tiada pada PATH | Lihat Hari 1 — Persediaan; atau guna laluan penuh `…/bin/jmeter` |
| `./run-nogui.sh: Permission denied` | Tiada kebenaran laksana | `chmod +x run-nogui.sh` atau `bash run-nogui.sh` |
| Error % 100%, `Connection refused` | SUT berhenti | Hidupkan semula Terminal A |
| Dashboard kosong / tiada graf | `.jtl` kosong — ujian terlalu pendek atau gagal | Semak `jmeter.log` dalam folder hasil |

---

## Latihan 5 — Cari titik pecah (breaking point)

**Sesi:** S3

### 🎯 Objektif
- Menaikkan beban berperingkat dan mengenal pasti had kapasiti (O7)

### Prasyarat
- Latihan 4 selesai; wrapper `run-nogui.sh` berfungsi

### Langkah
1. Hentikan SUT (Ctrl+C) dan mulakan pelayan "perlahan":
   ```bash
   LATENCY_MIN=200 LATENCY_MAX=800 ERROR_RATE=0.05 node server.js
   ```
   Windows (PowerShell): `$env:LATENCY_MIN=200; $env:LATENCY_MAX=800; $env:ERROR_RATE=0.05; node server.js`
2. Jalankan `run-nogui.sh` dengan beban menaik (tempoh pendek untuk kelas):
   ```bash
   PENGGUNA=50  RAMPUP=10 TEMPOH=60 ./run-nogui.sh
   PENGGUNA=150 RAMPUP=20 TEMPOH=60 ./run-nogui.sh
   PENGGUNA=400 RAMPUP=30 TEMPOH=60 ./run-nogui.sh
   ```
3. Bagi setiap larian, catat dari dashboard:

   | Pengguna | Throughput (trans/s) | 95th pct transaksi (ms) | Error % | APDEX |
   |----------|----------------------|-------------------------|---------|-------|
   | 50 | | | | |
   | 150 | | | | |
   | 400 | | | | |

4. Pantau CPU mesin anda (Activity Monitor / Task Manager) semasa larian 400 — adakah JMeter atau Node yang sesak?
5. Selepas selesai, pulihkan SUT biasa: `node server.js`.

> **Soalan analisis:** Pada bilangan pengguna berapa 95th percentile melebihi 2000 ms atau Error % melebihi 1%? Adakah throughput terus naik atau mendatar? Itulah anggaran **kapasiti** sistem di bawah keadaan ini. (Ingat: `ERROR_RATE=0.05` bermakna ~5% bayaran gagal **tanpa mengira beban** — bezakan ralat "asas" dengan ralat akibat beban.)

### ✅ Checkpoint
- [ ] Larian non-GUI dijalankan pada 50, 150 dan 400 pengguna dengan pelayan "perlahan"
- [ ] 95th percentile dan Error % dicatat bagi setiap larian
- [ ] Anggaran kapasiti (titik pecah) sistem dikenal pasti dan dibincangkan dengan pasangan
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Error % ≈ 5% walaupun 50 pengguna | `ERROR_RATE=0.05` — ralat sintetik, bukan beban | Bandingkan trend antara larian, bukan nilai mutlak |
| Laptop menjadi sangat perlahan pada 400 | Penjana beban & SUT pada mesin sama | Normal untuk makmal; catat CPU — dalam amalan sebenar, asingkan penjana beban |
| `java.lang.OutOfMemoryError` | Heap JMeter kecil | Tutup GUI; `HEAP="-Xms1g -Xmx2g" ./run-nogui.sh` (macOS/Linux) |
| Pembolehubah env tidak berkesan di Windows CMD | Sintaks shell berbeza | CMD: `set LATENCY_MIN=200` dahulu, kemudian `node server.js` |

---

## Latihan 6 — Senario puncak use case JPJ (Hari Kenaikan Harga Cukai)

**Sesi:** S3

Gabungkan korelasi + Transaction/If + sebut harga + SLA dalam satu senario beban puncak.

### 🎯 Objektif
- Membina aliran yang mengambil `amaun` + `tempoh_bulan` dari **sebut harga** (O8)
- Menguatkuasakan SLA per-transaksi dengan **Duration Assertion** `${__P(sla_ms,2000)}` (O8)

### Prasyarat
- Latihan 2 & 4 selesai; SUT biasa (`node server.js`) berjalan

### Langkah
1. Bina aliran penuh (atau salin plan Latihan 2): log masuk → `GET /api/kenderaan` (ekstrak `no_pendaftaran`) →
   `GET /api/kenderaan/${no_pendaftaran}/cukai` (JSON Extractor `amaun;tempoh_bulan` ← `$.amaun;$.tempoh_bulan`, default `0;12`) →
   `POST /api/kenderaan/${no_pendaftaran}/bayar-cukai` dengan:
   ```json
   { "csrf": "${csrf}", "tempoh_bulan": ${tempoh_bulan}, "amaun": ${amaun} }
   ```
2. **Klik kanan sampler bayar → Add → Assertions → Duration Assertion**: Duration in milliseconds `${__P(sla_ms,2000)}`; nama `SLA Bayaran < ${__P(sla_ms,2000)}ms`.
3. Jadikan beban property-driven: Thread Group `${__P(pengguna,300)}`, Ramp-up `${__P(rampup,30)}`, Loop Count *Infinite*, **Specify Thread lifetime** → Duration `${__P(tempoh,300)}`. Buang semua listener.
4. Bandingkan binaan anda dengan [`test-plans/07-beban-puncak-cukai.jmx`](../test-plans/07-beban-puncak-cukai.jmx). Kemudian jalankan rujukan (dari `hari-2/run`; tempoh dipendekkan untuk kelas):
   ```bash
   jmeter -n -t ../test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=300 -Jrampup=30 -Jtempoh=120 -Jsla_ms=2000 \
     -l hasil/r7.jtl -e -o hasil/laporan7
   ```
   (Untuk beban penuh kursus: `-Jtempoh=300`.)
5. Turunkan SLA dan jalankan semula ke folder baharu:
   ```bash
   jmeter -n -t ../test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=300 -Jrampup=30 -Jtempoh=120 -Jsla_ms=150 \
     -l hasil/r7-sla150.jtl -e -o hasil/laporan7-sla150
   ```
6. Bandingkan dua dashboard: Error % transaksi `Pembaharuan Cukai Jalan (Puncak)` dan **Top 5 Errors by sampler** (`The operation lasted too long: It took … milliseconds, but should not have lasted longer than 150 milliseconds.`).

### ✅ Checkpoint
- [ ] Aliran penuh log masuk → senarai → sebut harga → bayar cukai berjalan dengan nilai dikorelasi
- [ ] Duration Assertion menggunakan ambang `${__P(sla_ms,2000)}`
- [ ] Larian non-GUI 300 pengguna menjana laporan HTML (`hasil/laporan7`)
- [ ] Dengan `-Jsla_ms=150`, Error % naik kerana sampel yang melanggar SLA ditanda gagal
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Bayar 500 / `amaun` = 0 | Extractor sebut harga bukan anak sampler `/cukai` | Seret extractor ke bawah sampler `3. GET …/cukai` |
| Error % tidak berubah dengan `-Jsla_ms=150` | Duration Assertion menggunakan nombor tetap, bukan `${__P(sla_ms,2000)}` | Guna fungsi `__P` dalam medan duration |
| `-Jsla_ms` diabaikan | Ditulis `-J sla_ms=150` (ruang) atau `-Dsla_ms` | Tulis `-Jsla_ms=150` tanpa ruang |
| Ralat `folder is not empty` pada larian kedua | Folder laporan sama | Guna `-o` ke folder baharu |

---

## Latihan 7 — Gerbang SLA lulus/gagal untuk CI/CD

**Sesi:** S4

Daripada "membaca laporan dengan mata", kita jadikan NFR satu **gerbang automatik** yang boleh menggagalkan *build*.

### 🎯 Objektif
- Menukar NFR kepada semakan mesin terhadap `statistics.json` (O9)
- Memahami bagaimana gerbang ini dipasang dalam pipeline CI (O9)

### Prasyarat
- Latihan 6 selesai (`hasil/laporan7` dan `hasil/laporan7-sla150` wujud dalam `hari-2/run`)
- `jq` dipasang (`jq --version`); Windows: guna blok PowerShell

### Langkah
1. Tulis NFR anda: **95th percentile transaksi `Pembaharuan Cukai Jalan (Puncak)` < 1500 ms** dan **Error % < 1%**.
2. Lihat data mentah dashboard:
   ```bash
   cd hari-2/run
   jq '."Pembaharuan Cukai Jalan (Puncak)" | {sampleCount, errorPct, pct1ResTime, pct2ResTime, pct3ResTime}' hasil/laporan7/statistics.json
   ```
   (`pct1ResTime` = 90th, `pct2ResTime` = 95th, `pct3ResTime` = 99th; `errorPct` dalam peratus.)
3. Cipta fail `semak-sla.sh` dalam `hari-2/run` (fail anda sendiri):
   ```bash
   #!/usr/bin/env bash
   # Penggunaan: ./semak-sla.sh hasil/laporan7/statistics.json
   STAT="$1"; LABEL="Pembaharuan Cukai Jalan (Puncak)"
   P95=$(jq --arg l "$LABEL" '.[$l].pct2ResTime' "$STAT")
   ERR=$(jq --arg l "$LABEL" '.[$l].errorPct' "$STAT")
   echo "p95=${P95} ms  error=${ERR}%"
   if awk -v p="$P95" -v e="$ERR" 'BEGIN { exit !(p < 1500 && e < 1) }'; then
     echo "LULUS SLA"
   else
     echo "GAGAL SLA"; exit 1
   fi
   ```
   Windows (PowerShell):
   ```powershell
   $s = (Get-Content hasil\laporan7\statistics.json | ConvertFrom-Json).'Pembaharuan Cukai Jalan (Puncak)'
   "p95=$($s.pct2ResTime) ms  error=$($s.errorPct)%"
   if ($s.pct2ResTime -lt 1500 -and $s.errorPct -lt 1) { "LULUS SLA" } else { "GAGAL SLA"; exit 1 }
   ```
4. Jalankan pada kedua-dua laporan dan semak kod keluar:
   ```bash
   chmod +x semak-sla.sh
   ./semak-sla.sh hasil/laporan7/statistics.json;        echo "kod keluar: $?"
   ./semak-sla.sh hasil/laporan7-sla150/statistics.json; echo "kod keluar: $?"
   ```
5. Bincang dengan pasangan: dalam Jenkins / GitHub Actions, langkah `jmeter -n …` diikuti `./semak-sla.sh …` — langkah mana yang menggagalkan *build*, dan apa yang perlu disimpan sebagai artifak?
6. Sediakan mini-demo capstone 3 minit (README §4.5): 95th pct, Error %, APDEX, LULUS/GAGAL.

### ✅ Checkpoint
- [ ] NFR ditulis dengan beban, transaksi, percentile dan ambang Error %
- [ ] `jq` memaparkan `pct2ResTime` dan `errorPct` bagi transaksi `Pembaharuan Cukai Jalan (Puncak)`
- [ ] Gerbang keluar dengan kod `0` bagi `laporan7` dan kod `1` bagi `laporan7-sla150` (jika Error % ≥ 1)
- [ ] Mini-demo capstone dibentangkan (atau dirakam dalam nota pasangan)
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `jq` memulangkan `null` | Nama label tidak tepat (ruang, kurungan) | `jq 'keys' statistics.json` untuk melihat label sebenar |
| `jq: command not found` | jq tiada | macOS `brew install jq`; Windows guna blok PowerShell |
| Kod keluar sentiasa 0 | `exit 1` tiada dalam cabang gagal | Semak skrip; `echo $?` sejurus selepas larian |
| `laporan7` juga GAGAL | Error % ≥ 1 akibat ralat 500 sintetik 1% SUT | Normal pada sempadan; ulang dengan `ERROR_RATE=0 node server.js` atau bincang toleransi NFR |

### ⭐ Cabaran
1. **Taurus (bzt):** tulis `ujian.yml` yang menjalankan `07-beban-puncak-cukai.jmx` dengan modul `passfail` (`p95>1500ms for 10s, stop as failed`).
2. **Grafana:** tambah **Backend Listener** (`InfluxdbBackendListenerClient`) ke salinan plan `07` dan halakan ke InfluxDB tempatan (Docker) — tonton throughput masa nyata.
3. **Distributed (makmal sahaja):** dua laptop dalam rangkaian kelas — satu `jmeter-server`, satu controller `-R <ip>` dengan `-Gpengguna=50`. Sasaran tetap SUT dalam rangkaian kelas yang anda kawal.

---

## Semakan kendiri

- [ ] Saya boleh menerangkan mengapa rakaman mentah gagal (401) dan beza parameterisasi vs korelasi
- [ ] Saya boleh mengkorelasi `token` dan `csrf` dengan JSON Extractor (dan tahu setara Regex/Boundary)
- [ ] Saya boleh menggunakan Transaction Controller, If Controller dan ForEach Controller
- [ ] Saya boleh menulis JSR223 Groovy (cache ditanda) dan menggunakan `__P`, `__UUID`, `__Random`, `__time`
- [ ] Saya boleh menjalankan ujian non-GUI dan menjana laporan HTML
- [ ] Saya boleh mentafsir 95th percentile, Error % dan APDEX untuk menetapkan SLA dan mencari titik pecah
- [ ] Saya boleh membina gerbang SLA yang boleh menggagalkan *build* CI
- [ ] Isi penilaian kendiri Hari 2 (Kuiz hari)
