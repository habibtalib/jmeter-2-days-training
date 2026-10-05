# Lab Hari 1 — Asas JMeter & Ujian Beban

[⬅️ README Hari 1](../README.md) · [🎤 Nota Penceramah](../nota-penceramah.md) · [🎬 Rakam → Replay](./rakaman-e2e.md) · [🔒 Recording HTTPS](./rakaman-https-setup.md) · [🔑 Test plan rujukan](../test-plans/)

> **Peraturan lab:** Sebelum setiap run, **ramal** dulu — berapa sample? Error % berapa? Throughput naik ke turun? Tulis ramalan anda, baru klik **Start**. File rujukan (jawapan) ada dalam `hari-1/test-plans/`. Cuba bina sendiri dulu; buka file rujukan hanya selepas checkpoint, atau kalau dah tersangkut lebih 10 minit.

> ⚠️ **Etika:** Semua latihan target **`http://localhost:3000`** sahaja — sentiasa check Server=`localhost`, Port=`3000` sebelum Start.

> 📊 **Bukti progress:** JMeter run dalam laptop anda, jadi LMS tak boleh nampak run anda. Tick setiap ✅ Checkpoint dengan jujur. Item terakhir setiap checkpoint ialah **kuiz sesi** dalam README — itu bukti yang dinilai.

Pastikan **server mock dah running** dulu (biarkan terminal ini terbuka sepanjang hari):

```bash
cd sut && node server.js      # biarkan terbuka
```

| Latihan | Sesi | Fokus | File rujukan |
|---------|------|-------|--------------|
| 0 | S1 | Setup: Java, JMeter (PATH), SUT | — |
| 1 | S2 | Test Plan pertama | `01-hello-jpj.jmx` |
| 2 | S3 | Load test + assertion + timer | `02-cukai-beban.jmx` |
| 3 | S3 | Parameterize guna CSV | `03-csv-berparameter.jmx` |
| 4 | S3 | Buat assertion FAIL | `03-csv-berparameter.jmx` + baris palsu |
| 5 | S3 | Kesan latency server | `02-cukai-beban.jmx` |
| 6 | S4 | Record & tengok replay fail | `rakam-template.jmx`, `04-rakaman-mentah.jmx` |
| 7 ⭐ | S3 | Cabaran: dua sampler, scope yang betul | — |

---

## Latihan 0 — Persediaan: Java, JMeter & SUT

**Sesi:** S1

### 🎯 Objektif
- Install Java + JMeter dan run `jmeter` dari mana-mana folder (O2)
- Run SUT mock dan check endpoint health (O2)
- Boleh sebut target yang dibenarkan dalam kursus dan syarat etika (O1)

### Prasyarat
- Node.js 18+ (`node --version`)
- Installer JDK 17/21 dan zip JMeter 5.6.x (download dari internet, atau ambil dari USB penceramah)
- README §1.3–1.8 dah diterangkan

### Langkah

1. Check Java:
   ```bash
   java --version        # 11 atau lebih baru (disyorkan 17/21)
   ```

   ![Terminal: java --version](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-05-java-version.png)
   *Output sebenar `java --version`: OpenJDK **21** (Temurin) — 11 atau lebih baru dah cukup.*

2. Install JMeter (README §1.5). **Windows:** extract ke `C:\apache-jmeter-5.6.3`, tambah `C:\apache-jmeter-5.6.3\bin` dalam **User variables → Path**, kemudian **tutup & buka balik** terminal.

   ![Terminal: jmeter -v banner 5.6.3](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-06-jmeter-v-banner.png)
   *Lepas JMeter ada dalam PATH, `jmeter -v` dari mana-mana folder keluarkan banner **5.6.3**. (Dialog Path Windows tak ditangkap di sini.)*

3. Test dari folder **lain** (bukan `bin`):
   ```bash
   cd ~            # Windows: cd %USERPROFILE%
   jmeter -v
   ```

![Terminal: java --version dan jmeter -v](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-01-java-jmeter-versi.png)
*`java --version` (Temurin 21) dan `jmeter -v` dari folder home — banner Apache JMeter **5.6.3** keluar. Baris `WARN`/`WARNING` di atas banner boleh diabaikan.*

4. Start SUT dalam terminal lain dan biarkan terbuka:
   ```bash
   cd sut
   node server.js
   ```

   ![Terminal A: banner SUT Portal eJPJ (TIRUAN)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-07-sut-banner.png)
   *Banner SUT sebenar: latency 40–180 ms, error rate 1.0%, portal web, chatbot — biarkan terminal ni terbuka. (Tangkapan ini guna `PORT=3917` supaya tak ganggu kelas; anda run `node server.js` dan dapat port `3000`.)*

5. Dalam terminal kedua (atau browser):
   ```bash
   curl -s http://localhost:3000/api/health
   ```
   Expected: `{"status":"ok","masa":"…"}`. Buka `http://localhost:3000` dalam browser untuk tengok senarai endpoint.

![Terminal: SUT berjalan dan curl /api/health](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-02-sut-health.png)
*Terminal 1: banner SUT (latency 40–180 ms, error rate 1.0%, portal web). Terminal 2: `curl` ke `/api/health` pulangkan `{"status":"ok",…}`. (Tangkapan ini guna `PORT=3037`; dalam kelas guna port default `3000`.)*

