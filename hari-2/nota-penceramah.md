# Nota Penceramah — Hari 2: Rakam & Main Balik, Laporan Prestasi & Merancang Ujian

[📖 README Hari 2](./README.md) · [🧪 Lab](./snippets/lab.md) · [📋 Templat Pelan Ujian](./snippets/templat-pelan-ujian.md) · [📝 Templat Laporan Ujian](./snippets/templat-laporan-ujian.md) · [🗂️ Test plans](./test-plans/) · [⬅️ README Hari 1](../hari-1/README.md)

> **Mesej teras hari ini:**
> 1. **"Rakaman ialah titik mula, bukan produk siap."** Perakam menyalin apa yang dilihat — termasuk token yang akan luput.
> 2. **"Hijau ≠ betul."** Main balik yang lulus tanpa restart SUT, atau 200 tanpa assertion, ialah lulus palsu.
> 3. **"Laporan ialah produk anda."** Setiap angka dashboard mesti boleh diterangkan dengan istilah yang betul.
> 4. **"Percentile, baseline, NFR — dalam tertib itu."** Purata menipu; satu larian tanpa baseline tiada makna; NFR dipersetujui **sebelum** ujian.
> 5. **"Bilangan pengguna dikira, bukan diteka."** N = X × (R + Z).
> 6. **"Hanya sasaran yang dibenarkan secara bertulis."** Klien kita ialah JPJ — mereka mesti keluar dengan refleks ini.

## Ringkasan penyampai

| Perkara | Nilai |
|---------|-------|
| Klien | JPJ — Jabatan Pengangkutan Jalan Malaysia. Senario (cukai jalan, saman, no. pendaftaran) ialah dunia mereka; jemput mereka mengaitkan dengan sistem sebenar **secara lisan**, bukan dengan menguji sistem sebenar. |
| Tarikh & konteks | Hari 2: **Isnin, 5 Okt 2026**. Hari 1 diajar pada **21 Sep** — dua minggu lalu. Imbas kembali 10 minit sahaja; pemasangan rosak dikesan di S1. |
| Fokus (permintaan penganjur) | **Rakam & main balik untuk menghasilkan laporan**, **penerangan laporan & istilah**, dan **cara merancang ujian**. Korelasi diajar sebagai alat untuk menjadikan rakaman boleh dimain balik — bukan topik berdiri sendiri. Logic controller lanjutan, JSR223, CI, distributed, Grafana = ⭐ sekilas. |
| Nisbah | S1 ~40% demo/penerangan · S2 ~35% · S3 ~55% (dashboard & istilah) · S4 ~45% · selebihnya lab |
| Bahan | Projektor dua panel: Terminal A (log SUT) + JMeter GUI / pelayar (dashboard). Papan putih: perjalanan pengguna 4 langkah, jadual 401/403, formula APDEX, Little's Law. |
| Momen kunci | (1) S1: main balik tanpa restart = **semua hijau** → restart → 200/401/200/401; (2) S1: token sahaja dikorelasi → **403**; (3) S2: Aggregate Report 80 + 20, transaksi ≈ 440 ms walaupun think time 1–3 s; (4) S3: graf Over Time 1 titik → jana semula `-g` dengan butiran 5 s; (5) S3: SLA 150 ms → Error % 1% → 22% tanpa sistem berubah; (6) S4: Little's Law meramal 46 pengguna daripada laporan; (7) S3 §3.9: purata gabungan 363 ms menyembunyikan PENANG p95 ≈ 890 ms |
| Hasil wajib hujung hari | ≥ 85% peserta: Latihan 3 (plan boleh dimain balik) + Latihan 4 (lembaran kerja dashboard) + Latihan 6 (pelan dengan pengiraan N) + Kuiz hari dihantar |
| Kemajuan dalam pelatih.my | JMeter berjalan di laptop peserta — LMS tidak nampak. Item terakhir setiap ✅ Checkpoint ditanda apabila **Kuiz S1–S4** lulus; "Isi penilaian kendiri Hari 2" ditanda oleh **Kuiz hari**. Ingatkan peserta menghantar kuiz di hujung setiap sesi. |

### Angka sebenar untuk dirujuk (disahkan dengan JMeter 5.6.3 pada mock, 4 Okt 2026)

