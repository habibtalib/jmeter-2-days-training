# Hari 2 — JMeter Lanjutan, Analisis & CI

Hari ini kita naik taraf dari "memukul satu endpoint" kepada **senario pengguna sebenar penuh** yang tahan beban tinggi: log masuk → semak kenderaan → bayar cukai. Anda akan belajar **korelasi** (inti ujian beban berasaskan sesi), **Logic Controllers**, skrip **Groovy**, menjalankan beban **non-GUI**, menjana **laporan HTML**, dan mentafsir keputusan terhadap **SLA**.

**Apa yang akan dibina:**
- Senario log masuk yang meng-**ekstrak** `token` + `csrf` dinamik dan menggunakannya semula
- Transaksi penuh dibungkus **Transaction Controller** + **If Controller**
- **JSR223 (Groovy)** untuk logik & pengesahan tersuai
- Larian **non-GUI** + **laporan HTML dashboard** yang boleh dikongsi

> ⚠️ **Peringatan:** masih **localhost sahaja**. Pastikan `sut/server.js` berjalan (lihat Hari 1). Data sintetik — bukan rasmi JPJ.

---

## Persediaan

Pastikan pelayan tiruan berjalan:

```bash
cd sut && node server.js
```

Buka JMeter GUI. Kita akan membina di GUI, tetapi menjalankan beban sebenar secara **non-GUI**.

---

## Langkah 1: Korelasi (Correlation)

### Mengapa replay biasa gagal

Cuba rakam log masuk sekali dan "main semula" (replay) — ia **gagal**. Sebabnya: pelayan mengeluarkan nilai **dinamik** setiap sesi (token sesi, **CSRF token**, view-state). Nilai yang anda rakam semalam sudah **luput**. Anda mesti **menangkap** nilai itu dari respons **pada masa larian** dan menyuntiknya ke permintaan seterusnya. Inilah **korelasi**.

Dalam SUT kita, `POST /api/log-masuk` memulangkan:

```json
{ "token": "b3519618-...", "csrf": "cefa6be3...", "nama": "Pengguna 5500" }
```

- `token` → mesti dihantar sebagai header `Authorization: Bearer <token>` pada permintaan berikutnya.
- `csrf` → mesti dihantar dalam badan `bayar-cukai`; jika salah/hilang → **403**.

> **Konsep penting — parameterisasi vs korelasi:** *Parameterisasi* menyuap data yang **anda sudah tahu** (dari CSV — cth. `no_kp`). *Korelasi* menangkap data yang **hanya pelayan tahu**, dijana pada masa larian (token, csrf). Kedua-duanya diperlukan untuk senario realistik.

### Tiga jenis Extractor

| Extractor | Bila guna | Contoh |
|-----------|-----------|--------|
| **JSON Extractor** | Respons JSON (API moden) | `$.token` |
| **Regular Expression Extractor** | Mana-mana teks/HTML | `"token":"([^"]+)"` |
| **Boundary Extractor** | Teks dengan sempadan kiri/kanan jelas | Kiri `"token":"` Kanan `"` |

Untuk API JSON kita, **JSON Extractor** paling bersih.

### Bina: ekstrak token + csrf

1. Sampler **POST `/api/log-masuk`** (Body Data JSON, Header `Content-Type: application/json`, guna CSV `pengguna.csv` untuk `no_kp`/`kata_laluan`).
2. **Klik kanan sampler → Add → Post Processors → JSON Extractor.** Isi:
   - **Names of created variables:** `token;csrf`
   - **JSON Path expressions:** `$.token;$.csrf`
   - **Match No.:** `1;1` · **Default Values:** `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`
3. Sampler **GET `/api/kenderaan?no_kp=${no_kp}`** + Header Manager (anak) `Authorization: Bearer ${token}`.
4. Sampler **POST `/api/kenderaan/WXY1234/bayar-cukai`** + Header `Authorization: Bearer ${token}` + Body `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": 90 }`.
5. Assertion respons mengandungi `BERJAYA`. Jalankan (5 pengguna); lihat View Results Tree.

> **Konsep — Default Value ialah alat nyahpepijat:** Tetapkan default yang **ketara** (`TOKEN_TAK_JUMPA`) supaya bila ekstrak gagal, permintaan seterusnya menunjukkan nilai itu dalam log — anda serta-merta tahu korelasi rosak, bukan tercari-cari sebab 403.

> **Eksperimen:** Ganti `${csrf}` dengan teks tetap salah → perhatikan **403 "Token CSRF tidak sah"**. Inilah sebab korelasi wajib.