![Browser: halaman info Portal eJPJ (TIRUAN)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-03-browser-info-page.png)
*Halaman info `http://localhost:3000/` dalam browser — senarai endpoint API dan pautan ke portal web `/portal`.*

6. Buka GUI: `jmeter` (atau `bin\jmeter.bat`). Kenal pasti **test tree** (kiri), **panel setting** (kanan), button **Start / Stop / Clear All**, dan ikon **Log** (segi tiga amaran, kanan atas).

   ![JMeter GUI baru dibuka: Test Plan kosong](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-04-gui-test-plan-kosong.png)
   *GUI JMeter 5.6.3: **test tree** di kiri, **panel setting** di kanan; toolbar ada Start ▶, Stop, Clear All (berus); ikon **Log** (segi tiga amaran) dan kiraan thread di kanan atas.*

### ✅ Checkpoint
- [ ] `java --version` memaparkan versi 11 atau lebih baru
- [ ] `jmeter -v` berjalan dari folder selain `bin` dan memaparkan versi 5.6.x
- [ ] SUT berjalan dan `http://localhost:3000/api/health` memulangkan `{"status":"ok",…}`
- [ ] GUI JMeter dibuka tanpa ralat
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| `'jmeter' is not recognized…` (Windows) | `bin` tak ada dalam PATH, atau guna terminal lama | Tambah dalam **User variables → Path**; **buka terminal baru** |
| `jmeter` complain Java tak jumpa | JDK tak install / `JAVA_HOME` salah | Install JDK 11+; set `JAVA_HOME` ke folder JDK; tambah `%JAVA_HOME%\bin` dalam PATH; test `java -version` |
| `EADDRINUSE :::3000` masa `node server.js` | Ada SUT lain dah running di port 3000 | Guna window SUT yang dah ada, atau stop dulu (Ctrl+C); guna `PORT=3001 node server.js` hanya kalau perlu (dan tukar Defaults) |
| GUI JMeter sangat lambat / font kecil | Skrin resolusi tinggi / RAM rendah | **Options → Zoom In**; tutup aplikasi lain |
| `curl` tak ada (Windows lama) | — | Buka `http://localhost:3000/api/health` dalam browser |

### ⭐ Cabaran
Start SUT dengan `ERROR_RATE=0.2 node server.js` dan baca `sut/server.js` — endpoint mana yang kena kesan `ERROR_RATE`? (Jawapan: hanya `POST …/bayar-cukai`.) Lepas tu restart dengan `node server.js` biasa.

---

## Latihan 1 — Test Plan pertama anda

**Sesi:** S2

### 🎯 Objektif
- Bina Test Plan dengan Thread Group, HTTP Request Defaults, HTTP Request dan View Results Tree (O3)
- Baca tab Sampler result / Request / Response data dalam View Results Tree

### Prasyarat
- Latihan 0 dah siap; SUT running
- README §2.1–2.2

### Langkah

1. Buka JMeter (GUI). **Klik kanan Test Plan → Add → Threads (Users) → Thread Group** — 1 user, ramp-up 1, 1 loop.

   ![Thread Group baru: 1 thread, ramp-up 1, loop 1](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-04-thread-group-1-1-1.png)
   *Thread Group baru bawah Test Plan: Number of Threads `1`, Ramp-up `1`, Loop Count `1` (nilai default).*

2. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, server `localhost`, port `3000`. *(Plan rujukan letak Defaults bawah Test Plan — kesan sama.)*

   ![HTTP Request Defaults http localhost 3000](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-05-http-request-defaults.png)
   ***HTTP Request Defaults**: Protocol `http`, Server `localhost`, Port `3000`.*

3. **Klik kanan Thread Group → Add → Sampler → HTTP Request** → `GET /api/health` (biarkan Server/Port kosong).

   ![HTTP Request GET /api/health dengan Server dan Port kosong](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-06-sampler-api-health.png)
   *Sampler `GET /api/health`: Method `GET`, Path `/api/health`; Protocol/Server/Port **kosong** — diambil dari Defaults.*

4. Tambah sampler kedua `GET /` (page info).

   ![HTTP Request kedua GET /](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-07-sampler-halaman-info.png)
   *Sampler kedua `GET / (halaman info)`: Path `/`.*

5. **Klik kanan Thread Group → Add → Listener → View Results Tree**.

   ![View Results Tree ditambah bawah Thread Group](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-08-view-results-tree-ditambah.png)
   ***View Results Tree** di hujung Thread Group — kosong sehingga anda run.*

6. **File → Save** sebagai `lab1-saya.jmx`, kemudian run (▶). Pastikan response `{"status":"ok"}` dan code **200**.

![View Results Tree: tab Sampler result dengan Response code 200](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-01-vrt-sampler-result.png)
*Plan `01-hello-jpj.jmx` selepas run: dua sample hijau dalam View Results Tree; tab **Sampler result** untuk `GET /api/health` tunjuk `Response code:200` dan `Response message:OK`.*

![View Results Tree: tab Response data](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-02-vrt-response-data.png)
*Tab **Response data → Response Body**: `{"status":"ok","masa":"…"}`.*

7. Dalam View Results Tree, klik sample `/api/health` → tab **Request** — tengok URL penuh `http://localhost:3000/api/health` yang terbentuk daripada Defaults + Path.

