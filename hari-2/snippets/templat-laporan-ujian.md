# Templat Laporan Ujian Prestasi (Test Report & Findings)

[⬅️ README Hari 2](../README.md) · [🧪 Lab Hari 2](./lab.md) · [📋 Templat Pelan Ujian](./templat-pelan-ujian.md)

> **Cara guna:** Copy file ni (contohnya `laporan-<id-larian>.md`). Bahagian **A** ialah templat kosong ✍️; bahagian **B** ialah contoh yang dah diisi guna **nombor sebenar** daripada run plan `07-beban-puncak-cukai.jmx` pada mock `localhost:3000` (JMeter 5.6.3). Nombor run anda akan beza sikit — latency mock adalah rawak (40–180 ms) dan ~1% bayaran memang sengaja gagal (500).
>
> **Peraturan emas:** setiap finding mesti ada **bukti** (nombor + bahagian dashboard), **kesan** kepada users/bisnes, dan **cadangan**. Yang baca report ni ialah pengurusan — mula dengan keputusan, bukan dengan graf.

---

## A. Templat kosong

### A1. Ringkasan eksekutif ✍️

| | |
|-|-|
| **Keputusan keseluruhan** | LULUS / GAGAL / LULUS BERSYARAT |
| **Satu ayat** | *"Pada \_\_\_ users (\_\_\_ transaksi/s), transaksi \_\_\_ capai p95 \_\_\_ ms dan Error % \_\_\_ — \_\_\_ NFR."* |
| **3 perkara utama** | 1. … 2. … 3. … |
| **Tindakan disyorkan** | … |

### A2. Konteks larian ✍️

| Field | Nilai |
|-------|-------|
| ID run / tarikh & masa | |
| Sistem & versi | |
| Environment (SUT, load generator) | |
| Plan JMeter & versi JMeter | |
| Command tepat | `jmeter -n -t … -J… -l … -e -o …` |
| Model load (users, ramp-up, tempoh, think time) | |
| Jenis test (baseline / load / stress / spike / soak) | |
| File bukti (`.jtl`, folder report HTML) | |

### A3. Keputusan berbanding NFR ✍️

| NFR | Sasaran | Sebenar | Sumber (bahagian dashboard) | Status |
|-----|---------|---------|-----------------------------|--------|
| | | | | ✅ / ❌ |

### A4. Statistik utama (salin dari Statistics) ✍️

| Label | #Samples | FAIL | Error % | Average | Median | 90th pct | 95th pct | 99th pct | Max | Transactions/s |
|-------|---------:|-----:|--------:|--------:|-------:|---------:|---------:|---------:|----:|---------------:|
| *(baris transaksi)* | | | | | | | | | | |
| *(setiap step)* | | | | | | | | | | |
| **Total** | | | | | | | | | | |

### A5. Dapatan (findings) ✍️

Ulang blok ni untuk setiap finding (sasaran: 3 findings).

| Field | Isi |
|-------|-----|
| **ID & tajuk** | D1 — … |
| **Severity** | Kritikal / Tinggi / Sederhana / Rendah / Info |
| **Bukti** | Nombor + bahagian dashboard (contohnya *Statistics → 95th pct*, *Charts → Over Time → Response Times Over Time*) |
| **Kesan** | Apa maksudnya kepada users / bisnes |
| **Punca berkemungkinan** | Hipotesis — nyatakan kalau belum disahkan dengan metrik server |
| **Cadangan** | Tindakan seterusnya + siapa |

### A6. Perbandingan dengan baseline ✍️

| Metrik | Baseline | Run ni | Perubahan | Komen |
|--------|---------:|-----------:|----------:|-------|
| p95 transaksi (ms) | | | | |
| Transactions/s | | | | |
| Error % | | | | |

### A7. Batasan, andaian & langkah seterusnya ✍️

- …

### A8. Perbandingan lokasi (jika ujian teragih / berbilang lokasi) ✍️

Agent: … (lokasi → host:port) · Load per agent: … users × … loop · Jumlah users = … × … agent = …

