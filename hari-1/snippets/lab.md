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
2. Install JMeter (README §1.5). **Windows:** extract ke `C:\apache-jmeter-5.6.3`, tambah `C:\apache-jmeter-5.6.3\bin` dalam **User variables → Path**, kemudian **tutup & buka balik** terminal.
3. Test dari folder **lain** (bukan `bin`):
   ```bash
   cd ~            # Windows: cd %USERPROFILE%
   jmeter -v
   ```
4. Start SUT dalam terminal lain dan biarkan terbuka:
   ```bash
   cd sut
   node server.js
   ```
5. Dalam terminal kedua (atau browser):
   ```bash
   curl -s http://localhost:3000/api/health
   ```
   Expected: `{"status":"ok","masa":"…"}`. Buka `http://localhost:3000` dalam browser untuk tengok senarai endpoint.
6. Buka GUI: `jmeter` (atau `bin\jmeter.bat`). Kenal pasti **test tree** (kiri), **panel setting** (kanan), button **Start / Stop / Clear All**, dan ikon **Log** (segi tiga amaran, kanan atas).

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
2. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, server `localhost`, port `3000`.
3. **Klik kanan Thread Group → Add → Sampler → HTTP Request** → `GET /api/health` (biarkan Server/Port kosong).
4. Tambah sampler kedua `GET /` (page info).
5. **Klik kanan Thread Group → Add → Listener → View Results Tree**.
6. **File → Save** sebagai `lab1-saya.jmx`, kemudian run (▶). Pastikan response `{"status":"ok"}` dan code **200**.
7. Dalam View Results Tree, klik sample `/api/health` → tab **Request** — tengok URL penuh `http://localhost:3000/api/health` yang terbentuk daripada Defaults + Path.

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
2. Sampler: `GET /api/kenderaan/WXY1234/cukai` (buang atau disable sampler lain).
3. Tambah **Response Assertion** (klik kanan sampler → Add → Assertions) — Field to Test *Text Response*, *Substring*, pattern `amaun`.
4. Tambah **Duration Assertion** — 2000 ms.
5. Tambah **Constant Timer** 300 ms (think time) bawah Thread Group.
6. Tambah **Summary Report** dan **Aggregate Report**. **Disable** View Results Tree (klik kanan → **Disable**) — listener ni berat masa load test.
7. **Ramal** jumlah request, kemudian **Clear All** dan run. Catat: **Throughput**, **Average**, **Error %**, **95% Line**.

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
2. Tambah **CSV Data Set Config** (Thread Group → Add → Config Element) yang baca `../data/kenderaan.csv`
   (variable names: `no_pendaftaran,model`; ignore first line: **True**; recycle: **True**; stop thread: **False**; sharing mode: **All threads**).
3. Tukar path sampler kepada `/api/kenderaan/${no_pendaftaran}/cukai`.
4. Enable balik View Results Tree. Run (10 users × 10 loop). Dalam View Results Tree, pastikan
   setiap request guna nombor pendaftaran yang berlainan.

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
2. Run semula Latihan 3. Tengok request `ABC0000` **fail**
   assertion (`amaun` tak ada — endpoint return **404**).
3. Dalam View Results Tree, klik sample merah → tab **Sampler result** → baca *Assertion failure message*. Bandingkan response code (`404`) dengan body `{"ralat":"Kenderaan tidak dijumpai"}`.
4. Tengok **Error %** naik dalam Summary Report. **Ramal dulu:** dengan 6 baris data dan Recycle = True, lebih kurang berapa peratus sample akan fail?
5. Buang baris palsu tu lepas siap.

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
2. **Clear All**, kemudian run semula Latihan 2. Bandingkan **Average**, **95% Line** dan **Throughput** dengan run asal.
3. Isi jadual:

   | Run | Average (ms) | 95% Line (ms) | Throughput (/s) | Error % |
   |--------|--------------|---------------|-----------------|---------|
   | Latihan 2 (40–180 ms) | | | | |
   | Latihan 5 (300–900 ms) | | | | |

4. Restore SUT: Ctrl+C → `node server.js` (tanpa variable).

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
   Tambah **Recording Controller** bawah Thread Group dan set sebagai **Target Controller** untuk recorder.
   *(Atau terus buka `test-plans/rakam-template.jmx` — semua dah siap setup.)*
2. Pada recorder: **Requests Filtering → Excludes** → tambah regex static asset
   `(?i).*\.(bmp|css|js|gif|ico|jpe?g|png|swf|eot|otf|ttf|mp4|woff|woff2)([?;].*)?`.
3. Klik **Start**. Hantar request melalui proxy JMeter (port 8888):
   ```bash
   curl -s -x http://localhost:8888 -H 'Content-Type: application/json' \
     -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}' \
     http://localhost:3000/api/log-masuk
   curl -s -x http://localhost:8888 -H 'Authorization: Bearer TOKEN_PALSU' \
     'http://localhost:3000/api/kenderaan?no_kp=800101015500'
   ```
4. Klik **Stop**. Tengok sampler yang dah di-record dalam Recording Controller. Buka sampler `/api/kenderaan` → child **HTTP Header Manager** → perasan `Authorization: Bearer TOKEN_PALSU` di-hardcode.
5. Tambah **View Results Tree** bawah Thread Group. **Replay** (Run). Tengok request kenderaan → **401** sebab token yang di-record
   dah expired / palsu.
6. Buktikan guna plan rujukan dalam mode non-GUI, dan generate report HTML:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx \
     -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
   Buka `/tmp/laporan-rakaman/index.html` — Error % sepatutnya **~67%** (200 / 401 / 401).

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
| Firefox: tak ada apa di-record dari localhost | `localhost, 127.0.0.1` ada dalam **No proxy for** | Kosongkan kotak tu |
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
2. Bagi setiap sampler **Response Assertion sendiri** (sebagai child): `ok` untuk health, `saman` untuk saman.
3. Tambah **HTTP Request Defaults** dan **Constant Timer** 500 ms bawah Thread Group, dan **Summary Report**.
4. **Ramal:** berapa jumlah jeda timer setiap iteration? Lepas tu pindahkan timer jadi child sampler saman sahaja, dan ramal semula.
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