![View Results Tree: tab Request dengan URL penuh](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-03-vrt-request-url.png)
*Langkah 7: tab **Request** tunjuk URL penuh `GET http://localhost:…/api/health` — server dan port datang dari HTTP Request Defaults, path dari sampler. (Tangkapan guna port 3037.)*

> Bandingkan dengan `test-plans/01-hello-jpj.jmx`.

### ✅ Checkpoint
- [ ] Test Plan berjalan dan View Results Tree menunjukkan kod **200** dengan respons `{"status":"ok"}`
- [ ] Struktur plan sepadan dengan `test-plans/01-hello-jpj.jmx` (Thread Group → HTTP Request Defaults → HTTP Request → Listener)
- [ ] Tab **Request** menunjukkan URL penuh yang diwarisi daripada HTTP Request Defaults
- [ ] Lulus **Kuiz S2** (sekurang-kurangnya separuh betul) (Kuiz S2)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| `Non HTTP response code: java.net.ConnectException` | SUT tak running / port salah | Start `node server.js`; check Port `3000` dalam Defaults |
| `UnknownHostException` | Server Name ada `http://` atau space | Server Name = `localhost` sahaja (protocol ada field sendiri) |
| View Results Tree kosong | Listener di luar scope (contohnya di bawah Thread Group lain) atau plan tak di-run | Letak listener bawah Thread Group yang sama; tengok ikon Log |
| Button Start kelabu | Plan masih running | Tunggu, atau klik **Stop** |

### ⭐ Cabaran
Tambah **HTTP Header Manager** dengan `Accept: application/json`, kemudian pastikan header itu keluar dalam tab **Request → Request Headers**.

---

## Latihan 2 — Ujian beban + assertion + timer

**Sesi:** S3

### 🎯 Objektif
- Set load model 20 / 10 / 5 dan ramal bilangan sample (O4)
- Tambah Response Assertion, Duration Assertion dan Constant Timer (O7)
- Baca Throughput, Average, Error % dan 95% Line (O6)

### Prasyarat
- Latihan 1 dah siap
- README §2.3–2.5 dan §3.1–3.2

### Langkah

1. Tukar Thread Group kepada **20 users**, **ramp-up 10s**, **5 loop**.

![Thread Group: 20 threads, ramp-up 10, loop 5](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-01-thread-group-20-10-5.png)
*Thread Group dalam `02-cukai-beban.jmx`: **Number of Threads 20**, **Ramp-up period 10**, **Loop Count 5**. Tree kiri tunjuk susunan sampler, assertion, timer dan listener.*

2. Sampler: `GET /api/kenderaan/WXY1234/cukai` (buang atau disable sampler lain).

   ![Sampler GET /api/kenderaan/WXY1234/cukai; sampler lain disabled](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-04-sampler-cukai-lain-disable.png)
   *Sampler `GET /api/kenderaan/WXY1234/cukai`; dua sampler Latihan 1 di-**disable** (kelabu dalam tree).*

3. Tambah **Response Assertion** (klik kanan sampler → Add → Assertions) — Field to Test *Text Response*, *Substring*, pattern `amaun`.

   ![Response Assertion child sampler cukai: Text Response, Substring, amaun](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-08-response-assertion-amaun-baru.png)
   ***Response Assertion** child sampler cukai: Field to Test **Text Response**, Pattern Matching Rules **Substring**, Patterns to Test `amaun`.*

4. Tambah **Duration Assertion** (klik kanan sampler yang sama → Add → Assertions → Duration Assertion) — *Duration in milliseconds* `2000`.

   ![Duration Assertion 2000 ms child sampler](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-05-duration-assertion-2000.png)
   ***Duration Assertion** child sampler cukai: Duration in milliseconds `2000` (Response Assertion `amaun` di atasnya).*

![Response Assertion: Text Response, Substring, amaun](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-02-response-assertion-amaun.png)
*Response Assertion (child sampler): **Field to Test = Text Response**, **Pattern Matching Rules = Substring**, pattern `amaun`.*

5. Tambah **Constant Timer** 300 ms (think time) bawah Thread Group (klik kanan Thread Group → Add → Timer → Constant Timer; *Thread Delay* `300`).

   ![Constant Timer 300 ms bawah Thread Group](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-06-constant-timer-300.png)
   ***Constant Timer** bawah Thread Group: Thread Delay `300`.*

6. Tambah **Summary Report** dan **Aggregate Report** (klik kanan Thread Group → Add → Listener). **Disable** View Results Tree (klik kanan → **Disable**) — listener ni berat masa load test.

   ![Summary Report dan Aggregate Report ditambah, View Results Tree disabled](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-07-summary-aggregate-vrt-disable.png)
   *Summary Report + Aggregate Report ditambah; View Results Tree **disabled** (kelabu). Jadual kosong sehingga run.*

7. **Ramal** jumlah request, kemudian **Clear All** dan run. Catat: **Throughput**, **Average**, **Error %**, **95% Line**.

![Summary Report: 100 sample, 0% error](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-03-summary-report-100.png)
*Summary Report selepas run: **# Samples = 100** (20 × 5), **Error % = 0.00%**, Average 107 ms, Throughput 8.9/sec. Nombor anda akan berbeza sedikit.*

> **Soalan:** Berapa jumlah request yang dijangka? (20 × 5 = 100). Check betul ke tak.
> Bandingkan dengan `test-plans/02-cukai-beban.jmx`.

