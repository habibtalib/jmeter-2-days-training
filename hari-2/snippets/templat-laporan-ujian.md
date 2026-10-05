# Templat Laporan Ujian Prestasi (Test Report & Findings)

[⬅️ README Hari 2](../README.md) · [🧪 Lab Hari 2](./lab.md) · [📋 Templat Pelan Ujian](./templat-pelan-ujian.md)

> **Cara guna:** Salin fail ini (cth. `laporan-<id-larian>.md`). Bahagian **A** ialah templat kosong ✍️; bahagian **B** ialah contoh yang telah diisi menggunakan **angka sebenar** daripada larian plan `07-beban-puncak-cukai.jmx` terhadap mock `localhost:3000` (JMeter 5.6.3). Angka larian anda akan berbeza sedikit — latensi mock adalah rawak (40–180 ms) dan ~1% bayaran sengaja gagal (500).
>
> **Peraturan emas:** setiap dapatan mesti ada **bukti** (nombor + bahagian dashboard), **kesan** kepada pengguna/perniagaan, dan **cadangan**. Pembaca laporan ialah pengurusan — mulakan dengan keputusan, bukan dengan graf.

---

## A. Templat kosong

### A1. Ringkasan eksekutif ✍️

| | |
|-|-|
| **Keputusan keseluruhan** | LULUS / GAGAL / LULUS BERSYARAT |
| **Satu ayat** | *"Pada \_\_\_ pengguna (\_\_\_ transaksi/s), transaksi \_\_\_ mencapai p95 \_\_\_ ms dan Error % \_\_\_ — \_\_\_ NFR."* |
| **3 perkara utama** | 1. … 2. … 3. … |
| **Tindakan disyorkan** | … |

### A2. Konteks larian ✍️

| Medan | Nilai |
|-------|-------|
| ID larian / tarikh & masa | |
| Sistem & versi | |
| Persekitaran (SUT, penjana beban) | |
| Plan JMeter & versi JMeter | |
| Arahan tepat | `jmeter -n -t … -J… -l … -e -o …` |
| Model beban (pengguna, ramp-up, tempoh, think time) | |
| Jenis ujian (baseline / load / stress / spike / soak) | |
| Fail bukti (`.jtl`, folder laporan HTML) | |

### A3. Keputusan berbanding NFR ✍️

| NFR | Sasaran | Sebenar | Sumber (bahagian dashboard) | Status |
|-----|---------|---------|-----------------------------|--------|
| | | | | ✅ / ❌ |

### A4. Statistik utama (salin dari Statistics) ✍️

| Label | #Samples | FAIL | Error % | Average | Median | 90th pct | 95th pct | 99th pct | Max | Transactions/s |
|-------|---------:|-----:|--------:|--------:|-------:|---------:|---------:|---------:|----:|---------------:|
| *(baris transaksi)* | | | | | | | | | | |
| *(setiap langkah)* | | | | | | | | | | |
| **Total** | | | | | | | | | | |

### A5. Dapatan (findings) ✍️

Ulang blok ini untuk setiap dapatan (sasaran: 3 dapatan).

| Medan | Isi |
|-------|-----|
| **ID & tajuk** | D1 — … |
| **Keterukan** | Kritikal / Tinggi / Sederhana / Rendah / Maklumat |
| **Bukti** | Angka + bahagian dashboard (cth. *Statistics → 95th pct*, *Charts → Over Time → Response Times Over Time*) |
| **Kesan** | Apa maksudnya kepada pengguna / perniagaan |
| **Punca berkemungkinan** | Hipotesis — nyatakan jika belum disahkan dengan metrik pelayan |
| **Cadangan** | Tindakan seterusnya + siapa |

### A6. Perbandingan dengan baseline ✍️

| Metrik | Baseline | Larian ini | Perubahan | Komen |
|--------|---------:|-----------:|----------:|-------|
| p95 transaksi (ms) | | | | |
| Transactions/s | | | | |
| Error % | | | | |

### A7. Batasan, andaian & langkah seterusnya ✍️

- …

### A8. Perbandingan lokasi (jika ujian teragih / berbilang lokasi) ✍️

Ejen: … (lokasi → host:port) · Beban per ejen: … pengguna × … gelung · Jumlah pengguna = … × … ejen = …

| Lokasi | Label | Sampel | Ralat % | Purata ms | p90 ms | p95 ms | TPS | NFR (✅/❌) |
|--------|-------|-------:|--------:|----------:|-------:|-------:|----:|:----------:|
| | (transaksi) | | | | | | | |
| | TOTAL (sampel HTTP) | | | | | | | |
| | (transaksi) | | | | | | | |
| | TOTAL (sampel HTTP) | | | | | | | |
| Gabungan | Total | | | | | | | — |

