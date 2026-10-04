# Lab Hari 2 — Rakam & Main Balik, Laporan Prestasi & Merancang Ujian

[⬅️ README Hari 2](../README.md) · [🎤 Nota Penceramah](../nota-penceramah.md) · [🗂️ Test plans rujukan](../test-plans/) · [📋 Templat Pelan Ujian](./templat-pelan-ujian.md) · [📝 Templat Laporan Ujian](./templat-laporan-ujian.md)

> **Peraturan lab:** Dua tetingkap sentiasa terbuka — **Terminal A**: pelayan tiruan (`node sut/server.js` dari akar repo, jangan tutup), **Terminal B / JMeter GUI**: latihan. Bila sesuatu "tidak berfungsi", semak mengikut tertib: (1) log Terminal A, (2) View Results Tree → tab **Request** & **Response data**, (3) Debug Sampler, (4) `jmeter.log` (ikon ⚠️ kuning di penjuru kanan atas GUI).

> ⚠️ **Etika:** semua latihan **hanya** menyasarkan `http://localhost:3000` (Portal eJPJ tiruan, data sintetik). Setiap kali anda membuka plan, semak **HTTP Request Defaults → Server Name or IP = `localhost`, Port = `3000`** sebelum menekan Start.

> 💡 Simpan plan latihan anda dalam `hari-2/test-plans/` (cth. `latihan-01-rakaman.jmx`) supaya laluan CSV `../data/pengguna.csv` sah. Simpan hasil larian dalam folder `hasil/` (sudah dalam `.gitignore`). Plan rujukan ialah "kunci jawapan" — cuba sendiri dahulu.

| Latihan | Sesi | Plan / bahan rujukan | Hasil |
|---------|------|----------------------|-------|
| 1 — Rakam aliran bayar cukai | S1 | `hari-1/test-plans/rakam-template.jmx` | 4 sampler dalam 4 Transaction Controller bernama |
| 2 — Main balik & diagnosis 401/403 | S1 | `hari-1/test-plans/04-rakaman-mentah.jmx` | 200 / 401 / 200 / 401 dijelaskan; 403 dihasilkan |
| 3 — Jadikan rakaman boleh dimain balik | S2 | `04-korelasi-log-masuk.jmx`, `05-transaksi-penuh.jmx` | 80 sampel HTTP + 20 transaksi, Error % ≈ 0 |
| 4 — Jana HTML dashboard & baca setiap bahagian | S3 | `05-transaksi-penuh.jmx` (atau plan Latihan 3) | Lembaran kerja dashboard lengkap |
| 5 — Senario puncak `07` + SLA → 3 dapatan | S3 | `07-beban-puncak-cukai.jmx`, `templat-laporan-ujian.md` | Dua laporan + tiga dapatan bertulis |
| 6 — Rancang ujian + Little's Law | S4 | `templat-pelan-ujian.md` | Pelan diisi + pengiraan N & pacing |
| 7 — Pembentangan mini | S4 | Pelan (Lat. 6) + laporan (Lat. 5) | Pembentangan 3 minit |

---

## Latihan 1 — Rakam aliran bayar cukai

**Sesi:** S1

### 🎯 Objektif
- Merancang perjalanan pengguna 4 langkah dan nama transaksinya sebelum merakam (O1)
- Menyediakan HTTP(S) Test Script Recorder: port 8888, Grouping ke Transaction Controller, Excludes, think time `${T}` (O1)
- Merakam log masuk → senarai kenderaan → semak cukai → bayar cukai melalui proxy (O1)

### Prasyarat
- SUT berjalan: `node sut/server.js` → <http://localhost:3000/api/health> memulangkan `{"status":"ok",...}`
- `curl` tersedia (macOS/Linux terbina; Windows: **Git Bash**)
- README §1.2–1.5

### Langkah
1. **Rancang:** salin jadual README §1.2 ke kertas/nota anda. Untuk setiap langkah, tandakan nilai yang anda **jangka** dinamik (token, csrf, no_pendaftaran, amaun).
2. **File → Open →** `hari-1/test-plans/rakam-template.jmx` → **File → Save As** → `hari-2/test-plans/latihan-01-rakaman.jmx`.
3. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, Server `localhost`, Port `3000`. (Perakam akan membiarkan Server/Port sampler kosong.)
4. Klik **HTTP(S) Test Script Recorder**:
   - Port: `8888` · Target Controller: `Test Plan > Thread Group > Recording Controller`
   - **Grouping:** `Put each group in a new transaction controller`
   - **Capture HTTP Headers:** ditanda
   - **Requests Filtering → URL Patterns to Exclude:** regex aset statik sudah ada — tambah baris `.*google-analytics.*` dan `.*googletagmanager.*` (amalan untuk laman sebenar)
