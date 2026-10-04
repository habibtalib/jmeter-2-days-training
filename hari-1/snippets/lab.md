# Lab Hari 1 — Asas JMeter & Ujian Beban

[⬅️ README Hari 1](../README.md) · [🎤 Nota Penceramah](../nota-penceramah.md) · [🎬 Rakam → Main Balik](./rakaman-e2e.md) · [🔒 Rakaman HTTPS](./rakaman-https-setup.md) · [🔑 Test plan rujukan](../test-plans/)

> **Peraturan lab:** Sebelum setiap larian, **ramal** dahulu — berapa sampel? Error % berapa? Throughput naik atau turun? Tulis ramalan, kemudian klik **Start**. Fail rujukan (jawapan) ada dalam `hari-1/test-plans/`. Cuba bina sendiri dahulu; buka fail rujukan hanya selepas checkpoint atau jika tersekat lebih 10 minit.

> ⚠️ **Etika:** Semua latihan mensasarkan **`http://localhost:3000`** sahaja — sentiasa sahkan Server=`localhost`, Port=`3000` sebelum Start.

> 📊 **Bukti kemajuan:** JMeter berjalan pada mesin anda, jadi LMS tidak dapat melihat larian anda. Tandakan setiap ✅ Checkpoint dengan jujur, dan item terakhir setiap checkpoint ialah **kuiz sesi** dalam README — itulah bukti yang dinilai.

Pastikan **pelayan tiruan berjalan** dahulu (biarkan terminal ini terbuka sepanjang hari):

```bash
cd sut && node server.js      # biarkan terbuka
```

| Latihan | Sesi | Fokus | Fail rujukan |
|---------|------|-------|--------------|
| 0 | S1 | Persediaan: Java, JMeter (PATH), SUT | — |
| 1 | S2 | Test Plan pertama | `01-hello-jpj.jmx` |
| 2 | S3 | Ujian beban + assertion + timer | `02-cukai-beban.jmx` |
| 3 | S3 | Parameterisasi CSV | `03-csv-berparameter.jmx` |
| 4 | S3 | Buat assertion GAGAL | `03-csv-berparameter.jmx` + baris palsu |
| 5 | S3 | Kesan latensi pelayan | `02-cukai-beban.jmx` |
| 6 | S4 | Rakam & lihat main balik gagal | `rakam-template.jmx`, `04-rakaman-mentah.jmx` |
| 7 ⭐ | S3 | Cabaran: dua sampler, skop yang betul | — |

---

## Latihan 0 — Persediaan: Java, JMeter & SUT

**Sesi:** S1

### 🎯 Objektif
- Memasang Java + JMeter dan menjalankan `jmeter` dari mana-mana folder (O2)
- Menjalankan SUT tiruan dan mengesahkan endpoint kesihatan (O2)
- Menyatakan sasaran sah kursus dan syarat etika (O1)

### Prasyarat
- Node.js 18+ (`node --version`)
- Pemasang JDK 17/21 dan zip JMeter 5.6.x (dari internet, atau USB daripada penceramah)
- README §1.3–1.8 telah diterangkan

### Langkah

1. Sahkan Java:
   ```bash
   java --version        # 11 atau lebih baru (disyorkan 17/21)
   ```
2. Pasang JMeter (README §1.5). **Windows:** nyahzip ke `C:\apache-jmeter-5.6.3`, tambah `C:\apache-jmeter-5.6.3\bin` ke **User variables → Path**, kemudian **tutup & buka semula** terminal.
3. Sahkan dari folder **lain** (bukan `bin`):
   ```bash
   cd ~            # Windows: cd %USERPROFILE%
   jmeter -v
   ```
4. Mulakan SUT dalam terminal berasingan dan biarkan terbuka:
   ```bash
   cd sut
   node server.js
   ```
5. Dalam terminal kedua (atau pelayar):
   ```bash
   curl -s http://localhost:3000/api/health
   ```
   Jangkaan: `{"status":"ok","masa":"…"}`. Buka `http://localhost:3000` dalam pelayar untuk senarai endpoint.