> Rujuk: [`test-plans/04-korelasi-log-masuk.jmx`](./test-plans/04-korelasi-log-masuk.jmx).

---

## Langkah 2: Logic Controllers

**Logic Controller** mengawal **bila** dan **bagaimana** sampler dijalankan.

| Controller | Fungsi |
|------------|--------|
| **Transaction Controller** | Kumpul beberapa sampler sebagai **satu transaksi** & ukur jumlah masanya |
| **If Controller** | Jalankan anak hanya jika syarat benar |
| **Loop Controller** | Ulang anak N kali |
| **Throughput Controller** | Jalankan anak untuk **% peratus** thread (edaran beban) |
| **Runtime Controller** | Jalankan anak untuk tempoh saat tertentu |

### Bina: transaksi penuh

1. **Klik kanan Thread Group → Add → Logic Controller → Transaction Controller**, namakan `Pembaharuan Cukai Jalan`.
2. Alih 4 sampler (log masuk → senarai → sebut harga → bayar) **ke dalam** controller itu.
3. Selepas sampler senarai, tambah **JSON Extractor** kedua untuk ambil kenderaan pertama:
   - Names: `no_pendaftaran;amaun` · Paths: `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai` · Default: `NONE;0`
4. Bungkus sebut-harga + bayar dalam **If Controller** dengan syarat:
   ```
   ${__groovy(vars.get("no_pendaftaran") != "NONE" && vars.get("token") != "TOKEN_TAK_JUMPA")}
   ```
5. Tambah **Uniform Random Timer** (1000 ms + julat 2000 ms) sebagai think time.

> **Konsep — mengapa Transaction Controller:** Ia melaporkan satu metrik "Pembaharuan Cukai Jalan" yang merangkumi **keseluruhan perjalanan pengguna** (bukan setiap langkah berasingan). Ini padan dengan cara perniagaan berfikir: "berapa lama untuk **memperbaharui cukai**?", bukan "berapa lama endpoint /bayar-cukai".

> **Konsep — If Controller & fungsi `__groovy`:** Syarat ditulis sebagai ungkapan yang menilai kepada `true`/`false`. Guna `${__groovy(...)}` (bukan sintaks lama `${__jexl3}`) — ia paling laju dan disyorkan. Di sini kita elak cuba bayar bila tiada kenderaan/token.

> Rujuk: [`test-plans/05-transaksi-penuh.jmx`](./test-plans/05-transaksi-penuh.jmx).

---

## Langkah 3: JSR223 (Groovy) & Fungsi JMeter

Bila alat terbina tidak cukup, tulis kod. **JSR223** elemen (Sampler/PreProcessor/PostProcessor) menjalankan skrip — guna **Groovy** (paling laju; tandakan *Cache compiled script*).

Contoh (lihat [`snippets/jsr223-groovy.groovy`](./snippets/jsr223-groovy.groovy)):

```groovy
// PreProcessor: jana nilai unik sebelum permintaan
vars.put("no_rujukan", "REF-" + System.currentTimeMillis() + "-" + ctx.getThreadNum())

// PostProcessor: pengesahan JSON terperinci + tandakan gagal
import groovy.json.JsonSlurper
def json = new JsonSlurper().parseText(prev.getResponseDataAsString())
if (!json.token) { prev.setSuccessful(false); prev.setResponseMessage("Tiada token!") }
```

> **Konsep — objek terbina:** `vars` (pembolehubah thread), `props` (sifat global), `prev` (SampleResult sebelum ini), `ctx` (konteks thread), `log` (pengelog), `SampleResult`/`sampler` (dalam sampler/pre-processor).

### Fungsi JMeter yang biasa

| Fungsi | Hasil |
|--------|-------|
| `${__Random(1,1000)}` | Integer rawak |
| `${__RandomString(8,abcdef)}` | Rentetan rawak |
| `${__UUID}` | UUID unik |
| `${__time(yyyy-MM-dd)}` | Cap masa/tarikh |
| `${__P(pengguna,50)}` | Baca **property** `pengguna` (lalai 50) — untuk non-GUI |
| `${__threadNum}` | Nombor thread semasa |

> **Konsep — `__P` menjadikan plan boleh-guna-semula:** Daripada mengeras-kod 50 pengguna, guna `${__P(pengguna,50)}`. Kemudian pada baris arahan: `-Jpengguna=200`. Satu plan, banyak saiz beban — asas integrasi CI.

---