| Lokasi | Label | Sampel | Error % | Purata ms | p90 ms | p95 ms | TPS | NFR (✅/❌) |
|--------|-------|-------:|--------:|----------:|-------:|-------:|----:|:----------:|
| | (transaksi) | | | | | | | |
| | TOTAL (sampel HTTP) | | | | | | | |
| | (transaksi) | | | | | | | |
| | TOTAL (sampel HTTP) | | | | | | | |
| Gabungan | Total | | | | | | | — |

Findings lokasi: (1) … (2) …

---

## B. Contoh diisi — Hari Kenaikan Harga Cukai (mock eJPJ)

> Data di bawah datang daripada tiga run sebenar plan `07` (50 users, ramp-up 10 s, 60 s) yang dijalankan masa sediakan bahan: **R1** SLA 2000 ms (mock biasa), **R2** SLA 150 ms (mock biasa), **R3** SLA 2000 ms dengan mock "perlahan" (`LATENCY_MIN=500 LATENCY_MAX=1500`).

### B1. Ringkasan eksekutif

| | |
|-|-|
| **Keputusan keseluruhan** | **LULUS BERSYARAT** (R1) |
| **Satu ayat** | *"Pada 50 users (10.46 transaksi/s), transaksi `Pembaharuan Cukai Jalan (Puncak)` capai p95 **583 ms** (sasaran ≤ 2000 ms) tetapi Error % **1.00%** betul-betul pada had NFR < 1% — semua error ialah HTTP 500 pada step bayar."* |
| **3 perkara utama** | 1. Response time jauh dalam NFR (p95 583 ms ≈ 29% daripada had). 2. Error 500 pada `bayar-cukai` (~1%) — bukan sebab load, perlu disiasat. 3. Kalau server jadi 3× lebih perlahan (R3), throughput jatuh 45% dan p95 langgar NFR. |
| **Tindakan disyorkan** | Siasat punca 500 pada `bayar-cukai` sebelum load test penuh; run semula Load test lepas fix; run Stress test untuk cari knee point. |

### B2. Konteks larian (R1)

| Field | Nilai |
|-------|-------|
| ID run | R1 — 4 Okt 2026, 8.0x malam |
| Sistem | Portal eJPJ (tiruan), `sut/server.js` (latency 40–180 ms, `ERROR_RATE` 0.01) |
| Environment | SUT + JMeter dalam laptop yang sama (macOS), loopback |
| Plan & JMeter | `hari-2/test-plans/07-beban-puncak-cukai.jmx`, JMeter 5.6.3, non-GUI |
| Command | `jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 -l r07a.jtl -e -o rep07a` |
| Model load | 50 threads, ramp-up 10 s, 60 s, Loop *Infinite*; think time Uniform Random 0.5–1.5 s × 4 sampler ≈ 4 s/iteration |
| Jenis test | Load (skala lab) |

### B3. Keputusan berbanding NFR (R1)

| NFR | Sasaran | Sebenar | Sumber | Status |
|-----|---------|---------|--------|--------|
| p95 transaksi | ≤ 2000 ms | **583 ms** | Statistics → baris `Pembaharuan Cukai Jalan (Puncak)` → 95th pct | ✅ |
| Error % transaksi | < 1% | **1.00%** (6 / 598) | Statistics → Error % | ❌ (betul-betul pada had) |
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

> Nota bacaan: (1) **Total** cuma kira sampel HTTP (2432) — baris transaksi tak masuk. (2) Step 3 & 4 pecah jadi satu baris untuk setiap kenderaan sebab nama sampler ada `${no_pendaftaran}`. (3) 630 log masuk tapi 598 transaksi: iteration yang belum habis bila tempoh 60 s tamat tak hasilkan sampel transaksi.

### B5. Dapatan

**D1 — Response time transaksi jauh dalam NFR pada peak load skala lab**

