# Nota Penceramah — Hari 2: Korelasi, Logic Controllers, Non-GUI & Analisis SLA

[📖 README Hari 2](./README.md) · [🧪 Lab](./snippets/lab.md) · [🗂️ Test plans](./test-plans/) · [⬅️ README Hari 1](../hari-1/README.md)

> **Mesej teras hari ini:**
> 1. **"Ujian yang tidak dikorelasi hanya mengukur halaman ralat."** Token dan csrf mesti ditangkap pada masa larian.
> 2. **"Ukur perjalanan pengguna, bukan endpoint."** Transaction Controller = bahasa perniagaan.
> 3. **"GUI untuk membina, non-GUI untuk mengukur."**
> 4. **"SLA ditulis dalam percentile, dan ia mesti boleh gagal."** Duration Assertion + gerbang CI.
> 5. **"Hanya sasaran yang dibenarkan secara bertulis."** Klien kita ialah JPJ — mereka mesti keluar dengan refleks ini.

## Ringkasan penyampai

| Perkara | Nilai |
|---------|-------|
| Klien | JPJ — Jabatan Pengangkutan Jalan Malaysia. Senario dan istilah (cukai jalan, saman, no. pendaftaran) adalah dunia mereka; jemput mereka mengaitkan dengan sistem sebenar **secara lisan**, bukan dengan menguji sistem sebenar. |
| Konteks | Hari 1 diajar pada **21 Sep** — dua minggu lalu. Jangkakan lupa: mulakan S1 dengan **warm-up 15 minit**. |
| Nisbah | S1 ~40% penerangan/demo · S2 ~35% · S3 ~35% · S4 ~50% (konsep + penutup) · selebihnya lab |
| Bahan | Projektor dengan dua panel: Terminal A (log SUT) + JMeter GUI. Papan putih untuk aliran korelasi (log masuk → token → header) dan jadual metrik dashboard. |
| Momen kunci | (1) S1: replay `04-rakaman-mentah` → 401 di skrin; (2) S1: `csrf` salah → 403; (3) S2: ForEach 0 lelaran bila kotak "_" dinyahtanda; (4) S3: dashboard pertama dibuka; (5) S3: `-Jsla_ms=150` → Error % melonjak; (6) S4: gerbang SLA `kod keluar: 1` |
| Hasil wajib hujung hari | ≥ 85% peserta: Latihan 1 (korelasi 0% ralat) + Latihan 4 (dashboard dibuka) + Kuiz hari dihantar |
| Kemajuan dalam pelatih.my | JMeter berjalan di laptop peserta — LMS tidak nampak. Item terakhir setiap ✅ Checkpoint ditanda apabila **Kuiz S1–S4** lulus; "Isi penilaian kendiri Hari 2" ditanda oleh **Kuiz hari**. Ingatkan peserta menghantar kuiz di hujung setiap sesi. |

---

## ✅ Senarai semak sebelum kelas (malam sebelum / 8.15 pagi)

- [ ] **Java + JMeter 5.6** pada mesin demo: `java -version` (≥ 8; disyorkan 17) dan `jmeter --version` → 5.6.x.
- [ ] **Node.js** dipasang; `node sut/server.js` → `Portal eJPJ (TIRUAN) berjalan di http://localhost:3000`. Uji <http://localhost:3000/api/health>.
- [ ] **Internet tidak diperlukan** — SUT, plan, data dan laporan semuanya tempatan. (Hanya ⭐ Taurus/Grafana memerlukan muat turun — demo konsep sahaja.)
- [ ] Buka dalam tab JMeter: `hari-1/test-plans/01-hello-jpj.jmx`, `03-csv-berparameter.jmx`, `04-rakaman-mentah.jmx`, `hari-2/test-plans/04`–`08`.
- [ ] ⚠️ **Semak sasaran plan sebelum warm-up.** Klik **HTTP Request Defaults** setiap plan: Server mesti `localhost`, Port `3000`, Protocol `http`. Jadikan ini pengajaran etika: *"setiap plan yang dibuka — semak sasaran dahulu."*
- [ ] Jalankan pengesahan pantas (≈ 2 minit):
  ```bash
  node sut/server.js &
  jmeter -n -t hari-2/test-plans/04-korelasi-log-masuk.jmx -l /tmp/r4.jtl      # 45 sampel, 0% Err
  jmeter -n -t hari-2/test-plans/08-foreach-kenderaan.jmx  -l /tmp/r8.jtl      # 16 sampel, 0% Err
  jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=10 -Jrampup=2 -Jtempoh=8 -l /tmp/r7.jtl
  ```
