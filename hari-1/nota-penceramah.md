# Nota Penceramah — Hari 1: Asas Apache JMeter & Ujian Beban

[📖 README Hari 1](./README.md) · [🧪 Lab](./snippets/lab.md) · [🎬 Rakam → Main Balik](./snippets/rakaman-e2e.md) · [🔒 Rakaman HTTPS](./snippets/rakaman-https-setup.md) · [🔑 Test plan rujukan](./test-plans/) · [⚙️ SUT](../sut/server.js)

> 📌 **Status kohort JPJ:** Hari 1 kohort ini telah berlangsung pada **21 Sep 2026**. **Hari 2 dijadualkan 5 Okt 2026.** Halaman Hari 1 kini digunakan oleh peserta untuk **ulang kaji** — kuiz sesi (Kuiz S1–S4), Semakan Kendiri dan **Kuiz hari** dalam README, serta ✅ Checkpoint dalam lab. Nota di bawah kekal sebagai rujukan untuk kohort akan datang, dan bahagian [🔁 Pembukaan Hari 2](#-pembukaan-hari-2-ulang-kaji-hari-1-15-minit) menerangkan cara menggunakan bahan Hari 1 dalam 15 minit pertama Hari 2.

> **Mesej utama hari ini:** *"JMeter ialah senjata beban — halakan ia ke `localhost:3000` sahaja. Dan kod 200 bukan bermakna berjaya."* Peserta JPJ terdiri daripada pegawai IT, penguji dan pembangun dengan pengalaman berbeza; ramai belum pernah menjalankan ujian beban. Hari ini **bukan** tentang menghafal menu JMeter; ia tentang **meramal** apa yang akan berlaku sebelum klik Start (berapa sampel? Error %? throughput naik/turun?). Jika hanya tiga perkara diingati: **etika sasaran**, **skop mengikut kedudukan**, dan **percentile, bukan purata**.

## Ringkasan penyampai

| Perkara | Nilai |
|---------|-------|
| Nisbah | S1 ~50% penerangan + pemasangan · S2–S4 ~40% demo langsung · ~60% lab |
| Bahan | Projektor + JMeter GUI (**Options → Zoom In** dua kali), terminal fon ≥ 18pt, Firefox (untuk S4), papan putih untuk pokok skop dan formula throughput |
| Fail demo | `hari-1/test-plans/01…04`, `rakam-template.jmx`, `rakam-https-template.jmx`; SUT `node sut/server.js` |
| Momen kunci | (1) S1: "200 thread JMeter = 200 penyerang" — slaid etika; (2) S2: ramalan 20 × 5 = 100 disahkan oleh `# Samples`; (3) S3: baris palsu `ABC0000` menaikkan Error %; (4) S4: main balik rakaman → **401** merah — "esok kita baiki" |
| Hasil wajib hujung hari | ≥ 90% peserta: `jmeter -v` berfungsi, Latihan 1–3 ✅, dan pernah melihat 401 daripada `04-rakaman-mentah.jmx` |

---

> ⚠️ **Tabiat demo:** sentiasa sahkan Server=`localhost`, Port=`3000` sebelum Start.

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
| 9.00 – 9.10 | 0–10 | Aluan, objektif 2 hari, perkenal **Portal eJPJ (tiruan)**. Tinjauan tahap (angkat tangan). | Tinjauan: "Pernah guna JMeter / LoadRunner / k6?" "Pernah tulis skrip?" "Pernah alami sistem jatuh semasa hari puncak?" Pasangkan berpengalaman + baharu. |
| 9.10 – 9.25 | 10–25 | README §1.1–1.2: apa itu ujian prestasi, 4 komponen (Beban/Senario/Metrik/Kriteria), 5 jenis ujian. | Minta peserta beri contoh JPJ untuk setiap jenis (hari harga naik = Spike; cuti panjang = Soak). |
| 9.25 – 9.35 | 25–35 | §1.3 **Etika** — slaid "200 thread = 200 penyerang". | **Momen kunci #1.** Tegas, bukan menakutkan. Lihat *Mesej utama S1* di bawah. |
| 9.35 – 10.10 | 35–70 | **Latihan 0**: pasang Java + JMeter, **PATH Windows**, `jmeter -v`. | Rondaan. Edarkan USB awal jika muat turun perlahan. Peserta pantas: bantu jiran + ⭐ Cabaran Latihan 0. |
| 10.10 – 10.20 | 70–80 | §1.6–1.7: GUI vs non-GUI; jalankan SUT; jadual endpoint. **Live:** `curl -s http://localhost:3000/api/health`; buka `/` dalam pelayar. | Tunjuk konsol SUT mencetak latensi & kadar ralat. |
| 10.20 – 10.30 | 80–90 | §1.8 lawatan GUI (pokok, panel, Start/Stop/Clear All, Log). **Kuiz S1**. | Tunjuk ikon Log — "bila pelik, buka ini dahulu". |

**Mesej utama S1 — etika (skrip):**
> *"JMeter tidak tahu beza antara ujian dan serangan. Pelayan juga tidak tahu. Jika anda halakan 200 thread ke portal JPJ sebenar tanpa kelulusan bertulis, dari sudut undang-undang itu serangan penafian perkhidmatan — walaupun anda pegawai JPJ, walaupun niatnya baik. Sebab itu dua hari ini kita hanya menembak `localhost:3000`. Bila anda kembali ke pejabat dan mahu menguji staging: dapatkan kelulusan bertulis pemilik sistem, nyatakan hos, paras beban dan tetingkap masa, maklumkan pasukan infrastruktur dan pemantauan, dan pastikan ada orang yang boleh tekan Stop."*

**Soalan untuk ditanya:**
- "Kenapa tidak terus uji portal sebenar — lebih realistik?" (undang-undang + risiko gangguan kepada rakyat; staging dengan kebenaran ialah jalan yang betul)
- "Apa beza ujian fungsian dan ujian prestasi?" (berfungsi vs tahan beban)
- "Jika Average 200 ms, adakah semua pengguna gembira?" (tanam benih percentile untuk S2)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Beban kecil (10–50 thread) tidak apa-apa pada production" | Status undang-undang tidak bergantung pada saiz. Dan 50 thread tanpa think time boleh menjana ratusan req/s. |
| "JMeter ialah pelayar" | JMeter menghantar permintaan HTTP — ia **tidak** menjalankan JavaScript atau melukis halaman. Masa respons ≠ masa halaman dimuatkan dalam pelayar. |
| "GUI cukup untuk ujian beban" | GUI untuk bina/nyahpepijat sahaja; beban sebenar = non-GUI (Hari 2). |
| "PATH sudah ditambah, mesti berfungsi" | Hanya dalam **terminal baharu**. |

**✅ Sebelum bergerak ke S2:** ≥ 90% peserta `jmeter -v` berfungsi **dan** SUT berjalan. Mereka yang belum: pasangkan dengan rakan dan teruskan dengan GUI dari `bin\jmeter.bat` — PATH boleh dibaiki semasa rehat.

---

## 10.30 – 10.45 pagi · Rehat

Rondaan 5 minit terakhir: bantu peserta yang PATH/Java belum selesai.

---

## S2 · 10.45 pagi – 1.00 tgh · Anatomi Test Plan, Thread Group & Listeners (135 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 10.45 – 10.50 | 0–5 | Imbas semula: 3 soalan pantas (Spike vs Soak, sasaran sah, kenapa non-GUI). | Pilih peserta dari kumpulan "baharu". |
| 10.50 – 11.10 | 5–25 | §2.1 anatomi pokok + jadual kategori. **Papan putih:** lukis pokok, bulatkan skop setiap elemen. Tulis susunan pelaksanaan Config → Pre → Timer → Sampler → Post → Assertion → Listener. | Ini konsep paling penting hari ini. Ulang: *"Kedudukan = skop."* |
| 11.10 – 11.35 | 25–50 | **Demo `01-hello-jpj.jmx`** (lihat skrip demo) → **Latihan 1**. | Mula demo dengan menyemak HTTP Request Defaults secara terbuka. |
| 11.35 – 11.55 | 50–70 | §2.3 Thread Group. **Papan putih:** jadual "kira sebelum klik Start". Tanya ramalan untuk 20/10/5. | **Momen kunci #2** — ramalan 100 disahkan kemudian. |
| 11.55 – 12.10 | 70–85 | §2.4 HTTP Header Manager; sebut Cookie/Cache Manager. **Live:** tunjuk header dalam tab Request. | Tanam benih: rakaman S4 akan mencipta Header Manager per sampler. |
| 12.10 – 12.35 | 85–110 | §2.5 Listeners + kamus lajur. **Live:** jalankan 20/10/5 tanpa assertion → Summary + Aggregate. Baca setiap lajur bersama. | Contoh 99 × 100 ms + 1 × 10 s → Average 199 ms. Tulis di papan. |
| 12.35 – 12.50 | 110–125 | Peserta mula **Latihan 2** langkah 1, 2, 6, 7 (beban + listener, tanpa assertion lagi). | Semak `# Samples` = 100 pada 3 pasangan. |
| 12.50 – 1.00 | 125–135 | **Kuiz S2** + jambatan: *"Semua hijau — tapi adakah semuanya betul? Selepas makan: assertion."* | |

**Skrip ringkas (skop):**
> *"Bayangkan setiap elemen ialah payung. Payung di bawah Thread Group melindungi semua sampler di bawahnya. Payung yang dipegang oleh satu sampler — sebagai anak — hanya melindungi sampler itu. Bila assertion 'tak jalan' atau timer 'berganda', 9 daripada 10 kali payung itu di tempat yang salah."*

**Soalan untuk ditanya:**
- "Timer 300 ms di bawah Thread Group dengan 3 sampler — jeda setiap lelaran?" (900 ms)
- "Ramp-up 0 dengan 100 thread — apa yang berlaku?" (semua serentak = spike; jarang realistik)
- "Kenapa SLA ditulis dalam percentile?" (purata menyembunyikan ekor)
- "Kenapa View Results Tree dimatikan semasa beban?" (memori; angka tidak tepat)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Susunan visual dalam pokok = susunan pelaksanaan" | Untuk jenis berbeza, JMeter ikut susunan tetap (Timer **sebelum** sampler). Hanya sampler & elemen sejenis ikut susunan pokok. |
| "Ramp-up 10 s bermakna ujian tamat dalam 10 s" | Ramp-up hanya masa melancarkan thread; tempoh ujian bergantung pada loop × masa setiap lelaran. |
| "Throughput = bilangan pengguna" | Throughput = permintaan siap sesaat; bergantung pada threads, masa respons dan think time. |
| "Error % 0 = sistem bagus" | Tanpa assertion, Error % hanya mengira ralat HTTP/rangkaian (S3 membetulkan ini). |

**✅ Sebelum bergerak ke S3:** ≥ 80% Latihan 1 ✅ dan larian 20/10/5 menunjukkan 100 sampel.

---

## 1.00 – 2.00 ptg · Makan tengah hari

Rondaan 10 minit terakhir: pastikan setiap peserta ada plan 20/10/5 tersimpan — S3 menambah assertion padanya.

---

## S3 · 2.00 – 3.30 ptg · Assertions, Timers & CSV Data Set (90 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 2.00 – 2.05 | 0–5 | Tenaga selepas makan: **kuiz berdiri** — "Berdiri jika kod 200 bermakna respons betul." | Kemudian tunjuk 200 dengan badan `{"ralat":…}` (contoh hipotesis). |
| 2.05 – 2.20 | 5–20 | §3.1 Response + Duration Assertion. **Demo `02-cukai-beban.jmx`** (lihat skrip). | Tunjuk *Assertion failure message* dengan menurunkan Duration ke 100 ms secara langsung. |
| 2.20 – 2.30 | 20–30 | §3.2 Timers (Constant / Uniform / Gaussian). **Papan putih:** throughput ≈ threads ÷ (respons + think time). | Ramalkan bersama: dengan dan tanpa timer 300 ms. |
| 2.30 – 2.45 | 30–45 | Peserta siapkan **Latihan 2** (assertion + timer). | Kesilapan paling kerap: sampler lama masih aktif → 200/300 sampel. |
| 2.45 – 3.00 | 45–60 | §3.3 CSV Data Set Config. **Demo `03-csv-berparameter.jmx`** → **Latihan 3**. | Tekankan laluan relatif kepada `.jmx` dan *Ignore first line*. |
| 3.00 – 3.10 | 60–70 | **Latihan 4** — baris palsu `ABC0000`. | **Momen kunci #3.** Minta ramalan Error % dahulu (~1/6). |
| 3.10 – 3.20 | 70–80 | **Latihan 5** (latensi tinggi) — atau demo oleh penceramah jika masa suntuk. | Bandingkan jadual sebelum/selepas di papan. |
| 3.20 – 3.30 | 80–90 | **Kuiz S3**. Kes 1–5 (§3.4) dan Latihan 7 ⭐ untuk peserta pantas / kerja rumah. | |

**Skrip ringkas (assertion):**
> *"Tanpa assertion, JMeter hanya bertanya 'pelayan jawab tak?'. Dengan assertion, ia bertanya 'pelayan jawab dengan **betul** dan **cukup cepat** tak?'. Error % yang anda laporkan kepada pengurusan mesti jawapan soalan kedua."*

**Soalan untuk ditanya:**
- "Tambah timer 1000 ms — Average naik?" (tidak; throughput turun — masa timer tidak dikira dalam masa sampel)
- "CSV 5 baris, 10 thread × 10 gelung, Recycle True — apa berlaku selepas baris ke-5?" (kembali ke baris pertama)
- "Bila guna Recycle False + Stop thread True?" (data sekali guna, cth. akaun unik)
- "Dari mana `../data/` dikira?" (folder fail `.jmx`)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Timer menambah masa respons" | Timer berlaku **sebelum** sampler dan tidak dimasukkan dalam masa sampel; ia menurunkan throughput. |
| "Lebih banyak assertion = lebih baik" | Setiap assertion ada kos CPU pada penjana beban; utamakan Substring yang ringkas. |
| "CSV Sharing *All threads* = setiap thread baca keseluruhan fail" | Satu barisan dikongsi; setiap pembacaan mengambil baris seterusnya. |
| "Laluan CSV relatif kepada folder terminal" | Relatif kepada fail `.jmx`. |

**✅ Sebelum bergerak ke S4:** ≥ 80% Latihan 2 & 3 ✅. Latihan 4–5 boleh disiapkan di rumah (README ada langkah penuh).

---

## 3.30 – 3.45 ptg · Rehat

Minta peserta pasang/buka **Firefox** semasa rehat dan pastikan SUT masih berjalan.

---

## S4 · 3.45 – 5.00 ptg · Rakam Test Plan: HTTP(S) Test Script Recorder (75 minit)

| Masa | Minit | Aktiviti | Nota |
|------|-------|----------|------|
| 3.45 – 3.55 | 0–10 | §4.1–4.2: cara proxy merakam (rajah). Sediakan perakam + Recording Controller + Excludes. | Lebih pantas: buka `rakam-template.jmx`. |
| 3.55 – 4.05 | 10–20 | §4.3–4.4 **Live:** Start perakam → `curl -x http://localhost:8888 …` log masuk → sampler muncul. Tunjuk konfigurasi Firefox + *No proxy for*. | `curl` paling boleh dipercayai untuk POST; Firefox untuk menunjukkan konsep. |
| 4.05 – 4.30 | 20–45 | **Latihan 6**. | Masalah paling kerap: tiada apa dirakam (No proxy for / perakam tak Start) dan petikan `curl` dalam cmd.exe. |
| 4.30 – 4.40 | 45–55 | §4.5 HTTPS + sijil CA (**demo `rakam-https-template.jmx`** — jana sijil sahaja). | Tunjuk jadual Windows **Current User** vs Local Machine. Ingatkan: buang sijil selepas guna. |
| 4.40 – 4.50 | 55–65 | §4.6–4.7 **Demo `04-rakaman-mentah.jmx`** non-GUI + `-e -o` → laporan HTML ~67% ralat. | **Momen kunci #4.** Biarkan 401 merah di skrin. |
| 4.50 – 5.00 | 65–75 | **Kuiz S4** + **Kuiz hari** + jambatan ke Hari 2 (lihat di bawah). | Minta peserta simpan plan rakaman mereka. |

**Soalan untuk ditanya:**
- "Kenapa log masuk 200 tetapi langkah seterusnya 401?" (token baharu dikeluarkan tetapi tidak digunakan; token lama dihantar)
- "Nilai mana dalam rakaman yang berubah setiap sesi?" (`token`, `csrf`)
- "Kenapa perlu buang sijil CA JMeter selepas merakam?" (sesiapa yang ada kunci CA boleh MITM trafik anda)
- "Kenapa Excludes aset statik?" (bukan beban yang kita ukur; sampler sampah)

**Salah faham lazim:**

| Salah faham | Pembetulan |
|-------------|------------|
| "Rakaman = skrip siap untuk beban" | Rakaman ialah titik mula: bersihkan, parameterkan, **korelasi**. |
| "Perlu sijil CA untuk merakam localhost" | Hanya untuk **HTTPS**. SUT kita `http://`. |
| "Perakam boleh merakam pelayar apa sahaja secara automatik" | Hanya trafik yang **dihalakan** ke proxy `:8888`. |
| "Templat HTTPS boleh digunakan pada mana-mana laman" | Secara teknikal ya — secara etika hanya laman yang anda miliki / ada kebenaran bertulis. |

**✅ Kriteria tamat hari:** ≥ 90% peserta pernah melihat **401** daripada main balik rakaman (Latihan 6 atau `04-rakaman-mentah.jmx`) dan boleh menamakan `token` + `csrf` sebagai nilai dinamik.

---

## 🎬 Skrip demo setiap test plan

### `01-hello-jpj.jmx` — Test Plan pertama (S2, ~8 minit)

1. **File → Open** → `hari-1/test-plans/01-hello-jpj.jmx`.
2. Klik **HTTP Request Defaults** → *"Perkara pertama: ke mana plan ini menembak?"* Tunjuk `localhost` / `3000` dan Thread Group 1 / 1 / 1 — gunakan saat itu sebagai pengajaran etika (sasaran sentiasa disemak sebelum Start).
3. Tunjuk dua sampler: `GET /api/health` dan `GET / (halaman info)`.
4. **Start** → View Results Tree → klik setiap sampel: tab Sampler result (200, masa), Request (URL penuh), Response data (pilih *JSON*).
5. Tanya: *"Server Name dalam sampler kosong — dari mana URL penuh datang?"* (HTTP Request Defaults).

**Jangkaan:** 2 sampel hijau, 200, `{"status":"ok",…}` dan HTML `<h1>Portal eJPJ (TIRUAN)</h1>`.

### `02-cukai-beban.jmx` — Ujian beban + assertion + timer (S2/S3, ~10 minit)

1. Buka fail. Tunjuk pokok: HTTP Request Defaults (`localhost:3000`), HTTP Header Manager (`Accept: application/json`), Thread Group *"Pengguna Semak Cukai"* 20 / 10 / 5.
2. Sampler `GET /api/kenderaan/WXY1234/cukai` dengan anak *"Respons mengandungi 'amaun'"* dan *"Tempoh < 2000ms"*. Timer *"Think Time 300ms"*.
3. Listener: Summary Report, Aggregate Report, dan *"View Results Tree (nyahaktif semasa beban)"* — terangkan namanya.
4. **Minta ramalan** `# Samples` → Start → sahkan **100**, Error % 0.
5. **Live:** ubah Duration Assertion ke `100` → Clear All → Start → Error % melonjak. Buka sampel merah → *Assertion failure message*. Pulihkan ke `2000`.

**Jangkaan:** 100 sampel, 0% ralat (dengan 2000 ms), Average ~40–180 ms (latensi lalai SUT).

### `03-csv-berparameter.jmx` — CSV berparameter (S3, ~8 minit)

1. Buka fail. Tunjuk **CSV Data Set Config - kenderaan**: `../data/kenderaan.csv`, `no_pendaftaran,model`, Ignore first line True, Recycle True, Stop thread False, Sharing *All threads*.
2. Tunjuk **Uniform Random Timer (0.5-1.5s)**: Constant Delay Offset 500 + Random Delay Maximum 1000.
3. Start (10 × 10) → View Results Tree → tunjuk 5 nombor pendaftaran berpusing.
4. **Live (Latihan 4):** tambah `ABC0000,Kereta Hantu` ke CSV → Start → Error % naik → **buang baris itu**.

**Jangkaan:** 100 sampel cukai, 0% ralat; dengan `ABC0000` ~1/6 gagal.

### `04-rakaman-mentah.jmx` — Rakaman mentah yang gagal (S4, ~8 minit)

> ⛔ **Jangan "baiki" fail ini.** Kegagalannya ialah pengajaran.

1. Buka fail. Tunjuk Recording Controller dengan 3 sampler: `/api/log-masuk`, `/api/kenderaan`, `/api/kenderaan/WXY1234/bayar-cukai`.
2. Buka Header Manager sampler #2 → `Authorization: Bearer 4e6b9c2a-8f0d-4c11-9a2e-token-rakaman-luput`. Buka badan sampler #3 → `"csrf": "a1b2c3d4e5f6a7b8-csrf-rakaman-luput"`. *"Nilai ini dibekukan pada saat rakaman."*
3. Tunjuk HTTP(S) Test Script Recorder dalam plan adalah **disabled** — elemen GUI sahaja, diabaikan oleh non-GUI.
4. Terminal:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
5. Buka `/tmp/laporan-rakaman/index.html` → Error % **~67%**. Kemudian buka plan dalam GUI → Start → View Results Tree: 200 hijau, 401 merah, 401 merah (assertion *"Sepatutnya BERJAYA (akan GAGAL tanpa korelasi)"*).
6. Tutup dengan: *"Log masuk berjaya dan memberi token baharu — tetapi tiada siapa menangkapnya. Esok pagi kita tangkap."*

**Jangkaan:** `/api/log-masuk` 200 · `/api/kenderaan` 401 · `bayar-cukai` 401. Jika folder laporan sudah wujud → `-o` gagal; padam dahulu.

### `rakam-https-template.jmx` — Persediaan rakaman HTTPS (S4, ~6 minit)

1. Buka fail: perakam port 8888, Recording Controller, **tiada penapis hos** (Includes kosong) — ia akan merakam **semua** yang dihantar oleh pelayar melalui proxy.
2. Klik **Start** sekali → tunjuk fail `bin/ApacheJMeterTemporaryRootCA.crt` dijana (sah 7 hari) → **Stop**.
3. Tunjuk (tanpa melakukan sepenuhnya jika masa suntuk) import ke Firefox **Authorities** dan jadual Windows **Current User**.
4. **Jangan** melayari portal JPJ sebenar atau laman awam semasa demo. Jika perlu demo langsung, gunakan laman demo yang membenarkan ujian (cth. `blazedemo.com`, satu dua halaman sahaja) atau staging yang ada kebenaran bertulis.
5. Gunakan **profil Firefox bersih** — tanpa penapis hos, telemetri pelayar dan sambungan juga akan dirakam.
6. Tutup dengan **membuang sijil** dan memulihkan proxy Firefox.

---

## 🧯 Pelan kejar (catch-up)

| Situasi | Tindakan |
|---------|----------|
| Pemasangan Java/JMeter lambat (Wi-Fi perlahan / tiada admin) | Edar USB. Tiada admin: Temurin ZIP + `JAVA_HOME` & Path pada **User variables**. Masih gagal: pasangkan dengan rakan; mereka ikut di skrin rakan sehingga rehat. |
| PATH Windows tidak berfungsi | Jalankan terus `C:\apache-jmeter-5.6.3\bin\jmeter.bat` — PATH hanya keselesaan. Baiki semasa rehat. |
| Kelas lewat > 20 minit menjelang S3 | Gabungkan Latihan 2 & 3 (bina CSV terus atas plan 20/10/5); Latihan 4 & 5 jadi demo penceramah. |
| Kelas lewat > 20 minit menjelang S4 | Langkau pembinaan perakam dari kosong — guna `rakam-template.jmx` + `curl`. HTTPS jadi slaid sahaja. Pastikan **semua** melihat 401 dari `04-rakaman-mentah.jmx` (non-GUI, 1 minit). |
| Firefox tiada / disekat polisi | `curl` melalui proxy (Latihan 6 langkah 3). Windows cmd: guna versi petikan berganda dalam 🧯 Latihan 6, atau Git Bash. |
| Port 8888 sibuk | Tukar port perakam (cth. 8889) dan `curl -x http://localhost:8889`. |
| Peserta pantas / berpengalaman | ⭐ Cabaran setiap lab; Kes 1–5 dalam README §3.4; Latihan 7; rakaman 3 langkah penuh dalam `rakaman-e2e.md`. |

---

## 🌉 Jambatan ke Hari 2 (5 minit terakhir)

Biarkan laporan HTML ~67% ralat atau View Results Tree dengan dua 401 merah di skrin.

> *"Hari ini kita belajar menjana beban, mengesahkan respons, dan merakam. Tetapi rakaman kita gagal — bukan kerana JMeter rosak, tetapi kerana portal memberi setiap sesi token dan csrf yang **baharu**, dan rakaman menyimpan yang **lama**. Esok pagi perkara pertama yang kita buat ialah **korelasi**: tangkap `token` dan `csrf` daripada respons log masuk dengan **JSON Extractor**, gunakan semula sebagai `${token}` dan `${csrf}` — dan lihat Error % jatuh daripada ~67% ke 0%. Kemudian kita jalankan beban sebenar secara non-GUI, dan baca laporan seperti jurutera prestasi."*

Persediaan untuk peserta (juga dalam README ➡️):
- Pastikan `jmeter -v` dan `node --version` berfungsi.
- Simpan plan rakaman sendiri (`rakaman-saya.jmx`).
- Bawa nilai Throughput / Average / 95% Line dari Latihan 2 dan 5.

---

## 🔁 Pembukaan Hari 2: ulang kaji Hari 1 (15 minit)

Untuk kohort ini (Hari 1 pada 21 Sep 2026 → Hari 2 pada 5 Okt 2026 — jarak dua minggu), mulakan Hari 2 dengan ulang kaji pantas:

| Minit | Aktiviti |
|-------|----------|
| 0–5 | Peserta jawab **Kuiz hari — Penilaian kendiri Hari 1** (5 soalan) dalam LMS. |
| 5–10 | Bincang soalan yang paling banyak salah (lihat statistik LMS). Ulang tiga mesej: etika sasaran, skop mengikut kedudukan, percentile bukan purata. |
| 10–15 | Semua orang mulakan SUT dan jalankan `04-rakaman-mentah.jmx` sekali — lihat 200 / 401 / 401 — terus masuk ke korelasi. |

Semak juga peserta yang belum menanda ✅ Checkpoint Latihan 0–3 dalam LMS — mereka mungkin perlukan bantuan pemasangan sebelum S1 Hari 2 bermula.

---

## 📋 Semakan akhir hari (jurulatih)

- [ ] Rekod bilangan peserta yang melihat 401 dari main balik rakaman (sasaran ≥ 90%)
- [ ] Catat 3 kekeliruan paling kerap → buka Hari 2 dengan membetulkannya (5 minit)
- [ ] Pastikan setiap mesin boleh `node sut/server.js` dan `jmeter -v` — Hari 2 bergantung padanya
- [ ] Pastikan **tiada** peserta meninggalkan sijil `ApacheJMeterTemporaryRootCA` dipercayai dalam pelayar/OS, dan proxy Firefox dipulihkan
- [ ] Pulihkan `hari-1/data/kenderaan.csv` pada mesin yang masih ada baris `ABC0000`