| Field | Isi |
|-------|-----|
| Severity | Info (positif) |
| Bukti | R1: p95 transaksi **583 ms**, p99 644 ms, Max 693 ms (*Statistics*). Generate semula dengan granularity 5 s: *Response Time Percentiles Over Time* (sampel HTTP yang berjaya) — 95th percentile rata 172–181 ms dalam setiap selang; *Response Times Over Time* baris transaksi 430–470 ms sepanjang fasa stabil. APDEX transaksi 0.862 (transaksi 4 step ≈ 450 ms kadang-kadang lepas T = 500 ms — Tolerating, bukan Frustrated). |
| Kesan | 95% users siap pembaharuan (tanpa think time) dalam < 0.6 s. |
| Punca | Latency mock 40–180 ms × 4 step ≈ 440 ms purata — sama dengan Average 446 ms. |
| Cadangan | Set threshold APDEX per transaksi (`jmeter.reportgenerator.apdex_per_transaction`) supaya APDEX transaksi 4 step tak dinilai dengan T = 500 ms yang sama macam satu request. |

**D2 — ~1% bayaran gagal dengan HTTP 500, bukan disebabkan load**

| Field | Isi |
|-------|-----|
| Severity | **Tinggi** — buat NFR Error % gagal (1.00% ≮ 1%) |
| Bukti | *Errors*: `500/Internal Server Error` = 6 (100% daripada error, 0.25% semua sampel). *Top 5 Errors by sampler*: 3 pada `…/BMT3030/bayar-cukai`, 3 pada `…/JQK7788/bayar-cukai`. *Codes Per Second* (granularity 5 s): siri `500` muncul dalam 5 daripada 12 selang (0.2–0.4 /s), bertaburan — bukan berkumpul masa peak load. |
| Kesan | ~1 dalam 100 rakyat kena ulang bayaran — risiko caj berganda/aduan pada hari peak. |
| Punca | Mock memang ada `ERROR_RATE=0.01` (error sintetik). Untuk sistem sebenar: check log server pada timestamp sampel yang gagal (`timeStamp` dalam `.jtl`). |
| Cadangan | Team aplikasi siasat 500 pada `bayar-cukai`; run semula R1 lepas fix. Bandingkan dengan baseline 5 users untuk buktikan ia bukan sebab load. |

**D3 — NFR yang terlalu ketat boleh tukar keputusan walaupun sistem tak berubah langsung**

| Field | Isi |
|-------|-----|
| Severity | Sederhana (isu proses) |
| Bukti | R2 (`-Jsla_ms=150`, sistem sama): Error % transaksi **21.75%** (132 / 607), step bayar 19–26%, Total 5.37%; APDEX transaksi jatuh 0.862 → 0.717. *Errors* penuh dengan baris `The operation lasted too long: It took 1xx milliseconds, but should not have lasted longer than 150 milliseconds.` — satu baris untuk setiap nilai ms, jadi kena jumlahkan semua. |
| Kesan | Tanpa NFR yang dipersetujui, keputusan "pass/fail" boleh dimanipulasi dengan tukar threshold. |
| Punca | p90 step bayar ≈ 165–171 ms; threshold 150 ms potong ekor taburan. |
| Cadangan | Bekukan NFR (dengan system owner) **sebelum** run; nyatakan nilai `-Jsla_ms` dalam setiap report. |

**D4 (pilihan) — Bila server jadi perlahan, throughput jatuh walaupun bilangan users sama**

| Field | Isi |
|-------|-----|
| Severity | Tinggi (risiko kapasiti) |
| Bukti | R3 (mock 500–1500 ms, 50 users): transaksi **5.78 /s** (R1: 10.46 /s, −45%), p95 transaksi **4969 ms** (> 2000 ms ❌), APDEX Total 0.40. Little's Law: 5.78 × (3.95 + 4.0) ≈ 46 users — load users sama, response time naik → throughput turun. |
| Kesan | Kalau database/servis downstream jadi perlahan pada hari peak, portal cuma boleh siapkan lebih kurang separuh pembaharuan sejam. |
| Punca | Closed model: setiap thread tunggu response dulu sebelum iteration seterusnya. |
| Cadangan | Pantau response time servis downstream; run Stress test untuk cari knee point sebenar dengan metrik server. |

### B6. Perbandingan dengan baseline