### ✅ Checkpoint
- [ ] Thread Group ditetapkan 20 pengguna, ramp-up 10s, 5 gelung
- [ ] Response Assertion (`amaun`) dan Duration Assertion (2000 ms) ditambah, serta Constant Timer 300 ms
- [ ] Summary Report menunjukkan **100** permintaan dengan Error % 0%
- [ ] Nilai **Throughput**, **Average** dan **Error %** dicatat
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| `# Samples` = 200 atau 300, bukan 100 | Sampler lama (`/api/health`, `/`) masih enabled | Disable/buang sampler lain |
| Nombor berganda / bercampur | Result run lama tak di-clear | **Clear All** sebelum setiap run |
| Semua sample fail assertion | Pattern salah eja / Field to Test salah | *Text Response* + *Substring* + `amaun` (huruf kecil) |
| Throughput jauh lebih rendah dari expected | Timer buat jeda (memang betul!) atau ramp-up belum habis | Bandingkan dengan run tanpa timer — itulah pengajarannya |
| JMeter hang masa run | View Results Tree masih enabled dengan banyak sample | Disable View Results Tree masa load test |

### ⭐ Cabaran
Tukar Constant Timer kepada **Gaussian Random Timer** (Deviation 300, Constant Delay Offset 1000). Run semula — bandingkan Throughput. Lepas tu turunkan Duration Assertion ke `100` ms dan tengok Error % — macam ni lah SLA "menggigit".

---

## Latihan 3 — Parameterisasi dengan CSV

**Sesi:** S3

### 🎯 Objektif
- Hantar nombor pendaftaran yang berlainan guna CSV Data Set Config dan `${no_pendaftaran}` (O8)

### Prasyarat
- Latihan 2 dah siap
- README §3.3; file `hari-1/data/kenderaan.csv` ada

### Langkah

1. Save plan anda **dalam folder `hari-1/test-plans/`** (supaya path relatif `../data/` betul).

   ![Menu File JMeter: Save Test Plan as](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-13-menu-file.png)
   ***File → Save Test Plan as** → simpan dalam `hari-1/test-plans/`.*

2. Tambah **CSV Data Set Config** (klik kanan Thread Group → Add → Config Element → CSV Data Set Config; plan rujukan letak ia bawah Test Plan — kesan sama) yang baca `../data/kenderaan.csv`
   (variable names: `no_pendaftaran,model`; ignore first line: **True**; recycle: **True**; stop thread: **False**; sharing mode: **All threads**).

![CSV Data Set Config: ../data/kenderaan.csv, no_pendaftaran,model](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab3-01-csv-data-set-config.png)
*CSV Data Set Config: Filename `../data/kenderaan.csv`, Variable Names `no_pendaftaran,model`, Ignore first line **True**, Recycle on EOF **True**, Stop thread on EOF **False**, Sharing mode **All threads**.*

3. Tukar path sampler kepada `/api/kenderaan/${no_pendaftaran}/cukai`.

   ![Sampler path /api/kenderaan/${no_pendaftaran}/cukai](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab3-03-path-no-pendaftaran.png)
   *Path sampler: `/api/kenderaan/${no_pendaftaran}/cukai` (nama sampler pun guna `${no_pendaftaran}` supaya label berubah ikut baris CSV).*

4. Tukar Thread Group kepada **10 / 5 / 10** (threads / ramp-up / loop) dan enable balik View Results Tree. Run (10 users × 10 loop). Dalam View Results Tree, pastikan
   setiap request guna nombor pendaftaran yang berlainan.

   ![Thread Group 10 threads, ramp-up 5, loop 10; View Results Tree enabled](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab3-04-thread-group-10-5-10.png)
   *Thread Group `10` / `5` / `10`; View Results Tree dah di-enable semula.*

![View Results Tree: setiap sample guna nombor pendaftaran berlainan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab3-02-vrt-nombor-berlainan.png)
*View Results Tree: label sample bertukar ikut baris CSV (`WXY1234`, `VAB88`, `JQK77`, `BMT30…`, `PKL90…`); tab **Request** tunjuk `${no_pendaftaran}` dah diganti — `…/api/kenderaan/VAB88/cukai`.*

> Bandingkan dengan `test-plans/03-csv-berparameter.jmx`.

### ✅ Checkpoint
- [ ] CSV Data Set Config membaca `../data/kenderaan.csv` dengan pembolehubah `no_pendaftaran,model`
- [ ] Path sampler menggunakan `${no_pendaftaran}`
- [ ] View Results Tree menunjukkan nombor pendaftaran berlainan bagi setiap permintaan
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| URL keluar `${no_pendaftaran}` bulat-bulat | CSV tak dibaca — path salah atau plan di-save dalam folder lain | Save `.jmx` dalam `hari-1/test-plans/`; check Log untuk "File … not found" |
| Satu request ke `/api/kenderaan/no_pendaftaran/cukai` → 404 | *Ignore first line* = False | Set **True** |
| Semua thread guna nombor yang sama | CSV diletak sebagai child sampler dengan scope pelik, atau *Sharing mode* bukan All threads + data cuma 1 baris | Letak CSV terus bawah Thread Group; check file ada 5 baris data |
| Variable `model` kosong | Ada space dalam *Variable Names* (`no_pendaftaran, model`) | Jangan letak space lepas koma |

