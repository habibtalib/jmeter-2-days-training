# Templat Pelan Ujian Prestasi (Performance Test Plan)

[⬅️ README Hari 2](../README.md) · [🧪 Lab Hari 2](./lab.md) · [📝 Templat Laporan Ujian](./templat-laporan-ujian.md)

> **Cara guna:** Copy file ni (contohnya `pelan-ujian-<pasukan>.md`), kemudian isi setiap bahagian. Column **Contoh diisi (eJPJ)** tunjuk satu jawapan lengkap untuk Portal eJPJ (tiruan) — tukar ikut sistem anda. Bahagian yang ada tanda ✍️ ialah tempat anda isi.
>
> ⚠️ **Semua nombor contoh ialah ANDAIAN LATIHAN**, bukan statistik rasmi JPJ. Sistem sasaran dalam kursus ni **hanya** `http://localhost:3000` (mock dalam `sut/`). Test plan untuk sistem sebenar **tak sah** tanpa kebenaran bertulis (bahagian 12).

---

## 0. Maklumat dokumen

| Field | Contoh diisi (eJPJ) | ✍️ Anda |
|-------|---------------------|---------|
| Tajuk | Pelan Ujian Prestasi — Pembaharuan Cukai Jalan (Hari Kenaikan Harga) | |
| Sistem | Portal eJPJ (tiruan), versi `sut/server.js` repo kursus | |
| Versi pelan / tarikh | v0.1 · 5 Okt 2026 | |
| Disediakan oleh | Pasangan A (peserta kursus) | |
| Disemak / diluluskan oleh | Jurulatih (untuk latihan) · *sistem sebenar: system owner + ketua infrastruktur* | |
| Status | Draf | |

---

## 1. Latar belakang & objektif

**Latar belakang (contoh):** Hari terakhir sebelum harga cukai jalan naik, traffic portal dijangka naik beberapa kali ganda berbanding hari biasa. Pengurusan nak tahu sama ada flow **pembaharuan cukai jalan** masih dalam response time yang boleh diterima masa peak load, dan di mana had kapasitinya.

**Soalan bisnes yang mesti dijawab:**

| # | Soalan | Contoh diisi (eJPJ) | ✍️ Anda |
|---|--------|---------------------|---------|
| Q1 | Boleh tak sistem tampung peak load yang **dijangka**? | Boleh tak kekalkan 10 pembaharuan/saat selama 30 minit dalam NFR? | |
| Q2 | Di mana **had kapasiti** (knee point / breaking point)? | Pada berapa transaksi/saat p95 > 2000 ms atau Error % > 1%? | |
| Q3 | Macam mana sistem handle **spike** mengejut? | Pulih dalam < 5 minit lepas spike 2× tanpa error berterusan? | |
| Q4 | Prestasi **stabil** tak untuk tempoh panjang? | Tiada degradasi p95 > 20% atau memory leak dalam 4 jam | |

---

## 2. Skop

| | Contoh diisi (eJPJ) | ✍️ Anda |
|-|---------------------|---------|
| **Dalam skop** | Log masuk → senarai kenderaan → sebut harga cukai → bayar cukai (API `POST /api/log-masuk`, `GET /api/kenderaan`, `GET /api/kenderaan/:no/cukai`, `POST /api/kenderaan/:no/bayar-cukai`) | |
| **Luar skop** | Semak & bayar saman (fasa 2), payment gateway pihak ketiga (FPX/kad — guna stub), static asset/CDN, mobile app | |
| **Andaian** | Payment gateway sebenar tak ditest; database test saiznya setara production | |

---

## 3. Keperluan bukan fungsian (NFR) / SLA

> Tulis NFR yang **boleh diukur**: *transaksi + load + metrik (percentile) + threshold + tempoh*. Jangan tulis "sistem mesti laju".