6. Buka GUI: `jmeter` (atau `bin\jmeter.bat`). Kenal pasti **pokok ujian** (kiri), **panel konfigurasi** (kanan), butang **Start / Stop / Clear All**, dan ikon **Log** (segi tiga amaran, kanan atas).

### ✅ Checkpoint
- [ ] `java --version` memaparkan versi 11 atau lebih baru
- [ ] `jmeter -v` berjalan dari folder selain `bin` dan memaparkan versi 5.6.x
- [ ] SUT berjalan dan `http://localhost:3000/api/health` memulangkan `{"status":"ok",…}`
- [ ] GUI JMeter dibuka tanpa ralat
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `'jmeter' is not recognized…` (Windows) | `bin` tiada dalam PATH, atau terminal lama | Tambah ke **User variables → Path**; **buka terminal baharu** |
| `jmeter` mengadu Java tidak dijumpai | Tiada JDK / `JAVA_HOME` salah | Pasang JDK 11+; set `JAVA_HOME` ke folder JDK; tambah `%JAVA_HOME%\bin` ke PATH; `java -version` |
| `EADDRINUSE :::3000` semasa `node server.js` | SUT lain sudah berjalan di port 3000 | Guna tetingkap SUT yang sedia ada, atau hentikan (Ctrl+C); `PORT=3001 node server.js` hanya jika perlu (dan ubah Defaults) |
| GUI JMeter sangat perlahan / fon kecil | Skrin resolusi tinggi / memori rendah | **Options → Zoom In**; tutup aplikasi lain |
| `curl` tiada (Windows lama) | — | Buka `http://localhost:3000/api/health` dalam pelayar |

### ⭐ Cabaran
Mulakan SUT dengan `ERROR_RATE=0.2 node server.js` dan baca `sut/server.js` — endpoint mana yang terkesan oleh `ERROR_RATE`? (Jawapan: hanya `POST …/bayar-cukai`.) Pulihkan dengan `node server.js` biasa.

---

## Latihan 1 — Test Plan pertama anda

**Sesi:** S2

### 🎯 Objektif
- Membina Test Plan dengan Thread Group, HTTP Request Defaults, HTTP Request dan View Results Tree (O3)
- Membaca tab Sampler result / Request / Response data dalam View Results Tree

### Prasyarat
- Latihan 0 selesai; SUT berjalan
- README §2.1–2.2

### Langkah

1. Buka JMeter (GUI). **Klik kanan Test Plan → Add → Threads (Users) → Thread Group** — 1 pengguna, ramp-up 1, 1 gelung.
2. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, server `localhost`, port `3000`.
3. **Klik kanan Thread Group → Add → Sampler → HTTP Request** → `GET /api/health` (biarkan Server/Port kosong).
4. Tambah sampler kedua `GET /` (halaman info).
5. **Klik kanan Thread Group → Add → Listener → View Results Tree**.
6. **File → Save** sebagai `lab1-saya.jmx`, kemudian jalankan (▶). Sahkan respons `{"status":"ok"}` dan kod **200**.
7. Dalam View Results Tree, klik sampel `/api/health` → tab **Request** — lihat URL penuh `http://localhost:3000/api/health` yang dibina daripada Defaults + Path.

> Bandingkan dengan `test-plans/01-hello-jpj.jmx`.

### ✅ Checkpoint
- [ ] Test Plan berjalan dan View Results Tree menunjukkan kod **200** dengan respons `{"status":"ok"}`
- [ ] Struktur plan sepadan dengan `test-plans/01-hello-jpj.jmx` (Thread Group → HTTP Request Defaults → HTTP Request → Listener)
- [ ] Tab **Request** menunjukkan URL penuh yang diwarisi daripada HTTP Request Defaults
- [ ] Lulus **Kuiz S2** (sekurang-kurangnya separuh betul) (Kuiz S2)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `Non HTTP response code: java.net.ConnectException` | SUT tidak berjalan / port salah | Mulakan `node server.js`; semak Port `3000` dalam Defaults |
| `UnknownHostException` | Server Name ada `http://` atau ruang | Server Name = `localhost` sahaja (protokol di medan berasingan) |
| View Results Tree kosong | Listener di luar skop (cth. di bawah Thread Group lain) atau plan tak dijalankan | Letak listener di bawah Thread Group yang sama; semak ikon Log |
| Butang Start kelabu | Plan sedang berjalan | Tunggu, atau klik **Stop** |

