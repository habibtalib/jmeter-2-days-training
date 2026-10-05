# Nota Penceramah — Hari 2: Rakam & Main Balik, Laporan Prestasi & Merancang Ujian

[📖 README Hari 2](./README.md) · [🧪 Lab](./snippets/lab.md) · [📋 Templat Pelan Ujian](./snippets/templat-pelan-ujian.md) · [📝 Templat Laporan Ujian](./snippets/templat-laporan-ujian.md) · [🗂️ Test plans](./test-plans/) · [⬅️ README Hari 1](../hari-1/README.md)

> **Mesej utama hari ni:**
> 1. **"Recording tu titik mula, bukan produk siap."** Recorder salin apa yang dia nampak — termasuk token yang nanti akan expired.
> 2. **"Hijau ≠ betul."** Replay yang pass tanpa restart SUT, atau 200 tanpa assertion, itu false pass.
> 3. **"Report tu produk anda."** Setiap angka dalam dashboard kena boleh explain dengan istilah yang betul.
> 4. **"Percentile, baseline, NFR — ikut turutan tu."** Average boleh menipu; satu run tanpa baseline tak ada makna; NFR kena setuju **sebelum** test.
> 5. **"Bilangan users dikira, bukan diteka."** N = X × (R + Z).
> 6. **"Test hanya pada target yang ada kebenaran bertulis."** Klien kita JPJ — peserta mesti balik dengan refleks ni.

## Ringkasan penyampai

| Perkara | Nilai |
|---------|-------|
| Klien | JPJ — Jabatan Pengangkutan Jalan Malaysia. Senario (cukai jalan, saman, no. pendaftaran) memang dunia mereka; ajak mereka kaitkan dengan sistem sebenar **secara lisan** sahaja, bukan dengan test sistem sebenar. |
| Tarikh & konteks | Hari 2: **Isnin, 5 Okt 2026**. Hari 1 dah diajar pada **21 Sep** — dua minggu lepas. Recap 10 minit je; kalau ada installation rosak, kita kesan masa S1. |
| Fokus (permintaan penganjur) | **Record & replay sampai keluar report**, **explain report & istilah**, dan **cara plan test**. Correlation diajar sebagai alat untuk buat recording boleh di-replay — bukan topik sendiri. Logic controller advanced, JSR223, CI, distributed, Grafana = ⭐ sekilas je. |
| Nisbah | S1 ~40% demo/penerangan · S2 ~35% · S3 ~55% (dashboard & istilah) · S4 ~45% · selebihnya lab |
| Bahan | Projektor dua panel: Terminal A (log SUT) + JMeter GUI / browser (dashboard). Whiteboard: user journey 4 langkah, jadual 401/403, formula APDEX, Little's Law. |
| Momen kunci | (1) S1: replay tanpa restart = **semua hijau** → restart → 200/401/200/401; (2) S1: correlate token je → **403**; (3) S2: Aggregate Report 80 + 20, transaksi ≈ 440 ms walaupun think time 1–3 s; (4) S3: graf Over Time cuma 1 titik → generate semula `-g` dengan granularity 5 s; (5) S3: SLA 150 ms → Error % 1% → 22% tanpa sistem berubah; (6) S4: Little's Law boleh agak 46 users daripada report; (7) S3 §3.9: average gabungan 363 ms sorok PENANG p95 ≈ 890 ms |
| Hasil wajib hujung hari | ≥ 85% peserta: Latihan 3 (plan boleh di-replay) + Latihan 4 (worksheet dashboard) + Latihan 6 (plan dengan kiraan N) + Kuiz hari dihantar |
| Progress dalam pelatih.my | JMeter run di laptop peserta — LMS tak nampak. Item terakhir setiap ✅ Checkpoint ditanda bila **Kuiz S1–S4** pass; "Isi penilaian kendiri Hari 2" ditanda oleh **Kuiz hari**. Ingatkan peserta hantar kuiz di hujung setiap sesi. |

### Angka sebenar untuk dirujuk (disahkan dengan JMeter 5.6.3 pada mock, 4 Okt 2026)