| Larian | Angka |
|--------|-------|
| `04-rakaman-mentah.jmx` (main balik) | 3 sampel, Err 2 (66.67%); Errors: `401/Unauthorized` 2 · 100% · 66.67% |
| `05-transaksi-penuh.jmx` (10 × 2) | 80 sampel HTTP + 20 transaksi; 0% ralat; transaksi Avg ≈ 442 ms, p95 ≈ 561 ms; APDEX transaksi 0.875, Total 0.975 |
| `07` R1 (`-Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000`) | Total 2432 sampel, 41.29/s, Err 0.25% (6 × 500); transaksi 598, **10.46/s**, Avg 446, p95 **583**, Err **1.00%**; APDEX Total 0.971, transaksi 0.862 |
| `07` R2 (sama, `-Jsla_ms=150`) | Total Err 5.37%; transaksi Err **21.75%**, p95 572; bayar-cukai 19–26%; APDEX transaksi 0.717; ~30 baris berbeza `The operation lasted too long…` dalam Errors |
| `07` R3 (mock perlahan port 3001, 500–1500 ms) | Total 22.78/s; transaksi **5.78/s**, Avg 3954, p95 **4969**; APDEX Total 0.401 |
| Little's Law | R1: 10.46 × (0.446 + 4.0) ≈ 46.5 · R3: 5.78 × (3.954 + 4.0) ≈ 46.0 · purata thread aktif ≈ 45.8 (ramp-up 10 s) |
| Constant Throughput Timer 300/min (shared, current TG) sebagai anak log masuk | log masuk 5.39/s ≈ 323/min |
| `09` teragih (`run-berbilang-lokasi.sh`, 10 × 3 setiap ejen, 2 ejen) | Gabungan 240 sampel HTTP, 0% ralat, Avg 363, p95 873, 6.90/s; transaksi KL Avg 476 / p95 640; PENANG Avg 2430 / p95 3000; langkah p95 KL 175–180, PENANG 886–896; Active Threads: 2 siri (`127.0.0.1:1099-…`, `127.0.0.1:1100-…`) |

> Angka peserta akan berbeza sedikit (latensi mock rawak 40–180 ms, `ERROR_RATE` 1%). Tekankan **corak**, bukan nilai tepat.

---

## ✅ Senarai semak sebelum kelas (malam sebelum / 8.15 pagi)

- [ ] **Java + JMeter 5.6** pada mesin demo: `java -version` (≥ 8; disyorkan 17) dan `jmeter --version` → 5.6.x.
- [ ] **Mulakan SUT:** `node sut/server.js` → `Portal eJPJ (TIRUAN) berjalan di http://localhost:3000`. Uji <http://localhost:3000/api/health>.
- [ ] **Port perakam 8888 bebas:** `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (tiada output) / Windows `netstat -ano | findstr :8888`. Tutup Burp/Fiddler/proxy lain.
- [ ] **curl melalui proxy:** buka `hari-1/test-plans/rakam-template.jmx` → Start perakam → `curl -s -x http://localhost:8888 http://localhost:3000/api/health` → satu sampler muncul dalam Recording Controller. Stop. Jangan simpan perubahan pada templat.
- [ ] **Peserta Windows:** Git Bash dipasang (blok curl dalam README §1.4 ialah bash). Tanpa Git Bash → guna `04-rakaman-mentah.jmx` sebagai rakaman (pelan kejar).
- [ ] **Proxy pelayar:** hanya jika anda mahu menunjukkan rakaman pelayar (Firefox → Manual proxy `localhost:8888`, kosongkan *No proxy for*). SUT tiada borang web, jadi demo utama guna curl. **Sijil CA hanya untuk HTTPS** — SUT `http://`, tidak perlu.
- [ ] **Sandaran laporan:** jalankan sekali R1, R2 (dan R3) pada mesin demo ke `hasil/` (arahan dalam README §3.7) — jika larian langsung gagal, buka laporan sandaran.
  ```bash
  mkdir -p hasil
  jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
    -l hasil/r07-sla2000.jtl -e -o hasil/laporan07-sla2000 -Jjmeter.reportgenerator.overall_granularity=5000
  ```
- [ ] **Internet tidak diperlukan** — SUT, plan, data dan laporan semuanya tempatan.
- [ ] Cetak / kongsi `templat-pelan-ujian.md` dan `templat-laporan-ujian.md` (atau pastikan peserta boleh membukanya).
- [ ] ⚠️ **Semak sasaran setiap plan yang akan dibuka:** HTTP Request Defaults → `localhost` / `3000` / `http`. Jadikan ini pengajaran etika.
- [ ] Pautan **Borang penilaian** dalam menu pelatih.my disahkan dibuka **2.00 ptg**.
- [ ] Senarai pasangan (pair) + kenal pasti 2–3 peserta yang ketinggalan Hari 1 (pasangkan dengan peserta kuat).

> ⚠️ **Risiko bilik:** setiap peserta menjalankan SUT **sendiri** pada `localhost:3000` dan perakam **sendiri** pada `localhost:8888`. Jangan benarkan sesiapa menghalakan curl/proxy/plan ke IP rakan tanpa persetujuan — itu juga "sistem orang lain". Larian `07` 50 pengguna × 60 s ringan untuk laptop biasa; jangan naikkan ke lalai 300 × 300 s di kelas.

---