### ⭐ Cabaran
Tambah **HTTP Header Manager** dengan `Accept: application/json` dan sahkan header itu kelihatan dalam tab **Request → Request Headers**.

---

## Latihan 2 — Ujian beban + assertion + timer

**Sesi:** S3

### 🎯 Objektif
- Menetapkan model beban 20 / 10 / 5 dan meramal bilangan sampel (O4)
- Menambah Response Assertion, Duration Assertion dan Constant Timer (O7)
- Membaca Throughput, Average, Error % dan 95% Line (O6)

### Prasyarat
- Latihan 1 selesai
- README §2.3–2.5 dan §3.1–3.2

### Langkah

1. Tukar Thread Group kepada **20 pengguna**, **ramp-up 10s**, **5 gelung**.
2. Sampler: `GET /api/kenderaan/WXY1234/cukai` (buang/nyahaktif sampler lain).
3. Tambah **Response Assertion** (klik kanan sampler → Add → Assertions) — Field to Test *Text Response*, *Substring*, pattern `amaun`.
4. Tambah **Duration Assertion** — 2000 ms.
5. Tambah **Constant Timer** 300 ms (think time) di bawah Thread Group.
6. Tambah **Summary Report** dan **Aggregate Report**. **Nyahaktif** View Results Tree (klik kanan → **Disable**) — listener berat semasa beban.
7. **Ramal** jumlah permintaan, kemudian **Clear All** dan jalankan. Catat: **Throughput**, **Average**, **Error %**, **95% Line**.

> **Soalan:** Berapa jumlah permintaan dijangka? (20 × 5 = 100). Sahkan.
> Bandingkan dengan `test-plans/02-cukai-beban.jmx`.

### ✅ Checkpoint
- [ ] Thread Group ditetapkan 20 pengguna, ramp-up 10s, 5 gelung
- [ ] Response Assertion (`amaun`) dan Duration Assertion (2000 ms) ditambah, serta Constant Timer 300 ms
- [ ] Summary Report menunjukkan **100** permintaan dengan Error % 0%
- [ ] Nilai **Throughput**, **Average** dan **Error %** dicatat
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| `# Samples` = 200 atau 300, bukan 100 | Sampler lama (`/api/health`, `/`) masih aktif | Disable/buang sampler lain |
| Angka berganda / bercampur | Keputusan larian lama tidak dikosongkan | **Clear All** sebelum setiap larian |
| Semua sampel gagal assertion | Pattern salah eja / Field to Test salah | *Text Response* + *Substring* + `amaun` (huruf kecil) |
| Throughput jauh lebih rendah dari jangkaan | Timer menyebabkan jeda (betul!) atau ramp-up masih berjalan | Bandingkan dengan larian tanpa timer — itulah pelajaran |
| JMeter beku semasa larian | View Results Tree aktif dengan banyak sampel | Disable View Results Tree semasa beban |

### ⭐ Cabaran
Gantikan Constant Timer dengan **Gaussian Random Timer** (Deviation 300, Constant Delay Offset 1000). Jalankan semula — bandingkan Throughput. Kemudian kurangkan Duration Assertion kepada `100` ms dan perhatikan Error % — inilah cara SLA "menggigit".

---

## Latihan 3 — Parameterisasi dengan CSV

**Sesi:** S3

### 🎯 Objektif
- Menyuap nombor pendaftaran berlainan melalui CSV Data Set Config dan `${no_pendaftaran}` (O8)