| Metrik | Baseline (R1, mock biasa) | R3 (mock perlahan) | Perubahan | Komen |
|--------|--------------------------:|-------------------:|----------:|-------|
| p95 transaksi (ms) | 583 | 4969 | +752% | Langgar NFR-01 |
| Transactions/s | 10.46 | 5.78 | −45% | Users sama (50) |
| Error % transaksi | 1.00% | 0.90% | ≈ sama | Error sintetik, bukan sebab load |
| APDEX Total | 0.971 | 0.401 | −0.57 | Kebanyakan sampel > 500 ms |

### B7. Batasan & langkah seterusnya

- SUT ialah mock tanpa database dan tanpa had kapasiti sebenar — keputusan ni tunjuk **kaedah**, bukan kapasiti eJPJ sebenar.
- SUT dan JMeter kongsi satu laptop; tiada metrik server dikumpul.
- Run 60 s terlalu pendek untuk soak test; graf Over Time dengan granularity default 60 s cuma ada 1–2 titik — generate semula dengan `-Jjmeter.reportgenerator.overall_granularity=5000`.
- Seterusnya: Stress test berperingkat (50 → 100 → 150 users) + Spike test, dengan monitoring CPU.

### B8. Perbandingan lokasi — contoh diisi (plan `09`, ujian teragih)

> Run sebenar `hari-2/run/run-berbilang-lokasi.sh` (JMeter 5.6.3, satu mesin, localhost sahaja): agent **KL** `127.0.0.1:1099` → mock port 3000 (40–180 ms); agent **PENANG** `127.0.0.1:1100` → mock port 3001 (300–900 ms, tiru network jauh). Load per agent: 10 users × 3 loop, ramp-up 5 s → jumlah **20 users**. Nombor dipetik dari `laporan/<LOKASI>/statistics.json`.

| Lokasi | Label | Sampel | Error % | Purata ms | p90 ms | p95 ms | TPS | NFR p95 ≤ 800 ms/step |
|--------|-------|-------:|--------:|----------:|-------:|-------:|----:|:------------------------:|
| KL | Pembaharuan Cukai Jalan (transaksi) | 30 | 0.00 | 476 | 598 | 640 | 1.30 | — |
| KL | TOTAL (sampel HTTP) | 120 | 0.00 | 119 | 170 | 178 | 4.04 | ✅ |
| PENANG | Pembaharuan Cukai Jalan (transaksi) | 30 | 0.00 | 2430 | 2915 | 3000 | 1.06 | — |
| PENANG | TOTAL (sampel HTTP) | 120 | 0.00 | 607 | 873 | 892 | 3.51 | ❌ |
| Gabungan | Total (`laporan/gabungan`) | 240 | 0.00 | 363 | 790 | 873 | 6.90 | — (sorok perbezaan) |

| Finding L1 | |
|---|---|
| Severity | Tinggi |
| Bukti | Transaksi PENANG purata **2430 ms** (p95 3000 ms) vs KL **476 ms** (p95 640 ms) — ~5× lebih perlahan; setiap step HTTP PENANG 570–670 ms vs KL 110–130 ms; error 0% di kedua-dua lokasi (*Statistics*, report per lokasi). |
| Kesan | Rakyat yang guna portal dari kawasan PENANG kena tunggu ~2.4 s setiap pembaharuan berbanding ~0.5 s di KL. |
| Punca | Latency network ke lokasi tu, bukan aplikasi yang gagal — aplikasi sama, error 0%. |
| Cadangan | Check laluan network/WAN PENANG (traceroute, RTT) dan pertimbangkan CDN/entry point serantau sebelum tuning server. |

| Finding L2 | |
|---|---|
| Severity | Sederhana (risiko pelaporan) |
| Bukti | Purata gabungan **363 ms** nampak OK, tapi dengan NFR p95 ≤ 800 ms setiap step: KL p95 175–180 ms ✅, PENANG p95 886–896 ms ❌. |
| Kesan | Report yang cuma quote nombor gabungan akan luluskan sistem yang sebenarnya gagal untuk satu lokasi. |
| Punca | Purata/percentile gabungan campur taburan dua populasi yang berbeza. |
| Cadangan | Report keputusan NFR **per lokasi** (label `[LOKASI]` + report per lokasi); nombor gabungan cuma untuk jumlah load/throughput. |