### ⭐ Cabaran
Tambah sampler `GET /api/saman?no_kp=${no_kp}` guna **CSV kedua** dengan column `no_kp` (tiga user sintetik: `800101015500`, `900202025600`, `850303035700`). Save file baru dalam `hari-1/data/` dengan nama anda sendiri.

---

## Latihan 4 — Buat assertion GAGAL (belajar dari kegagalan)

**Sesi:** S3

### 🎯 Objektif
- Buktikan assertion boleh tangkap response yang salah dan naikkan Error % (O7)

### Prasyarat
- Latihan 3 dah siap (plan CSV running dengan 0% error)

### Langkah

1. Tambah satu baris palsu dalam `hari-1/data/kenderaan.csv`, contohnya: `ABC0000,Kereta Hantu`.

![kenderaan.csv dengan baris palsu ABC0000](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-01-csv-baris-palsu.png)
*Baris palsu `ABC0000,Kereta Hantu` ditambah di hujung CSV — tiada baris kosong sebelumnya, dan header kekal.*

2. Run semula Latihan 3. Tengok request `ABC0000` **fail**
   assertion (`amaun` tak ada — endpoint return **404**).

   ![View Results Tree: GET /api/kenderaan/ABC0000/cukai merah, 404 Not Found](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-06-vrt-abc0000-404.png)
   *Run sebenar plan Latihan 3 anda: sample `ABC0000` merah — `Response code:404`, `Response message:Not Found`; nombor lain hijau.*

   ![Assertion result: Test failed: text expected to contain /amaun/](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-07-vrt-assertion-default-message.png)
   *Nod **Response Assertion** bawah sample merah: `Assertion failure message:Test failed: text expected to contain /amaun/` (mesej default plan anda sendiri).*

3. Dalam View Results Tree, klik sample merah → tab **Sampler result** → baca *Assertion failure message*. Bandingkan response code (`404`) dengan body `{"ralat":"Kenderaan tidak dijumpai"}`.

![View Results Tree: sample ABC0000 merah dengan Response code 404](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-02-vrt-404.png)
*Sample `ABC0000` berwarna merah — tab **Sampler result** tunjuk `Response code:404` dan `Response message:Not Found`.*

![View Results Tree: Assertion result dengan Assertion failure message](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-03-vrt-assertion-gagal.png)
*Kembangkan sample merah dan klik nod Response Assertion — **Assertion failure message** papar mesej custom `Kenderaan ABC0000 tidak memulangkan sebut harga (mungkin 404)` (diset dalam *Custom failure message* plan rujukan `03-csv-berparameter.jmx`; plan anda sendiri akan papar mesej default `Test failed: text expected to contain /amaun/`).*

4. Tengok **Error %** naik dalam Summary Report. **Ramal dulu:** dengan 6 baris data dan Recycle = True, lebih kurang berapa peratus sample akan fail?

   ![Summary Report: ABC0000 100% error, TOTAL 16.00%](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-08-summary-report-error-16.png)
   *Summary Report run yang sama: `GET /api/kenderaan/ABC0000/cukai` **100.00%** error (16 sample), TOTAL **16.00%** daripada 100 — ≈ 1/6.*

5. Buang baris palsu tu lepas siap.

   ![kenderaan.csv sebelum dan selepas buang ABC0000](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-05-buang-baris-palsu.png)
   *Sebelum: baris terakhir `ABC0000,Kereta Hantu`. Selepas buang: berakhir dengan `PKL909` dan `grep -c ABC0000` = `0`.*

![Summary Report: baris ABC0000 100% error, TOTAL 16% Error](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-04-summary-error.png)
*Jawapan langkah 4: hanya baris `ABC0000` gagal (100%), jadi Error % TOTAL ≈ 1/6 — di sini 16.00% (16 daripada 100 sample).*

### ✅ Checkpoint
- [ ] Permintaan `ABC0000` gagal assertion (endpoint pulangkan **404**)
- [ ] Error % dalam Summary Report meningkat
- [ ] Baris palsu dibuang dari `kenderaan.csv` selepas selesai
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| Baris palsu tak pernah digunakan | File tak di-save, atau ada baris kosong sebelum baris palsu | Save file; pastikan tak ada baris kosong |
| Error % = 100% | Baris palsu tertambah pada baris header / format rosak | Buka CSV dalam text editor (bukan Excel) dan check |
| Lupa buang baris palsu → latihan seterusnya fail | — | `git checkout hari-1/data/kenderaan.csv` atau padam baris tu secara manual |

### ⭐ Cabaran
Jangan ubah file asal — copy ke `kenderaan-rosak.csv` dan tukar Filename dalam CSV Data Set Config. Lepas tu tambah Response Assertion kedua dengan **Field to Test = Response Code**, pattern `200` — dua assertion, mesej fail yang berbeza.

---

## Latihan 5 — Kesan latensi terhadap prestasi

**Sesi:** S3

### 🎯 Objektif
- Tengok hubungan antara latency server, throughput dan percentile (O6)

### Prasyarat
- Latihan 2 dah siap dan nilai Throughput / Average dah dicatat

### Langkah

1. Stop server (Ctrl+C). Start semula dengan latency tinggi:
   ```bash
   LATENCY_MIN=300 LATENCY_MAX=900 node server.js
   ```
   Windows PowerShell: `$env:LATENCY_MIN=300; $env:LATENCY_MAX=900; node server.js`