### Prasyarat
- Latihan 2 selesai
- README §3.3; fail `hari-1/data/kenderaan.csv` wujud

### Langkah

1. Simpan plan anda **dalam folder `hari-1/test-plans/`** (supaya laluan relatif `../data/` betul).
2. Tambah **CSV Data Set Config** (Thread Group → Add → Config Element) membaca `../data/kenderaan.csv`
   (variable names: `no_pendaftaran,model`; ignore first line: **True**; recycle: **True**; stop thread: **False**; sharing mode: **All threads**).
3. Ubah path sampler kepada `/api/kenderaan/${no_pendaftaran}/cukai`.
4. Dayakan semula View Results Tree. Jalankan (10 pengguna × 10 gelung). Dalam View Results Tree, sahkan
   setiap permintaan guna nombor pendaftaran berlainan.

> Bandingkan dengan `test-plans/03-csv-berparameter.jmx`.

### ✅ Checkpoint
- [ ] CSV Data Set Config membaca `../data/kenderaan.csv` dengan pembolehubah `no_pendaftaran,model`
- [ ] Path sampler menggunakan `${no_pendaftaran}`
- [ ] View Results Tree menunjukkan nombor pendaftaran berlainan bagi setiap permintaan
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| URL mengandungi `${no_pendaftaran}` secara literal | CSV tidak dibaca — laluan salah atau plan disimpan di folder lain | Simpan `.jmx` dalam `hari-1/test-plans/`; semak Log untuk "File … not found" |
| Satu permintaan ke `/api/kenderaan/no_pendaftaran/cukai` → 404 | *Ignore first line* = False | Tetapkan **True** |
| Semua thread guna nombor sama | CSV diletak sebagai anak sampler dalam skop pelik, atau *Sharing mode* bukan All threads + data 1 baris | Letak CSV terus di bawah Thread Group; semak fail ada 5 baris data |
| Pembolehubah `model` kosong | Ruang dalam *Variable Names* (`no_pendaftaran, model`) | Tiada ruang selepas koma |

### ⭐ Cabaran
Tambah sampler `GET /api/saman?no_kp=${no_kp}` menggunakan **CSV kedua** dengan lajur `no_kp` (tiga pengguna sintetik: `800101015500`, `900202025600`, `850303035700`). Simpan fail baharu dalam `hari-1/data/` dengan nama anda sendiri.

---

## Latihan 4 — Buat assertion GAGAL (belajar dari kegagalan)

**Sesi:** S3

### 🎯 Objektif
- Membuktikan assertion menangkap respons salah dan menaikkan Error % (O7)

### Prasyarat
- Latihan 3 selesai (plan berparameter CSV berjalan dengan 0% ralat)

### Langkah

1. Tambah satu baris palsu pada `hari-1/data/kenderaan.csv`, cth: `ABC0000,Kereta Hantu`.
2. Jalankan semula Latihan 3. Perhatikan permintaan `ABC0000` **gagal**
   assertion (`amaun` tiada — endpoint pulangkan **404**).
3. Dalam View Results Tree, klik sampel merah → tab **Sampler result** → baca *Assertion failure message*. Bandingkan kod respons (`404`) dengan badan `{"ralat":"Kenderaan tidak dijumpai"}`.
4. Lihat **Error %** meningkat dalam Summary Report. **Ramal dahulu:** dengan 6 baris data dan Recycle = True, kira-kira berapa peratus sampel akan gagal?
5. Buang baris palsu selepas selesai.

### ✅ Checkpoint
- [ ] Permintaan `ABC0000` gagal assertion (endpoint pulangkan **404**)
- [ ] Error % dalam Summary Report meningkat
- [ ] Baris palsu dibuang dari `kenderaan.csv` selepas selesai
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Baris palsu tidak pernah digunakan | Fail tidak disimpan, atau baris kosong sebelum baris palsu | Simpan fail; pastikan tiada baris kosong |
| Error % = 100% | Baris palsu ditambah pada baris tajuk / format rosak | Buka CSV dalam editor teks (bukan Excel) dan semak |
| Lupa buang baris palsu → Latihan seterusnya gagal | — | `git checkout hari-1/data/kenderaan.csv` atau padam baris secara manual |

