# Hari 1 — Asas Apache JMeter & Ujian Beban

Panduan langkah demi langkah untuk membina ujian prestasi (**performance test**) menggunakan **Apache JMeter** terhadap **Portal eJPJ (tiruan)**. Pada akhir bengkel ini (~6 jam), anda akan mampu membina Test Plan lengkap: menghantar permintaan HTTP, mengawal beban dengan Thread Group, mengesahkan respons dengan Assertion, dan mentafsir keputusan dalam Listener.

**Apa yang akan dibina:**
- Test Plan pertama yang memukul `/api/health` dan `/`
- Ujian beban 20 pengguna terhadap endpoint sebut harga cukai
- Assertion (Response & Duration) + Timer (think time)
- Parameterisasi dengan **CSV Data Set Config** (setiap thread nombor pendaftaran berlainan)

> ⚠️ **Etika & undang-undang:** Sepanjang kursus kita menguji **salinan tempatan** (`sut/`, `http://localhost:3000`) sahaja. Menjalankan ujian beban terhadap sistem pengeluaran/awam yang anda **tidak** miliki atau tanpa kebenaran bertulis adalah menyalahi undang-undang (setara serangan **DoS**). Data adalah **sintetik** — bukan data rasmi JPJ.

---

## Persediaan

### 1. Pasang Java (JDK 8+)

JMeter berjalan atas **Java**. Pasang **JDK 11 atau lebih baru** (disyorkan JDK 17/21 LTS).

```bash
java --version      # sahkan Java wujud
```