## S1 · 9.00 – 10.30 pagi · Rakam & Main Balik (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 9.00–9.05 | 5 | Selamat datang semula. Agenda hari (jadual README): *"Hari ini kita buat kerja jurutera prestasi dari rakaman sampai laporan dan pelan."* Kemajuan pelatih.my = kuiz per sesi. | Sebut terus: laporan & perancangan ialah fokus petang. |
| 9.05–9.15 | 10 | **Imbas kembali Hari 1** (§1.1): semua jalankan `node sut/server.js`; buka `04-rakaman-mentah.jmx` → **semak HTTP Request Defaults bersama** → Start → 1 hijau, 2 merah. Jadual 4 soalan pantas. | Ini juga semakan pemasangan — JMeter/Java/Node rosak dikesan **sekarang**. |
| 9.15–9.25 | 10 | **§1.2 Rancang dahulu** — papan putih: 4 langkah, nama `T01…T04`, bulatkan data dinamik. Tanya: *"Satu klik 'Bayar' di portal sebenar — berapa permintaan?"* | Konsep "satu tindakan = satu transaksi". |
| 9.25–9.40 | 15 | 🎬 **Demo §1.3–1.5**: Save As `latihan-01-rakaman.jmx`; HTTP Request Defaults; Grouping → *Put each group in a new transaction controller*; Excludes (+ analitik); Constant Timer `${T}`; Start; dialog *Recorder: Transactions Control* (taip `T01_LogMasuk`); jalankan blok curl dengan `sleep 6`; Stop. Kembangkan pokok: nama `/api/log-masuk-1`, Header Manager dengan `Authorization: Bearer …` dikeras-kod, badan `csrf` literal, timer ≈ 6000 ms. | Tunjuk `lsof … :8888`. Tekankan: *"Perakam menyimpan Bearer token sebagai teks tetap; Cookie pula dibuang — aplikasi cookie perlukan Cookie Manager."* |
| 9.40–10.00 | 20 | **Latihan 1** (pasangan). | Ronda: isu #1 lupa Start / lupa `-x $P` → tiada sampler; isu #2 semua dalam satu kumpulan (tidak tunggu 5 s). Pasangan pantas → ⭐ format string. |
| 10.00–10.10 | 10 | 🎬 **Demo main balik** (momen kunci #1): Start **tanpa** restart → semua hijau. *"Siap untuk 300 pengguna?"* Biar mereka jawab. Restart SUT → Start → 200/401/200/401. VRT: Sampler result → Request → Response data. Kemudian korelasi `token` sahaja → **403** (momen kunci #2). | *"401 = siapa anda; 403 = adakah permintaan ini sah."* Tanya kenapa `T03` hijau (tiada token diperlukan) → perlunya assertion. |
| 10.10–10.25 | 15 | **Latihan 2.** | Jika rakaman peserta gagal → guna `04-rakaman-mentah.jmx` (pelan kejar). |
| 10.25–10.30 | 5 | Checkpoint + **Kuiz S1**. | Jambatan: *"Selepas rehat kita baiki rakaman ini sehingga boleh dimain balik oleh 10, 50, 300 pengguna."* |

**Skrip ringkas (main balik):**
> *"Bayangkan anda merakam video diri anda masuk ke bank dengan kad akses semalam. Hari ini anda tayang video itu kepada pengawal — pintu tidak terbuka, kerana kad semalam sudah dibatalkan. Itulah main balik rakaman. Tetapi jika bank lupa membatalkan kad semalam, pintu terbuka — dan anda fikir video anda 'berjaya'. Itulah lulus palsu."*

**Soalan untuk ditanya:**
- "Kenapa kita tunggu 6 saat antara langkah?" (`proxy.pause` 5 s → kumpulan baharu)
- "Apa yang `${T}` rakam?" (jurang masa sebenar antara permintaan)
- "Kenapa semua hijau sebelum restart?" (sesi rakaman masih hidup dalam memori mock)
- "Di sistem JPJ sebenar, nilai dinamik apa lagi?" (cookie sesi, view-state, nonce pembayaran, ID transaksi FPX — **bincang sahaja**)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Perakam akan uruskan token" | Perakam menyalin nilai literal; korelasi kerja kita (S2) |
| "Semua hijau = skrip betul" | Lulus palsu: sesi rakaman masih sah; 200 tanpa assertion |
| "Rakam dengan pelayar biasa sahaja" | Pelayar mesti dihalakan ke proxy 8888; SUT ini API → curl |
| "Perlu sijil CA untuk merakam" | Hanya untuk HTTPS |
| "401 dan 403 sama sahaja" | 401 = token (identiti); 403 = csrf (kesahihan permintaan) |

**✅ Sebelum bergerak ke S2:** ≥ 80% pasangan mempunyai rakaman 4 langkah (sendiri atau `04-rakaman-mentah`) dan boleh menerangkan 401 vs 403.

---

## 10.30 – 10.45 pagi · Rehat

Biarkan SUT berjalan. Jurulatih: semak siapa tiada rakaman → beri `04-rakaman-mentah.jmx` (Save As ke `hari-2/test-plans/`) untuk S2.

---

## S2 · 10.45 – 1.00 tgh · Jadikan Rakaman Boleh Dimain Balik (135 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 10.45–10.55 | 10 | §2.1 senarai semak 10 perkara (tunjuk pada rakaman di skrin) + §2.2 parameterisasi vs korelasi. | Analogi: *"CSV ialah IC anda; token ialah nombor giliran kaunter — hanya kaunter yang tahu."* |
| 10.55–11.15 | 20 | 🎬 **Live build** §2.3–2.5: JSON Extractor `token;csrf` + default `TOKEN_TAK_JUMPA` → `Bearer ${token}` / `${csrf}` → CSV `pengguna.csv` → extractor kenderaan `$.kenderaan[0]…` → path `${no_pendaftaran}`. Tunjuk JSON Path Tester + Debug Sampler. | Taip perlahan. Tekankan skop extractor (anak sampler) dan kedudukan `.jmx` (laluan CSV relatif). |
| 11.15–11.25 | 10 | 🎬 §2.6–2.8: nama sampler, Transaction Controller (Generate parent sample — tunjuk dua-dua), padam timer `${T}`, Uniform Random Timer, Response Assertion, If Controller. | Tanya: *"Timer di bawah TC dengan 4 sampler — berapa jeda?"* (4) |
| 11.25–12.20 | 55 | **Latihan 3.** Ujian fungsian 1 × 1 dahulu, kemudian 10 × 2. | Isu lazim: CSV tidak dijumpai (plan bukan dalam `hari-2/test-plans/`), extractor bukan anak, timer rakaman 6 s masih ada (larian "tergantung"). Minit 12.00: pasangan yang tersekat → buka `05` dan bandingkan elemen demi elemen. |
| 12.20–12.35 | 15 | 🎬 Jalankan `05` (10 × 2): Summary vs Aggregate — setiap lajur (§2.9). 80 + 20; transaksi ≈ 440 ms walaupun think time. | **Momen kunci #3.** *"Masa transaksi = masa sistem; think time mempengaruhi throughput, bukan response time."* — jambatan ke Little's Law. |
| 12.35–12.50 | 15 | ⭐ Sekilas §2.10: `08` ForEach (Match `-1`, *Add "_" before number ?* → 0 lelaran tanpa ralat) + JSR223 (Cache, `vars.get`). **Atau** masa kejar untuk Latihan 3. | Pilih ikut kemajuan kelas — Latihan 3 lebih penting. |
| 12.50–1.00 | 10 | Checkpoint + **Kuiz S2**. | Jambatan: *"Selepas makan: kita berhenti melihat GUI dan mula membaca laporan seperti pengurusan membacanya."* |

**Soalan untuk ditanya:**
- "Mengapa default extractor `TOKEN_TAK_JUMPA`, bukan kosong?" (kegagalan kelihatan dalam tab Request)
- "300 thread log masuk — berapa token?" (300; `vars` per thread)
- "Kenapa If Controller sebelum bayar?" (elak bayaran palsu yang mencemarkan Error %)
- "Kenapa satu baris setiap kenderaan dalam Aggregate Report?" (label dinamik `${no_pendaftaran}`)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Letak extractor di mana-mana dalam Thread Group" | Skop mengikut kedudukan — anak sampler log masuk |
| "Biarkan timer `${T}` rakaman — ia realistik" | Ia think time **anda**, sama untuk semua thread → pengguna bergerak serentak; guna timer rawak |
| "Transaksi patut termasuk think time" | Biasanya tidak — kita ukur masa sistem |
| "Aggregate & Summary Report sama" | Aggregate ada Median & 90/95/99% Line; Summary ada Std. Dev. & Avg. Bytes |

**✅ Sebelum bergerak ke S3:** ≥ 80% mempunyai plan yang memberi baris transaksi `Pembaharuan Cukai Jalan` dengan Error % ≈ 0 (sendiri atau `05`).

---

## 1.00 – 2.00 ptg · Makan tengah hari

Ingatkan: **jangan tutup Terminal A**. Jurulatih: buka laporan sandaran R1/R2/R3 dalam tab pelayar. **Borang penilaian kursus dibuka 2.00 ptg** — sebut sekali di awal S3, dan sekali lagi di penutup.

---

## S3 · 2.00 – 3.30 ptg · Laporan & Istilah (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 2.00–2.05 | 5 | Tenaga: *"Siapa pernah diminta 'buat laporan' daripada tangkap layar?"* Maklumkan borang penilaian sudah dibuka. | |
| 2.05–2.13 | 8 | 🎬 §3.1: `mkdir -p hasil` → `jmeter -n -t …05… -l … -e -o …` → buka `index.html`. Kemudian `-g` ke folder baharu dengan `overall_granularity=5000`. Tunjuk ralat `folder is not empty`. Anatomi `.jtl` (buka dalam editor). | Jika lupa `mkdir`: ralat `parent folder is not writable` — tunjuk sebagai pengajaran. |
| 2.13–2.25 | 12 | 🎬 **Lawatan dashboard** (§3.2–3.3, **dipendekkan**) menggunakan laporan sandaran R1: Test and Report information → APDEX (formula di papan; gagal = Frustrated) → Statistics (Total ≠ transaksi) → Errors/Top 5 → **3 graf sahaja**: Active Threads, Response Times Over Time, Total TPS (+ Codes/s untuk R2). Graf lain = rujukan README §3.3 / Latihan 4. | **Momen kunci #4.** Tunjuk laporan butiran 60 s (1 titik) vs 5 s. Satu soalan setiap graf. |
| 2.25–2.38 | 13 | **Latihan 4** — lembaran kerja (pasangan pantas lengkapkan 14 baris; lain-lain sekurang-kurangnya 8). | Pasangan pantas → bandingkan `statistics.json` dengan jadual. |
| 2.38–2.45 | 7 | §3.5 glosari (pilih 6: response time / latency, throughput / TPS, percentile vs average, APDEX, saturation) + §3.6 jadual corak. Contoh "average menipu" di papan. | Glosari ialah rujukan — jangan baca semua baris. |
| 2.45–2.48 | 3 | 🎬 §3.7: lancarkan R1 & R2 (60 s setiap satu) — terangkan Duration Assertion semasa menunggu. | Peserta mula Latihan 5 serentak. |
| 2.48–3.05 | 17 | **Latihan 5** — larian + jadual perbandingan + **2** dapatan dalam kelas (dapatan ke-3 kerja rumah). Tunjuk contoh bahagian B `templat-laporan-ujian.md`. | **Momen kunci #5:** R2 — Error % 1% → 22% tanpa sistem berubah. *"Yang berubah hanya definisi 'cukup laju'."* |
| 3.05–3.12 | 7 | 🎬 **§3.9 Laporan berbilang lokasi** — demo `./run-berbilang-lokasi.sh` (skrip di bawah). | **Momen kunci #7:** purata gabungan 363 ms "OK" — PENANG p95 ≈ 890 ms gagal. |
| 3.12–3.25 | 13 | **Latihan 8** — jalankan skrip, buka 3 laporan, isi lembaran perbandingan, 2 dapatan lokasi. | Peserta lambat: guna laporan jurulatih (kongsi skrin) dan isi lembaran sahaja. Pastikan SUT Terminal A dihentikan dahulu (port 3000). |
| 3.25–3.30 | 5 | Checkpoint + **Kuiz S3**. | |

**Skrip ringkas (percentile):**
> *"Jika 100 rakyat memperbaharui cukai dan purata 300 ms, kita tidak tahu apa-apa tentang rakyat yang paling lambat. p95 583 ms bermaksud: 95 orang selesai dalam 0.6 saat, 5 orang lebih lama. NFR yang baik melindungi 5 orang itu."*

**🎬 Skrip demo §3.9 (7 minit) — laporan berbilang lokasi:**

Sebelum kelas: jalankan sekali `cd hari-2/run && ./run-berbilang-lokasi.sh` untuk memanaskan JVM dan menyimpan laporan sandaran. Semasa demo: **hentikan SUT Terminal A** (skrip guna port 3000/3001/1099/1100/4001/4002).

1. *(1 min)* Papan putih: controller + 2 ejen (KL 1099, PENANG 1100). *"JPJ meletakkan penjana beban di beberapa negeri — satu ujian, dua lokasi. Ejen menjana beban; controller hanya mengumpul."*
2. *(2 min)* `./run-berbilang-lokasi.sh` (≈ 45 s). Semasa berjalan, tunjuk dalam skrip: `-Jsite=KL` pada ejen (setempat) vs `-Gpengguna=10` pada controller (semua ejen) → **10 × 2 = 20 pengguna**. Tunjuk `summary +` yang datang berlonggok: *"sample sender StrippedBatch — sampel dihantar balik berkelompok."*
3. *(2 min)* `laporan/gabungan`: Statistics — baris `[KL]` & `[PENANG]`; Active Threads Over Time — **dua siri** `127.0.0.1:1099-…` dan `127.0.0.1:1100-…` (bukti kedua-dua ejen berjalan). Total: purata 363 ms.
4. *(2 min)* Jadual perbandingan di konsol + `laporan/PENANG`: transaksi KL 476 ms vs PENANG 2430 ms; p95 langkah 180 vs 890 ms; ralat 0% kedua-dua.

**Mesej utama:** *"Satu ujian, banyak lokasi → satu laporan gabungan untuk beban & throughput, tetapi keputusan NFR mesti **per lokasi**. Purata gabungan menyembunyikan lokasi yang gagal. Labelkan sampel dengan lokasi (`[${__P(site)}]`) supaya anda boleh memecahkannya kemudian."*

**Soalan dijangka — *"Kenapa masa PENANG lebih tinggi?"***
> Dalam demo: kerana kita sengaja memberi mock PENANG latensi 300–900 ms (`LATENCY_MIN/MAX`) untuk meniru laluan rangkaian jauh; mock KL 40–180 ms. Aplikasi dan beban sama (10 pengguna setiap ejen), ralat 0% di kedua-dua → perbezaan ialah **kependaman**, bukan kapasiti pelayan. Di dunia sebenar, masa respons yang diukur oleh ejen = rangkaian (RTT, DNS, TLS, laluan WAN/ISP) **+** pelayan. Jika semua ejen menyasarkan pelayan yang **sama** dan hanya satu lokasi lambat → syak rangkaian/laluan lokasi itu (bandingkan `Connect` dan `Latency` dalam JTL; traceroute). Jika semua lokasi lambat bersama apabila beban naik → syak pelayan. Juga semak ejen itu sendiri (CPU penuh, jam tidak segerak) sebelum membuat kesimpulan.

**Soalan untuk ditanya:**
- "Kenapa APDEX transaksi 0.86 tetapi setiap langkah 1.0?" (transaksi 4 langkah ≈ 450 ms dinilai dengan T = 500 ms yang sama)
- "Kenapa Codes per Second hanya 200 walaupun R2 22% gagal?" (Duration Assertion; kod HTTP tetap 200)
- "Throughput mendatar walaupun pengguna naik — maksudnya?" (tepu / titik lutut)
- "Ralat 1% berlaku pada 5 pengguna juga — beban atau bukan?" (baseline!)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Total Statistics termasuk transaksi" | Total = sampel HTTP sahaja; baris transaksi berasingan |
| "APDEX tidak peduli ralat" | Dalam JMeter, sampel gagal = Frustrated |
| "Latency = response time" | Latency = sehingga bait pertama (termasuk connect); response time = sehingga bait terakhir |
| "Hits/s = TPS" | 1 transaksi pembaharuan = 4 hits |
| "Graf Over Time rosak — satu titik sahaja" | Butiran lalai 60 s; jana semula dengan `overall_granularity` |
| "Max ialah SLA" | Max = satu sampel; SLA pada percentile |

**✅ Sebelum bergerak ke S4:** ≥ 85% telah membuka dashboard sendiri dan mengisi lembaran kerja; ≥ 60% mempunyai sekurang-kurangnya satu dapatan bertulis.

---

## 3.30 – 3.45 ptg · Rehat

Jurulatih: tulis di papan formula `N = X × (R + Z)` dan angka R1 (10.46/s, 0.446 s, 4 s) — sedia untuk S4. Semak berapa yang sudah isi borang penilaian.

---

## S4 · 3.45 – 5.00 ptg · Merancang Ujian Prestasi (75 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 3.45–3.55 | 10 | §4.1 kitaran hayat (rajah) + §4.2 NFR: tulis semula "portal mesti laju" bersama kelas menjadi NFR SMART. | Kaitkan setiap fasa dengan apa yang mereka buat hari ini. |
| 3.55–4.10 | 15 | §4.3 **Little's Law**: contoh eJPJ (36,000/jam → 10/s → 600 pengguna). Kemudian **semak dengan R1**: 10.46 × 4.45 ≈ 46 ≈ thread aktif. R3: N sama, R naik → X turun. Pacing: Constant Throughput Timer (sampel/**minit**, anak sampler pertama) & Precise Throughput Timer. | **Momen kunci #6.** *"Little's Law membolehkan anda menyemak laporan orang lain dalam 30 saat."* |
| 4.10–4.18 | 8 | §4.4–4.7: campuran transaksi, baseline → load → stress → spike → soak, kriteria masuk/keluar/gantung, pemantauan, risiko, **kebenaran bertulis**. | Tanya JPJ: *"Siapa dalam organisasi anda yang menandatangani kebenaran ujian beban?"* |
| 4.18–4.38 | 20 | **Latihan 6** — isi templat pelan (pasangan). | Pastikan setiap pasangan mempunyai pengiraan N yang betul unit (saat). |
| 4.38–4.50 | 12 | **Latihan 7** — pembentangan mini, 3–4 pasangan × 3 minit. | Pilih sukarelawan; jika masa singkat, 2 pasangan. Satu soalan "Bagaimana anda tahu…?" setiap pasangan. |
| 4.50–4.53 | 3 | ⭐ §4.9 sekilas: CI (`jmeter -n` keluar 0 walaupun gagal → gerbang `statistics.json`), distributed (sudah didemo di §3.9 — hanya ulang: setiap worker = seluruh Thread Group, `-G`), Grafana (semasa vs selepas). | Konsep sahaja — tiada demo. |
| 4.53–5.00 | 7 | **Penutup** (lihat di bawah). | **Jangan** potong penutup + borang penilaian. |

**Penutup — skrip (7 minit):**
1. **Rumusan 2 hari** — jadual §4.10. *"Hari 1 anda belajar menjana beban. Hari 2 anda belajar menjana beban yang **betul**, membaca apa yang ia beritahu, dan merancangnya supaya keputusan boleh dipercayai."*
2. **Borang penilaian kursus:** *"Borang penilaian kursus dibuka 2.00 ptg; isi sebelum tamat."* Dalam pelatih.my → menu **Borang penilaian**. Beri 3 minit di dalam kelas — jangan tinggalkan untuk "nanti".
3. **Kuiz S4 + Kuiz hari — Penilaian kendiri Hari 2**: hantar sekarang; ia melengkapkan checkpoint lab dan item "Isi penilaian kendiri Hari 2".
4. **Sijil:** sijil penyertaan dikeluarkan oleh penganjur selepas kehadiran dan borang penilaian disahkan — jangan janji tarikh yang anda tidak kawal.
5. **Mesej akhir etika:** *"Repo ini, SUT ini, templat ini — bawa pulang. Tetapi sebelum JMeter dihalakan ke sistem JPJ sebenar: kebenaran bertulis, staging, tetingkap masa, dan pasukan infra memantau bersama."*

**Soalan untuk ditanya:**
- "Volum 18,000/jam, R = 2 s, Z = 28 s — berapa pengguna?" (150)
- "Constant Throughput Timer 10 — kenapa throughput jauh lebih rendah?" (unit sampel/minit)
- "Kenapa baseline dahulu?" (bezakan kesan beban daripada isu sedia ada)
- "Apa satu perkara yang anda akan ubah dalam cara pasukan anda melaporkan prestasi selepas kursus ini?"

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Bilangan pengguna = bilangan pengguna berdaftar" | Pengguna **serentak** = X × (R + Z) |
| "Lebih ramai thread = lebih banyak throughput selamanya" | Throughput dihadkan oleh kapasiti; selepas tepu, response time naik |
| "Pacing timer boleh mempercepatkan" | Timer hanya memperlahankan; jika N < X × (R + Z), tambah threads |
| "Ujian kecil ke sistem awam tidak mengapa" | Saiz tidak relevan — kebenaran bertulis wajib |
| "Distributed membahagi thread antara worker" | Setiap worker menjalankan **seluruh** Thread Group |

**✅ Kriteria tamat hari:** ≥ 85% hantar Kuiz hari; borang penilaian diisi oleh semua; setiap pasangan mempunyai pelan dengan pengiraan N; sekurang-kurangnya 2 pembentangan mini.

---

## 🎬 Skrip demo

### Demo rakaman (S1, ~15 minit)
1. Buka `hari-1/test-plans/rakam-template.jmx` → **Save As** `hari-2/test-plans/latihan-01-rakaman.jmx`.
2. Tambah HTTP Request Defaults (`localhost`/`3000`) di bawah Thread Group. Perakam: Grouping → *Put each group in a new transaction controller*; tambah `.*google-analytics.*` dalam Excludes; tambah Constant Timer `${T}` di bawah perakam.
3. Start → tunjuk `lsof -iTCP:8888 -sTCP:LISTEN -n -P`. Dalam *Recorder: Transactions Control*, taip `T01_LogMasuk` → jalankan blok T01 (README §1.4). Ulang T02–T04 dengan nama masing-masing, tunggu > 5 s.
4. Stop. Kembangkan pokok. Tunjuk: Header Manager `T02` → `Authorization: Bearer <uuid>` (teks tetap); badan `T04` → `csrf` tetap; Constant Timer → nombor sebenar.
5. Jika rakaman gagal di skrin (proxy/port): beralih segera ke `04-rakaman-mentah.jmx` — *"inilah hasil rakaman yang sama."*

### Demo main balik (S1, ~10 minit)
1. Start tanpa restart → semua hijau. Tanya kelas: sedia untuk beban?
2. Terminal A: Ctrl+C → `node sut/server.js`. Clear All → Start → 200 / 401 / 200 / 401.
3. VRT `T02` → Request (token lama) vs Response data `T01` (token baharu).
4. JSON Extractor `token` sahaja + `Bearer ${token}` → Start → `T02` 200, `T04` **403** `Token CSRF tidak sah — sila log masuk semula`.

### Plan `05-transaksi-penuh.jmx` (S2, ~5 minit)
1. Tunjuk `Pembaharuan Cukai Jalan` → `Jika ada kenderaan` → `3. GET …/${no_pendaftaran}/cukai` → `4. POST …/bayar-cukai` (`"amaun": ${amaun}`), Uniform Random Timer di bawah TC.
2. Start (10 × 2). Aggregate Report: 80 sampel HTTP + 20 transaksi; 3 label kenderaan (`WXY1234`, `JQK7788`, `BMT3030` — kenderaan pertama setiap pengguna CSV).
3. Jika muncul 1 ralat 500: *"`ERROR_RATE` 1% SUT — sengaja. Dashboard akan menunjukkannya pada petang ini."*

### Dashboard pertama (S3, ~10 minit)
```bash
mkdir -p hasil
jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx -l hasil/r05.jtl -e -o hasil/laporan05
jmeter -g hasil/r05.jtl -o hasil/laporan05-5s -Jjmeter.reportgenerator.overall_granularity=5000
jmeter -g hasil/r05.jtl -o hasil/laporan05-5s      # ralat: folder is not empty (sengaja)
```

### Plan `07` — SLA (S3, ~5 minit + larian)
1. R1 & R2 (README §3.7, ≈ 1 minit setiap satu). Semasa menunggu: tunjuk Duration Assertion `${__P(sla_ms,2000)}` dalam GUI.
2. R2 → Errors: ~30 baris `The operation lasted too long: It took 1xx milliseconds…` — *"jadual ini mengumpul ikut teks; jumlahkan."* Codes Per Second → hanya `200` (+ sedikit `500`). Transactions Per Second → siri `-failure`.
3. ⭐ R3 (mock perlahan, port 3001) jika masa: `PORT=3001 LATENCY_MIN=500 LATENCY_MAX=1500 node sut/server.js` + `-Jport=3001` — throughput jatuh ~45%. Hentikan mock 3001 selepas itu.

### Little's Law (S4, ~5 minit di papan)
```
R1:  X = 10.46 trans/s   R = 0.446 s   Z ≈ 4 × 1.0 s = 4.0 s
     N = 10.46 × 4.446 ≈ 46.5   (purata thread aktif ≈ 45.8: 10 s ramp-up + 50 s × 50)
R3:  X = 5.78            R = 3.954 s   Z = 4.0 s
     N = 5.78 × 7.954 ≈ 46.0    → N sama, R naik, X turun
```

---

## 🧯 Pelan kejar (catch-up)

| Situasi | Tindakan |
|---------|----------|
| JMeter/Java/Node rosak pada laptop peserta (dikesan semasa imbas kembali) | Pasangkan dengan rakan serta-merta; baiki semasa rehat 10.30. Jangan berhenti kelas. |
| **Rakaman gagal** (proxy, port 8888, tiada Git Bash, curl tidak melalui proxy) | Guna `hari-1/test-plans/04-rakaman-mentah.jmx` (Save As ke `hari-2/test-plans/`) sebagai rakaman — Latihan 2 & 3 berjalan sama. Untuk Latihan 4–5 guna `05-transaksi-penuh.jmx` / `07`. |
| Port 8888 digunakan | Tukar port perakam (cth. 8889) dan `P=http://localhost:8889` |
| Ketinggalan Latihan 3 > 20 minit | Buka `05-transaksi-penuh.jmx`, jalankan, dan **terangkan** setiap elemen kepada pasangan. Membina sendiri jadi kerja rumah. |
| Larian `07` terlalu berat untuk laptop | `-Jpengguna=25`; atau buka laporan sandaran jurulatih (kongsi folder `hasil/` melalui pemacu USB/rangkaian kelas). Corak tetap kelihatan. |
| Kelas lewat menjelang S3 | Lawatan dashboard kekal penuh (fokus penganjur). Latihan 4: baris 1–9 sahaja. Latihan 5: R1 & R2 + **dua** dapatan. |
| Kelas lewat menjelang S4 | Latihan 6: bahagian 3 (NFR) + Lampiran A (Little's Law) + 12 (kebenaran) sahaja. Latihan 7: 2 pasangan. Langkau ⭐ §4.9. **Jangan** potong penutup + borang penilaian. |
| Peserta pantas / berpengalaman | ⭐ format string perakam (Lab 1), Regex/Boundary + `08` ForEach (Lab 3), R3 + ambang APDEX + stress (Lab 5), gerbang SLA CI (Lab 7), bantu pasangan lain. |

## 📋 Semakan akhir hari (jurulatih)

- [ ] Rekod bilangan peserta yang menghantar Kuiz hari (sasaran ≥ 85%)
- [ ] Sahkan borang penilaian kursus diisi oleh semua peserta (menu **Borang penilaian** pelatih.my)
- [ ] Kumpul (gambar) 2–3 pelan ujian & dapatan terbaik untuk e-mel susulan (dengan izin peserta)
- [ ] Hentikan SUT (dan mock port 3001 jika digunakan); padam `hasil/` pada mesin demo
- [ ] Maklumkan penganjur senarai kehadiran untuk sijil
- [ ] Laporkan isu bahan yang ditemui supaya repo dibetulkan sebelum kelas seterusnya