Dapatan lokasi: (1) … (2) …

---

## B. Contoh diisi — Hari Kenaikan Harga Cukai (mock eJPJ)

> Data di bawah datang daripada tiga larian sebenar plan `07` (50 pengguna, ramp-up 10 s, 60 s) yang dijalankan semasa penyediaan bahan: **R1** SLA 2000 ms (mock biasa), **R2** SLA 150 ms (mock biasa), **R3** SLA 2000 ms dengan mock "perlahan" (`LATENCY_MIN=500 LATENCY_MAX=1500`).

### B1. Ringkasan eksekutif

| | |
|-|-|
| **Keputusan keseluruhan** | **LULUS BERSYARAT** (R1) |
| **Satu ayat** | *"Pada 50 pengguna (10.46 transaksi/s), transaksi `Pembaharuan Cukai Jalan (Puncak)` mencapai p95 **583 ms** (sasaran ≤ 2000 ms) tetapi Error % **1.00%** berada tepat pada had NFR < 1% — semua ralat ialah HTTP 500 pada langkah bayar."* |
| **3 perkara utama** | 1. Masa respons jauh dalam NFR (p95 583 ms ≈ 29% daripada had). 2. Ralat 500 pada `bayar-cukai` (~1%) — tidak bergantung pada beban, perlu disiasat. 3. Jika pelayan menjadi 3× lebih perlahan (R3), throughput jatuh 45% dan p95 melanggar NFR. |
| **Tindakan disyorkan** | Siasat punca 500 pada `bayar-cukai` sebelum ujian beban penuh; ulang larian Load selepas pembetulan; jalankan Stress untuk mencari titik lutut. |

### B2. Konteks larian (R1)

| Medan | Nilai |
|-------|-------|
| ID larian | R1 — 4 Okt 2026, 8.0x malam |
| Sistem | Portal eJPJ (tiruan), `sut/server.js` (latensi 40–180 ms, `ERROR_RATE` 0.01) |
| Persekitaran | SUT + JMeter pada laptop yang sama (macOS), loopback |
| Plan & JMeter | `hari-2/test-plans/07-beban-puncak-cukai.jmx`, JMeter 5.6.3, non-GUI |
| Arahan | `jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 -l r07a.jtl -e -o rep07a` |
| Model beban | 50 threads, ramp-up 10 s, 60 s, Loop *Infinite*; think time Uniform Random 0.5–1.5 s × 4 sampler ≈ 4 s/lelaran |
| Jenis ujian | Load (skala makmal) |

### B3. Keputusan berbanding NFR (R1)

| NFR | Sasaran | Sebenar | Sumber | Status |
|-----|---------|---------|--------|--------|
| p95 transaksi | ≤ 2000 ms | **583 ms** | Statistics → baris `Pembaharuan Cukai Jalan (Puncak)` → 95th pct | ✅ |
| Error % transaksi | < 1% | **1.00%** (6 / 598) | Statistics → Error % | ❌ (tepat pada had) |
| Throughput transaksi | ≥ 10 /s | **10.46 /s** | Statistics → Transactions/s | ✅ |
| p95 log masuk | ≤ 1000 ms | **173 ms** | Statistics → `1. POST /api/log-masuk` | ✅ |
| APDEX keseluruhan | ≥ 0.90 | **0.971** | APDEX → Total | ✅ |

### B4. Statistik utama (R1, dipetik dari dashboard)

| Label | #Samples | FAIL | Error % | Average | Median | 90th pct | 95th pct | 99th pct | Max | Transactions/s |
|-------|---------:|-----:|--------:|--------:|-------:|---------:|---------:|---------:|----:|---------------:|
| Pembaharuan Cukai Jalan (Puncak) | 598 | 6 | 1.00% | 446 | 446 | 554 | 583 | 644 | 693 | 10.46 |
| 1. POST /api/log-masuk | 630 | 0 | 0.00% | 110 | 107 | 166 | 173 | 180 | 181 | 10.70 |
| 2. GET /api/kenderaan | 614 | 0 | 0.00% | 113 | 114 | 168 | 174 | 180 | 189 | 10.60 |
| 4. POST /api/kenderaan/BMT3030/bayar-cukai | 196 | 3 | 1.53% | 109 | 107 | 165 | 176 | 182 | 182 | 3.58 |
| 4. POST /api/kenderaan/JQK7788/bayar-cukai | 196 | 3 | 1.53% | 113 | 113 | 168 | 173 | 181 | 182 | 3.54 |
| **Total** | 2432 | 6 | 0.25% | 112 | 112 | 168 | 175 | 180 | 189 | 41.29 |

