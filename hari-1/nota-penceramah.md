# Nota Penceramah — Hari 1: Asas Apache JMeter & Ujian Beban

[📖 README Hari 1](./README.md) · [🧪 Lab](./snippets/lab.md) · [🎬 Rakam → Main Balik](./snippets/rakaman-e2e.md) · [🔒 Rakaman HTTPS](./snippets/rakaman-https-setup.md) · [🔑 Test plan rujukan](./test-plans/) · [⚙️ SUT](../sut/server.js)

> 📌 **Status kohort JPJ:** Hari 1 untuk kohort ni dah berlangsung pada **21 Sep 2026**. **Hari 2 dijadualkan 5 Okt 2026.** Peserta sekarang guna page Hari 1 untuk **ulang kaji** — kuiz sesi (Kuiz S1–S4), Semakan Kendiri dan **Kuiz hari** dalam README, serta ✅ Checkpoint dalam lab. Nota di bawah kekal sebagai rujukan untuk kohort akan datang. Bahagian [🔁 Pembukaan Hari 2](#-pembukaan-hari-2-ulang-kaji-hari-1-15-minit) terangkan macam mana nak guna bahan Hari 1 dalam 15 minit pertama Hari 2.

> **Mesej utama hari ini:** *"JMeter ni alat untuk hasilkan load — halakan ke `localhost:3000` sahaja. Dan response code 200 tak semestinya berjaya."* Peserta JPJ terdiri daripada pegawai IT, tester dan developer dengan pengalaman yang berbeza; ramai yang belum pernah run load test. Hari ini **bukan** pasal hafal menu JMeter. Fokusnya ialah **jangka** apa yang akan berlaku sebelum klik Start (berapa sample? Error % berapa? throughput naik atau turun?). Kalau peserta ingat tiga perkara saja: **etika target**, **skop ikut kedudukan**, dan **percentile, bukan average**.

## Ringkasan penyampai

| Perkara | Nilai |
|---------|-------|
| Nisbah | S1 ~50% penerangan + install · S2–S4 ~40% live demo · ~60% lab |
| Bahan | Projektor + JMeter GUI (**Options → Zoom In** dua kali), terminal font ≥ 18pt, Firefox (untuk S4), whiteboard untuk lukis tree skop dan formula throughput |
| File demo | `hari-1/test-plans/01…04`, `rakam-template.jmx`, `rakam-https-template.jmx`; SUT `node sut/server.js` |
| Momen kunci | (1) S1: "200 thread JMeter = 200 penyerang" — slide etika; (2) S2: jangkaan 20 × 5 = 100 disahkan oleh `# Samples`; (3) S3: baris palsu `ABC0000` naikkan Error %; (4) S4: replay rakaman → **401** merah — "esok kita fix" |
| Hasil wajib hujung hari | ≥ 90% peserta: `jmeter -v` jalan, Latihan 1–3 ✅, dan dah tengok sendiri 401 daripada `04-rakaman-mentah.jmx` |

---

> ⚠️ **Tabiat demo:** setiap kali sebelum Start, pastikan Server=`localhost`, Port=`3000`.

---

## ✅ Senarai semak sebelum kelas (malam sebelum / 30 minit awal)

- [ ] **USB/pemacu kongsi** dengan: pemasang **Temurin JDK 21** (Windows `.msi`, macOS `.pkg`), `apache-jmeter-5.6.3.zip`, pemasang **Node.js 18+/22 LTS**, dan salinan repo kursus — Wi-Fi makmal kerajaan sering perlahan atau menyekat muat turun.
- [ ] Mesin demo: `java --version`, `jmeter -v`, `node --version` semua berjalan.
- [ ] `node sut/server.js` → `http://localhost:3000/api/health` memulangkan `{"status":"ok",…}`.
- [ ] Jalankan semakan non-GUI pada mesin demo:
  ```bash
  node sut/server.js &
  jmeter -n -t hari-1/test-plans/02-cukai-beban.jmx -l /tmp/r02.jtl
  jmeter -n -t hari-1/test-plans/03-csv-berparameter.jmx -l /tmp/r03.jtl
  jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/r04.jtl   # MESTI 200/401/401
  ```
- [ ] **Windows PATH:** sediakan slaid/kertas langkah *User variables → Path → New → `C:\apache-jmeter-5.6.3\bin`* — punca masalah #1 dalam S1. Ingatkan: **buka terminal baharu**.
- [ ] **Hak admin:** semak sama ada peserta ada hak admin. Jika tidak: JDK `.msi` mungkin gagal → guna Temurin **ZIP** + `JAVA_HOME` pada User variables; sijil CA → store **Current User** sahaja (ralat *"cert not owner"*).
- [ ] **Firefox** dipasang pada mesin peserta (S4). Jika tiada, `curl` melalui proxy sudah memadai.
- [ ] **Port 3000 dan 8888** bebas pada mesin peserta (aplikasi lain, cth. Docker/IIS, kadang-kadang menggunakan 3000/8888).
- [ ] Antivirus/proksi korporat: JMeter proxy pada `localhost:8888` kadang-kadang disekat — uji sekali pada satu mesin makmal.
- [ ] Padam `ApacheJMeterTemporaryRootCA.crt` lama pada mesin demo (sah 7 hari) supaya demo S4 menunjukkan penjanaan baharu.

---

## S1 · 9.00 – 10.30 pagi · Pengenalan Ujian Prestasi & Persediaan (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 9.00 – 9.10 | 0–10 | Aluan, objektif 2 hari, kenalkan **Portal eJPJ (tiruan)**. Survey tahap peserta (angkat tangan). | Tanya: "Pernah guna JMeter / LoadRunner / k6?" "Pernah tulis script?" "Pernah alami sistem down masa hari peak?" Pair-kan yang berpengalaman dengan yang baru. |
| 9.10 – 9.25 | 10–25 | README §1.1–1.2: apa itu performance testing, 4 komponen (Beban/Senario/Metrik/Kriteria), 5 jenis test. | Minta peserta bagi contoh JPJ untuk setiap jenis (hari harga naik = Spike; cuti panjang = Soak). |
| 9.25 – 9.35 | 25–35 | §1.3 **Etika** — slide "200 thread = 200 penyerang". | **Momen kunci #1.** Tegas, tapi jangan sampai takutkan peserta. Tengok *Mesej utama S1* di bawah. |
| 9.35 – 10.10 | 35–70 | **Latihan 0**: install Java + JMeter, **PATH Windows**, `jmeter -v`. | Pusing tengok setiap meja. Edarkan USB awal kalau download lambat. Peserta yang laju: tolong rakan sebelah + ⭐ Cabaran Latihan 0. |
| 10.10 – 10.20 | 70–80 | §1.6–1.7: GUI vs non-GUI; run SUT; jadual endpoint. **Live:** `curl -s http://localhost:3000/api/health`; buka `/` dalam browser. | Tunjuk console SUT yang print latency & error rate. |
| 10.20 – 10.30 | 80–90 | §1.8 tour GUI (tree, panel, Start/Stop/Clear All, Log). **Kuiz S1**. | Tunjuk ikon Log — "kalau ada benda pelik, buka ni dulu". |

**Mesej utama S1 — etika (skrip):**
> *"JMeter tak tahu beza antara test dengan serangan. Server pun tak tahu. Kalau anda halakan 200 thread ke portal JPJ sebenar tanpa kelulusan bertulis, dari segi undang-undang itu dikira serangan DoS (denial of service) — walaupun anda pegawai JPJ, walaupun niat baik. Sebab itu dua hari ni kita hanya test `localhost:3000`. Bila balik ke pejabat dan nak test staging: dapatkan kelulusan bertulis daripada system owner, nyatakan host, tahap load dan time window, maklumkan team infra dan team monitoring, dan pastikan ada orang yang boleh tekan Stop."*

**Soalan untuk ditanya:**
- "Kenapa tak test terus portal sebenar — lagi realistik, kan?" (isu undang-undang + risiko ganggu servis kepada rakyat; staging dengan kebenaran ialah cara yang betul)
- "Apa beza functional test dengan performance test?" (berfungsi vs tahan load)
- "Kalau Average 200 ms, semua user puas hati ke?" (tanam idea percentile untuk S2)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Load kecil (10–50 thread) tak apa kalau buat kat production" | Status undang-undang tak bergantung pada saiz load. Lagipun 50 thread tanpa think time boleh hasilkan ratusan req/s. |
| "JMeter ni macam browser" | JMeter hantar HTTP request saja — ia **tak** run JavaScript atau render page. Response time ≠ masa page siap load dalam browser. |
| "GUI cukup untuk load test" | GUI untuk bina/debug saja; load sebenar = non-GUI (Hari 2). |
| "PATH dah tambah, mesti jalan" | Hanya dalam **terminal baru**. |

**✅ Sebelum masuk S2:** ≥ 90% peserta `jmeter -v` dah jalan **dan** SUT dah running. Yang belum: pair-kan dengan rakan dan teruskan guna GUI dari `bin\jmeter.bat` — PATH boleh fix masa rehat.

---

## 10.30 – 10.45 pagi · Rehat

5 minit terakhir rehat: pusing tolong peserta yang PATH/Java belum settle.

---

## S2 · 10.45 pagi – 1.00 tgh · Anatomi Test Plan, Thread Group & Listeners (135 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 10.45 – 10.50 | 0–5 | Recap: 3 soalan cepat (Spike vs Soak, target yang sah, kenapa non-GUI). | Pilih peserta dari kumpulan "baru". |
| 10.50 – 11.10 | 5–25 | §2.1 anatomi tree + jadual kategori. **Whiteboard:** lukis tree, bulatkan skop setiap elemen. Tulis turutan execution Config → Pre → Timer → Sampler → Post → Assertion → Listener. | Ini konsep paling penting hari ini. Ulang: *"Kedudukan = skop."* |
| 11.10 – 11.35 | 25–50 | **Demo `01-hello-jpj.jmx`** (tengok skrip demo) → **Latihan 1**. | Mula demo dengan check HTTP Request Defaults depan semua orang. |
| 11.35 – 11.55 | 50–70 | §2.3 Thread Group. **Whiteboard:** jadual "kira sebelum klik Start". Tanya jangkaan untuk 20/10/5. | **Momen kunci #2** — jangkaan 100 disahkan nanti. |
| 11.55 – 12.10 | 70–85 | §2.4 HTTP Header Manager; sebut Cookie/Cache Manager. **Live:** tunjuk header dalam tab Request. | Tanam idea: rakaman S4 nanti akan buat Header Manager untuk setiap sampler. |
| 12.10 – 12.35 | 85–110 | §2.5 Listeners + kamus column. **Live:** run 20/10/5 tanpa assertion → Summary + Aggregate. Baca setiap column sama-sama. | Contoh 99 × 100 ms + 1 × 10 s → Average 199 ms. Tulis di whiteboard. |
| 12.35 – 12.50 | 110–125 | Peserta mula **Latihan 2** langkah 1, 2, 6, 7 (load + listener, belum ada assertion). | Check `# Samples` = 100 pada 3 pasangan. |
| 12.50 – 1.00 | 125–135 | **Kuiz S2** + jambatan: *"Semua hijau — tapi betul ke semuanya? Lepas makan: assertion."* | |

**Skrip ringkas (skop):**
> *"Bayangkan setiap elemen ni macam payung. Payung di bawah Thread Group lindungi semua sampler di bawahnya. Payung yang dipegang oleh satu sampler — sebagai child — hanya lindungi sampler tu. Kalau assertion 'tak jalan' atau timer 'jadi dua kali', 9 daripada 10 kes payung tu letak di tempat yang salah."*

**Soalan untuk ditanya:**
- "Timer 300 ms di bawah Thread Group yang ada 3 sampler — berapa jeda setiap iteration?" (900 ms)
- "Ramp-up 0 dengan 100 thread — apa jadi?" (semua serentak = spike; jarang realistik)
- "Kenapa SLA ditulis dalam percentile?" (average sorokkan tail)
- "Kenapa View Results Tree kena disable masa load?" (makan memory; angka jadi tak tepat)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Susunan dalam tree = turutan execution" | Untuk jenis elemen berbeza, JMeter ikut turutan tetap (Timer **sebelum** sampler). Hanya sampler & elemen sama jenis ikut susunan tree. |
| "Ramp-up 10 s maksudnya test habis dalam 10 s" | Ramp-up cuma masa untuk start semua thread; tempoh test bergantung pada loop × masa setiap iteration. |
| "Throughput = bilangan users" | Throughput = request yang siap sesaat; bergantung pada threads, response time dan think time. |
| "Error % 0 = sistem bagus" | Tanpa assertion, Error % cuma kira error HTTP/network (S3 akan betulkan ni). |

**✅ Sebelum masuk S3:** ≥ 80% Latihan 1 ✅ dan run 20/10/5 tunjuk 100 sample.

---

## 1.00 – 2.00 ptg · Makan tengah hari

10 minit terakhir: pastikan setiap peserta dah save plan 20/10/5 — S3 akan tambah assertion pada plan tu.

---

## S3 · 2.00 – 3.30 ptg · Assertions, Timers & CSV Data Set (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 2.00 – 2.05 | 0–5 | Naikkan semangat lepas makan: **kuiz berdiri** — "Berdiri kalau anda rasa response code 200 maksudnya response betul." | Lepas tu tunjuk 200 dengan body `{"ralat":…}` (contoh andaian). |
| 2.05 – 2.20 | 5–20 | §3.1 Response + Duration Assertion. **Demo `02-cukai-beban.jmx`** (tengok skrip). | Tunjuk *Assertion failure message* dengan turunkan Duration ke 100 ms secara live. |
| 2.20 – 2.30 | 20–30 | §3.2 Timers (Constant / Uniform / Gaussian). **Whiteboard:** throughput ≈ threads ÷ (response + think time). | Kira sama-sama: dengan dan tanpa timer 300 ms. |
| 2.30 – 2.45 | 30–45 | Peserta siapkan **Latihan 2** (assertion + timer). | Silap paling kerap: sampler lama masih enabled → 200/300 sample. |
| 2.45 – 3.00 | 45–60 | §3.3 CSV Data Set Config. **Demo `03-csv-berparameter.jmx`** → **Latihan 3**. | Tekankan path relatif kepada `.jmx` dan *Ignore first line*. |
| 3.00 – 3.10 | 60–70 | **Latihan 4** — baris palsu `ABC0000`. | **Momen kunci #3.** Minta peserta teka Error % dulu (~1/6). |
| 3.10 – 3.20 | 70–80 | **Latihan 5** (latency tinggi) — atau penceramah demo sendiri kalau masa tak cukup. | Bandingkan jadual sebelum/selepas di whiteboard. |
| 3.20 – 3.30 | 80–90 | **Kuiz S3**. Kes 1–5 (§3.4) dan Latihan 7 ⭐ untuk peserta yang laju / kerja rumah. | |

**Skrip ringkas (assertion):**
> *"Tanpa assertion, JMeter cuma tanya 'server jawab ke tak?'. Dengan assertion, dia tanya 'server jawab dengan **betul** dan **cukup laju** ke tak?'. Error % yang anda report kepada management mesti jawapan untuk soalan kedua."*

**Soalan untuk ditanya:**
- "Tambah timer 1000 ms — Average naik tak?" (tak; throughput yang turun — masa timer tak dikira dalam masa sample)
- "CSV 5 baris, 10 thread × 10 loop, Recycle True — apa jadi lepas baris ke-5?" (balik ke baris pertama)
- "Bila nak guna Recycle False + Stop thread True?" (data sekali guna, contohnya akaun unik)
- "`../data/` tu dikira dari mana?" (folder file `.jmx`)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Timer tambah response time" | Timer jalan **sebelum** sampler dan tak masuk dalam masa sample; yang turun ialah throughput. |
| "Lagi banyak assertion lagi bagus" | Setiap assertion guna CPU pada load generator; utamakan Substring yang ringkas. |
| "CSV Sharing *All threads* = setiap thread baca seluruh file" | Satu queue dikongsi; setiap kali baca, ambil baris seterusnya. |
| "Path CSV relatif kepada folder terminal" | Relatif kepada file `.jmx`. |

**✅ Sebelum masuk S4:** ≥ 80% Latihan 2 & 3 ✅. Latihan 4–5 boleh siapkan di rumah (README ada langkah penuh).

---

## 3.30 – 3.45 ptg · Rehat

Minta peserta install/buka **Firefox** masa rehat dan pastikan SUT masih running.

---

## S4 · 3.45 – 5.00 ptg · Rakam Test Plan: HTTP(S) Test Script Recorder (75 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 3.45 – 3.55 | 0–10 | §4.1–4.2: macam mana proxy merakam (rajah). Setup recorder + Recording Controller + Excludes. | Cara cepat: buka `rakam-template.jmx`. |
| 3.55 – 4.05 | 10–20 | §4.3–4.4 **Live:** Start recorder → `curl -x http://localhost:8888 …` log masuk → sampler keluar. Tunjuk setting Firefox + *No proxy for*. | `curl` paling stabil untuk POST; Firefox untuk tunjuk konsep. |
| 4.05 – 4.30 | 20–45 | **Latihan 6**. | Masalah paling kerap: tak ada apa yang direkod (No proxy for / recorder belum Start) dan quote `curl` dalam cmd.exe. |
| 4.30 – 4.40 | 45–55 | §4.5 HTTPS + certificate CA (**demo `rakam-https-template.jmx`** — generate certificate saja). | Tunjuk jadual Windows **Current User** vs Local Machine. Ingatkan: buang certificate lepas guna. |
| 4.40 – 4.50 | 55–65 | §4.6–4.7 **Demo `04-rakaman-mentah.jmx`** non-GUI + `-e -o` → HTML report ~67% error. | **Momen kunci #4.** Biarkan 401 merah kekal di skrin. |
| 4.50 – 5.00 | 65–75 | **Kuiz S4** + **Kuiz hari** + jambatan ke Hari 2 (tengok di bawah). | Minta peserta save plan rakaman masing-masing. |

**Soalan untuk ditanya:**
- "Kenapa log masuk dapat 200 tapi langkah seterusnya 401?" (token baru dikeluarkan tapi tak digunakan; token lama yang dihantar)
- "Nilai mana dalam rakaman yang berubah setiap session?" (`token`, `csrf`)
- "Kenapa kena buang certificate CA JMeter lepas rakam?" (sesiapa yang ada key CA tu boleh MITM traffic anda)
- "Kenapa Excludes static asset?" (bukan load yang kita nak ukur; sampler sampah)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Rakaman = script siap untuk load test" | Rakaman cuma titik mula: kena cleanup, parameterize, dan buat **korelasi**. |
| "Perlu certificate CA untuk rakam localhost" | Hanya untuk **HTTPS**. SUT kita guna `http://`. |
| "Recorder boleh rakam apa-apa browser secara automatik" | Hanya traffic yang **dihalakan** ke proxy `:8888`. |
| "Template HTTPS boleh guna untuk mana-mana website" | Dari segi teknikal boleh — dari segi etika hanya website milik anda / yang ada kebenaran bertulis. |

**✅ Kriteria tamat hari:** ≥ 90% peserta dah tengok sendiri **401** daripada replay rakaman (Latihan 6 atau `04-rakaman-mentah.jmx`) dan boleh sebut `token` + `csrf` sebagai nilai dinamik.

---

## 🎬 Skrip demo setiap test plan

### `01-hello-jpj.jmx` — Test Plan pertama (S2, ~8 minit)

1. **File → Open** → `hari-1/test-plans/01-hello-jpj.jmx`.
2. Klik **HTTP Request Defaults** → *"Perkara pertama: plan ni hantar request ke mana?"* Tunjuk `localhost` / `3000` dan Thread Group 1 / 1 / 1 — guna saat ni untuk ingatkan pasal etika (target mesti check dulu sebelum Start).
3. Tunjuk dua sampler: `GET /api/health` dan `GET / (halaman info)`.
4. **Start** → View Results Tree → klik setiap sample: tab Sampler result (200, masa), Request (URL penuh), Response data (pilih *JSON*).
5. Tanya: *"Server Name dalam sampler kosong — URL penuh tu datang dari mana?"* (HTTP Request Defaults).

**Jangkaan:** 2 sample hijau, 200, `{"status":"ok",…}` dan HTML `<h1>Portal eJPJ (TIRUAN)</h1>`.

### `02-cukai-beban.jmx` — Ujian beban + assertion + timer (S2/S3, ~10 minit)

1. Buka file. Tunjuk tree: HTTP Request Defaults (`localhost:3000`), HTTP Header Manager (`Accept: application/json`), Thread Group *"Pengguna Semak Cukai"* 20 / 10 / 5.
2. Sampler `GET /api/kenderaan/WXY1234/cukai` dengan child *"Respons mengandungi 'amaun'"* dan *"Tempoh < 2000ms"*. Timer *"Think Time 300ms"*.
3. Listener: Summary Report, Aggregate Report, dan *"View Results Tree (nyahaktif semasa beban)"* — terangkan kenapa nama dia macam tu.
4. **Minta peserta teka** `# Samples` → Start → sahkan **100**, Error % 0.
5. **Live:** tukar Duration Assertion ke `100` → Clear All → Start → Error % melonjak. Buka sample merah → *Assertion failure message*. Tukar balik ke `2000`.

**Jangkaan:** 100 sample, 0% error (dengan 2000 ms), Average ~40–180 ms (latency default SUT).

### `03-csv-berparameter.jmx` — CSV berparameter (S3, ~8 minit)

1. Buka file. Tunjuk **CSV Data Set Config - kenderaan**: `../data/kenderaan.csv`, `no_pendaftaran,model`, Ignore first line True, Recycle True, Stop thread False, Sharing *All threads*.
2. Tunjuk **Uniform Random Timer (0.5-1.5s)**: Constant Delay Offset 500 + Random Delay Maximum 1000.
3. Start (10 × 10) → View Results Tree → tunjuk 5 nombor pendaftaran yang bergilir.
4. **Live (Latihan 4):** tambah `ABC0000,Kereta Hantu` dalam CSV → Start → Error % naik → **buang balik baris tu**.

**Jangkaan:** 100 sample cukai, 0% error; dengan `ABC0000` ~1/6 gagal.

### `04-rakaman-mentah.jmx` — Rakaman mentah yang gagal (S4, ~8 minit)

> ⛔ **Jangan "fix" file ni.** Kegagalan tu sendiri ialah pengajarannya.

1. Buka file. Tunjuk Recording Controller dengan 3 sampler: `/api/log-masuk`, `/api/kenderaan`, `/api/kenderaan/WXY1234/bayar-cukai`.
2. Buka Header Manager sampler #2 → `Authorization: Bearer 4e6b9c2a-8f0d-4c11-9a2e-token-rakaman-luput`. Buka body sampler #3 → `"csrf": "a1b2c3d4e5f6a7b8-csrf-rakaman-luput"`. *"Nilai ni beku pada saat rakaman dibuat."*
3. Tunjuk HTTP(S) Test Script Recorder dalam plan ni **disabled** — elemen GUI saja, non-GUI akan abaikan.
4. Terminal:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
5. Buka `/tmp/laporan-rakaman/index.html` → Error % **~67%**. Lepas tu buka plan dalam GUI → Start → View Results Tree: 200 hijau, 401 merah, 401 merah (assertion *"Sepatutnya BERJAYA (akan GAGAL tanpa korelasi)"*).
6. Tutup dengan: *"Log masuk berjaya dan dapat token baru — tapi tak ada siapa yang tangkap. Esok pagi kita tangkap."*

**Jangkaan:** `/api/log-masuk` 200 · `/api/kenderaan` 401 · `bayar-cukai` 401. Kalau folder report dah wujud → `-o` akan gagal; delete dulu.

### `rakam-https-template.jmx` — Persediaan rakaman HTTPS (S4, ~6 minit)

1. Buka file: recorder port 8888, Recording Controller, **tiada filter host** (Includes kosong) — ia akan rakam **semua** yang browser hantar melalui proxy.
2. Klik **Start** sekali → tunjuk file `bin/ApacheJMeterTemporaryRootCA.crt` yang dijana (sah 7 hari) → **Stop**.
3. Tunjuk (tak perlu buat sampai habis kalau masa tak cukup) import ke Firefox **Authorities** dan jadual Windows **Current User**.
4. **Jangan** buka portal JPJ sebenar atau website awam masa demo. Kalau perlu live demo, guna laman demo yang benarkan testing (contohnya `blazedemo.com`, satu dua page saja) atau staging yang ada kebenaran bertulis.
5. Guna **profile Firefox yang bersih** — tanpa filter host, telemetry browser dan extension pun akan ikut direkod.
6. Tutup dengan **buang certificate** dan reset balik proxy Firefox.

---

## 🧯 Pelan kejar (catch-up)

| Situasi | Tindakan |
|---------|----------|
| Install Java/JMeter lambat (Wi-Fi perlahan / tiada admin) | Edar USB. Tiada admin: Temurin ZIP + `JAVA_HOME` & Path pada **User variables**. Masih gagal: pair-kan dengan rakan; ikut di skrin rakan sampai rehat. |
| PATH Windows tak jalan | Run terus `C:\apache-jmeter-5.6.3\bin\jmeter.bat` — PATH cuma untuk senang. Fix masa rehat. |
| Kelas lewat > 20 minit bila sampai S3 | Gabungkan Latihan 2 & 3 (bina CSV terus atas plan 20/10/5); Latihan 4 & 5 jadi demo penceramah. |
| Kelas lewat > 20 minit bila sampai S4 | Skip setup recorder dari kosong — guna `rakam-template.jmx` + `curl`. HTTPS cuma slide. Pastikan **semua** tengok 401 dari `04-rakaman-mentah.jmx` (non-GUI, 1 minit). |
| Firefox tiada / disekat oleh policy | `curl` melalui proxy (Latihan 6 langkah 3). Windows cmd: guna versi double quote dalam 🧯 Latihan 6, atau Git Bash. |
| Port 8888 dah dipakai | Tukar port recorder (contohnya 8889) dan `curl -x http://localhost:8889`. |
| Peserta laju / berpengalaman | ⭐ Cabaran setiap lab; Kes 1–5 dalam README §3.4; Latihan 7; rakaman 3 langkah penuh dalam `rakaman-e2e.md`. |

---

## 🌉 Jambatan ke Hari 2 (5 minit terakhir)

Biarkan HTML report ~67% error atau View Results Tree dengan dua 401 merah kekal di skrin.

> *"Hari ni kita belajar hasilkan load, validate response, dan rakam. Tapi rakaman kita gagal — bukan sebab JMeter rosak, tapi sebab portal bagi token dan csrf yang **baru** untuk setiap session, sedangkan rakaman simpan yang **lama**. Esok pagi benda pertama kita buat ialah **korelasi**: tangkap `token` dan `csrf` daripada response log masuk guna **JSON Extractor**, guna semula sebagai `${token}` dan `${csrf}` — dan tengok Error % jatuh dari ~67% ke 0%. Lepas tu kita run load sebenar secara non-GUI, dan baca report macam performance engineer."*

Persediaan untuk peserta (juga ada dalam README ➡️):
- Pastikan `jmeter -v` dan `node --version` jalan.
- Save plan rakaman sendiri (`rakaman-saya.jmx`).
- Bawa nilai Throughput / Average / 95% Line dari Latihan 2 dan 5.

---

## 🔁 Pembukaan Hari 2: ulang kaji Hari 1 (15 minit)

Untuk kohort ni (Hari 1 pada 21 Sep 2026 → Hari 2 pada 5 Okt 2026 — jarak dua minggu), mula Hari 2 dengan ulang kaji ringkas:

| Minit | Aktiviti |
|-------|----------|
| 0–5 | Peserta jawab **Kuiz hari — Penilaian kendiri Hari 1** (5 soalan) dalam LMS. |
| 5–10 | Bincang soalan yang paling ramai salah (tengok statistik LMS). Ulang tiga mesej: etika target, skop ikut kedudukan, percentile bukan average. |
| 10–15 | Semua orang start SUT dan run `04-rakaman-mentah.jmx` sekali — tengok 200 / 401 / 401 — terus masuk topik korelasi. |

Check juga peserta yang belum tanda ✅ Checkpoint Latihan 0–3 dalam LMS — mungkin mereka perlukan bantuan install sebelum S1 Hari 2 bermula.

---

## 📋 Semakan akhir hari (jurulatih)

- [ ] Rekod bilangan peserta yang melihat 401 dari main balik rakaman (sasaran ≥ 90%)
- [ ] Catat 3 kekeliruan paling kerap → buka Hari 2 dengan membetulkannya (5 minit)
- [ ] Pastikan setiap mesin boleh `node sut/server.js` dan `jmeter -v` — Hari 2 bergantung padanya
- [ ] Pastikan **tiada** peserta meninggalkan sijil `ApacheJMeterTemporaryRootCA` dipercayai dalam pelayar/OS, dan proxy Firefox dipulihkan
- [ ] Pulihkan `hari-1/data/kenderaan.csv` pada mesin yang masih ada baris `ABC0000`