- [ ] `hari-2/run/hasil/` dikosongkan (atau biarkan satu laporan contoh sedia dibuka sebagai sandaran).
- [ ] `jq` dipasang pada mesin demo (Latihan 7). Peserta Windows: blok PowerShell dalam lab.
- [ ] Pautan **Borang penilaian** dalam menu pelatih.my disahkan dibuka **2.00 ptg**.
- [ ] Senarai pasangan (pair) + kenal pasti 2–3 peserta yang ketinggalan Hari 1 (pasangkan dengan peserta kuat).

> ⚠️ **Risiko bilik:** setiap peserta menjalankan SUT **sendiri** pada `localhost:3000` — tiada server dikongsi. Latihan 5 (400 pengguna) membebankan laptop peserta; amaran awal supaya mereka menutup aplikasi berat. Jangan benarkan sesiapa menghalakan plan ke IP rakan tanpa persetujuan — itu juga "sistem orang lain".

---

## S1 · 9.00 – 10.30 pagi · Imbas Kembali & Korelasi (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 9.00–9.05 | 5 | Selamat datang semula. Agenda hari (jadual README). Kemajuan dalam pelatih.my = kuiz per sesi. | Tekankan: hari ini **realistik**, esok mereka boleh terangkan kepada pasukan. |
| 9.05–9.20 | 15 | **Warm-up Hari 1.** Semua: `cd sut && node server.js`. Buka `01-hello-jpj.jmx` → **semak HTTP Request Defaults bersama** (localhost/3000) → Start → # Samples. Buka `03-csv-berparameter.jmx` → Start → 5 no. pendaftaran berbeza. Soalan pantas README §1.1 (jadual 4 soalan). | Ini juga semakan pemasangan — sesiapa yang JMeter/Java rosak dikesan **sekarang**, bukan pada S3. |
| 9.20–9.30 | 10 | 🎬 **Demo replay gagal** (`hari-1/test-plans/04-rakaman-mentah.jmx`): log masuk 200 → `/api/kenderaan` 401 → bayar 401. Tanya: *"Mengapa?"* | **Momen kunci #1.** Tunjuk Terminal A/View Results Tree. Jangan beri jawapan terus — biar mereka teka "token luput". |
| 9.30–9.40 | 10 | §1.2–1.3 Korelasi vs parameterisasi (papan putih: `pengguna.csv` → log masuk → **`token`, `csrf`** → header/badan). §1.4 jadual 3 extractor. | Analogi: *"CSV ialah IC anda; token ialah nombor giliran kaunter — hanya kaunter yang tahu."* |
| 9.40–9.55 | 15 | 🎬 **Live build** §1.5: sampler log masuk → JSON Extractor `token;csrf` → Debug Sampler → GET dengan `Bearer ${token}` → bayar dengan `${csrf}`. | Taip perlahan. Tunjuk JSON Path Tester dalam View Results Tree. |
| 9.55–10.00 | 5 | 🎬 Eksperimen §1.7: `csrf` = `abc123` → **403**; token salah → **401**. | **Momen kunci #2.** *"Dua kod, dua punca — 401 siapa anda, 403 adakah permintaan ini sah."* |
| 10.00–10.25 | 25 | **Latihan 1** (pasangan). | Minit 10.10: ronda — isu #1 extractor di bawah Thread Group, isu #2 CSV tidak dijumpai (plan belum disimpan). Pasangan pantas → ⭐ Regex/Boundary. |
| 10.25–10.30 | 5 | Checkpoint + **Kuiz S1** dalam pelatih.my. | Jambatan: *"Kita boleh log masuk. Selepas rehat: kita jadikan ia satu transaksi pembaharuan cukai yang lengkap."* |