| Run | Angka |
|--------|-------|
| `04-rakaman-mentah.jmx` (replay) | 3 sampel, Err 2 (66.67%); Errors: `401/Unauthorized` 2 · 100% · 66.67% |
| `05-transaksi-penuh.jmx` (10 × 2) | 80 sampel HTTP + 20 transaksi; 0% error; transaksi Avg ≈ 442 ms, p95 ≈ 561 ms; APDEX transaksi 0.875, Total 0.975 |
| `07` R1 (`-Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000`) | Total 2432 sampel, 41.29/s, Err 0.25% (6 × 500); transaksi 598, **10.46/s**, Avg 446, p95 **583**, Err **1.00%**; APDEX Total 0.971, transaksi 0.862 |
| `07` R2 (sama, `-Jsla_ms=150`) | Total Err 5.37%; transaksi Err **21.75%**, p95 572; bayar-cukai 19–26%; APDEX transaksi 0.717; ~30 baris berlainan `The operation lasted too long…` dalam Errors |
| `07` R3 (mock perlahan port 3001, 500–1500 ms) | Total 22.78/s; transaksi **5.78/s**, Avg 3954, p95 **4969**; APDEX Total 0.401 |
| Little's Law | R1: 10.46 × (0.446 + 4.0) ≈ 46.5 · R3: 5.78 × (3.954 + 4.0) ≈ 46.0 · average thread aktif ≈ 45.8 (ramp-up 10 s) |
| Constant Throughput Timer 300/min (shared, current TG) sebagai child log masuk | log masuk 5.39/s ≈ 323/min |
| `09` distributed (`run-berbilang-lokasi.sh`, 10 × 3 setiap agent, 2 agent) | Gabungan 240 sampel HTTP, 0% error, Avg 363, p95 873, 6.90/s; transaksi KL Avg 476 / p95 640; PENANG Avg 2430 / p95 3000; langkah p95 KL 175–180, PENANG 886–896; Active Threads: 2 siri (`127.0.0.1:1099-…`, `127.0.0.1:1100-…`) |

> Angka peserta akan lain sikit (latency mock random 40–180 ms, `ERROR_RATE` 1%). Tekankan **pattern**, bukan nilai tepat.

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

> ⚠️ **Risiko dalam bilik:** setiap peserta run SUT **sendiri** pada `localhost:3000` dan recorder **sendiri** pada `localhost:8888`. Jangan bagi sesiapa halakan curl/proxy/plan ke IP kawan tanpa izin — itu pun kira "sistem orang lain". Run `07` dengan 50 users × 60 s ringan je untuk laptop biasa; jangan naikkan ke default 300 × 300 s dalam kelas.

---