### ⭐ Cabaran
Daripada mengubah fail asal, salin ke `kenderaan-rosak.csv` dan tukar Filename CSV Data Set Config. Kemudian tambah Response Assertion kedua dengan **Field to Test = Response Code**, pattern `200` — dua assertion, mesej kegagalan berbeza.

---

## Latihan 5 — Kesan latensi terhadap prestasi

**Sesi:** S3

### 🎯 Objektif
- Memerhati hubungan latensi pelayan, throughput dan percentile (O6)

### Prasyarat
- Latihan 2 selesai dengan nilai Throughput / Average dicatat

### Langkah

1. Hentikan pelayan (Ctrl+C). Mulakan semula dengan latensi tinggi:
   ```bash
   LATENCY_MIN=300 LATENCY_MAX=900 node server.js
   ```
   Windows PowerShell: `$env:LATENCY_MIN=300; $env:LATENCY_MAX=900; node server.js`
2. **Clear All**, kemudian jalankan semula Latihan 2. Bandingkan **Average**, **95% Line** dan **Throughput** dengan larian asal.
3. Isi jadual:

   | Larian | Average (ms) | 95% Line (ms) | Throughput (/s) | Error % |
   |--------|--------------|---------------|-----------------|---------|
   | Latihan 2 (40–180 ms) | | | | |
   | Latihan 5 (300–900 ms) | | | | |

4. Pulihkan SUT: Ctrl+C → `node server.js` (tanpa pembolehubah).

> **Soalan reflektif:** Mengapa throughput jatuh apabila latensi naik walaupun bilangan pengguna sama? (Petunjuk: setiap thread menunggu lebih lama sebelum boleh menghantar permintaan seterusnya.)

### ✅ Checkpoint
- [ ] Pelayan dimulakan semula dengan `LATENCY_MIN=300 LATENCY_MAX=900`
- [ ] Average dan Throughput dibandingkan dengan larian asal Latihan 2
- [ ] Boleh menerangkan mengapa throughput jatuh apabila latensi naik
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Angka sama seperti sebelum | Pembolehubah tidak sampai ke Node (Windows cmd) | `set LATENCY_MIN=300` dan `set LATENCY_MAX=900` dalam cmd, atau sintaks PowerShell di atas |
| Error % naik mendadak | Duration Assertion 2000 ms masih OK — jika anda menurunkannya dalam Cabaran Latihan 2, ia kini gagal | Pulihkan kepada 2000 ms, atau gunakan ini sebagai demo SLA |
| Latihan seterusnya terasa lambat | SUT masih dalam mod latensi tinggi | Mulakan semula SUT tanpa pembolehubah |