- **macOS:** `brew install openjdk@21` (atau muat turun dari Adoptium/Temurin).
- **Windows:** muat turun pemasang dari [adoptium.net](https://adoptium.net/), atau `winget install EclipseAdoptium.Temurin.21.JDK`.
- **Linux:** `sudo apt install openjdk-21-jdk`.

### 2. Pasang Apache JMeter

- **macOS:** `brew install jmeter`, kemudian jalankan `jmeter`.
- **Manual (semua OS):** muat turun binari dari [jmeter.apache.org/download_jmeter.cgi](https://jmeter.apache.org/download_jmeter.cgi), nyahzip, dan jalankan:
  - `bin/jmeter` (macOS/Linux) atau `bin\jmeter.bat` (Windows) — buka **GUI**.

```bash
jmeter --version   # sahkan JMeter wujud
```

> **Konsep — GUI vs non-GUI:** JMeter GUI hanya untuk **membina & menyahpepijat** plan. Untuk **beban sebenar**, sentiasa jalankan mod **non-GUI** (`jmeter -n -t plan.jmx ...`) kerana GUI menggunakan banyak memori dan **memperlahankan** penjana beban. Kita bina di GUI hari ini; kita larikan beban sebenar secara non-GUI pada Hari 2.

### 3. Jalankan Sistem Under Test (SUT)

Buka satu tetingkap terminal dan biarkan pelayan tiruan berjalan sepanjang bengkel:

```bash
cd sut
node server.js
```

Anda sepatutnya nampak `Portal eJPJ (TIRUAN) berjalan di  http://localhost:3000`. Buka URL itu dalam pelayar untuk senarai endpoint. (Perlukan **Node.js 18+**; tiada `npm install` diperlukan.)

### 4. Kenali Antara Muka JMeter

| Bahagian | Fungsi |
|----------|--------|
| **Menu / Toolbar** (atas) | Buka/Simpan `.jmx`, butang **Start (▶)** / **Stop**, **Clear** hasil |
| **Pokok ujian** (kiri) | Struktur Test Plan — klik kanan untuk **Add** elemen |
| **Panel konfigurasi** (kanan) | Tetapan elemen yang dipilih |
| **Log** (bawah, ikon segi tiga amaran) | Ralat & amaran JMeter |

Setiap Test Plan disimpan sebagai satu fail **`.jmx`** (format XML).

---

## Pengenalan Ujian Prestasi (Performance Testing)

**Ujian prestasi** mengukur sejauh mana laju, stabil, dan berskala sesuatu sistem di bawah beban tertentu — bukan sama ada ia *berfungsi* (itu ujian fungsian), tetapi sama ada ia *tahan* apabila ramai pengguna datang serentak.

> **Konsep — Anatomi ujian prestasi:** Setiap ujian merangkumi: **Beban** (berapa pengguna serentak & corak kedatangan), **Senario** (urutan permintaan yang meniru pengguna sebenar), **Metrik** (throughput, response time, error rate), dan **Kriteria** (SLA/NFR — ambang lulus/gagal). Hari 1 fokus pada membina Beban + Senario + membaca Metrik asas.

**Domain kita:** bayangkan hari terakhir sebelum cukai jalan naik harga — beribu rakyat log masuk ke portal JPJ serentak untuk memperbaharui cukai. Bolehkah sistem menampung lonjakan itu? Itulah soalan yang ujian prestasi menjawab.

### Jenis ujian prestasi

| Jenis | Soalan | Corak beban |
|-------|--------|-------------|
| **Load test** | Bolehkah sistem tampung beban *dijangka*? | Pengguna tetap pada paras normal/puncak |
| **Stress test** | Di mana sistem *pecah*? | Naikkan pengguna sehingga gagal |
| **Spike test** | Bagaimana bila beban *melonjak* mengejut? | Lonjakan mendadak (cth. hari cukai) |
| **Soak / Endurance** | Adakah *memory leak* / degradasi jangka panjang? | Beban sederhana untuk jam/hari |
| **Scalability** | Adakah sistem *berskala* bila kita tambah sumber? | Beban sama, bandingkan konfigurasi |

---

## Anatomi Test Plan JMeter

Sebelum membina, fahami blok binaan utama. Semua tersusun sebagai **pokok** — kedudukan elemen menentukan **skop** (ruang lingkup)-nya.

```
Test Plan
└── Thread Group            (berapa pengguna, ramp-up, gelung)
    ├── HTTP Request Defaults   (Config: server/port lalai)
    ├── HTTP Header Manager     (Config: header dikongsi)
    ├── HTTP Request            (Sampler: satu permintaan)
    │   ├── Response Assertion  (semak kandungan respons)
    │   └── JSON Extractor      (Post-Processor: ekstrak nilai)
    ├── Constant Timer          (Timer: think time)
    └── View Results Tree       (Listener: papar keputusan)
```

| Kategori | Peranan | Contoh |
|----------|---------|--------|
| **Thread Group** | Mentakrif populasi pengguna maya | bilangan thread, ramp-up, gelung |
| **Sampler** | Menghantar satu permintaan | **HTTP Request**, JDBC, FTP |
| **Config Element** | Tetapan dikongsi (bukan permintaan) | HTTP Request Defaults, Header/Cookie/Cache Manager, **CSV Data Set Config** |
| **Timer** | Jeda antara permintaan (think time) | Constant, Uniform Random, Gaussian |
| **Assertion** | Semak respons betul | Response, Duration, JSON Assertion |
| **Pre/Post-Processor** | Jalan sebelum/selepas sampler | JSON Extractor, JSR223 |
| **Listener** | Kumpul & papar keputusan | View Results Tree, Summary/Aggregate Report |

> **Konsep penting — Skop mengikut kedudukan:** Elemen **Config**, **Timer**, **Assertion**, dan **Listener** memberi kesan kepada **semua sampler pada aras yang sama atau lebih dalam** (adik-beradik & anak). Letak elemen di bawah Thread Group → ia menyentuh semua sampler; letak sebagai **anak** satu sampler → ia menyentuh sampler itu **sahaja**. Salah letak = punca pepijat paling biasa untuk pemula.

---

## Langkah 1: Test Plan Pertama Anda

Mari bina ujian paling ringkas — satu pengguna memukul `/api/health`.

1. Buka JMeter. Anda sudah ada **Test Plan** kosong.
2. **Klik kanan Test Plan → Add → Threads (Users) → Thread Group.**
3. Pada Thread Group, tetapkan buat sementara: **Number of Threads = 1**, **Ramp-up = 1**, **Loop Count = 1**.
4. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults.** Isi:
   - **Protocol:** `http` · **Server Name or IP:** `localhost` · **Port Number:** `3000`
5. **Klik kanan Thread Group → Add → Sampler → HTTP Request.** Isi:
   - **Method:** `GET` · **Path:** `/api/health` (biarkan server/port kosong — diwarisi dari Defaults)
6. **Klik kanan Thread Group → Add → Listener → View Results Tree.**
7. Klik **Save** (`.jmx`), kemudian **Start (▶)**.

Dalam View Results Tree, klik sampel — anda sepatutnya nampak ikon **hijau**, kod **200**, dan badan respons `{"status":"ok",...}`.

> **Konsep — HTTP Request Defaults:** Config ini menetapkan **nilai lalai** (server, port, protokol) yang **diwarisi** oleh semua HTTP Request di bawahnya. Jadi bila alamat SUT berubah (cth. dari `localhost` ke pelayan ujian), anda tukar **satu tempat** sahaja.

> Rujuk fail siap: [`test-plans/01-hello-jpj.jmx`](./test-plans/01-hello-jpj.jmx).

---

## Langkah 2: Thread Group — Model Beban

**Thread Group** ialah jantung ujian beban — ia mentakrif **populasi pengguna maya**.

| Medan | Maksud | Contoh |
|-------|--------|--------|
| **Number of Threads (users)** | Bilangan pengguna maya serentak | `20` |
| **Ramp-Up Period (seconds)** | Masa untuk melancarkan **semua** thread | `10` (2 pengguna/saat) |
| **Loop Count** | Berapa kali setiap thread ulang senario | `5` (atau *Infinite*) |

> **Konsep penting — Ramp-up:** Jangan lancar semua pengguna serentak (ramp-up = 0) melainkan itu memang spike test — ia mencipta "kejutan" tidak realistik. Ramp-up beransur (cth. 20 pengguna dalam 10s) meniru kedatangan pengguna sebenar dan memberi sistem masa memanaskan (*warm-up*).

> **Konsep — jumlah permintaan:** Bilangan sampel = **Threads × Loop Count** (jika satu sampler). 20 × 5 = **100** permintaan. Semak ini dalam Summary Report untuk sahkan ujian berjalan penuh.

Ubah Thread Group anda kepada **20 / 10 / 5** untuk langkah seterusnya.

---

## Langkah 3: HTTP Header Manager

Banyak API memerlukan **header** (cth. `Content-Type`, `Accept`, `Authorization`). **HTTP Header Manager** menetapkan header yang dikongsi oleh sampler dalam skopnya.

1. **Klik kanan Thread Group → Add → Config Element → HTTP Header Manager.**
2. Klik **Add** dan masukkan: Name `Accept`, Value `application/json`.

> **Konsep — Config Element lain yang berguna:**
> - **HTTP Cookie Manager** — simpan & hantar semula cookie (perlu untuk sesi berasaskan cookie).
> - **HTTP Cache Manager** — meniru cache pelayar (elak muat semula sumber statik).
> Untuk API JSON kita, Header Manager sudah memadai; kita guna token (bukan cookie) pada Hari 2.

---

## Langkah 4: Listener — Membaca Keputusan

**Listener** mengumpul & memaparkan keputusan. Tiga yang paling penting:

| Listener | Guna | Amaran |
|----------|------|--------|
| **View Results Tree** | Nyahpepijat — lihat setiap permintaan/respons penuh | **Sangat berat** — untuk 1–2 pengguna sahaja, matikan semasa beban |
| **Summary Report** | Ringkasan setiap label: # sampel, Average, Min/Max, Error %, Throughput | Ringan — sesuai untuk beban |
| **Aggregate Report** | Seperti Summary + **Median**, **90/95/99 percentile** | Ringan |

Tambah ketiga-tiga di bawah Thread Group. Jalankan ujian (20/10/5) dan perhatikan:

- **# Samples** = 100
- **Average** — purata masa respons (ms)
- **Throughput** — permintaan/saat
- **Error %** — peratus sampel gagal

> **Konsep penting — JANGAN guna GUI listener semasa beban sebenar.** View Results Tree menyimpan **setiap** respons dalam memori → penjana beban kehabisan RAM dan angka menjadi tidak tepat. Untuk beban sebenar (Hari 2), buang GUI listener dan tulis ke fail **`.jtl`** melalui `-l` dalam mod non-GUI.

> **Konsep — Average boleh menipu:** Purata menyembunyikan puncak. Sentiasa lihat **percentile** — "95th percentile = 800 ms" bermakna 95% permintaan siap ≤ 800 ms (dan 5% lebih teruk). SLA biasanya ditulis dalam percentile, bukan purata.

---

## Langkah 5: Assertion — Sahkan Respons Betul

Kod **200** tidak semestinya bermakna respons **betul**. **Assertion** mengesahkan kandungan.

### Response Assertion

1. **Klik kanan HTTP Request → Add → Assertions → Response Assertion.**
2. **Field to Test:** *Text Response* · **Pattern Matching Rules:** *Substring* · **Patterns to Test:** tambah `amaun`.

Kini sampel hanya "lulus" jika badan respons mengandungi `amaun`.

### Duration Assertion

1. **Add → Assertions → Duration Assertion.**
2. **Duration in milliseconds:** `2000` — sampel gagal jika ambil lebih 2 saat.

> **Konsep — Assertion menukar makna "gagal":** Tanpa assertion, hanya ralat rangkaian/HTTP dikira gagal. Dengan assertion, respons yang **salah kandungan** atau **terlalu lambat** juga dikira gagal → **Error %** anda mencerminkan kualiti sebenar, bukan sekadar sambungan berjaya.

Sampler `GET /api/kenderaan/WXY1234/cukai` dengan kedua-dua assertion → rujuk [`test-plans/02-cukai-beban.jmx`](./test-plans/02-cukai-beban.jmx).

---

## Langkah 6: Timer — Think Time

Pengguna sebenar **tidak** menghantar permintaan bertalu-talu — mereka membaca, berfikir, menaip. **Timer** menambah jeda ini supaya beban realistik.

| Timer | Kelakuan |
|-------|----------|
| **Constant Timer** | Jeda tetap (cth. 300 ms) setiap sampler |
| **Uniform Random Timer** | Jeda rawak seragam (asas + julat rawak) |
| **Gaussian Random Timer** | Jeda rawak taburan normal (paling realistik) |

1. **Klik kanan Thread Group → Add → Timer → Constant Timer.** Delay `300`.

> **Konsep — think time menjejaskan throughput:** Menambah think time **menurunkan** throughput (thread menunggu, tidak menghantar). Ini **betul** — throughput tanpa think time tidak realistik dan boleh membebankan sistem secara palsu. Untuk mencapai sasaran *permintaan/saat* tertentu, laraskan **bilangan thread** dan **think time** bersama, atau guna **Throughput Controller / Timer** (Hari 2).

---

## Langkah 7: Parameterisasi dengan CSV Data Set Config

Menghantar `WXY1234` seribu kali tidak realistik — ia mengenakan cache dan tidak menguji kepelbagaian data. **CSV Data Set Config** menyuap nilai berlainan ke setiap thread/lelaran.

1. **Klik kanan Thread Group → Add → Config Element → CSV Data Set Config.**
2. Isi:
   - **Filename:** `../data/kenderaan.csv` *(relatif kepada lokasi fail `.jmx`)*
   - **Variable Names:** `no_pendaftaran,model`
   - **Ignore first line:** `True` (baris tajuk) · **Recycle on EOF:** `True` · **Stop thread on EOF:** `False`
   - **Sharing mode:** `All threads`
3. Ubah path sampler kepada: `/api/kenderaan/${no_pendaftaran}/cukai`.
4. Jalankan (10 pengguna × 10 gelung). Dalam View Results Tree, sahkan setiap permintaan guna nombor berlainan.

> **Konsep — `${nama}` ialah pembolehubah JMeter:** Sintaks `${no_pendaftaran}` menggantikan nilai dari CSV pada masa larian. Nilai ini boleh datang dari CSV, User Defined Variables, Extractor (Hari 2), atau fungsi terbina seperti `${__Random(1,100)}`.

> **Konsep — Sharing mode:** *All threads* = satu barisan CSV dikongsi (baris seterusnya diberi kepada thread seterusnya). *Current thread group* / *Current thread* mengasingkan barisan. Untuk data unik-setiap-pengguna, gunakan dengan berhati-hati + `Recycle=False` + `Stop thread=True`.

> Rujuk fail siap: [`test-plans/03-csv-berparameter.jmx`](./test-plans/03-csv-berparameter.jmx).

---

## Langkah 8: Rakam Test Plan (HTTP(S) Test Script Recorder)

Selain membina sampler satu-satu, JMeter boleh **merakam** trafik sebenar melalui **proxy** dan menjananya menjadi sampler secara automatik. Berguna untuk aliran panjang (banyak permintaan) supaya anda tidak menaip setiap satu.

**Cara ia berfungsi:** JMeter memasang satu **proxy** (lalai port `8888`). Anda tetapkan **Firefox** untuk melalui proxy itu; setiap permintaan **dirakam** ke dalam **Recording Controller**.

> **Mengapa Firefox?** Firefox ada **tetapan proxy tersendiri** — anda tak perlu ubah proxy seluruh OS (yang menjejaskan semua aplikasi lain). Ini menjadikannya pelayar paling bersih & selamat untuk merakam.

**A. Sediakan perakam (di JMeter GUI):**

1. **Klik kanan Test Plan → Add → Non-Test Elements → HTTP(S) Test Script Recorder.**
2. **Klik kanan Thread Group → Add → Logic Controller → Recording Controller** (destinasi rakaman). Pada perakam, set **Target Controller → Test Plan > Thread Group > Recording Controller**.
3. **Requests Filtering → Excludes:** tambah regex aset statik `(?i).*\.(bmp|css|js|gif|ico|jpe?g|png|swf|eot|otf|ttf|mp4|woff|woff2)([?;].*)?` supaya imej/CSS/JS tidak dirakam.

> Atau langkau A1–A3: buka [`test-plans/rakam-template.jmx`](./test-plans/rakam-template.jmx) — semuanya sudah dipasang.

**B. Konfigur Firefox untuk proxy:**

4. Firefox → **Settings** → taip "proxy" dalam kotak carian → **Network Settings → Settings…**
5. Pilih **Manual proxy configuration**: **HTTP Proxy** `localhost`, **Port** `8888`; tandakan **Also use this proxy for HTTPS**.
6. **⚠️ Penting:** **kosongkan** `localhost, 127.0.0.1` dari kotak **No proxy for** — jika tidak, trafik localhost akan **memintas** proxy dan **tiada apa dirakam**. Klik **OK**.
7. **Untuk sasaran HTTPS sahaja:** klik **Start** (langkah C8) sekali dahulu supaya JMeter menjana `ApacheJMeterTemporaryRootCA.crt` dalam folder `bin/`, kemudian di Firefox: **Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import…** → pilih fail itu → tandakan **Trust this CA to identify websites**. *(SUT kita `http://`, jadi langkah sijil ini **tidak** perlu.)*

**C. Rakam:**

8. Di JMeter, pilih **HTTP(S) Test Script Recorder** → klik hijau **Start** ▶.
9. Dalam **Firefox**, layari `http://localhost:3000` dan lakukan aliran (log masuk → semak kenderaan → bayar). Setiap permintaan muncul sebagai sampler dalam **Recording Controller**.
   > Alternatif tanpa pelayar (guna `curl` melalui proxy JMeter — berguna untuk `POST`):
   > ```bash
   > curl -s -x http://localhost:8888 -H 'Content-Type: application/json' \
   >   -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}' \
   >   http://localhost:3000/api/log-masuk
   > ```
10. Klik **Stop** ⏹. **Pulihkan Firefox:** Network Settings → **Use system proxy settings** (atau *No proxy*) supaya pelayaran biasa berfungsi semula.

> **Pintasan — templat perakam siap sedia:** Daripada membina perakam dari awal, buka [`test-plans/rakam-template.jmx`](./test-plans/rakam-template.jmx) — **HTTP(S) Test Script Recorder** (port 8888) + **Recording Controller** sudah dipasang dan disasarkan ke `localhost`. Terus klik **Start**, layari dalam **Firefox** yang dikonfigur ke proxy (bahagian B), dan rakam. (Untuk sasaran **HTTPS**, import sijil `ApacheJMeterTemporaryRootCA.crt` ke Firefox dahulu — langkah B7.)

> **⚠️ Konsep terpenting — rakaman TIDAK korelasi secara automatik:** Perakam mengeras-kod nilai yang dilihat pada masa rakaman, termasuk **token** & **csrf** sesi tersebut. Bila anda main balik, sesi itu sudah luput → permintaan berkumpul jadi **401/403**. Membaiki ini = **korelasi** (Hari 2).

**Cuba main balik (bukti):** buka [`test-plans/04-rakaman-mentah.jmx`](./test-plans/04-rakaman-mentah.jmx) — hasil rakaman "mentah" dengan token dikeras-kod:

```bash
node sut/server.js &     # pastikan SUT berjalan
jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/r04.jtl
# /api/log-masuk → 200 ; /api/kenderaan → 401 ; bayar-cukai → 401 (Assertion BERJAYA gagal)
```

Log masuk berjaya, tetapi dua permintaan seterusnya **401** kerana token rakaman sudah luput. Plan ini sengaja **rosak** untuk menunjukkan sebab korelasi diperlukan — dibaiki di [`hari-2/test-plans/04-korelasi-log-masuk.jmx`](../hari-2/test-plans/04-korelasi-log-masuk.jmx).

> **Petua bersih-selepas-rakam:** Buang permintaan aset/analitik yang tak berkaitan, namakan semula sampler dengan bermakna, tambah **Header Manager**, **think time**, dan **CSV** — kemudian **korelasikan** nilai dinamik. Rakaman ialah titik mula, bukan produk siap.

---

## Latihan — Senario Sebenar JPJ (Use Cases)

Kaitkan kemahiran Hari 1 dengan soalan operasi sebenar. Semua guna alat Hari 1 sahaja.

### Kes 1 — Kesihatan sistem asas
`GET /api/health` dengan 50 pengguna, ramp 20s. **Soalan:** adakah throughput stabil? Error % = 0?

### Kes 2 — Beban semak cukai
`GET /api/kenderaan/${no_pendaftaran}/cukai` berparameter CSV, 30 pengguna × 10 gelung + Response Assertion. **Soalan:** apakah 95th percentile? (Guna Aggregate Report.)

### Kes 3 — Semak saman
`GET /api/saman?no_kp=900202025600`, 20 pengguna. Tambah Response Assertion mengandungi `saman`. **Soalan:** bandingkan latensi dengan endpoint cukai.

### Kes 4 — Kesan think time
Jalankan Kes 2 dua kali: (a) tanpa timer, (b) dengan Constant Timer 1000 ms. **Soalan:** bagaimana throughput & Average berubah? Mengapa?

### Kes 5 — Kesan latensi pelayan
Mulakan semula pelayan dengan `LATENCY_MIN=300 LATENCY_MAX=900 node server.js`. Ulang Kes 2. **Soalan:** manakah lebih menjejaskan pengguna — throughput atau percentile?

> **🎯 Cabaran gabungan:** Bina satu Test Plan dengan HTTP Request Defaults + Header Manager + CSV Data Set + 2 sampler (cukai & saman), setiap satu dengan Response Assertion, Constant Timer, dan Summary + Aggregate Report. Jalankan 25 pengguna × 8 gelung dan laporkan Error %, Average, dan 95th percentile kepada kelas.

---

## Ringkasan Hari 1

Tahniah! Anda telah:

- [x] Memasang **Java + JMeter** dan menjalankan **SUT tiruan** (`node server.js`)
- [x] Memahami **ujian prestasi** & jenisnya (Load, Stress, Spike, Soak, Scalability)
- [x] Mengenali **anatomi Test Plan** dan konsep **skop mengikut kedudukan**
- [x] Membina Thread Group (**threads / ramp-up / loop**) sebagai model beban
- [x] Menggunakan **HTTP Request Defaults** & **Header Manager**
- [x] Membaca **Listener** (View Results Tree / Summary / Aggregate) dan memahami **percentile vs average**
- [x] Menambah **Response & Duration Assertion**
- [x] Menambah **Timer** (think time) dan memahami kesannya pada throughput
- [x] Memparameter data dengan **CSV Data Set Config** dan pembolehubah `${...}`
- [x] **Merakam** Test Plan dengan **HTTP(S) Test Script Recorder** dan memahami mengapa rakaman perlu **dikorelasi**

> **Lab:** Selesaikan [`snippets/lab.md`](./snippets/lab.md) sebelum Hari 2.

---

## Apa Seterusnya?

Pada **[Hari 2](../hari-2/)**, kita akan:

- **Korelasi** nilai dinamik (`token`, `csrf`) dengan **JSON Extractor** — sebab replay biasa gagal
- Guna **Logic Controllers** (Transaction, If, Loop, Throughput)
- Menulis skrip **JSR223 (Groovy)** & fungsi JMeter (`${__Random}`, `${__UUID}`, `${__P}`)
- Menjalankan beban sebenar **non-GUI** + menjana **laporan HTML dashboard**
- Mentafsir metrik lanjutan (throughput, percentile, error %) & menetapkan **SLA/NFR**
- Sekilas pandang **distributed testing**, **CI/CD**, dan pemantauan **Grafana**

Jumpa di Hari 2!