## Langkah 4: Larian Non-GUI + Laporan HTML

Untuk **beban sebenar**, jangan guna GUI. Buang semua GUI listener dan jalankan dari terminal.

```bash
jmeter -n -t hari-2/test-plans/06-ujian-beban-nogui.jmx \
  -Jpengguna=100 -Jrampup=30 -Jtempoh=180 \
  -l results.jtl \
  -e -o laporan/
```

| Bendera | Maksud |
|---------|--------|
| `-n` | Mod non-GUI |
| `-t` | Fail Test Plan (`.jmx`) |
| `-l` | Fail hasil mentah (`.jtl`) |
| `-e -o <dir>` | Jana **laporan HTML dashboard** ke direktori (mesti kosong) |
| `-J<nama>=<nilai>` | Tetapkan **property** (dibaca oleh `${__P(...)}`) |

Atau guna skrip pembungkus:

```bash
cd hari-2/run
./run-nogui.sh                          # lalai 50 pengguna / 120s
PENGGUNA=200 RAMPUP=60 TEMPOH=300 ./run-nogui.sh
```

> **Konsep — fail `.jtl`:** Hasil mentah CSV setiap sampel (cap masa, label, masa, kod, berjaya…). Anda boleh jana laporan HTML **kemudian** dari `.jtl` sedia ada: `jmeter -g results.jtl -o laporan/`.

Buka `laporan/index.html`.

---

## Langkah 5: Membaca Keputusan & Menetapkan SLA

Laporan HTML dashboard mengandungi bahagian penting:

| Metrik | Maksud | Pandangan sihat |
|--------|--------|-----------------|
| **APDEX** | Skor kepuasan (0–1) berdasarkan ambang | Hampir 1.0 |
| **Throughput** | Permintaan/transaksi selesai per saat | Stabil, tidak menurun |
| **Average / Median** | Masa respons purata / titik tengah | Median < ambang SLA |
| **90/95/99 percentile** | 95% permintaan ≤ nilai ini | Utama untuk SLA |
| **Error %** | Peratus sampel gagal | ≈ 0% (< 1% biasanya diterima) |
| **Response time vs Latency** | Jumlah masa vs masa ke bait pertama | Jurang besar = pemprosesan lambat |

> **Konsep penting — response time ≠ latency:** *Latency* = masa sehingga **bait pertama** diterima. *Response time* = masa sehingga **respons penuh**. *Connect time* = masa jabat tangan sambungan. Jurang antara latency & response time menunjukkan masa penstriman/pemprosesan pelayan.

> **Konsep — SLA/NFR ditulis dalam percentile:** Contoh NFR: *"95th percentile masa transaksi Pembaharuan Cukai < 1500 ms, Error % < 1%, pada 200 pengguna serentak."* Purata **tidak** sesuai untuk SLA kerana ia menyembunyikan ekor lambat (tail latency).

> **Konsep — mencari titik pecah (breaking point):** Naikkan beban berperingkat (`-Jpengguna=50`, `150`, `400`). Titik di mana percentile melonjak atau Error % naik mendadak ialah **had kapasiti** — output paling berharga sesuatu stress test.

### Senario puncak: Hari Kenaikan Harga Cukai (`07-beban-puncak-cukai.jmx`)

Ini menggabungkan semua yang di atas ke dalam satu **use case JPJ realistik** — lonjakan pembaharuan cukai jalan pada hari harga naik. Aliran transaksinya menggunakan **sebut harga sebagai sumber amaun** (bukan mengeras-kod): log masuk → senarai kenderaan → `GET /cukai` (ekstrak `amaun` + `tempoh_bulan`) → `bayar-cukai`. Ia juga **menguatkuasakan SLA per-transaksi** dengan **Duration Assertion** — sampel yang melebihi ambang ditanda **gagal**, jadi pelanggaran SLA muncul sebagai Error % dalam laporan, bukan hanya angka percentile.

```bash
cd hari-2/run
PENGGUNA=300 RAMPUP=30 TEMPOH=300 ./run-nogui.sh    # tukar test-plans/06 → 07 di dalam skrip, atau:

jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
  -Jpengguna=300 -Jrampup=30 -Jtempoh=300 -Jsla_ms=2000 \
  -l hasil/results.jtl -e -o hasil/laporan
```