> Nota bacaan: (1) **Total** hanya mengira sampel HTTP (2432) — baris transaksi tidak dimasukkan. (2) Langkah 3 & 4 berpecah kepada satu baris setiap kenderaan kerana nama sampler mengandungi `${no_pendaftaran}`. (3) 630 log masuk tetapi 598 transaksi: lelaran yang belum selesai apabila tempoh 60 s tamat tidak menghasilkan sampel transaksi.

### B5. Dapatan

**D1 — Masa respons transaksi jauh dalam NFR pada beban puncak skala makmal**

| Medan | Isi |
|-------|-----|
| Keterukan | Maklumat (positif) |
| Bukti | R1: p95 transaksi **583 ms**, p99 644 ms, Max 693 ms (*Statistics*). Dijana semula dengan butiran 5 s: *Response Time Percentiles Over Time* (sampel HTTP berjaya) — 95th percentile rata 172–181 ms dalam setiap selang; *Response Times Over Time* baris transaksi 430–470 ms sepanjang fasa stabil. APDEX transaksi 0.862 (transaksi 4 langkah ≈ 450 ms kadang-kadang melepasi T = 500 ms — Tolerating, bukan Frustrated). |
| Kesan | 95% pengguna menyelesaikan pembaharuan (tanpa think time) dalam < 0.6 s. |
| Punca | Latensi mock 40–180 ms × 4 langkah ≈ 440 ms purata — sepadan dengan Average 446 ms. |
| Cadangan | Tetapkan ambang APDEX per transaksi (`jmeter.reportgenerator.apdex_per_transaction`) supaya APDEX transaksi 4 langkah tidak dinilai dengan T = 500 ms yang sama seperti satu permintaan. |

**D2 — ~1% bayaran gagal dengan HTTP 500, tidak bergantung pada beban**

| Medan | Isi |
|-------|-----|
| Keterukan | **Tinggi** — menyebabkan NFR Error % gagal (1.00% ≮ 1%) |
| Bukti | *Errors*: `500/Internal Server Error` = 6 (100% daripada ralat, 0.25% semua sampel). *Top 5 Errors by sampler*: 3 pada `…/BMT3030/bayar-cukai`, 3 pada `…/JQK7788/bayar-cukai`. *Codes Per Second* (butiran 5 s): siri `500` muncul dalam 5 daripada 12 selang (0.2–0.4 /s), bertaburan — bukan berkumpul pada puncak beban. |
| Kesan | ~1 dalam 100 rakyat perlu mengulang bayaran — risiko caj berganda/aduan pada hari puncak. |
| Punca | Mock mempunyai `ERROR_RATE=0.01` (ralat sintetik). Dalam sistem sebenar: semak log pelayan pada cap masa sampel gagal (`timeStamp` dalam `.jtl`). |
| Cadangan | Pasukan aplikasi menyiasat 500 pada `bayar-cukai`; ulang R1 selepas pembaikan. Bandingkan dengan baseline 5 pengguna untuk membuktikan ia bukan akibat beban. |

**D3 — NFR yang terlalu ketat menukar keputusan tanpa sebarang perubahan sistem**

| Medan | Isi |
|-------|-----|
| Keterukan | Sederhana (isu proses) |
| Bukti | R2 (`-Jsla_ms=150`, sistem sama): Error % transaksi **21.75%** (132 / 607), langkah bayar 19–26%, Total 5.37%; APDEX transaksi jatuh 0.862 → 0.717. *Errors* dipenuhi baris `The operation lasted too long: It took 1xx milliseconds, but should not have lasted longer than 150 milliseconds.` — satu baris bagi setiap nilai ms, jadi jumlahkan semuanya. |
| Kesan | Tanpa NFR yang dipersetujui, keputusan "lulus/gagal" boleh dimanipulasi dengan mengubah ambang. |
| Punca | p90 langkah bayar ≈ 165–171 ms; ambang 150 ms memotong ekor taburan. |
| Cadangan | Bekukan NFR (dengan pemilik sistem) **sebelum** larian; nyatakan nilai `-Jsla_ms` dalam setiap laporan. |

**D4 (pilihan) — Apabila pelayan menjadi perlahan, throughput jatuh walaupun pengguna sama**

| Medan | Isi |
|-------|-----|
| Keterukan | Tinggi (risiko kapasiti) |
| Bukti | R3 (mock 500–1500 ms, 50 pengguna): transaksi **5.78 /s** (R1: 10.46 /s, −45%), p95 transaksi **4969 ms** (> 2000 ms ❌), APDEX Total 0.40. Little's Law: 5.78 × (3.95 + 4.0) ≈ 46 pengguna — beban pengguna sama, masa respons naik → throughput turun. |
| Kesan | Jika pangkalan data/servis hiliran menjadi perlahan pada hari puncak, portal menyiapkan hampir separuh sahaja pembaharuan sejam. |
| Punca | Model tertutup (closed model): setiap thread menunggu respons sebelum lelaran seterusnya. |
| Cadangan | Pantau masa respons servis hiliran; jalankan Stress untuk mencari titik lutut sebenar dengan metrik pelayan. |