### ⭐ Cabaran
Naikkan threads kepada 60 (latensi tinggi kekal). Adakah throughput pulih? Apa yang ini ajar tentang hubungan concurrency, masa respons dan throughput (Little's Law: concurrency ≈ throughput × masa respons)?

---

## Latihan 6 — Rakam Test Plan & lihat ia gagal main balik

**Sesi:** S4

### 🎯 Objektif
- Merakam aliran dengan HTTP(S) Test Script Recorder ke dalam Recording Controller (O9)
- Membuktikan main balik gagal (401) dan menamakan nilai yang perlu dikorelasi (O9)

### Prasyarat
- SUT berjalan (`node sut/server.js`)
- README §4.1–4.6; panduan penuh: [`rakaman-e2e.md`](./rakaman-e2e.md)

### Langkah

1. **Klik kanan Test Plan → Add → Non-Test Elements → HTTP(S) Test Script Recorder.**
   Tambah **Recording Controller** di bawah Thread Group dan set sebagai **Target Controller** perakam.
   *(Atau buka terus `test-plans/rakam-template.jmx` — semuanya sudah dipasang.)*
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
4. Klik **Stop**. Lihat sampler yang dirakam dalam Recording Controller. Buka sampler `/api/kenderaan` → **HTTP Header Manager** anaknya → perhatikan `Authorization: Bearer TOKEN_PALSU` dikeras-kod.
5. Tambah **View Results Tree** di bawah Thread Group. **Main balik** (Run). Perhatikan permintaan berkumpul → **401** kerana token dirakam
   sudah luput / palsu.
6. Buktikan dengan plan rujukan, non-GUI, dan jana laporan HTML:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx \
     -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
   Buka `/tmp/laporan-rakaman/index.html` — Error % sepatutnya **~67%** (200 / 401 / 401).

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
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Gejala | Punca | Penyelesaian |
|--------|-------|--------------|
| Tiada sampler dirakam | Perakam belum **Start**, atau trafik tidak melalui `:8888` | `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (macOS/Linux) / `netstat -ano \| findstr :8888` (Windows); pastikan `curl -x http://localhost:8888` |
| Firefox: tiada apa dirakam dari localhost | `localhost, 127.0.0.1` dalam **No proxy for** | Kosongkan kotak itu |
| `Address already in use` bila Start | Port 8888 digunakan aplikasi lain / perakam kedua | Tutup plan lain yang ada perakam; atau tukar port (dan arahan `curl -x`) |
| `curl` di Windows cmd: `{"ralat":…}` / JSON rosak | Petikan tunggal tidak difahami oleh cmd.exe | Guna Git Bash, atau: `curl -s -x http://localhost:8888 -H "Content-Type: application/json" -d "{\"no_kp\":\"800101015500\",\"kata_laluan\":\"rahsia123\"}" http://localhost:3000/api/log-masuk` |
| Sampler dirakam di bawah Test Plan, bukan Recording Controller | Target Controller tidak ditetapkan | Pilih **Test Plan > Thread Group > Recording Controller** |
| `-e -o` gagal: *"folder … not empty"* | Folder laporan sudah wujud | Padam folder atau guna nama baharu |
| Pelayaran Firefox biasa gagal selepas latihan | Proxy masih menunjuk ke JMeter yang telah berhenti | Network Settings → **Use system proxy settings** |

### ⭐ Cabaran
Ikut [`rakaman-e2e.md`](./rakaman-e2e.md) sepenuhnya: rakam aliran **3 langkah** (log masuk → senarai kenderaan → bayar cukai) dengan `TOKEN` dan `CSRF` **sebenar**, mulakan semula SUT, kemudian main balik. Mengapa kali ini bayar-cukai juga gagal walaupun token itu "sebenar" semasa dirakam? Untuk HTTPS (laman yang anda **dibenarkan** sahaja), ikut [`rakaman-https-setup.md`](./rakaman-https-setup.md) — termasuk import `ApacheJMeterTemporaryRootCA.crt` dan **membuangnya** selepas selesai.

---

## Latihan 7 (Cabaran) — Dua sampler, skop yang betul

**Sesi:** S3

### 🎯 Objektif
- Menyusun elemen mengikut skop dan menerangkan kesan kedudukan setiap elemen (O5)

### Prasyarat
- Latihan 1–3 selesai

### Langkah

1. Bina **satu Test Plan** dengan **dua sampler** (`/api/health` dan `/api/saman?no_kp=900202025600`) di bawah Thread Group yang sama.
2. Beri setiap sampler **Response Assertion tersendiri** (sebagai anak): `ok` untuk health, `saman` untuk saman.
3. Tambah **HTTP Request Defaults** dan **Constant Timer** 500 ms di bawah Thread Group, serta **Summary Report**.
4. **Ramal:** jumlah jeda timer setiap lelaran? Kemudian pindahkan timer menjadi anak sampler saman sahaja dan ramal semula.
5. Susun elemen dengan betul (Config → Sampler → Assertion → Listener) dan terangkan **skop** setiap elemen kepada rakan sebelah anda.

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