5. **Klik kanan HTTP(S) Test Script Recorder → Add → Timer → Constant Timer**: Thread Delay `${T}`.
6. Klik **Start** ▶. Jika dialog sijil Root CA muncul, klik **OK** (tidak digunakan untuk `http://`). Tetingkap **Recorder: Transactions Control** muncul — biarkan terbuka.
7. Terminal B: sahkan proxy hidup — `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (Windows: `netstat -ano | findstr :8888`).
8. Sebelum setiap langkah, taip nama transaksi (`T01_LogMasuk`, `T02_SenaraiKenderaan`, `T03_SemakCukai`, `T04_BayarCukai`) dalam medan prefix/transaction name pada tetingkap *Recorder: Transactions Control*. Kemudian jalankan blok curl langkah itu daripada README §1.4 — **tunggu > 5 s** antara blok.
9. Selepas langkah 4 memaparkan `"status":"BERJAYA"`, klik **Stop** ⏹ dan **File → Save**.
10. Kembangkan **Recording Controller**: catat nama setiap Transaction Controller dan sampler. Buka Header Manager `T02` — salin 8 aksara pertama nilai `Authorization`. Buka badan sampler `T04` — cari `csrf`.

### ✅ Checkpoint
- [ ] Jadual perancangan 4 langkah (tindakan, permintaan, nama transaksi, data dinamik) ditulis sebelum merakam
- [ ] Grouping ditetapkan ke *Put each group in a new transaction controller* dan Constant Timer `${T}` ditambah di bawah perakam
- [ ] Recording Controller mengandungi **4** kumpulan / Transaction Controller, setiap satu dengan satu sampler `/api/...`, tanpa aset statik
- [ ] Anda boleh menunjuk di mana `token` dan `csrf` sesi rakaman dikeras-kod dalam plan
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `curl: (7) Failed to connect to localhost port 8888` | Perakam belum **Start** | Klik Start pada HTTP(S) Test Script Recorder |
| curl berjaya tetapi tiada sampler dirakam | Terlupa `-x $P`, atau pembolehubah `P` tidak ditetapkan dalam terminal itu | Jalankan semula baris `P=…` dan `B=…`; semak `echo $P` |
| `Could not create script recorder - port in use` | Port 8888 digunakan (perakam lain / aplikasi lain) | Tutup tab JMeter lain yang merakam; atau tukar port (dan `P`) |
| Semua 4 permintaan dalam satu Transaction Controller | Jurang antara langkah < 5 s | Rakam semula dengan `sleep 6` antara blok; atau pisahkan secara manual (seret sampler) |
| Ralat "Target Controller is configured to Use Recording Controller but no such controller exists" | Recording Controller dipadam | **Klik kanan Thread Group → Add → Logic Controller → Recording Controller** |
| `TOKEN` kosong dalam langkah 2 | Respons log masuk tidak sampai (SUT mati) | Semak Terminal A; jalankan blok T01 semula |

### ⭐ Cabaran
1. Rakam semula dengan Naming scheme **Use format string** dan format `#{counter,number,000} - #{method} #{path}`. Bandingkan nama sampler.
2. Rakam dengan Grouping **Add separators between groups** (tetapan asal templat). Bila pilihan ini lebih sesuai daripada Transaction Controller?

---

## Latihan 2 — Main balik & diagnosis 401/403

**Sesi:** S1

### 🎯 Objektif
- Memainkan semula rakaman selepas sesi rakaman luput dan merekod kod setiap langkah (O2)
- Menggunakan tab **Sampler result**, **Request** dan **Response data** View Results Tree untuk mencari punca (O2)
- Membezakan 401 (token) dengan 403 (csrf) melalui eksperimen (O2)

### Prasyarat
- Latihan 1 selesai (`latihan-01-rakaman.jmx`), atau guna sandaran `hari-1/test-plans/04-rakaman-mentah.jmx`
- README §1.6–1.7

### Langkah
1. **Main balik pertama — tanpa restart SUT:** Start ▶. Catat kod setiap langkah. (Jangkaan: semua 200 — "lulus palsu", sesi rakaman masih hidup.)
2. **Luputkan sesi:** Terminal A → **Ctrl+C** → `node sut/server.js`.
3. **Main balik kedua:** klik ikon **Clear All** (berus) pada toolbar, kemudian Start ▶. Isi jadual:

   | Transaksi | Kod | Response message | Mesej `ralat` dalam Response data |
   |-----------|-----|------------------|-----------------------------------|
   | T01_LogMasuk | | | |
   | T02_SenaraiKenderaan | | | |
   | T03_SemakCukai | | | |
   | T04_BayarCukai | | | |