| ID | NFR (contoh diisi) | Metrik JMeter / sumber | Threshold | ✍️ Anda |
|----|--------------------|------------------------|--------|---------|
| NFR-01 | Transaksi **Pembaharuan Cukai Jalan** pada **10 transaksi/s** selama 30 minit | `95th pct` baris transaksi (Statistics / `pct2ResTime`) | ≤ **2000 ms** | |
| NFR-02 | Error rate transaksi masa peak load | `Error %` baris transaksi | < **1%** | |
| NFR-03 | Throughput transaksi yang dikekalkan | `Transactions/s` baris transaksi | ≥ **10 /s** | |
| NFR-04 | Log masuk masa peak load | `95th pct` `1. POST /api/log-masuk` | ≤ **1000 ms** | |
| NFR-05 | Kepuasan users keseluruhan | APDEX (T = 500 ms, F = 1500 ms — default JMeter) | ≥ **0.90** | |
| NFR-06 | Resource application server | CPU purata (tool monitoring server) | < **75%** | |

**SLA vs SLO vs NFR (untuk dokumen ni):** NFR = requirement yang kita test; SLO = sasaran dalaman team operasi; SLA = janji kontrak kepada users/klien (biasanya lebih longgar daripada SLO).

---

## 4. Model beban (workload model)

### 4.1 Volum perniagaan → kadar sasaran

| Input | Contoh diisi (eJPJ) — andaian | ✍️ Anda |
|-------|-------------------------------|---------|
| Volum masa peak hour | 36,000 pembaharuan dalam jam 10.00–11.00 | |
| Kadar sasaran **X** (transaksi/s) | 36,000 ÷ 3,600 s = **10 transaksi/s** | |
| HTTP request setiap transaksi | 4 (log masuk, senarai, sebut harga, bayar) | |
| Kadar request (hits/s) | 10 × 4 = **40 request/s** | |
| Response time transaksi dijangka **R** | ≈ 2 s (sama dengan had NFR-01 — anggaran konservatif) | |
| Think time sepanjang journey **Z** | 58 s (baca senarai 15 s + semak sebut harga 20 s + isi bayaran 23 s) | |

### 4.2 Little's Law — bilangan pengguna serentak

```
N = X × (R + Z)
N = pengguna serentak · X = throughput (transaksi/s) · R = masa respons (s) · Z = think time (s)
```

| | Contoh diisi (eJPJ) | ✍️ Anda |
|-|---------------------|---------|
| N (virtual users / threads) | 10 × (2 + 58) = **600 concurrent users** | |
| Sanity check | 600 users × 1 journey setiap 60 s = 10 journey/s ✔ | |

> **Semakan dengan lab kursus (dah disahkan):** plan `07` ada think time ≈ 4 s setiap iteration (Uniform Random Timer 0.5–1.5 s × 4 sampler) dan R ≈ 0.45 s. Run 50 users (ramp 10 s, 60 s) bagi **10.46 transaksi/s** → 10.46 × (0.45 + 4.0) ≈ **46** users — sama dengan purata thread aktif (~46, sebab ramp-up 10 s).

### 4.3 Kawalan kadar (pacing)

| Pilihan | Contoh diisi (eJPJ) | ✍️ Anda |
|---------|---------------------|---------|
| Pendekatan | **Closed model**: 600 threads + think time yang realistik | |
| Pengehad kadar | **Constant Throughput Timer** sebagai child `1. POST /api/log-masuk`: Target throughput **600** (sampel/minit), *Calculate Throughput based on* = **all active threads in current thread group (shared)** → maksimum 10 iteration/s | |
| Alternatif | **Precise Throughput Timer**: Target throughput 10, Throughput period 1 s, Test duration 1800 s | |

> ⚠️ Timer throughput kira **sampel yang dia pengaruhi**. Kalau letak terus bawah Transaction Controller yang ada 4 sampler, sasaran dikira per sampler (bukan per transaksi). Letak sebagai **child satu sampler** (contohnya log masuk) untuk kawal kadar transaksi.

---

## 5. Campuran transaksi (transaction mix) & skrip

| User journey | % load | Kadar (pada jumlah 10 trans/s) | Script JMeter | Status script | ✍️ Anda |
|---------------------|--------:|--------------------------------|--------------|--------------|---------|
| Pembaharuan cukai (log masuk → senarai → sebut harga → bayar) | 70% | 7 /s | `07-beban-puncak-cukai.jmx` | Dah disahkan (0 functional error pada 1 user) | |
| Semak sahaja (log masuk → senarai → sebut harga, tanpa bayar) | 30% | 3 /s | Copy `07` + **Throughput Controller** (Percent Executions 70) yang balut step bayar | Perlu dibina | |