**Skrip ringkas (korelasi):**
> *"Bayangkan anda merakam video diri anda masuk ke bank dengan kad akses semalam. Hari ini anda tayang video itu kepada pengawal — pintu tidak terbuka, kerana kad semalam sudah dibatalkan. Itulah replay. Korelasi bermaksud: setiap kali masuk, ambil kad baharu dari kaunter, dan tunjukkan kad **itu** di setiap pintu."*

**Soalan untuk ditanya:**
- "Nilai mana dalam respons log masuk yang berubah setiap kali?" (`token`, `csrf`; `nama` tidak)
- "Jika 300 thread log masuk, berapa token wujud?" (300 — `vars` per thread)
- "Bila anda pilih Regex berbanding JSON Extractor?" (respons HTML/teks, header)
- "Di sistem JPJ sebenar, nilai dinamik apa lagi yang mungkin ada?" (cookie sesi, view-state, nonce pembayaran, ID transaksi FPX — **bincang sahaja**)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Rakaman cukup — JMeter akan urus token" | Perakam menyalin nilai literal; korelasi kerja manual (atau plugin) |
| "Letak extractor di mana-mana dalam Thread Group" | Skop mengikut kedudukan — anak sampler log masuk sahaja |
| "Default value kosong lebih kemas" | Default ketara (`TOKEN_TAK_JUMPA`) = alat nyahpepijat |
| "401 dan 403 sama sahaja" | 401 = identiti (token); 403 = kebenaran/permintaan (csrf) |

**✅ Sebelum bergerak ke S2:** ≥ 80% pasangan menunjukkan Debug Sampler dengan `token`/`csrf` sebenar dan bayaran `BERJAYA`.

---

## 10.30 – 10.45 pagi · Rehat

Biarkan SUT berjalan. Jurulatih: semak siapa masih merah pada Latihan 1 → beri `04-korelasi-log-masuk.jmx` untuk dikaji selepas rehat.

---

## S2 · 10.45 pagi – 1.00 tgh · Logic Controllers, ForEach & JSR223 Groovy (135 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 10.45–10.55 | 10 | §2.1 jadual Logic Controllers. Tanya: *"Di kaunter JPJ, apakah satu 'transaksi' dari sudut pelanggan?"* | Kaitkan Throughput Controller dengan campuran trafik sebenar (70% semak, 30% bayar). |
| 10.55–11.10 | 15 | 🎬 **Demo plan `05`**: Transaction Controller `Pembaharuan Cukai Jalan`, Generate parent sample (tidak ditanda vs ditanda), If Controller `${__groovy(...)}`, Uniform Random Timer 1–3 s. Jalankan → Summary Report baris transaksi. | Tunjuk bahawa masa transaksi ≈ jumlah 4 langkah (timer **tidak** dikira). |
| 11.10–11.40 | 30 | **Latihan 2 Bahagian A.** | Isu lazim: sampler di **bawah** controller, bukan **di dalam**; syarat If tanpa `${__groovy(...)}`. |
| 11.40–11.55 | 15 | 🎬 **Demo plan `08`** (ForEach): Match No. `-1` → Debug Sampler `no_pendaftaran_1/_2/_matchNr`. Nyahtanda *Add "_" before number?* → 0 lelaran, tiada ralat. | **Momen kunci #3.** *"Ujian yang tidak berbuat apa-apa tetapi hijau — paling berbahaya."* |
| 11.55–12.10 | 15 | **Latihan 2 Bahagian B.** | Sasaran: 16 sampel, 5 bayaran. |
| 12.10–12.25 | 15 | §2.6–2.7 JSR223 Groovy + fungsi. 🎬 Tampal PostProcessor; tukar path → `/api/log-masukX` → mesej tersuai merah. Tekankan *Cache compiled script* & `vars.get()` bukan `${}`. Jadual fungsi; `__P` sebagai jambatan ke S3. | Jangan ajar Groovy sebagai bahasa — tunjuk 5 objek (`vars`, `props`, `prev`, `ctx`, `log`) sahaja. |
| 12.25–12.50 | 25 | **Latihan 3.** | Pasangan lambat: langkah 1–4 + 7 sahaja (langkau PreProcessor). |
| 12.50–1.00 | 10 | Checkpoint + **Kuiz S2**. | Jambatan: *"Selepas makan, kita berhenti klik Start dalam GUI."* |