Semua beban dikawal melalui property: `-Jpengguna` `-Jrampup` `-Jtempoh` `-Jhost` `-Jport`, dan **ambang SLA** melalui `-Jsla_ms` (lalai `2000`). Turunkan `-Jsla_ms` (cth. `-Jsla_ms=150`) untuk melihat Duration Assertion mula menandakan sampel gagal — cara padat menunjukkan hubungan **ambang SLA ↔ Error %**.

---

## Langkah 6: Distributed / Remote Testing (Sekilas)

Satu mesin ada had (CPU/rangkaian). Untuk beban sangat tinggi, JMeter berjalan **teragih**: satu **controller** (master) mengarah beberapa **worker** (slave) yang menjana beban:

```bash
# pada setiap worker
jmeter-server
# pada controller
jmeter -n -t plan.jmx -R worker1,worker2,worker3 -l results.jtl -e -o laporan/
```

> **Petua:** Untuk beban besar dalam amali sebenar, banyak pasukan kini guna **JMeter dalam kontena/awan** (cth. beberapa instance di CI, atau perkhidmatan seperti Azure Load Testing) berbanding menyiapkan master-slave secara manual.

---

## Langkah 7: CI/CD & Pemantauan Langsung (Sekilas)

- **CI/CD:** Jalankan `jmeter -n ...` dalam **Jenkins / GitHub Actions**, kemudian **gagalkan build** jika ambang dilanggar (guna *JMeter Performance Plugin* atau semak `.jtl`). Ini menjadikan ujian prestasi sebahagian *pipeline*, bukan aktiviti sekali-sekala.
- **Taurus (bzt):** pembungkus YAML atas JMeter yang memudahkan integrasi CI + kriteria lulus/gagal.
- **Pemantauan langsung:** Tambah **Backend Listener** (InfluxDB) → papar metrik **masa nyata** dalam **Grafana** semasa ujian berjalan (berguna untuk demo & ujian panjang/soak).

> **Konsep — "shift-left performance":** Menjalankan ujian prestasi awal & automatik (setiap PR/nightly) menangkap regresi prestasi sebelum ia sampai ke pengeluaran — jauh lebih murah daripada menemuinya semasa hari cukai sebenar.

---

## Amalan Terbaik & Kesilapan Biasa

| ✅ Amalan baik | ❌ Elak |
|----------------|---------|
| Jalankan beban sebenar **non-GUI** | GUI + View Results Tree semasa beban |
| **Korelasi** semua nilai dinamik | Mengeras-kod token/csrf yang direkod |
| Tambah **think time** & ramp-up beransur | 1000 pengguna serentak, 0 think time |
| Ukur dengan **percentile** | Bergantung pada Average sahaja |
| **Parameter** data (CSV) | Data sama diulang → cache palsu |
| Guna `${__P()}` + non-GUI untuk CI | Edit `.jmx` setiap kali tukar beban |
| **Panaskan** sistem sebelum ukur | Kira detik pertama (cold start) sebagai SLA |
| Uji **salinan/staging** yang anda benarkan | ❗ Uji pengeluaran/sistem awam tanpa kebenaran |

---

## Ringkasan Hari 2

Anda telah:

- [x] Memahami & melaksanakan **korelasi** (JSON/Regex/Boundary Extractor) untuk `token` + `csrf`
- [x] Menggunakan **Logic Controllers** (Transaction, If) untuk senario realistik
- [x] Menulis **JSR223 (Groovy)** & fungsi JMeter (`__Random`, `__UUID`, `__P`)
- [x] Menjalankan beban **non-GUI** dan menjana **laporan HTML dashboard**
- [x] Mentafsir **throughput, percentile, error %, APDEX** dan menetapkan **SLA/NFR**
- [x] Memahami **distributed testing**, **CI/CD**, dan pemantauan **Grafana** secara ringkas
- [x] Menghayati **amalan terbaik** & mengelak kesilapan biasa

> **Lab:** Selesaikan [`snippets/lab.md`](./snippets/lab.md) — termasuk mencari titik pecah & menetapkan SLA.

---

## Apa Seterusnya?

- Dalami satu jenis extractor lanjutan (Boundary Extractor) pada respons HTML sebenar.
- Sediakan **pipeline CI** yang menjalankan `06-ujian-beban-nogui.jmx` setiap malam dan gagalkan pada pelanggaran SLA.
- Terokai **Backend Listener + InfluxDB + Grafana** untuk papan pemuka masa nyata.
- Baca [dokumentasi rasmi JMeter](https://jmeter.apache.org/usermanual/index.html) dan [Best Practices](https://jmeter.apache.org/usermanual/best-practices.html).

Terima kasih kerana menyertai kursus ini!