**Elemen JMeter penting dalam script:** correlation `token` + `csrf` (JSON Extractor), CSV `pengguna.csv`, Transaction Controller, Uniform Random Timer, Response Assertion `BERJAYA`, Duration Assertion `${__P(sla_ms,2000)}`, property `-Jpengguna/-Jrampup/-Jtempoh`.

---

## 6. Data ujian

| Perkara | Contoh diisi (eJPJ) | ✍️ Anda |
|---------|---------------------|---------|
| Sumber | `hari-2/data/pengguna.csv` (3 user sintetik), `kenderaan.csv` | |
| Jumlah diperlukan | Sistem sebenar: ≥ 600 akaun test unik (satu per virtual user) supaya tak ada "cache palsu" | |
| Data dinamik | `token`, `csrf` — di-correlate masa run (tak simpan dalam CSV) | |
| Reset data | Bayaran ubah data → reset database test sebelum setiap run | |
| Data peribadi | **Dilarang** — guna data sintetik/masked sahaja | |

---

## 7. Persekitaran ujian

| Komponen | Contoh diisi (eJPJ) | Beza dengan production | ✍️ Anda |
|----------|---------------------|-------------------------|---------|
| SUT | Mock Node.js `localhost:3000` (latency tiruan 40–180 ms, `ERROR_RATE` 1%) | Tiada database, tiada had kapasiti sebenar | |
| Load generator | Laptop peserta, JMeter 5.6.3, non-GUI | Mesin sama dengan SUT → berebut CPU | |
| Network | Loopback | Tiada latency internet | |
| Versi dibekukan | Commit repo kursus | — | |

> Keputusan hanya sah untuk environment yang ditest. Nyatakan beza dengan production dan kesannya pada cara kita baca keputusan.

---

## 8. Jenis ujian & jadual larian

| # | Jenis | Tujuan | Konfigurasi (sistem sebenar — contoh) | Konfigurasi lab (mock) | ✍️ Anda |
|---|-------|--------|---------------------------------------|---------------------------|---------|
| 1 | **Smoke / shakeout** | Pastikan script & environment berfungsi | 1–5 users, 5 min | `05-transaksi-penuh.jmx` (10 × 2 loop) | |
| 2 | **Baseline** | Rujukan pada load rendah — semua run lain dibandingkan dengan ni | 60 users (~1 trans/s), 15 min | `07` `-Jpengguna=5 -Jrampup=5 -Jtempoh=60` | |
| 3 | **Load** (peak dijangka) | Jawab Q1 | 600 users, ramp 10 min, kekal 30 min | `07` `-Jpengguna=50 -Jrampup=10 -Jtempoh=60` | |
| 4 | **Stress** (berperingkat) | Jawab Q2 — cari knee point | 600 → 900 → 1200 (150%, 200%), 15 min setiap tahap | `07` `-Jpengguna=50/100/150` | |
| 5 | **Spike** | Jawab Q3 | 100 → 1200 dalam 1 min, kekal 5 min, balik ke 100 | Ramp-up pendek: `-Jpengguna=150 -Jrampup=1` | |
| 6 | **Soak / endurance** | Jawab Q4 | 420 users (70%), 4–8 jam | `-Jtempoh=1800` (30 min, demo sahaja) | |

**Command run standard (non-GUI):**

```bash
jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
  -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
  -l hasil/<id-larian>.jtl -e -o hasil/<id-larian>-laporan
```

---

## 9. Kriteria masuk, keluar & penggantungan

| Jenis | Contoh diisi (eJPJ) | ✍️ Anda |
|-------|---------------------|---------|
| **Masuk (entry)** | Script pass smoke test (0 functional error); data dah sedia; environment dibekukan; monitoring aktif; **kebenaran bertulis dah ditandatangani**; NOC/SOC dah dimaklumkan | |
| **Keluar (exit)** | Semua run yang dirancang selesai; keputusan dianalisis berbanding NFR; report dah diserahkan; tiada isu blocker yang terbuka | |
| **Gantung (suspend)** | Error % > 10% selama 2 min; CPU load generator > 80%; system owner minta stop; ada kesan pada sistem lain | |
| **Sambung (resume)** | Punca dah dikenal pasti & dibaiki; kelulusan test manager | |
| **Lulus/gagal** | PASS kalau NFR-01 hingga NFR-04 dipenuhi dalam run Load; NFR-05/06 dilaporkan sebagai pemerhatian | |