**Soalan untuk ditanya:**
- "Mengapa kita tidak menghantar bayaran apabila tiada kenderaan?" (Error % palsu, mencemarkan analisis)
- "Transaction Controller — patut termasuk think time?" (biasanya tidak; kita ukur sistem)
- "ForEach hijau tetapi tiada bayaran — bagaimana anda mengesannya?" (kiraan sampel dalam Summary Report; Debug Sampler `_matchNr`)
- "Mengapa `${__P(pengguna,50)}` lebih baik daripada 50?" (satu plan, banyak beban — S3)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "If Controller boleh terima `no_pendaftaran != NONE`" | Mesti nilai akhir `true`/`false` → `${__groovy(...)}` / `${__jexl3(...)}` |
| "Generate parent sample mesti ditanda" | Pilihan laporan; plan rujukan tidak menandanya untuk melihat setiap langkah |
| "BeanShell dan Groovy sama" | Groovy dikompil + cache; BeanShell ditafsir setiap kali — elak untuk beban |
| "`vars` dikongsi semua thread" | `vars` per thread; `props` global |

**✅ Sebelum bergerak ke S3:** ≥ 80% mempunyai baris transaksi dalam Summary Report; ≥ 60% selesai ForEach (selebihnya boleh kaji `08` dalam S4).

---

## 1.00 – 2.00 ptg · Makan tengah hari

Ingatkan: **jangan tutup Terminal A**. Jurulatih: sediakan `hari-2/run` dalam terminal besar; padam `hasil/` lama. **Borang penilaian kursus dibuka 2.00 ptg** — sebut sekali sebelum S3 bermula, dan sekali lagi di penutup.

---