![Terminal: SUT dengan LATENCY_MIN=300 LATENCY_MAX=900](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab5-01-sut-latensi-tinggi.png)
*SUT dimulakan dengan `LATENCY_MIN=300 LATENCY_MAX=900` — banner tunjuk **Latensi tiruan : 300-900 ms**. (Tangkapan guna port berasingan 3038.)*

2. **Clear All**, kemudian run semula Latihan 2. Bandingkan **Average**, **95% Line** dan **Throughput** dengan run asal.

![Aggregate Report: SUT biasa (40–180 ms)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab5-02-aggregate-normal.png)
*Run Latihan 2 dengan SUT biasa (40–180 ms): Average **107 ms**, 95% Line **169 ms**, Throughput **8.9/sec**.*

![Aggregate Report: SUT latensi tinggi (300–900 ms)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab5-03-aggregate-latensi-tinggi.png)
*Plan yang sama dengan SUT latency tinggi (300–900 ms): Average **588 ms**, 95% Line **847 ms**, Throughput turun ke **7.2/sec** — thread sama, tapi setiap thread tunggu lebih lama.*

3. Isi jadual:

   | Run | Average (ms) | 95% Line (ms) | Throughput (/s) | Error % |
   |--------|--------------|---------------|-----------------|---------|
   | Latihan 2 (40–180 ms) | | | | |
   | Latihan 5 (300–900 ms) | | | | |

4. Restore SUT: Ctrl+C → `node server.js` (tanpa variable).

   ![Terminal: SUT dimulakan semula tanpa variable latency](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-04-restart-sut.png)
   *Lepas restore: banner tunjuk **Latensi tiruan : 40-180 ms** semula. (Tangkapan ini guna `PORT=3917`; anda run `node server.js` sahaja.)*

> **Soalan refleksi:** Kenapa throughput jatuh bila latency naik, walaupun bilangan users sama? (Hint: setiap thread kena tunggu lebih lama sebelum boleh hantar request seterusnya.)

### ✅ Checkpoint
- [ ] Pelayan dimulakan semula dengan `LATENCY_MIN=300 LATENCY_MAX=900`
- [ ] Average dan Throughput dibandingkan dengan larian asal Latihan 2
- [ ] Boleh menerangkan mengapa throughput jatuh apabila latensi naik
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| Nombor sama macam sebelum ni | Variable tak sampai ke Node (Windows cmd) | `set LATENCY_MIN=300` dan `set LATENCY_MAX=900` dalam cmd, atau guna syntax PowerShell di atas |
| Error % naik mendadak | Duration Assertion 2000 ms masih OK — tapi kalau anda dah turunkan dalam Cabaran Latihan 2, sekarang ia fail | Set balik ke 2000 ms, atau guna ni sebagai demo SLA |
| Latihan seterusnya rasa lambat | SUT masih dalam mode latency tinggi | Restart SUT tanpa variable |