### B6. Perbandingan dengan baseline

| Metrik | Baseline (R1, mock biasa) | R3 (mock perlahan) | Perubahan | Komen |
|--------|--------------------------:|-------------------:|----------:|-------|
| p95 transaksi (ms) | 583 | 4969 | +752% | Melanggar NFR-01 |
| Transactions/s | 10.46 | 5.78 | −45% | Pengguna sama (50) |
| Error % transaksi | 1.00% | 0.90% | ≈ sama | Ralat sintetik, bukan beban |
| APDEX Total | 0.971 | 0.401 | −0.57 | Kebanyakan sampel > 500 ms |

### B7. Batasan & langkah seterusnya

- SUT ialah mock tanpa pangkalan data dan tanpa had kapasiti sebenar — keputusan menunjukkan **kaedah**, bukan kapasiti eJPJ sebenar.
- SUT dan JMeter berkongsi satu laptop; tiada metrik pelayan dikumpul.
- Larian 60 s terlalu pendek untuk soak; graf Over Time dengan butiran lalai 60 s hanya ada 1–2 titik — jana semula dengan `-Jjmeter.reportgenerator.overall_granularity=5000`.
- Seterusnya: Stress berperingkat (50 → 100 → 150 pengguna) + Spike, dengan pemantauan CPU.

### B8. Perbandingan lokasi — contoh diisi (plan `09`, ujian teragih)

> Larian sebenar `hari-2/run/run-berbilang-lokasi.sh` (JMeter 5.6.3, satu mesin, localhost sahaja): ejen **KL** `127.0.0.1:1099` → mock port 3000 (40–180 ms); ejen **PENANG** `127.0.0.1:1100` → mock port 3001 (300–900 ms, meniru rangkaian jauh). Beban per ejen: 10 pengguna × 3 gelung, ramp-up 5 s → **20 pengguna** jumlah. Angka dipetik dari `laporan/<LOKASI>/statistics.json`.

| Lokasi | Label | Sampel | Ralat % | Purata ms | p90 ms | p95 ms | TPS | NFR p95 ≤ 800 ms/langkah |
|--------|-------|-------:|--------:|----------:|-------:|-------:|----:|:------------------------:|
| KL | Pembaharuan Cukai Jalan (transaksi) | 30 | 0.00 | 476 | 598 | 640 | 1.30 | — |
| KL | TOTAL (sampel HTTP) | 120 | 0.00 | 119 | 170 | 178 | 4.04 | ✅ |
| PENANG | Pembaharuan Cukai Jalan (transaksi) | 30 | 0.00 | 2430 | 2915 | 3000 | 1.06 | — |
| PENANG | TOTAL (sampel HTTP) | 120 | 0.00 | 607 | 873 | 892 | 3.51 | ❌ |
| Gabungan | Total (`laporan/gabungan`) | 240 | 0.00 | 363 | 790 | 873 | 6.90 | — (menyembunyikan beza) |

| Dapatan L1 | |
|---|---|
| Keterukan | Tinggi |
| Bukti | Transaksi PENANG purata **2430 ms** (p95 3000 ms) vs KL **476 ms** (p95 640 ms) — ~5× lebih perlahan; setiap langkah HTTP PENANG 570–670 ms vs KL 110–130 ms; ralat 0% di kedua-dua lokasi (*Statistics*, laporan per lokasi). |
| Kesan | Rakyat yang mengakses dari kawasan PENANG menunggu ~2.4 s setiap pembaharuan berbanding ~0.5 s di KL. |
| Punca | Kependaman laluan ke lokasi (rangkaian), bukan kegagalan aplikasi — aplikasi yang sama, ralat 0%. |
| Cadangan | Semak laluan rangkaian/WAN PENANG (traceroute, RTT) dan pertimbangkan CDN/titik masuk serantau sebelum menala pelayan. |

| Dapatan L2 | |
|---|---|
| Keterukan | Sederhana (risiko pelaporan) |
| Bukti | Purata gabungan **363 ms** kelihatan baik, tetapi dengan NFR p95 ≤ 800 ms setiap langkah: KL p95 175–180 ms ✅, PENANG p95 886–896 ms ❌. |
| Kesan | Laporan yang hanya memetik angka gabungan akan meluluskan sistem yang gagal untuk satu lokasi. |
| Punca | Purata/percentile gabungan mencampurkan taburan dua populasi yang berbeza. |
| Cadangan | Laporkan keputusan NFR **per lokasi** (label `[LOKASI]` + laporan per lokasi); angka gabungan hanya untuk jumlah beban/throughput. |