## S3 · 2.00 – 3.30 ptg · Non-GUI, HTML Dashboard & SLA (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 2.00–2.05 | 5 | Tenaga: *"Siapa pernah lihat sistem 'jatuh' pada hari terakhir bayar sesuatu?"* Maklumkan borang penilaian sudah dibuka (isi sebelum tamat). | |
| 2.05–2.15 | 10 | §3.1–3.2 Non-GUI: jadual bendera. 🎬 `./run-nogui.sh` dengan `PENGGUNA=50 TEMPOH=60` — baris `summary +` setiap 30 s. | Tunjuk `__P` dalam `06` → `-J` dalam wrapper. |
| 2.15–2.30 | 15 | 🎬 **Buka dashboard** (momen kunci #4): APDEX → Statistics (90/95/99) → Errors → Response Times Over Time → Active Threads → TPS. §3.3 jadual metrik; response time vs latency vs connect. | Papan putih: graf p95 vs average dengan "ekor" lambat. |
| 2.30–2.45 | 15 | **Latihan 4.** | Isu: folder `-o` tidak kosong; `chmod +x`. Windows → `run-nogui.bat`. |
| 2.45–2.55 | 10 | §3.4–3.5 NFR dalam percentile + titik pecah (rajah Mermaid). **Latihan 5** dimulakan — setiap pasangan pilih **satu** tahap (50 / 150 / 400) dan kongsi angka di papan putih. | Membahagi tahap antara pasangan menjimatkan masa — kelas membina jadual bersama. |
| 2.55–3.10 | 15 | §3.6 🎬 **Demo plan `07`** — lihat skrip demo di bawah (SLA 2000 → 150). | **Momen kunci #5.** |
| 3.10–3.25 | 15 | **Latihan 6** (`-Jtempoh=120`, atau 60 jika kelas lambat). | Laptop lemah: `-Jpengguna=100`. |
| 3.25–3.30 | 5 | Checkpoint + **Kuiz S3**. | |

**Soalan untuk ditanya:**
- "Average 350 ms, p95 2900 ms — lulus NFR p95 < 1500?" (tidak — ekor lambat)
- "Throughput mendatar walaupun pengguna bertambah — maksudnya?" (kesesakan; sistem tepu)
- "APDEX 0.75 — baik atau buruk?" (sederhana; banyak Tolerating/Frustrated)
- "Error % 5% pada 50 pengguna dengan `ERROR_RATE=0.05` — beban atau asas?" (asas; lihat trend)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Lebih banyak pengguna = lebih banyak throughput selamanya" | Throughput mendatar pada kapasiti; selepas itu masa respons naik |
| "APDEX menanda sampel gagal" | APDEX ialah skor kepuasan; kegagalan datang daripada assertion/kod HTTP |
| "Latency = response time" | Latency = bait pertama; response time = respons penuh |
| "Laptop JMeter boleh simulasi 10,000 pengguna" | Penjana beban sendiri ada had — pantau CPU; teragih untuk beban besar |

**✅ Sebelum bergerak ke S4:** ≥ 85% telah membuka dashboard sendiri; jadual titik pecah kelas lengkap di papan putih; ≥ 60% telah menjalankan `07` dengan dua nilai `sla_ms`.

---

## 3.30 – 3.45 ptg · Rehat

Jurulatih: ambil gambar jadual titik pecah di papan putih (untuk penutup). Semak berapa yang sudah isi borang penilaian.

---

## S4 · 3.45 – 5.00 ptg · Distributed, CI/CD, Grafana & Penutup (75 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 3.45–3.55 | 10 | §4.1 Distributed: rajah controller → worker → SUT di papan. `-R`, `-G` vs `-J`, CSV di setiap worker, RMI SSL. | Konsep sahaja. Tanya: *"100 thread × 3 worker = ?"* |
| 3.55–4.05 | 10 | §4.2 CI/CD: `jmeter -n` keluar 0 walaupun ralat → gerbang. 🎬 `jq` pada `statistics.json`, kemudian `semak-sla.sh` pada `laporan7` (LULUS, kod 0) dan `laporan7-sla150` (GAGAL, kod 1). | **Momen kunci #6.** *"Inilah yang Jenkins faham: kod keluar."* |
| 4.05–4.10 | 5 | §4.3 Backend Listener + InfluxDB + Grafana (gambar/penerangan); HTML dashboard = bedah siasat, Grafana = pemantauan semasa. | Tiada demo langsung (perlukan Docker). |
| 4.10–4.25 | 15 | **Latihan 7** (gerbang SLA). | Pasangan Windows: blok PowerShell. Tiada `jq`? Guna PowerShell atau tunjuk di skrin jurulatih. |
| 4.25–4.30 | 5 | §4.4 Amalan terbaik — baca jadual dengan kelas; tekankan baris terakhir (etika). | Tanya JPJ: *"Siapa dalam organisasi anda yang memberi kebenaran bertulis untuk ujian beban?"* |
| 4.30–4.45 | 15 | §4.5 **Mini-demo capstone** — 3–4 pasangan, 3 minit setiap satu. | Pilih sukarelawan; jika masa singkat, 2 pasangan sahaja. |
| 4.45–4.55 | 10 | **Penutup** (lihat di bawah): rumusan 2 hari (§4.6), borang penilaian, Kuiz S4 + Kuiz hari, sijil. | |
| 4.55–5.00 | 5 | Soal jawab terbuka & bersurai. | |

**Penutup — skrip (10 minit):**
1. **Rumusan 2 hari** — tunjuk jadual §4.6. *"Hari 1 anda belajar menjana beban. Hari 2 anda belajar menjana beban yang **betul**, dan membaca apa yang ia beritahu."*
2. Tunjuk gambar jadual titik pecah kelas: *"Inilah output yang pengurusan mahu — 'sistem selamat sehingga N pengguna'."*
3. **Borang penilaian kursus:** *"Borang penilaian kursus dibuka 2.00 ptg; isi sebelum tamat."* Dalam pelatih.my → menu **Borang penilaian**. Beri 3 minit di dalam kelas — jangan tinggalkan untuk "nanti".
4. **Kuiz S4 + Kuiz hari — Penilaian kendiri Hari 2**: hantar sekarang; ia melengkapkan checkpoint lab dan item "Isi penilaian kendiri Hari 2".
5. **Sijil:** sijil penyertaan dikeluarkan oleh penganjur selepas kehadiran dan borang penilaian disahkan — jangan janji tarikh yang anda tidak kawal.
6. **Mesej akhir etika:** *"Repo ini, SUT ini — bawa pulang. Tetapi sebelum anda menghalakan JMeter ke sistem JPJ sebenar: kebenaran bertulis, staging, tetingkap masa, dan pasukan infra memantau bersama."*

**Soalan untuk ditanya:**
- "Kenapa *build* hijau walaupun Error % 12%?" (kod keluar JMeter 0)
- "`-J` atau `-G` untuk worker?" (`-G`)
- "Apa satu perkara yang anda akan ubah dalam cara pasukan anda menguji selepas kursus ini?"

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Distributed membahagi thread antara worker" | Setiap worker menjalankan **seluruh** Thread Group |
| "CI akan gagal sendiri bila ujian gagal" | Perlu gerbang (skrip, Taurus `passfail`, plugin) |
| "Grafana menggantikan HTML dashboard" | Saling melengkapi: semasa vs selepas |
| "Ujian beban kecil ke sistem awam tidak mengapa" | Saiz tidak relevan — kebenaran bertulis wajib |

**✅ Kriteria tamat hari:** ≥ 85% hantar Kuiz hari; borang penilaian diisi oleh semua; sekurang-kurangnya 2 mini-demo dibentangkan.

---

## 🎬 Skrip demo setiap plan

### Plan `04-korelasi-log-masuk.jmx` (S1, ~5 minit)
1. Tunjuk pokok: CSV `pengguna.csv` → `POST /api/log-masuk` → **Ekstrak token + csrf** → `GET /api/kenderaan (Bearer token)` → `POST /api/kenderaan/WXY1234/bayar-cukai` → Think Time 500ms → View Results Tree.
2. Start (5 pengguna × 3 gelung = 45 sampel). Klik sampler bayar → **Request**: `Authorization: Bearer 3f…`, badan `"csrf": "a9…"`.
3. Tukar `${csrf}` → `abc123` → **403** di skrin. Pulihkan. *"Satu medan, seluruh transaksi gagal."*

### Plan `05-transaksi-penuh.jmx` (S2, ~5 minit)
1. Tunjuk `Pembaharuan Cukai Jalan` → `Jika ada kenderaan` → `3. GET …/${no_pendaftaran}/cukai` → `4. POST …/bayar-cukai` (`"amaun": ${amaun}`).
2. Start (10 × 2). Summary Report: baris transaksi ≈ jumlah 4 langkah.
3. Jika muncul 1 ralat 500: *"Itu `ERROR_RATE` 1% SUT — sengaja. Dashboard akan memberitahu kita di mana."*

### Plan `08-foreach-kenderaan.jmx` (S2, ~5 minit)
1. Tambah Debug Sampler selepas GET kenderaan. Start → `no_pendaftaran_matchNr=2` untuk `800101015500`.
2. Summary Report: 16 sampel HTTP (3 log masuk + 3 senarai + 5 sebut harga + 5 bayar), tidak termasuk baris transaksi `Bayar Cukai Semua Kenderaan`.
3. Nyahtanda *Add "_" before number?* → Start → hanya 6 sampel HTTP (log masuk + senarai), **0 ralat**. Tanda semula.

### Plan `06-ujian-beban-nogui.jmx` (S3, ~8 minit)
```bash
cd hari-2/run
PENGGUNA=50 RAMPUP=10 TEMPOH=60 ./run-nogui.sh
```
Sementara menunggu, tunjuk `__P` dalam Thread Group. Buka `hasil/<cap-masa>/laporan/index.html`. Laluan: APDEX → Statistics → Errors → Over Time.

### Plan `07-beban-puncak-cukai.jmx` — demo pelanggaran SLA (S3, ~10 minit)
1. Jalankan dengan SLA lalai (beban kecil supaya pantas):
   ```bash
   cd hari-2/run
   jmeter -n -t ../test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
     -l hasil/demo7.jtl -e -o hasil/demo7
   ```
   Dashboard: Error % ≈ 0 (mungkin sedikit akibat 500 sintetik).
2. Turunkan SLA — latensi SUT ialah 40–180 ms, jadi `150` memotong ekor taburan:
   ```bash
   jmeter -n -t ../test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=150 \
     -l hasil/demo7-150.jtl -e -o hasil/demo7-150
   ```
   Dashboard: **Top 5 Errors** → `The operation lasted too long: It took … milliseconds, but should not have lasted longer than 150 milliseconds.` Error % langkah bayar dan transaksi naik (ujian kami: `-Jsla_ms=100` pada 10 pengguna → ~9% Err keseluruhan, ~37% transaksi gagal).
3. Mesej: *"Pelayan sama, kod sama. Yang berubah ialah **definisi kita tentang 'cukup laju'**. Itulah mengapa NFR mesti dipersetujui **sebelum** ujian."*
4. Pilihan dramatik: mulakan semula SUT dengan `LATENCY_MIN=1500 LATENCY_MAX=3000 node server.js` dan jalankan dengan `-Jsla_ms=2000` — SLA lalai kini gagal tanpa mengubah plan.

---

## 🧯 Pelan kejar (catch-up)

| Situasi | Tindakan |
|---------|----------|
| JMeter/Java rosak pada laptop peserta (dikesan semasa warm-up) | Pasangkan dengan rakan serta-merta; baiki semasa rehat 10.30 (rujuk Hari 1 — Persediaan). Jangan berhenti kelas. |
| SUT tidak boleh dijalankan (Node tiada) | Peserta guna SUT rakan sebelah **dengan persetujuan** — tukar HTTP Request Defaults ke IP rakan, pulihkan `localhost` selepas itu. Plan `06`/`07`: `-Jhost=<ip>`. |
| Ketinggalan Latihan 1 > 15 minit | Buka `04-korelasi-log-masuk.jmx`, jalankan, dan **terangkan** setiap elemen kepada pasangan. Membina sendiri boleh jadi kerja rumah. |
| Ketinggalan S2 | Latihan 2 A wajib (baris transaksi). Latihan 2 B: kaji `08` sahaja. Latihan 3: langkah 1–4 + 7. |
| Kelas lewat menjelang S3 | Latihan 5: setiap pasangan satu tahap beban sahaja (jadual dikongsi). Latihan 6: `-Jtempoh=60`, `-Jpengguna=100`. |
| Kelas lewat menjelang S4 | Latihan 7: jurulatih tunjuk `semak-sla.sh` di skrin; peserta jalankan `jq` sahaja. Kurangkan mini-demo kepada 2 pasangan. **Jangan** potong penutup + borang penilaian. |
| Laptop terlalu perlahan untuk 300/400 pengguna | Kurangkan kepada 100/150; konsep titik pecah tetap kelihatan (bandingkan trend). |
| Peserta pantas / berpengalaman | ⭐ Regex/Boundary (Lab 1), Throughput Controller saman (Lab 2), JSR223 Assertion (Lab 3), Taurus `passfail` (Lab 7), bantu pasangan lain. |

## 📋 Semakan akhir hari (jurulatih)

- [ ] Rekod bilangan peserta yang menghantar Kuiz hari (sasaran ≥ 85%)
- [ ] Sahkan borang penilaian kursus diisi oleh semua peserta (menu **Borang penilaian** pelatih.my)
- [ ] Simpan gambar jadual titik pecah kelas + soalan yang tidak terjawab (untuk e-mel susulan)
- [ ] Hentikan SUT; padam `hari-2/run/hasil/` pada mesin demo
- [ ] Maklumkan penganjur senarai kehadiran untuk sijil
- [ ] Laporkan isu bahan yang ditemui supaya repo dibetulkan sebelum kelas seterusnya