### ⭐ Cabaran
Naikkan threads ke 60 (latency tinggi kekal). Throughput naik balik tak? Apa yang ni ajar tentang hubungan concurrency, response time dan throughput (Little's Law: concurrency ≈ throughput × response time)?

---

## Latihan 6 — Rakam Test Plan & lihat ia gagal main balik

**Sesi:** S4

### 🎯 Objektif
- Record flow guna HTTP(S) Test Script Recorder ke dalam Recording Controller (O9)
- Buktikan replay fail (401) dan namakan nilai yang perlu di-correlate (O9)

### Prasyarat
- SUT running (`node sut/server.js`)
- README §4.1–4.6; panduan penuh: [`rakaman-e2e.md`](./rakaman-e2e.md)

### Langkah

1. **Klik kanan Test Plan → Add → Non-Test Elements → HTTP(S) Test Script Recorder.**
   Tambah **Thread Group** (klik kanan Test Plan → Add → Threads (Users) → Thread Group), kemudian **Recording Controller** bawah Thread Group (klik kanan Thread Group → Add → Logic Controller → Recording Controller) dan set sebagai **Target Controller** untuk recorder.
   *(Atau terus buka `test-plans/rakam-template.jmx` — semua dah siap setup.)*

![HTTP(S) Test Script Recorder dalam rakam-template.jmx](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-01-recorder-port-8888.png)
*`rakam-template.jmx`: HTTP(S) Test Script Recorder dengan **Port 8888** dan **Target Controller = Use Recording Controller**; Recording Controller di bawah Thread Group.*

2. Pada recorder: tab **Requests Filtering → URL Patterns to Exclude → Add** → tambah regex static asset
   `(?i).*\.(bmp|css|js|gif|ico|jpe?g|png|swf|eot|otf|ttf|mp4|woff|woff2)([?;].*)?`.

   ![Recorder Requests Filtering: regex static asset dalam URL Patterns to Exclude](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-05-requests-filtering-exclude.png)
   *Tab **Requests Filtering → URL Patterns to Exclude**: regex static asset `(?i).*\.(bmp|css|js|…)…` (dah ada dalam `rakam-template.jmx`).*

3. Klik **Start**. Hantar request melalui proxy JMeter (port 8888):
   ```bash
   curl -s -x http://localhost:8888 -H 'Content-Type: application/json' \
     -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}' \
     http://localhost:3000/api/log-masuk
   curl -s -x http://localhost:8888 -H 'Authorization: Bearer TOKEN_PALSU' \
     'http://localhost:3000/api/kenderaan?no_kp=800101015500'
   ```

   ![Dua curl melalui proxy: log-masuk 200 dan kenderaan TOKEN_PALSU](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-06-curl-melalui-proxy.png)
   *Dua request melalui proxy: log masuk pulangkan token; `/api/kenderaan` dengan `TOKEN_PALSU` → `Token tidak sah atau tamat tempoh`. (tangkapan ini guna proxy 18888 dan instance mock kami sendiri pada port 3917 supaya tak ganggu kelas — anda guna 8888 / 3000)*

4. Klik **Stop**. Tengok sampler yang dah di-record dalam Recording Controller. Buka sampler `/api/kenderaan` → child **HTTP Header Manager** → perasan `Authorization: Bearer TOKEN_PALSU` di-hardcode.

   ![Recording Controller: Header Manager /api/kenderaan dengan Authorization Bearer TOKEN_PALSU](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-07-header-manager-token-palsu.png)
   *Lepas **Stop**: `/api/log-masuk-1` dan `/api/kenderaan-2` dalam Recording Controller; Header Manager `/api/kenderaan-2` ada `Authorization: Bearer TOKEN_PALSU` — hardcode.*

![Portal web: Log Masuk, Kenderaan Saya, Bayar Cukai Jalan, Pembayaran Berjaya](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-02-portal-aliran.png)
*Flow portal web yang dirakam melalui browser (Cabaran / [`rakaman-e2e.md`](./rakaman-e2e.md)): **Log Masuk** → **Kenderaan Saya** → **Bayar Cukai Jalan** (form ada field tersembunyi `csrf`) → **Pembayaran Berjaya** (Status: BERJAYA).*

![Sampler yang dirakam di bawah Recording Controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-03-recording-controller.png)
*Hasil rakaman flow portal di atas: setiap request jadi sampler bawah **Recording Controller**, masing-masing dengan **HTTP Header Manager**. Perasan `/portal/favicon.svg` turut dirakam (`svg` tiada dalam regex Excludes) dan `/time/1/current` ialah request latar belakang Chrome — buang sampler yang bukan flow anda. (Rakaman ini guna port proxy 8898.)*

5. Tambah **View Results Tree** bawah Thread Group (kalau guna `rakam-template.jmx`, ia dah ada bawah Test Plan — guna yang tu). **Replay** (Run). Tengok request kenderaan → **401** sebab token yang di-record
   dah expired / palsu.

   ![Replay: /api/kenderaan-2 merah 401 Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-08-replay-kenderaan-401.png)
   *Replay rakaman: `/api/log-masuk-1` hijau, `/api/kenderaan-2` merah — `Response code:401`, `Unauthorized`.*

6. Buktikan guna plan rujukan dalam mode non-GUI, dan generate report HTML:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx \
     -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
   Buka `/tmp/laporan-rakaman/index.html` — Error % sepatutnya **~67%** (200 / 401 / 401).

![Laporan HTML: Error 66.67%, 401/Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-04-laporan-replay-401.png)
*Langkah 6: laporan HTML untuk `04-rakaman-mentah.jmx` — `/api/log-masuk` lulus, tapi `/api/kenderaan` dan `…/bayar-cukai` fail **401/Unauthorized**; Error % TOTAL **66.67%**.*

> **Soalan analisis:** Nilai mana yang **berubah setiap session** dan perlu **di-correlate**
> (bukan di-hardcode)? Bandingkan dengan rujukan siap
> [`test-plans/04-rakaman-mentah.jmx`](../test-plans/04-rakaman-mentah.jmx) — cara fix-nya
> ada dalam Hari 2 (correlation `token` + `csrf`).
>
> **Panduan end-to-end step by step:** [`rakaman-e2e.md`](./rakaman-e2e.md).

### ✅ Checkpoint
- [ ] HTTP(S) Test Script Recorder dan Recording Controller (Target Controller) disediakan, dengan regex aset statik dalam Excludes
- [ ] Sampler `/api/log-masuk` dan `/api/kenderaan` dirakam dalam Recording Controller
- [ ] Main balik menunjukkan **401** kerana token dirakam sudah luput / palsu
- [ ] Boleh menerangkan nilai yang berubah setiap sesi dan perlu dikorelasi (`token`, `csrf`)
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Simptom | Punca | Cara fix |
|--------|-------|--------------|
| Tak ada sampler di-record | Recorder belum **Start**, atau traffic tak lalu `:8888` | `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (macOS/Linux) / `netstat -ano \| findstr :8888` (Windows); pastikan guna `curl -x http://localhost:8888` |
| Firefox: tak ada apa di-record dari localhost | `localhost, 127.0.0.1` ada dalam **No proxy for**, atau Firefox 67+ bypass proxy untuk localhost | Kosongkan kotak tu **dan** `about:config` → `network.proxy.allow_hijacking_localhost` = `true`; proxy guna `127.0.0.1` port `8888` (Windows: benarkan Java dalam Defender Firewall) |
| `Address already in use` bila Start | Port 8888 dah dipakai aplikasi lain / recorder kedua | Tutup plan lain yang ada recorder; atau tukar port (dan command `curl -x`) |
| `curl` dalam Windows cmd: `{"ralat":…}` / JSON rosak | cmd.exe tak faham single quote | Guna Git Bash, atau: `curl -s -x http://localhost:8888 -H "Content-Type: application/json" -d "{\"no_kp\":\"800101015500\",\"kata_laluan\":\"rahsia123\"}" http://localhost:3000/api/log-masuk` |
| Sampler di-record bawah Test Plan, bukan Recording Controller | Target Controller tak di-set | Pilih **Test Plan > Thread Group > Recording Controller** |
| `-e -o` fail: *"folder … not empty"* | Folder report dah wujud | Padam folder tu atau guna nama baru |
| Browsing biasa dalam Firefox tak jalan lepas latihan | Proxy masih point ke JMeter yang dah stop | Network Settings → **Use system proxy settings** |

### ⭐ Cabaran
Ikut [`rakaman-e2e.md`](./rakaman-e2e.md) sepenuhnya: record flow **3 langkah** (log masuk → senarai kenderaan → bayar cukai) dengan `TOKEN` dan `CSRF` yang **sebenar**, restart SUT, kemudian replay. Kenapa kali ni bayar-cukai pun fail, walaupun token tu "sebenar" masa di-record? Untuk HTTPS (laman yang anda **dibenarkan** sahaja), ikut [`rakaman-https-setup.md`](./rakaman-https-setup.md) — termasuk import `ApacheJMeterTemporaryRootCA.crt` dan **buang** certificate tu lepas siap.

---

## Latihan 7 (Cabaran) — Dua sampler, skop yang betul

**Sesi:** S3

### 🎯 Objektif
- Susun element ikut scope dan terangkan kesan kedudukan setiap element (O5)

### Prasyarat
- Latihan 1–3 dah siap

### Langkah

1. Bina **satu Test Plan** dengan **dua sampler** (`/api/health` dan `/api/saman?no_kp=900202025600`) bawah Thread Group yang sama.

   ![Dua sampler: GET /api/health dan GET /api/saman dengan parameter no_kp](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-03-dua-sampler-saman.png)
   *Dua sampler bawah Thread Group yang sama; `GET /api/saman` dengan parameter `no_kp` = `900202025600`.*

2. Bagi setiap sampler **Response Assertion sendiri** (sebagai child): `ok` untuk health, `saman` untuk saman.

   ![Response Assertion saman sebagai child sampler saman](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-04-assertion-saman.png)
   *Setiap sampler ada **Response Assertion** sendiri (child): `ok` untuk health, `saman` untuk saman (dipaparkan).*

3. Tambah **HTTP Request Defaults** dan **Constant Timer** 500 ms bawah Thread Group, dan **Summary Report**.

   ![HTTP Request Defaults, Constant Timer 500 ms dan Summary Report bawah Thread Group](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-05-defaults-timer-summary.png)
   *HTTP Request Defaults, **Constant Timer 500 ms** (dipaparkan) dan Summary Report bawah Thread Group — timer di sini kena pada kedua-dua sampler.*

4. **Ramal:** berapa jumlah jeda timer setiap iteration? Lepas tu pindahkan timer jadi child sampler saman sahaja, dan ramal semula.

![Constant Timer di bawah Thread Group: kena pada kedua-dua sampler](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-01-timer-bawah-thread-group.png)
*Constant Timer 500 ms **di bawah Thread Group** — scope merangkumi kedua-dua sampler, jadi 2 × 500 ms jeda setiap iteration. Setiap sampler ada assertion sendiri; Error % 0.00%, TOTAL Throughput 1.9/sec.*

![Constant Timer sebagai child sampler saman: kena pada satu sampler sahaja](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-02-timer-anak-sampler-saman.png)
*Timer dipindahkan jadi **child** sampler saman — hanya 1 × 500 ms setiap iteration, jadi TOTAL Throughput naik ke 2.8/sec.*

5. Susun element dengan betul (Config → Sampler → Assertion → Listener) dan terangkan **scope** setiap element kepada rakan sebelah.

### ✅ Checkpoint
- [ ] Dua sampler, setiap satu dengan Response Assertion sendiri, lulus 0% ralat
- [ ] Boleh menerangkan perbezaan timer di bawah Thread Group (2 × 500 ms) vs anak satu sampler (1 × 500 ms)
- [ ] Skop setiap elemen diterangkan kepada rakan

---

## Semakan kendiri

- [ ] Saya boleh menamakan lima jenis ujian prestasi dan menyatakan syarat etika sebelum menjana beban
- [ ] Saya boleh menjalankan `jmeter -v` dari mana-mana folder dan memulakan SUT tiruan
- [ ] Saya boleh membina Test Plan dengan Thread Group, HTTP Request Defaults, sampler dan listener
- [ ] Saya boleh menambah Response Assertion, Duration Assertion dan Timer
- [ ] Saya boleh memparameter permintaan dengan CSV Data Set Config
- [ ] Saya boleh membaca Throughput, Average, Error % dan percentile dalam Summary / Aggregate Report
- [ ] Saya boleh merakam Test Plan dengan HTTP(S) Test Script Recorder
- [ ] Saya boleh menerangkan mengapa rakaman mentah gagal dimain balik (401) dan apa itu korelasi
- [ ] Isi penilaian kendiri Hari 1 (Kuiz hari)