---

## 10. Pemantauan (monitoring)

| Lapisan | Metrik | Tool (contoh) | Pemilik | ✍️ Anda |
|---------|--------|---------------|---------|---------|
| Load generator | CPU, memory, network | Activity Monitor / Task Manager / `top` | Tester | |
| Client (JMeter) | Response time, throughput, Error %, thread aktif | `.jtl` + HTML dashboard; (pilihan) Backend Listener → InfluxDB/Grafana | Tester | |
| Application server | CPU, memory, thread/connection, error log | APM / tool monitoring organisasi | Team aplikasi | |
| Database | Slow query, lock, connection | Tool DBA | DBA | |

> Tanpa metrik server, report cuma boleh cakap *"apa"* yang jadi, bukan *"kenapa"*.

---

## 11. Risiko & mitigasi

| Risiko | Kesan | Mitigasi (contoh) | ✍️ Anda |
|--------|-------|-------------------|---------|
| Environment test lebih kecil daripada production | Keputusan tak boleh terus diekstrapolasi | Nyatakan nisbah; test skala secara berperingkat | |
| Load generator sendiri jadi bottleneck | Nombor yang keluar ukur JMeter, bukan SUT | Non-GUI, jangan guna View Results Tree, pantau CPU < 80%, guna distributed kalau perlu | |
| Data test habis / berulang | Cache palsu, data error | CSV cukup besar, reset data | |
| Test ganggu sistem lain (network dikongsi) | Gangguan servis | Time window yang dipersetujui, contact person untuk "STOP" | |
| Payment gateway pihak ketiga | Caj / kena block | Guna stub; jangan target pihak ketiga | |

---

## 12. Kebenaran & etika

| Perkara | Contoh diisi (eJPJ) | ✍️ Anda |
|---------|---------------------|---------|
| Sasaran dibenarkan | `http://localhost:3000` sahaja (latihan) | |
| Kebenaran bertulis daripada | *Sistem sebenar:* system owner **dan** ketua infrastruktur/keselamatan | |
| Skop dalam kebenaran | Host/URL, endpoint, load maksimum, time window (contohnya Sabtu 10.00 malam – 2.00 pagi) | |
| Pihak yang dimaklumkan | NOC/SOC, team aplikasi, DBA | |
| Prosedur stop | Tester tekan Stop / `shutdown.sh`; contact person: ✍️ | |

> ⚠️ Tanpa kebenaran bertulis, load test pada sistem orang lain ialah serangan denial of service (DoS) — walaupun load tu "kecil".

---

## 13. Peranan & tanggungjawab

| Peranan | Tanggungjawab | ✍️ Nama |
|---------|---------------|---------|
| Test manager / ketua test | Test plan, kelulusan, keputusan pass/fail | |
| Performance test engineer | Script, data, run, analisis, report | |
| System owner | Kebenaran, NFR, keutamaan | |
| Infrastruktur / DBA | Environment, monitoring server | |

---

## 14. Penyerahan (deliverables)

- Test plan ni (dah diluluskan)
- Script `.jmx` + data CSV (dalam version control)
- File `.jtl` mentah + report HTML dashboard untuk setiap run
- **Test report** — guna [`templat-laporan-ujian.md`](./templat-laporan-ujian.md)

---

## Lampiran A — Lembaran kerja Little's Law (isi semasa Latihan 6)

| Langkah | Formula | Nilai anda |
|---------|---------|------------|
| 1. Volum peak hour | V (transaksi/jam) | |
| 2. Kadar sasaran | X = V ÷ 3600 | |
| 3. Response time transaksi dijangka | R (s) | |
| 4. Think time sepanjang journey | Z (s) | |
| 5. Concurrent users | N = X × (R + Z) | |
| 6. Kadar HTTP request | X × (bilangan request setiap transaksi) | |
| 7. Pacing (kalau threads < N) | Constant Throughput Timer = X × 60 sampel/minit | |