## S1 · 9.00 – 10.30 pagi · Rakam & Main Balik (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 9.00–9.05 | 5 | Selamat datang semula. Agenda hari ni (jadual README): *"Hari ni kita buat kerja performance engineer — dari recording sampai report dan test plan."* Progress pelatih.my = kuiz setiap sesi. | Cakap terus: report & planning ialah fokus petang. |
| 9.05–9.15 | 10 | **Recap Hari 1** (§1.1): semua run `node sut/server.js`; buka `04-rakaman-mentah.jmx` → **semak HTTP Request Defaults sama-sama** → Start → 1 hijau, 2 merah. Jadual 4 soalan cepat. | Ni sekali gus semakan installation — JMeter/Java/Node yang rosak kita kesan **sekarang**. |
| 9.15–9.25 | 10 | **§1.2 Plan dulu** — whiteboard: 4 langkah, nama `T01…T04`, bulatkan data dinamik. Tanya: *"Satu klik 'Bayar' kat portal sebenar — berapa request sebenarnya?"* | Konsep "satu tindakan = satu transaksi". |
| 9.25–9.40 | 15 | 🎬 **Demo §1.3–1.5**: Save As `latihan-01-rakaman.jmx`; HTTP Request Defaults; Grouping → *Put each group in a new transaction controller*; Excludes (+ analitik); Constant Timer `${T}`; Start; dialog *Recorder: Transactions Control* (taip `T01_LogMasuk`); run blok curl dengan `sleep 6`; Stop. Expand tree: nama `/api/log-masuk-1`, Header Manager dengan `Authorization: Bearer …` hardcoded, body `csrf` literal, timer ≈ 6000 ms. | Tunjuk `lsof … :8888`. Tekankan: *"Recorder simpan Bearer token sebagai teks tetap; Cookie pula dibuang — app yang guna cookie perlukan Cookie Manager."* |
| 9.40–10.00 | 20 | **Latihan 1** (berpasangan). | Ronda: isu #1 lupa Start / lupa `-x $P` → tak ada sampler; isu #2 semua masuk satu group (tak tunggu 5 s). Pasangan yang laju → ⭐ format string. |
| 10.00–10.10 | 10 | 🎬 **Demo replay** (momen kunci #1): Start **tanpa** restart → semua hijau. *"Dah ready untuk 300 users?"* Biar mereka jawab. Restart SUT → Start → 200/401/200/401. VRT: Sampler result → Request → Response data. Lepas tu correlate `token` je → **403** (momen kunci #2). | *"401 = siapa anda; 403 = request ni sah ke tak."* Tanya kenapa `T03` hijau (tak perlukan token) → sebab tu kita perlukan assertion. |
| 10.10–10.25 | 15 | **Latihan 2.** | Kalau recording peserta gagal → guna `04-rakaman-mentah.jmx` (pelan kejar). |
| 10.25–10.30 | 5 | Checkpoint + **Kuiz S1**. | Jambatan: *"Lepas rehat kita betulkan recording ni sampai boleh di-replay oleh 10, 50, 300 users."* |

**Skrip ringkas (replay):**
> *"Bayangkan anda record video diri sendiri masuk bank guna kad akses semalam. Hari ni anda tayang video tu kat guard — pintu tak buka, sebab kad semalam dah dibatalkan. Itulah replay recording. Tapi kalau bank lupa batalkan kad semalam, pintu terbuka — dan anda ingat video anda 'berjaya'. Itulah false pass."*

**Soalan untuk ditanya:**
- "Kenapa kita tunggu 6 saat antara langkah?" (`proxy.pause` 5 s → group baru)
- "`${T}` tu record apa?" (jurang masa sebenar antara request)
- "Kenapa semua hijau sebelum restart?" (session recording masih hidup dalam memory mock)
- "Dalam sistem JPJ sebenar, nilai dinamik apa lagi yang ada?" (session cookie, view-state, nonce pembayaran, ID transaksi FPX — **bincang je**)

**Salah faham biasa:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Recorder akan uruskan token" | Recorder salin nilai literal; correlation tu kerja kita (S2) |
| "Semua hijau = script betul" | False pass: session recording masih valid; 200 tanpa assertion |
| "Record guna browser biasa je" | Browser kena dihalakan ke proxy 8888; SUT ni API → guna curl |
| "Perlu sijil CA untuk record" | Hanya untuk HTTPS |
| "401 dengan 403 sama je" | 401 = token (identiti); 403 = csrf (request tu sah atau tak) |

**✅ Sebelum gerak ke S2:** ≥ 80% pasangan ada recording 4 langkah (sendiri atau `04-rakaman-mentah`) dan boleh explain 401 vs 403.

---

## 10.30 – 10.45 pagi · Rehat

Biar SUT terus run. Jurulatih: semak siapa tak ada recording → bagi `04-rakaman-mentah.jmx` (Save As ke `hari-2/test-plans/`) untuk S2.

---

## S2 · 10.45 – 1.00 tgh · Jadikan Rakaman Boleh Dimain Balik (135 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 10.45–10.55 | 10 | §2.1 senarai semak 10 perkara (tunjuk pada recording di skrin) + §2.2 parameterisation vs correlation. | Analogi: *"CSV tu macam IC anda; token pula macam nombor giliran kaunter — kaunter je yang tahu."* |
| 10.55–11.15 | 20 | 🎬 **Live build** §2.3–2.5: JSON Extractor `token;csrf` + default `TOKEN_TAK_JUMPA` → `Bearer ${token}` / `${csrf}` → CSV `pengguna.csv` → extractor kenderaan `$.kenderaan[0]…` → path `${no_pendaftaran}`. Tunjuk JSON Path Tester + Debug Sampler. | Taip perlahan-lahan. Tekankan scope extractor (child kepada sampler) dan lokasi `.jmx` (path CSV relatif). |
| 11.15–11.25 | 10 | 🎬 §2.6–2.8: nama sampler, Transaction Controller (Generate parent sample — tunjuk dua-dua), buang timer `${T}`, Uniform Random Timer, Response Assertion, If Controller. | Tanya: *"Timer bawah TC yang ada 4 sampler — berapa kali pause?"* (4) |
| 11.25–12.20 | 55 | **Latihan 3.** Functional test 1 × 1 dulu, lepas tu 10 × 2. | Isu biasa: CSV tak jumpa (plan bukan dalam `hari-2/test-plans/`), extractor bukan child, timer recording 6 s masih ada (run nampak "hang"). Pukul 12.00: pasangan yang tersangkut → buka `05` dan banding element satu per satu. |
| 12.20–12.35 | 15 | 🎬 Run `05` (10 × 2): Summary vs Aggregate — setiap column (§2.9). 80 + 20; transaksi ≈ 440 ms walaupun ada think time. | **Momen kunci #3.** *"Masa transaksi = masa sistem; think time beri kesan pada throughput, bukan response time."* — jambatan ke Little's Law. |
| 12.35–12.50 | 15 | ⭐ Sekilas §2.10: `08` ForEach (Match `-1`, *Add "_" before number ?* → 0 iteration tanpa error) + JSR223 (Cache, `vars.get`). **Atau** guna masa ni untuk kejar Latihan 3. | Pilih ikut progress kelas — Latihan 3 lebih penting. |
| 12.50–1.00 | 10 | Checkpoint + **Kuiz S2**. | Jambatan: *"Lepas lunch, kita stop tengok GUI dan mula baca report macam management baca."* |

**Soalan untuk ditanya:**
- "Kenapa default extractor `TOKEN_TAK_JUMPA`, bukan kosong?" (kegagalan nampak jelas dalam tab Request)
- "300 thread log masuk — berapa token?" (300; `vars` per thread)
- "Kenapa If Controller sebelum bayar?" (elak bayaran palsu yang kotorkan Error %)
- "Kenapa satu baris untuk setiap kenderaan dalam Aggregate Report?" (label dinamik `${no_pendaftaran}`)

**Salah faham biasa:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Letak extractor kat mana-mana dalam Thread Group" | Scope ikut kedudukan — mesti child kepada sampler log masuk |
| "Biar je timer `${T}` dari recording — kan realistik" | Itu think time **anda**, sama untuk semua thread → users bergerak serentak; guna timer random |
| "Transaksi patut termasuk think time" | Biasanya tak — kita ukur masa sistem |
| "Aggregate & Summary Report sama je" | Aggregate ada Median & 90/95/99% Line; Summary ada Std. Dev. & Avg. Bytes |

**✅ Sebelum gerak ke S3:** ≥ 80% ada plan yang keluarkan baris transaksi `Pembaharuan Cukai Jalan` dengan Error % ≈ 0 (sendiri atau `05`).

---

## 1.00 – 2.00 ptg · Makan tengah hari

Ingatkan: **jangan tutup Terminal A**. Jurulatih: buka report backup R1/R2/R3 dalam tab browser. **Borang penilaian kursus dibuka 2.00 ptg** — sebut sekali masa mula S3, dan sekali lagi masa penutup.

---

## S3 · 2.00 – 3.30 ptg · Laporan & Istilah (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 2.00–2.05 | 5 | Ice-breaker: *"Siapa pernah kena suruh 'buat report' daripada screenshot?"* Maklumkan borang penilaian dah dibuka. | |
| 2.05–2.13 | 8 | 🎬 §3.1: `mkdir -p hasil` → `jmeter -n -t …05… -l … -e -o …` → buka `index.html`. Lepas tu `-g` ke folder baru dengan `overall_granularity=5000`. Tunjuk error `folder is not empty`. Anatomi `.jtl` (buka dalam editor). | Kalau lupa `mkdir`: error `parent folder is not writable` — jadikan pengajaran. |
| 2.13–2.25 | 12 | 🎬 **Walkthrough dashboard** (§3.2–3.3, **versi pendek**) guna report backup R1: Test and Report information → APDEX (formula kat whiteboard; gagal = Frustrated) → Statistics (Total ≠ transaksi) → Errors/Top 5 → **3 graf je**: Active Threads, Response Times Over Time, Total TPS (+ Codes/s untuk R2). Graf lain = rujukan README §3.3 / Latihan 4. | **Momen kunci #4.** Tunjuk report granularity 60 s (1 titik) vs 5 s. Satu soalan untuk setiap graf. |
| 2.25–2.38 | 13 | **Latihan 4** — worksheet (pasangan laju siapkan 14 baris; yang lain sekurang-kurangnya 8). | Pasangan laju → banding `statistics.json` dengan jadual. |
| 2.38–2.45 | 7 | §3.5 glosari (pilih 6: response time / latency, throughput / TPS, percentile vs average, APDEX, saturation) + §3.6 jadual pattern. Contoh "average menipu" kat whiteboard. | Glosari tu rujukan — tak payah baca semua baris. |
| 2.45–2.48 | 3 | 🎬 §3.7: launch R1 & R2 (60 s setiap satu) — explain Duration Assertion sementara tunggu. | Peserta mula Latihan 5 serentak. |
| 2.48–3.05 | 17 | **Latihan 5** — run + jadual perbandingan + **2** dapatan dalam kelas (dapatan ke-3 jadi kerja rumah). Tunjuk contoh bahagian B `templat-laporan-ujian.md`. | **Momen kunci #5:** R2 — Error % 1% → 22% tanpa sistem berubah. *"Yang berubah cuma definisi 'cukup laju'."* |
| 3.05–3.12 | 7 | 🎬 **§3.9 Report multi-lokasi** — demo `./run-berbilang-lokasi.sh` (skrip di bawah). | **Momen kunci #7:** average gabungan 363 ms nampak "OK" — tapi PENANG p95 ≈ 890 ms gagal. |
| 3.12–3.25 | 13 | **Latihan 8 → demo jurulatih (5 min) + kerja rumah** (keputusan 5 Okt): run skrip anda, tunjuk report gabungan + per lokasi, satu dapatan. Baki masa → Latihan 9 (lihat jadual tambahan di bawah). | Pastikan SUT Terminal A dah stop dulu (port 3000) sebelum demo. |
| 3.25–3.30 | 5 | Checkpoint + **Kuiz S3**. | |

**Skrip ringkas (percentile):**
> *"Kalau 100 orang renew cukai jalan dan average 300 ms, kita tak tahu apa-apa pasal orang yang paling lambat. p95 583 ms maksudnya: 95 orang siap dalam 0.6 saat, 5 orang lagi ambil masa lebih lama. NFR yang bagus jaga 5 orang tu."*

**🎬 Skrip demo §3.9 (7 minit) — report multi-lokasi:**

Sebelum kelas: run sekali `cd hari-2/run && ./run-berbilang-lokasi.sh` untuk warm up JVM dan simpan report backup. Masa demo: **stop SUT Terminal A** (skrip guna port 3000/3001/1099/1100/4001/4002).

1. *(1 min)* Whiteboard: controller + 2 agent (KL 1099, PENANG 1100). *"JPJ letak load generator di beberapa negeri — satu test, dua lokasi. Agent yang jana load; controller cuma kumpul hasil."*
2. *(2 min)* `./run-berbilang-lokasi.sh` (≈ 45 s). Sementara run, tunjuk dalam skrip: `-Jsite=KL` pada agent (local) vs `-Gpengguna=10` pada controller (semua agent) → **10 × 2 = 20 users**. Tunjuk `summary +` yang masuk berlonggok: *"sample sender StrippedBatch — sampel dihantar balik secara batch."*
3. *(2 min)* `laporan/gabungan`: Statistics — baris `[KL]` & `[PENANG]`; Active Threads Over Time — **dua siri** `127.0.0.1:1099-…` dan `127.0.0.1:1100-…` (bukti dua-dua agent run). Total: average 363 ms.
4. *(2 min)* Jadual perbandingan kat console + `laporan/PENANG`: transaksi KL 476 ms vs PENANG 2430 ms; p95 langkah 180 vs 890 ms; error 0% untuk dua-dua.

**Mesej utama:** *"Satu test, banyak lokasi → satu report gabungan untuk load & throughput, tapi keputusan NFR mesti **ikut lokasi**. Average gabungan sorok lokasi yang gagal. Label sampel dengan lokasi (`[${__P(site)}]`) supaya nanti anda boleh pecahkan."*

**Soalan dijangka — *"Kenapa masa PENANG lebih tinggi?"***
> Dalam demo: sebab kita sengaja set latency 300–900 ms (`LATENCY_MIN/MAX`) pada mock PENANG untuk tiru laluan network yang jauh; mock KL 40–180 ms. App dan load sama (10 users setiap agent), error 0% kat dua-dua → bezanya ialah **latency**, bukan kapasiti server. Dalam dunia sebenar, response time yang agent ukur = network (RTT, DNS, TLS, laluan WAN/ISP) **+** server. Kalau semua agent target server yang **sama** dan cuma satu lokasi lambat → syak network/laluan lokasi tu (banding `Connect` dan `Latency` dalam JTL; traceroute). Kalau semua lokasi lambat serentak bila load naik → syak server. Semak juga agent tu sendiri (CPU penuh, jam tak sync) sebelum buat kesimpulan.

**Soalan untuk ditanya:**
- "Kenapa APDEX transaksi 0.86 tapi setiap langkah 1.0?" (transaksi 4 langkah ≈ 450 ms dinilai dengan T = 500 ms yang sama)
- "Kenapa Codes per Second cuma ada 200 walaupun R2 22% gagal?" (Duration Assertion; kod HTTP tetap 200)
- "Throughput mendatar walaupun users naik — maksudnya apa?" (saturation / knee point)
- "Error 1% berlaku pada 5 users pun — sebab load ke bukan?" (baseline!)

**Salah faham biasa:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Total dalam Statistics termasuk transaksi" | Total = sampel HTTP je; baris transaksi berasingan |
| "APDEX tak kira error" | Dalam JMeter, sampel gagal = Frustrated |
| "Latency = response time" | Latency = sampai byte pertama (termasuk connect); response time = sampai byte terakhir |
| "Hits/s = TPS" | 1 transaksi pembaharuan = 4 hits |
| "Graf Over Time rosak — satu titik je" | Granularity default 60 s; generate semula dengan `overall_granularity` |
| "Max tu SLA" | Max = satu sampel je; SLA guna percentile |

**✅ Sebelum gerak ke S4:** ≥ 85% dah buka dashboard sendiri dan isi worksheet; ≥ 60% ada sekurang-kurangnya satu dapatan bertulis.

**⏱️ Tambahan PerfMon + chatbot (§3.10–3.11, Latihan 9) — ~22 minit.** Peserta JPJ minta topik ni (laporan sebenar mereka ada CPU daripada ejen + sistem chatbot). Ambil masa daripada blok sedia ada:

| Masa asal | Ubah | Jimat | Guna untuk |
|-----------|------|------:|------------|
| 3.05–3.12 demo §3.9 + 3.12–3.25 Latihan 8 | Demo §3.9 sahaja (5 min); Latihan 8 → kerja rumah / ⭐ | 15 | 🎬 Demo PerfMon (8 min) + Latihan 9 langkah 5–8 dengan report jurulatih (7 min) |
| 2.38–2.45 glosari | Pilih 4 istilah, bukan 6 | 2 | §3.11 p95/p99 chatbot (whiteboard "1 daripada 100 soalan") |
| 2.48–3.05 Latihan 5 | Dapatan ke-2 jadi kerja rumah | 5 | Soalan 6–7 Kuiz S3 + NFR p95/p99 |

**Persediaan malam sebelum:** (1) pasang jpgc-perfmon, jpgc-cmd, jpgc-graphs-basic dalam JMeter jurulatih; (2) unzip ServerAgent-2.2.3; (3) run `./run-chatbot-perfmon.sh` sekali dan simpan folder `hasil/<masa>/` sebagai **report backup** (run ambil ~3.5 min — jangan tunggu dalam kelas kalau lewat); (4) Mac Apple Silicon: ejen mesti guna Java x86_64 (README §3.10 "Had & isu platform").

**Skrip ringkas (p99 chatbot):**
> *"Chatbot JPJ terima 10 soalan sesaat. p95 1.7 s — OK. Tapi p99 6 s maksudnya 6 orang setiap minit tunggu lebih 6 saat, dan ramai akan tekan 'hantar' sekali lagi. Purata 1.07 s sorok semua tu."*
---

## 3.30 – 3.45 ptg · Rehat

Jurulatih: tulis kat whiteboard formula `N = X × (R + Z)` dan angka R1 (10.46/s, 0.446 s, 4 s) — siap untuk S4. Semak berapa ramai dah isi borang penilaian.

---

## S4 · 3.45 – 5.00 ptg · Merancang Ujian Prestasi (75 minit)

| Masa | Minit | Aktiviti | Nota |
|------|------:|----------|------|
| 3.45–3.55 | 10 | §4.1 lifecycle (rajah) + §4.2 NFR: tulis semula "portal mesti laju" sama-sama dengan kelas jadi NFR SMART. | Kaitkan setiap fasa dengan apa yang mereka dah buat hari ni. |
| 3.55–4.10 | 15 | §4.3 **Little's Law**: contoh eJPJ (36,000/jam → 10/s → 600 users). Lepas tu **cross-check dengan R1**: 10.46 × 4.45 ≈ 46 ≈ thread aktif. R3: N sama, R naik → X turun. Pacing: Constant Throughput Timer (sampel/**minit**, child kepada sampler pertama) & Precise Throughput Timer. | **Momen kunci #6.** *"Dengan Little's Law, anda boleh semak report orang lain dalam 30 saat."* |
| 4.10–4.18 | 8 | §4.4–4.7: transaction mix, baseline → load → stress → spike → soak, kriteria entry/exit/suspend, monitoring, risiko, **kebenaran bertulis**. | Tanya JPJ: *"Dalam organisasi anda, siapa yang sign kebenaran untuk load test?"* |
| 4.18–4.38 | 20 | **Latihan 6** — isi templat pelan (berpasangan). | Pastikan setiap pasangan kira N dengan unit yang betul (saat). |
| 4.38–4.50 | 12 | **Latihan 7** — mini presentation, 3–4 pasangan × 3 minit. | Pilih sukarelawan; kalau masa suntuk, 2 pasangan cukup. Satu soalan "Macam mana anda tahu…?" untuk setiap pasangan. |
| 4.50–4.53 | 3 | ⭐ §4.9 sekilas: CI (`jmeter -n` exit 0 walaupun gagal → gate guna `statistics.json`), distributed (dah demo di §3.9 — ulang je: setiap worker run seluruh Thread Group, `-G`), Grafana (real-time vs selepas run). | Konsep je — tak ada demo. |
| 4.53–5.00 | 7 | **Penutup** (rujuk bawah). | **Jangan** potong penutup + borang penilaian. |

**Penutup — skrip (7 minit):**
1. **Rumusan 2 hari** — jadual §4.10. *"Hari 1 anda belajar jana load. Hari 2 anda belajar jana load yang **betul**, baca apa yang report beritahu, dan plan test supaya keputusan boleh dipercayai."*
2. **Borang penilaian kursus:** *"Borang penilaian kursus dibuka 2.00 ptg; isi sebelum tamat."* Dalam pelatih.my → menu **Borang penilaian**. Bagi 3 minit dalam kelas — jangan tinggal untuk "nanti".
3. **Kuiz S4 + Kuiz hari — Penilaian kendiri Hari 2**: hantar sekarang; ia lengkapkan checkpoint lab dan item "Isi penilaian kendiri Hari 2".
4. **Sijil:** sijil penyertaan dikeluarkan oleh penganjur selepas kehadiran dan borang penilaian disahkan — jangan janji tarikh yang anda tak kawal.
5. **Mesej akhir pasal etika:** *"Repo ni, SUT ni, templat ni — bawa balik. Tapi sebelum JMeter dihalakan ke sistem JPJ sebenar: mesti ada kebenaran bertulis, guna staging, ada time window, dan team infra monitor sama-sama."*

**Soalan untuk ditanya:**
- "Volume 18,000/jam, R = 2 s, Z = 28 s — berapa users?" (150)
- "Constant Throughput Timer 10 — kenapa throughput jauh lebih rendah?" (unit dia sampel/minit)
- "Kenapa baseline dulu?" (asingkan kesan load daripada isu yang memang dah ada)
- "Satu perkara apa yang anda akan ubah dalam cara team anda report performance lepas kursus ni?"

**Salah faham biasa:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Bilangan users = bilangan pengguna berdaftar" | Concurrent users = X × (R + Z) |
| "Lagi banyak thread = lagi banyak throughput, selama-lamanya" | Throughput terhad pada kapasiti; lepas saturation, response time naik |
| "Pacing timer boleh percepatkan" | Timer cuma memperlahankan; kalau N < X × (R + Z), tambah threads |
| "Test kecil ke sistem awam tak apa" | Saiz tak relevan — kebenaran bertulis wajib |
| "Distributed bahagi thread antara worker" | Setiap worker run **seluruh** Thread Group |

**✅ Kriteria tamat hari:** ≥ 85% hantar Kuiz hari; borang penilaian diisi oleh semua; setiap pasangan ada plan dengan kiraan N; sekurang-kurangnya 2 mini presentation.

---

## 🎬 Skrip demo

### Demo rakaman (S1, ~15 minit)
1. Buka `hari-1/test-plans/rakam-template.jmx` → **Save As** `hari-2/test-plans/latihan-01-rakaman.jmx`.
2. Tambah HTTP Request Defaults (`localhost`/`3000`) bawah Thread Group. Recorder: Grouping → *Put each group in a new transaction controller*; tambah `.*google-analytics.*` dalam Excludes; tambah Constant Timer `${T}` bawah recorder.
3. Start → tunjuk `lsof -iTCP:8888 -sTCP:LISTEN -n -P`. Dalam *Recorder: Transactions Control*, taip `T01_LogMasuk` → run blok T01 (README §1.4). Ulang T02–T04 dengan nama masing-masing, tunggu > 5 s.
4. Stop. Expand tree. Tunjuk: Header Manager `T02` → `Authorization: Bearer <uuid>` (teks tetap); body `T04` → `csrf` tetap; Constant Timer → nombor sebenar.
5. Kalau recording gagal depan skrin (proxy/port): terus tukar ke `04-rakaman-mentah.jmx` — *"ni hasil recording yang sama."*

### Demo main balik (S1, ~10 minit)
1. Start tanpa restart → semua hijau. Tanya kelas: dah ready untuk load?
2. Terminal A: Ctrl+C → `node sut/server.js`. Clear All → Start → 200 / 401 / 200 / 401.
3. VRT `T02` → Request (token lama) vs Response data `T01` (token baru).
4. JSON Extractor `token` je + `Bearer ${token}` → Start → `T02` 200, `T04` **403** `Token CSRF tidak sah — sila log masuk semula`.

### Plan `05-transaksi-penuh.jmx` (S2, ~5 minit)
1. Tunjuk `Pembaharuan Cukai Jalan` → `Jika ada kenderaan` → `3. GET …/${no_pendaftaran}/cukai` → `4. POST …/bayar-cukai` (`"amaun": ${amaun}`), Uniform Random Timer bawah TC.
2. Start (10 × 2). Aggregate Report: 80 sampel HTTP + 20 transaksi; 3 label kenderaan (`WXY1234`, `JQK7788`, `BMT3030` — kenderaan pertama setiap user dalam CSV).
3. Kalau keluar 1 error 500: *"Tu `ERROR_RATE` 1% SUT — memang sengaja. Dashboard akan tunjuk petang nanti."*

### Dashboard pertama (S3, ~10 minit)
```bash
mkdir -p hasil
jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx -l hasil/r05.jtl -e -o hasil/laporan05
jmeter -g hasil/r05.jtl -o hasil/laporan05-5s -Jjmeter.reportgenerator.overall_granularity=5000
jmeter -g hasil/r05.jtl -o hasil/laporan05-5s      # ralat: folder is not empty (sengaja)
```

### Plan `07` — SLA (S3, ~5 minit + larian)
1. R1 & R2 (README §3.7, ≈ 1 minit setiap satu). Sementara tunggu: tunjuk Duration Assertion `${__P(sla_ms,2000)}` dalam GUI.
2. R2 → Errors: ~30 baris `The operation lasted too long: It took 1xx milliseconds…` — *"jadual ni group ikut teks; kena jumlahkan sendiri."* Codes Per Second → cuma `200` (+ sikit `500`). Transactions Per Second → siri `-failure`.
3. ⭐ R3 (mock perlahan, port 3001) kalau ada masa: `PORT=3001 LATENCY_MIN=500 LATENCY_MAX=1500 node sut/server.js` + `-Jport=3001` — throughput jatuh ~45%. Stop mock 3001 lepas tu.

### PerfMon + chatbot (S3, ~8 minit + run 3.5 minit)
1. Whiteboard: mesin JMeter ↔ pelayan (ServerAgent port 4444). *"JMeter ukur masa respons; CPU datang dari ejen atas pelayan — file berasingan `perfmon.jtl`."*
2. Terminal: `./startAgent.sh --udp-port 0 --tcp-port 4444` → `telnet localhost 4444` → `test` → `Yep`. Tunjuk dalam GUI plan `10b`: PerfMon Metrics Collector (CPU, Memory `usedperc`, Filename).
3. `cd hari-2/run && ./run-chatbot-perfmon.sh` (atau buka report backup). Sementara run: §3.11 — *"p95 vs p99, purata menipu"*; tunjuk `summary` naik setiap 30 s.
4. Buka `active-threads.png`, `cpu-perfmon.png`, `response-times-over-time.png` sebelah-menyebelah: run kami CPU ≥ 80% dari ~31 pengguna, p95 1027 → 3567 ms dalam tetingkap yang sama, throughput mendatar ~14 /s.
5. Dashboard → Statistics: p95 1665 vs **p99 6076 ms**; Response Time Percentiles (ekor menegak selepas p95); **perangkap:** *Percentiles Over Time* = successful sahaja — Max tak lepas ~3 s.
6. **Ctrl+C ServerAgent.** *"Ejen ni tiada password dan boleh run arahan (`exec`) — test env sahaja, firewall, stop lepas test."*

**Soalan dijangka — *"Kenapa Memory 94% sepanjang test?"*** Tu memory keseluruhan laptop (macOS kira cache), rata dari awal — bukan leak. Ambil baseline idle dulu; yang penting ialah **perubahan** semasa beban.

**Soalan dijangka — *"Pelayan kami Windows/Linux — sama ke?"*** Ya: `startAgent.bat`/`startAgent.sh` pada pelayan ujian, buka port 4444 hanya untuk IP mesin JMeter. Alternatif yang lebih moden: node_exporter/Prometheus atau Telegraf/InfluxDB + Grafana.

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
| JMeter/Java/Node rosak pada laptop peserta (dikesan masa recap) | Pair terus dengan kawan; betulkan masa rehat 10.30. Jangan hentikan kelas. |
| **Recording gagal** (proxy, port 8888, tak ada Git Bash, curl tak lalu proxy) | Guna `hari-1/test-plans/04-rakaman-mentah.jmx` (Save As ke `hari-2/test-plans/`) sebagai recording — Latihan 2 & 3 jalan sama. Untuk Latihan 4–5 guna `05-transaksi-penuh.jmx` / `07`. |
| Port 8888 dah diguna | Tukar port recorder (cth. 8889) dan `P=http://localhost:8889` |
| Ketinggalan Latihan 3 > 20 minit | Buka `05-transaksi-penuh.jmx`, run, dan **explain** setiap element kepada pasangan. Bina sendiri jadi kerja rumah. |
| Run `07` terlalu berat untuk laptop | `-Jpengguna=25`; atau buka report backup jurulatih (share folder `hasil/` guna pendrive/network kelas). Pattern tetap nampak. |
| Kelas lewat bila sampai S3 | Walkthrough dashboard kekal penuh (fokus penganjur). Latihan 4: baris 1–9 je. Latihan 5: R1 & R2 + **dua** dapatan. |
| Kelas lewat bila sampai S4 | Latihan 6: bahagian 3 (NFR) + Lampiran A (Little's Law) + 12 (kebenaran) je. Latihan 7: 2 pasangan. Skip ⭐ §4.9. **Jangan** potong penutup + borang penilaian. |
| Peserta laju / berpengalaman | ⭐ format string recorder (Lab 1), Regex/Boundary + `08` ForEach (Lab 3), R3 + threshold APDEX + stress (Lab 5), CI SLA gate (Lab 7), tolong pasangan lain. |

## 📋 Semakan akhir hari (jurulatih)

- [ ] Rekod bilangan peserta yang menghantar Kuiz hari (sasaran ≥ 85%)
- [ ] Sahkan borang penilaian kursus diisi oleh semua peserta (menu **Borang penilaian** pelatih.my)
- [ ] Kumpul (gambar) 2–3 pelan ujian & dapatan terbaik untuk e-mel susulan (dengan izin peserta)
- [ ] Hentikan SUT (dan mock port 3001 jika digunakan); padam `hasil/` pada mesin demo
- [ ] Maklumkan penganjur senarai kehadiran untuk sijil
- [ ] Laporkan isu bahan yang ditemui supaya repo dibetulkan sebelum kelas seterusnya