4. Klik `T02` (merah) → tab **Request**: bandingkan nilai `Authorization: Bearer …` dengan **token** dalam **Response data** `T01`. Sama atau berbeza?
5. **Eksperimen 403 (token sahaja):** **Klik kanan sampler log masuk → Add → Post Processors → JSON Extractor**: Names `token`, JSON Path `$.token`, Match No. `1`, Default `TOKEN_TAK_JUMPA`. Dalam Header Manager `T02` **dan** `T04`, tukar nilai `Authorization` kepada `Bearer ${token}`. **Jangan** sentuh `csrf`. Start ▶.
6. Catat: `T02` = ?, `T04` = ? dan mesej ralat `T04`.
7. Bandingkan dengan sandaran tanpa GUI (Terminal B, akar repo):
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l hasil/r04.jtl
   # summary = 3 ... Err: 2 (66.67%)
   ```
8. Simpan plan (**File → Save**) — ia menjadi titik mula Latihan 3.

### ✅ Checkpoint
- [ ] Main balik tanpa restart menunjukkan 4 × 200 dan anda boleh menerangkan kenapa ia "lulus palsu"
- [ ] Selepas restart SUT: log masuk **200**, senarai **401**, semak cukai **200**, bayar **401** — dicatat dalam jadual
- [ ] Tab **Request** digunakan untuk membuktikan token yang dihantar ≠ token yang baru dikeluarkan
- [ ] Dengan `token` sahaja dikorelasi, bayar menjadi **403** `Token CSRF tidak sah — sila log masuk semula`
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Semua 200 walaupun selepas "restart" | SUT tidak benar-benar dimulakan semula (proses lama masih berjalan) | Pastikan Ctrl+C menghentikan proses; Terminal A memaparkan mesej mula semula |
| Semua sampler `Non HTTP response code: java.net.ConnectException` | SUT tidak berjalan | Terminal A: `node sut/server.js` |
| `T03_SemakCukai` hijau — "bukankah semua patut gagal?" | Endpoint sebut harga tidak memerlukan token | Betul — sebab itulah kita perlu assertion & semakan setiap langkah, bukan hanya "ada yang hijau" |
| Eksperimen 403 masih 401 | Header `Authorization` dalam `T04` belum ditukar, atau tiada ruang selepas `Bearer` | Nilai mesti `Bearer ${token}` dalam **setiap** Header Manager yang berkaitan |
| `Bearer TOKEN_TAK_JUMPA` dalam tab Request | JSON Extractor bukan anak sampler log masuk | Seret extractor ke bawah sampler log masuk |

---

## Latihan 3 — Jadikan rakaman boleh dimain balik

**Sesi:** S2

### 🎯 Objektif
- Mengkorelasi `token` + `csrf` dan data kenderaan, serta memparameter pengguna dengan CSV (O3)
- Menamakan sampler, membungkus dengan Transaction Controller, menambah think time rawak dan assertion (O4)
- Menjalankan 10 pengguna × 2 gelung dan membaca Summary & Aggregate Report (O4)

### Prasyarat
- Latihan 2 selesai (plan dengan `token` dikorelasi)
- README §2.1–2.9; buka `test-plans/05-transaksi-penuh.jmx` dalam tab lain sebagai kunci jawapan

### Langkah
1. **File → Save As** → `hari-2/test-plans/latihan-03-boleh-main-balik.jmx`.
2. **Korelasi `csrf`:** buka JSON Extractor log masuk → Names `token;csrf`, JSON Path `$.token;$.csrf`, Match No. `1;1`, Default `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`. Dalam badan bayar, tukar nilai `csrf` kepada `${csrf}`.
3. **Parameterisasi:** **Klik kanan Thread Group → Add → Config Element → CSV Data Set Config**: Filename `../data/pengguna.csv`, Variable Names `no_kp,kata_laluan`, Ignore first line `True`, Recycle on EOF `True`, Sharing mode `All threads`. Badan log masuk → `{ "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }`; parameter `no_kp` sampler senarai → `${no_kp}`.
4. **Korelasi berantai:** **Klik kanan sampler senarai → Add → Post Processors → JSON Extractor** (`Ekstrak kenderaan pertama`): Names `no_pendaftaran;amaun`, Paths `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai`, Match No. `1;1`, Default `NONE;0`. Tukar path sebut harga → `/api/kenderaan/${no_pendaftaran}/cukai`, path bayar → `/api/kenderaan/${no_pendaftaran}/bayar-cukai`, badan bayar → `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": ${amaun} }`.
5. **Nama:** namakan semula sampler `1. POST /api/log-masuk`, `2. GET /api/kenderaan`, `3. GET /api/kenderaan/${no_pendaftaran}/cukai`, `4. POST /api/kenderaan/${no_pendaftaran}/bayar-cukai`.
6. **Transaction Controller:** **Klik kanan Thread Group → Add → Logic Controller → Transaction Controller** `Pembaharuan Cukai Jalan`. Seret Recording Controller (atau keempat-empat sampler) **ke dalamnya**. Biarkan *Generate parent sample* dan *Include duration of timer…* **tidak ditanda**.
7. **Think time:** padam Constant Timer hasil rakaman (nilai seperti `6012`). **Klik kanan Transaction Controller → Add → Timer → Uniform Random Timer** (`Think Time (1-3s)`): Random Delay Maximum `2000`, Constant Delay Offset `1000`.
8. **Assertion:** **Klik kanan sampler bayar → Add → Assertions → Response Assertion**: Text Response, Substring, pattern `BERJAYA`.
9. **(Disyorkan) If Controller:** **Klik kanan Transaction Controller → Add → Logic Controller → If Controller** `Jika ada kenderaan`, Condition `${__groovy(vars.get("no_pendaftaran") != "NONE" && vars.get("token") != "TOKEN_TAK_JUMPA")}`; seret sampler 3 & 4 ke dalamnya.
10. **Ujian fungsian dahulu:** Thread Group 1 pengguna, 1 gelung, View Results Tree aktif. Start → semua hijau, Request bayar mengandungi token/csrf sebenar.
11. **Larian kecil:** Thread Group `10` pengguna, Ramp-up `10`, Loop Count `2`. **Disable** View Results Tree. **Add → Listener → Summary Report** dan **Aggregate Report**. Start.
12. Catat dari Aggregate Report: # Samples baris `Pembaharuan Cukai Jalan` dan jumlah sampel 4 langkah; Average, 95% Line baris transaksi; Error %.

> Bandingkan dengan [`test-plans/05-transaksi-penuh.jmx`](../test-plans/05-transaksi-penuh.jmx) (disahkan: 80 sampel HTTP + 20 baris transaksi, 0% ralat; transaksi ≈ 440 ms).

### ✅ Checkpoint
- [ ] `token`, `csrf`, `no_pendaftaran` dan `amaun` diekstrak pada masa larian — tiada nilai rakaman tinggal dalam header/badan/path
- [ ] CSV `pengguna.csv` memberikan 3 `no_kp` berbeza (lihat Request atau label kenderaan berbeza: `WXY1234`, `JQK7788`, `BMT3030`)
- [ ] Sampler dinamakan semula, dibungkus Transaction Controller `Pembaharuan Cukai Jalan`, dengan Uniform Random Timer dan Response Assertion `BERJAYA`
- [ ] Larian 10 × 2: **80** sampel HTTP + **20** baris transaksi dalam Aggregate Report, Error % ≈ 0 (≤ 1 ralat 500 sintetik diterima)
- [ ] Lulus **Kuiz S2** (sekurang-kurangnya separuh betul) (Kuiz S2)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `${no_kp}` dihantar secara literal | CSV tidak dijumpai — plan tidak disimpan dalam `hari-2/test-plans/` | Save As ke folder itu; atau laluan mutlak |
| Log masuk **401** `No. KP atau kata laluan tidak sah` | Badan kosong / tiada `Content-Type: application/json` | Semak Header Manager sampler log masuk (rakaman) atau tambah di aras Thread Group |
| Bayar **403** | `csrf` belum dikorelasi / ejaan `${csrf}` | Names & Paths extractor sama bilangan, dipisah `;` |
| Laluan `/api/kenderaan/NONE/cukai` → 404 | Extractor kenderaan bukan anak sampler senarai | Seret extractor ke bawah `2. GET /api/kenderaan` |
| Bayar 400/500 dengan `"amaun": ${amaun}` literal | `amaun` tidak diekstrak | Dua nama, dua path: `no_pendaftaran;amaun` |
| Tiada baris transaksi | Sampler di **bawah**, bukan **di dalam**, Transaction Controller | Seret sampler ke atas nama controller |
| Larian sangat perlahan | Constant Timer `${T}` rakaman (6 s+) masih ada | Padam timer rakaman; guna Uniform Random Timer |
| Kadang-kadang 1 ralat 500 | `ERROR_RATE` 1% SUT — sengaja | Jangkaan normal; untuk larian bersih: `ERROR_RATE=0 node sut/server.js` |

### ⭐ Cabaran
1. Gantikan JSON Extractor `token` dengan **Regular Expression Extractor** (`"token":"([^"]+)"`, Template `$1$`) atau **Boundary Extractor** (Left `"token":"`, Right `"`). Hasil mesti sama.
2. Ambil `amaun` + `tempoh_bulan` dari respons **sebut harga** (`$.amaun;$.tempoh_bulan`) seperti plan `07`.
3. Buka [`08-foreach-kenderaan.jmx`](../test-plans/08-foreach-kenderaan.jmx): Match No. `-1` + ForEach Controller → 3 pengguna membayar **5** kenderaan (16 sampel HTTP). Nyahtanda *Add "_" before number ?* dan perhatikan 0 lelaran tanpa ralat.
4. Tambah **JSR223 PostProcessor** (Groovy, *Cache compiled script if available*) dari blok "2)" dalam [`jsr223-groovy.groovy`](./jsr223-groovy.groovy) di bawah log masuk.

---

## Latihan 4 — Jana HTML dashboard & baca setiap bahagian

**Sesi:** S3

### 🎯 Objektif
- Menjana HTML dashboard semasa larian (`-e -o`) dan kemudian daripada `.jtl` (`-g -o`) (O5)
- Melaras butiran graf dengan `-Jjmeter.reportgenerator.overall_granularity` (O5)
- Mencatat nilai sebenar dan mentafsir setiap bahagian dashboard dengan istilah yang betul (O6)

### Prasyarat
- SUT berjalan; **tutup** larian GUI (boleh biarkan GUI terbuka tanpa larian)
- `jmeter --version` memaparkan 5.6.x
- README §3.1–3.5

### Langkah
1. Terminal B, dari akar repo — jalankan plan rakaman bersih anda (atau rujukan `05`) secara non-GUI:
   ```bash
   mkdir -p hasil                    # Windows: mkdir hasil — folder induk -o mesti wujud
   jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx \
     -l hasil/r05.jtl -e -o hasil/laporan05
   ```
   (Plan Latihan 3: gantikan `05-transaksi-penuh.jmx` dengan `latihan-03-boleh-main-balik.jmx` — pastikan View Results Tree **disabled**.)
2. Perhatikan baris `summary =` dalam terminal (jumlah sampel, `Err:`). Buka `hasil/laporan05/index.html`.
3. Jana dashboard **kedua** daripada `.jtl` yang sama dengan graf setiap 5 s:
   ```bash
   jmeter -g hasil/r05.jtl -o hasil/laporan05-5s \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```
   Bandingkan *Charts → Over Time → Response Times Over Time* dalam kedua-dua laporan.
4. Cuba jana sekali lagi ke `hasil/laporan05-5s` — catat mesej ralat.
5. Isi **lembaran kerja** dengan nilai **sebenar** dari dashboard anda:

   | # | Bahagian | Apa yang anda catat | Nilai anda | Tafsiran (1 ayat) |
   |---|----------|---------------------|------------|-------------------|
   | 1 | Test and Report information | Source file, Start/End Time | | Larian lengkap? |
   | 2 | APDEX | Total; baris transaksi; T & F | | Kenapa transaksi < 1.0? |
   | 3 | Requests Summary | PASS % / FAIL % | | |
   | 4 | Statistics — Total | #Samples, Error %, Average, 95th pct, Transactions/s | | Total termasuk transaksi? |
   | 5 | Statistics — baris transaksi | #Samples, Average, Median, 90th/95th/99th pct, Max | | Jurang Median → 99th? |
   | 6 | Statistics — langkah paling lambat | Label + 95th pct | | |
   | 7 | Errors / Top 5 Errors by sampler | Jenis ralat, bilangan | | |
   | 8 | Over Time → Active Threads Over Time | Bentuk ramp-up | | Model beban berlaku? |
   | 9 | Over Time → Response Time Percentiles Over Time | p95 awal vs akhir | | Stabil? |
   | 10 | Throughput → Hits Per Second vs Total Transactions Per Second | Nisbah | | Kenapa ≈ 4 : 1? |
   | 11 | Throughput → Codes Per Second | Kod yang muncul | | |
   | 12 | Response Times → Response Time Overview | Bilangan setiap bar | | |
   | 13 | Response Times → Response Time Distribution | Julat paling banyak | | |
   | 14 | Latency vs Response time (`.jtl` atau Latencies Over Time) | Satu sampel log masuk | | Masa di pelayan atau pemindahan? |

6. Buka `hasil/laporan05/statistics.json` dalam editor; cari `pct2ResTime` bagi `Pembaharuan Cukai Jalan` dan pastikan ia sama dengan **95th pct** dalam jadual.

### ✅ Checkpoint
- [ ] `hasil/laporan05/index.html` dijana dengan `-e -o` dan dibuka
- [ ] Dashboard kedua dijana dengan `-g … -o` dan `overall_granularity=5000`; anda boleh menerangkan beza bilangan titik graf
- [ ] Lembaran kerja 14 baris diisi dengan nilai sebenar dan satu ayat tafsiran setiap satu
- [ ] Anda boleh menerangkan kenapa **Total** Statistics ≠ jumlah termasuk baris transaksi, dan kenapa sampel gagal dikira Frustrated dalam APDEX
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `Cannot write to '…' as folder is not empty` | Folder `-o` sudah wujud | Folder baharu, atau padam yang lama |
| `… as folder does not exist and parent folder is not writable` | Folder induk (`hasil/`) belum wujud — JMeter menyemak sebelum ujian bermula | `mkdir -p hasil` (Windows: `mkdir hasil`), kemudian ulang |
| `jmeter: command not found` | JMeter tiada pada PATH | Hari 1 — Persediaan; atau laluan penuh `…/bin/jmeter` |
| Graf Over Time hanya 1–2 titik | Butiran lalai 60 s | Jana semula dengan `-Jjmeter.reportgenerator.overall_granularity=5000` |
| Dashboard kosong / tiada baris | `.jtl` kosong — SUT mati atau plan gagal awal | Semak `summary =` dan `jmeter.log` |
| Plan anda: semua sampel `Non HTTP response code` | Sampler rakaman tiada Server/Port (dirakam bersama HTTP Request Defaults) tetapi Defaults itu telah dipadam/dinyahdayakan | Pastikan HTTP Request Defaults `localhost`/`3000` aktif dalam plan |

---

## Latihan 5 — Senario puncak `07` + SLA → tiga dapatan

**Sesi:** S3

### 🎯 Objektif
- Menjalankan senario puncak `07` dengan dua ambang SLA dan membandingkan laporan (O7)
- Menjejak pelanggaran SLA dalam Statistics, Errors, Top 5 Errors dan Transactions Per Second (O7)
- Menulis tiga dapatan (bukti → kesan → punca → cadangan) dalam templat laporan (O7)

### Prasyarat
- Latihan 4 selesai; SUT biasa berjalan (`node sut/server.js`)
- [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) dibuka — baca contoh bahagian B
- README §3.6–3.8

### Langkah
1. Buka `07-beban-puncak-cukai.jmx` dalam GUI **sekali** untuk melihat: Thread Group `${__P(pengguna,300)}`, Transaction Controller `Pembaharuan Cukai Jalan (Puncak)`, Duration Assertion `${__P(sla_ms,2000)}`, Think Time Rush 0.5–1.5 s. Jangan Start dalam GUI.
2. **R1 — SLA 2000 ms** (≈ 1 minit):
   ```bash
   jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
     -l hasil/r07-sla2000.jtl -e -o hasil/laporan07-sla2000 \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```
3. **R2 — SLA 150 ms**, sistem sama:
   ```bash
   jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=150 \
     -l hasil/r07-sla150.jtl -e -o hasil/laporan07-sla150 \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```
4. Isi jadual perbandingan:

   | Metrik (baris `Pembaharuan Cukai Jalan (Puncak)`) | R1 (2000 ms) | R2 (150 ms) |
   |---------------------------------------------------|-------------:|------------:|
   | #Samples | | |
   | Error % | | |
   | 95th pct (ms) | | |
   | Transactions/s | | |
   | APDEX (baris transaksi) | | |
   | Error % `Total` | | |

   (Rujukan larian kami: R1 → 598 sampel, 1.00%, 583 ms, 10.46/s, APDEX 0.862; R2 → 607 sampel, **21.75%**, 572 ms, 10.54/s, APDEX 0.717.)
5. Dalam R2, buka **Errors**: berapa baris `The operation lasted too long…`? Kenapa banyak? Buka **Top 5 Errors by sampler** dan **Charts → Throughput → Codes Per Second** — adakah kod `200` sahaja? Kenapa?
6. **Little's Law cepat:** dengan Transactions/s R1, R ≈ Average transaksi (s), Z ≈ 4 s → kira X × (R + Z). Bandingkan dengan Active Threads Over Time.
7. Salin bahagian **A** `templat-laporan-ujian.md` ke `hasil/laporan-pasangan-<nama>.md` dan tulis **tiga dapatan** menggunakan angka **anda** (cadangan: D1 masa respons vs NFR, D2 ralat 500 & Error %, D3 kesan ambang SLA).

### ✅ Checkpoint
- [ ] Dua laporan `07` dijana (`laporan07-sla2000`, `laporan07-sla150`) dengan butiran 5 s
- [ ] Jadual perbandingan R1 vs R2 diisi dan anda boleh menerangkan kenapa Error % naik walaupun masa respons sama
- [ ] Anda menunjuk tiga tempat pelanggaran SLA kelihatan (Statistics/Error %, Errors/Top 5, siri `-failure` Transactions Per Second) dan kenapa *Codes Per Second* tidak menunjukkannya
- [ ] Tiga dapatan ditulis dengan bukti (angka + bahagian dashboard), kesan, punca dan cadangan
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Error % R2 sama dengan R1 | `-Jsla_ms` ditulis dengan ruang (`-J sla_ms=150`) atau `-D` | Tulis `-Jsla_ms=150` tanpa ruang |
| Laptop sangat perlahan / kipas kuat | JMeter + SUT pada mesin sama | Kurangkan `-Jpengguna=25`; catat sebagai batasan dalam laporan |
| `folder is not empty` | Nama folder `-o` digunakan semula | Nama baharu setiap larian |
| Error % R1 > 1% | Ralat 500 sintetik 1% SUT | Normal pada sempadan — itu dapatan D2 anda |
| Dapatan berbunyi "sistem OK" | Tiada angka/bukti | Setiap dapatan: angka + nama bahagian dashboard |

### ⭐ Cabaran
1. **R3 — mock perlahan tanpa mengganggu SUT utama:** Terminal C: `PORT=3001 LATENCY_MIN=500 LATENCY_MAX=1500 node sut/server.js`, kemudian jalankan R1 dengan `-Jport=3001` ke folder baharu. Bandingkan Transactions/s dan p95 dengan R1, dan sahkan Little's Law (larian kami: 5.78/s, p95 4969 ms). Hentikan Terminal C selepas selesai.
2. Jana semula R1 dengan `-Jjmeter.reportgenerator.apdex_satisfied_threshold=300 -Jjmeter.reportgenerator.apdex_tolerated_threshold=1000`. Bagaimana APDEX berubah, dan siapa patut memilih T/F?
3. Stress berperingkat: jalankan R1 dengan `-Jpengguna=100` dan `150`. Adakah throughput terus naik? Apa yang menghadkan — SUT atau CPU laptop?

---

## Latihan 6 — Rancang ujian prestasi + Little's Law

**Sesi:** S4

### 🎯 Objektif
- Mengisi pelan ujian prestasi: NFR, model beban, jenis larian, kriteria, pemantauan, risiko, kebenaran (O8)
- Mengira bilangan pengguna serentak dengan Little's Law dan tetapan pacing (O8)

### Prasyarat
- [`templat-pelan-ujian.md`](./templat-pelan-ujian.md) — baca contoh eJPJ yang telah diisi
- README §4.1–4.7

### Langkah
1. Salin templat ke `hasil/pelan-pasangan-<nama>.md`.
2. Pilih senario (pilih satu): **(a)** pembaharuan cukai jalan pada hari kenaikan harga (seperti contoh, tukar angka), **(b)** bayar saman pada hari terakhir diskaun saman, **(c)** sistem dalaman organisasi anda (secara konsep sahaja — tiada larian).
3. Isi bahagian 1–3: objektif (Q1–Q4), skop, dan **sekurang-kurangnya 4 NFR** yang boleh diukur.
4. **Lampiran A — Little's Law:** tetapkan volum jam puncak V, kira X = V ÷ 3600, anggar R dan Z, kira **N = X × (R + Z)**, kadar hits/s, dan tetapan **Constant Throughput Timer** (X × 60 sampel/minit, sebagai anak sampler pertama).
5. **Semak dengan data makmal:** gunakan R1 Latihan 5 — adakah 50 pengguna × (R + 4 s) memberi Transactions/s yang dijangka?
6. Isi bahagian 5 (campuran transaksi), 8 (jadual baseline → load → stress → spike → soak dengan konfigurasi `-J`), 9 (kriteria masuk/keluar/gantung), 10 (pemantauan), 11 (sekurang-kurangnya 3 risiko) dan 12 (kebenaran & prosedur henti).

### ✅ Checkpoint
- [ ] Sekurang-kurangnya 4 NFR ditulis dengan transaksi, beban, metrik percentile, ambang dan tempoh
- [ ] Pengiraan Little's Law lengkap: V → X → N, kadar hits/s, dan tetapan pacing
- [ ] Jadual jenis larian (baseline, load, stress, spike, soak) dengan konfigurasi JMeter
- [ ] Kriteria masuk/keluar, pemantauan, 3 risiko dan bahagian kebenaran bertulis diisi
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| N sangat kecil (cth. 10) untuk volum besar | Z dilupakan (hanya R digunakan) | N = X × (R **+ Z**); think time biasanya mendominasi |
| N tidak masuk akal (berjuta) | Unit bercampur (minit vs saat) | Tukar semua kepada **saat** |
| Pacing tidak mencapai sasaran | Constant Throughput Timer dalam **sampel/minit**, atau threads < N | Sasaran = X × 60; tambah threads |
| NFR "sistem mesti stabil" | Tidak boleh diukur | Tambah metrik + ambang + beban + tempoh |

---

## Latihan 7 — Pembentangan mini (pasangan)

**Sesi:** S4

### 🎯 Objektif
- Menyampaikan pelan ujian dan satu dapatan laporan kepada "pengurusan" dalam 3 minit (O9)

### Prasyarat
- Latihan 5 (dapatan) dan Latihan 6 (pelan) selesai

### Langkah
1. Sediakan 4 bahagian (maksimum 45 saat setiap satu):
   - **NFR utama** — satu ayat boleh diukur
   - **Model beban** — X, R, Z → N (tunjuk pengiraan)
   - **Jenis larian** — tertib dan kenapa baseline dahulu
   - **Satu dapatan** dari Latihan 5 — Bukti (angka + bahagian dashboard) → Kesan → Cadangan
2. Tutup dengan satu ayat: *"Sebelum ujian sebenar, kami perlukan kebenaran bertulis daripada …"*
3. Bentangkan (pasangan lain bertanya **satu** soalan: "Bagaimana anda tahu …?").
4. Catat satu maklum balas yang anda terima.

### ✅ Checkpoint
- [ ] Pembentangan ≤ 3 minit merangkumi NFR, pengiraan N, jenis larian dan satu dapatan
- [ ] Dapatan disokong angka sebenar dan nama bahagian dashboard
- [ ] Soalan pasangan lain dijawab dan satu maklum balas dicatat
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Melebihi masa | Membaca jadual satu-persatu | Satu angka utama setiap bahagian |
| "Graf ini naik…" tanpa kesimpulan | Tiada kesan/cadangan | Akhiri setiap dapatan dengan "jadi…" |
| Tiada sebutan kebenaran | Terlupa etika | Ayat penutup wajib (langkah 2) |

### ⭐ Cabaran
1. **Gerbang SLA CI:** jalankan blok `jq` + `awk` dalam README §4.9 pada `laporan07-sla2000` dan `laporan07-sla150`; tunjukkan kod keluar (`echo $?`).
2. Terangkan dalam satu minit bagaimana anda akan memantau ujian soak 4 jam (Backend Listener + Grafana vs HTML dashboard).

---

## Semakan kendiri

- [ ] Saya boleh merancang perjalanan pengguna dan merakamnya ke dalam Transaction Controller bernama, tanpa aset statik
- [ ] Saya boleh menerangkan kenapa main balik gagal (401/403) — dan kenapa main balik yang "lulus" belum tentu betul
- [ ] Saya boleh membersihkan rakaman: korelasi, parameterisasi CSV, nama, think time, assertion
- [ ] Saya boleh menjana HTML dashboard dengan `-e -o` dan `-g`, dan melaras butiran graf
- [ ] Saya boleh menerangkan setiap bahagian dashboard dan istilahnya (percentile, throughput, latency, APDEX, Error %)
- [ ] Saya boleh menulis dapatan dengan bukti, kesan, punca dan cadangan
- [ ] Saya boleh mengira pengguna serentak dengan Little's Law dan merancang jenis larian
- [ ] Isi penilaian kendiri Hari 2 (Kuiz hari)
