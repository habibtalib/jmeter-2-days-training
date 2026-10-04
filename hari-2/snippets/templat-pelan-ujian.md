# Templat Pelan Ujian Prestasi (Performance Test Plan)

[⬅️ README Hari 2](../README.md) · [🧪 Lab Hari 2](./lab.md) · [📝 Templat Laporan Ujian](./templat-laporan-ujian.md)

> **Cara guna:** Salin fail ini (cth. `pelan-ujian-<pasukan>.md`) dan isi setiap bahagian. Lajur **Contoh diisi (eJPJ)** menunjukkan satu jawapan lengkap untuk Portal eJPJ (tiruan) — gantikan dengan sistem anda. Bahagian bertanda ✍️ ialah tempat anda menulis.
>
> ⚠️ **Semua angka contoh ialah ANDAIAN LATIHAN**, bukan statistik rasmi JPJ. Sistem sasaran dalam kursus ini **hanya** `http://localhost:3000` (mock dalam `sut/`). Pelan untuk sistem sebenar **tidak sah** tanpa kebenaran bertulis (bahagian 12).

---

## 0. Maklumat dokumen

| Medan | Contoh diisi (eJPJ) | ✍️ Anda |
|-------|---------------------|---------|
| Tajuk | Pelan Ujian Prestasi — Pembaharuan Cukai Jalan (Hari Kenaikan Harga) | |
| Sistem | Portal eJPJ (tiruan), versi `sut/server.js` repo kursus | |
| Versi pelan / tarikh | v0.1 · 5 Okt 2026 | |
| Disediakan oleh | Pasangan A (peserta kursus) | |
| Disemak / diluluskan oleh | Jurulatih (bagi latihan) · *sistem sebenar: pemilik sistem + ketua infrastruktur* | |
| Status | Draf | |

---

## 1. Latar belakang & objektif

**Latar belakang (contoh):** Pada hari terakhir sebelum kenaikan harga cukai jalan, trafik portal dijangka melonjak beberapa kali ganda berbanding hari biasa. Pengurusan mahu tahu sama ada aliran **pembaharuan cukai jalan** kekal dalam masa respons yang boleh diterima pada beban puncak, dan di mana had kapasitinya.

**Soalan perniagaan yang mesti dijawab:**

| # | Soalan | Contoh diisi (eJPJ) | ✍️ Anda |
|---|--------|---------------------|---------|
| Q1 | Bolehkah sistem menampung beban puncak **dijangka**? | Bolehkah 10 pembaharuan/saat dikekalkan selama 30 minit dalam NFR? | |
| Q2 | Di manakah **had kapasiti** (titik lutut / knee point)? | Pada berapa transaksi/saat p95 > 2000 ms atau Error % > 1%? | |
| Q3 | Bagaimana sistem bertindak terhadap **lonjakan** mengejut? | Pulih dalam < 5 minit selepas lonjakan 2× tanpa ralat berterusan? | |
| Q4 | Adakah prestasi **stabil** dalam tempoh panjang? | Tiada degradasi p95 > 20% atau kebocoran memori dalam 4 jam | |

---

## 2. Skop

| | Contoh diisi (eJPJ) | ✍️ Anda |
|-|---------------------|---------|
| **Dalam skop** | Log masuk → senarai kenderaan → sebut harga cukai → bayar cukai (API `POST /api/log-masuk`, `GET /api/kenderaan`, `GET /api/kenderaan/:no/cukai`, `POST /api/kenderaan/:no/bayar-cukai`) | |
| **Luar skop** | Semak & bayar saman (fasa 2), gerbang pembayaran pihak ketiga (FPX/kad — diganti stub), aset statik/CDN, aplikasi mudah alih | |
| **Andaian** | Gerbang pembayaran sebenar tidak diuji; pangkalan data ujian bersaiz setara pengeluaran | |

---

## 3. Keperluan bukan fungsian (NFR) / SLA

> Tulis NFR yang **boleh diukur**: *transaksi + beban + metrik (percentile) + ambang + tempoh*. Elakkan "sistem mesti laju".

| ID | NFR (contoh diisi) | Metrik JMeter / sumber | Ambang | ✍️ Anda |
|----|--------------------|------------------------|--------|---------|
| NFR-01 | Transaksi **Pembaharuan Cukai Jalan** pada **10 transaksi/s** selama 30 minit | `95th pct` baris transaksi (Statistics / `pct2ResTime`) | ≤ **2000 ms** | |
| NFR-02 | Kadar ralat transaksi pada beban puncak | `Error %` baris transaksi | < **1%** | |
| NFR-03 | Throughput transaksi yang dikekalkan | `Transactions/s` baris transaksi | ≥ **10 /s** | |
| NFR-04 | Log masuk pada beban puncak | `95th pct` `1. POST /api/log-masuk` | ≤ **1000 ms** | |
| NFR-05 | Kepuasan pengguna keseluruhan | APDEX (T = 500 ms, F = 1500 ms — lalai JMeter) | ≥ **0.90** | |
| NFR-06 | Sumber pelayan aplikasi | CPU purata (alat pemantauan pelayan) | < **75%** | |

**SLA vs SLO vs NFR (untuk dokumen ini):** NFR = keperluan yang kita uji; SLO = sasaran dalaman pasukan operasi; SLA = janji kontrak kepada pengguna/klien (biasanya lebih longgar daripada SLO).

---

## 4. Model beban (workload model)

### 4.1 Volum perniagaan → kadar sasaran

| Input | Contoh diisi (eJPJ) — andaian | ✍️ Anda |
|-------|-------------------------------|---------|
| Volum pada jam puncak | 36,000 pembaharuan dalam jam 10.00–11.00 | |
| Kadar sasaran **X** (transaksi/s) | 36,000 ÷ 3,600 s = **10 transaksi/s** | |
| Permintaan HTTP setiap transaksi | 4 (log masuk, senarai, sebut harga, bayar) | |
| Kadar permintaan (hits/s) | 10 × 4 = **40 permintaan/s** | |
| Masa respons transaksi dijangka **R** | ≈ 2 s (sama dengan had NFR-01 — anggaran konservatif) | |
| Think time sepanjang perjalanan **Z** | 58 s (baca senarai 15 s + semak sebut harga 20 s + isi bayaran 23 s) | |

### 4.2 Little's Law — bilangan pengguna serentak

```
N = X × (R + Z)
N = pengguna serentak · X = throughput (transaksi/s) · R = masa respons (s) · Z = think time (s)
```

| | Contoh diisi (eJPJ) | ✍️ Anda |
|-|---------------------|---------|
| N (pengguna maya / threads) | 10 × (2 + 58) = **600 pengguna serentak** | |
| Semakan kewarasan | 600 pengguna × 1 perjalanan setiap 60 s = 10 perjalanan/s ✔ | |

> **Semakan dengan makmal kursus (disahkan):** plan `07` mempunyai think time ≈ 4 s setiap lelaran (Uniform Random Timer 0.5–1.5 s × 4 sampler) dan R ≈ 0.45 s. Larian 50 pengguna (ramp 10 s, 60 s) memberi **10.46 transaksi/s** → 10.46 × (0.45 + 4.0) ≈ **46** pengguna — sepadan dengan purata thread aktif (~46, kerana ramp-up 10 s).

### 4.3 Kawalan kadar (pacing)

| Pilihan | Contoh diisi (eJPJ) | ✍️ Anda |
|---------|---------------------|---------|
| Pendekatan | **Closed model**: 600 threads + think time realistik | |
| Penghad kadar | **Constant Throughput Timer** sebagai anak `1. POST /api/log-masuk`: Target throughput **600** (sampel/minit), *Calculate Throughput based on* = **all active threads in current thread group (shared)** → maksimum 10 lelaran/s | |
| Alternatif | **Precise Throughput Timer**: Target throughput 10, Throughput period 1 s, Test duration 1800 s | |

> ⚠️ Timer throughput mengira **sampel yang dipengaruhinya**. Jika diletak terus di bawah Transaction Controller 4 sampler, sasaran dikira per sampler (bukan per transaksi). Letakkan sebagai **anak satu sampler** (cth. log masuk) untuk mengawal kadar transaksi.

---

## 5. Campuran transaksi (transaction mix) & skrip

| Perjalanan pengguna | % beban | Kadar (pada 10 trans/s jumlah) | Skrip JMeter | Status skrip | ✍️ Anda |
|---------------------|--------:|--------------------------------|--------------|--------------|---------|
| Pembaharuan cukai (log masuk → senarai → sebut harga → bayar) | 70% | 7 /s | `07-beban-puncak-cukai.jmx` | Disahkan (0 ralat fungsian pada 1 pengguna) | |
| Semak sahaja (log masuk → senarai → sebut harga, tanpa bayar) | 30% | 3 /s | Salinan `07` + **Throughput Controller** (Percent Executions 70) membungkus langkah bayar | Perlu dibina | |

**Elemen JMeter penting dalam skrip:** korelasi `token` + `csrf` (JSON Extractor), CSV `pengguna.csv`, Transaction Controller, Uniform Random Timer, Response Assertion `BERJAYA`, Duration Assertion `${__P(sla_ms,2000)}`, property `-Jpengguna/-Jrampup/-Jtempoh`.

---

## 6. Data ujian

| Perkara | Contoh diisi (eJPJ) | ✍️ Anda |
|---------|---------------------|---------|
| Sumber | `hari-2/data/pengguna.csv` (3 pengguna sintetik), `kenderaan.csv` | |
| Isipadu diperlukan | Sistem sebenar: ≥ 600 akaun ujian unik (satu per pengguna maya) supaya tiada "cache palsu" | |
| Data dinamik | `token`, `csrf` — dikorelasi pada masa larian (tidak disimpan dalam CSV) | |
| Penyediaan semula | Bayaran mengubah data → reset pangkalan data ujian sebelum setiap larian | |
| Data peribadi | **Dilarang** — hanya data sintetik/topeng (masked) | |

---

## 7. Persekitaran ujian

| Komponen | Contoh diisi (eJPJ) | Beza dengan pengeluaran | ✍️ Anda |
|----------|---------------------|-------------------------|---------|
| SUT | Mock Node.js `localhost:3000` (latensi tiruan 40–180 ms, `ERROR_RATE` 1%) | Tiada pangkalan data, tiada had kapasiti sebenar | |
| Penjana beban | Laptop peserta, JMeter 5.6.3, non-GUI | Sama mesin dengan SUT → bersaing CPU | |
| Rangkaian | Loopback | Tiada latensi internet | |
| Versi dibekukan | Commit repo kursus | — | |

> Keputusan hanya sah untuk persekitaran yang diuji. Nyatakan perbezaan dengan pengeluaran dan kesannya terhadap tafsiran.

---

## 8. Jenis ujian & jadual larian

| # | Jenis | Tujuan | Konfigurasi (sistem sebenar — contoh) | Konfigurasi makmal (mock) | ✍️ Anda |
|---|-------|--------|---------------------------------------|---------------------------|---------|
| 1 | **Smoke / shakeout** | Skrip & persekitaran berfungsi | 1–5 pengguna, 5 min | `05-transaksi-penuh.jmx` (10 × 2 gelung) | |
| 2 | **Baseline** | Rujukan pada beban rendah — bandingkan semua larian lain dengannya | 60 pengguna (~1 trans/s), 15 min | `07` `-Jpengguna=5 -Jrampup=5 -Jtempoh=60` | |
| 3 | **Load** (puncak dijangka) | Jawab Q1 | 600 pengguna, ramp 10 min, kekal 30 min | `07` `-Jpengguna=50 -Jrampup=10 -Jtempoh=60` | |
| 4 | **Stress** (berperingkat) | Jawab Q2 — cari titik lutut | 600 → 900 → 1200 (150%, 200%), 15 min setiap tahap | `07` `-Jpengguna=50/100/150` | |
| 5 | **Spike** | Jawab Q3 | 100 → 1200 dalam 1 min, kekal 5 min, kembali 100 | Ramp-up pendek: `-Jpengguna=150 -Jrampup=1` | |
| 6 | **Soak / endurance** | Jawab Q4 | 420 pengguna (70%), 4–8 jam | `-Jtempoh=1800` (30 min, demo sahaja) | |

**Arahan larian standard (non-GUI):**

```bash
jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
  -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
  -l hasil/<id-larian>.jtl -e -o hasil/<id-larian>-laporan
```

---

## 9. Kriteria masuk, keluar & penggantungan

| Jenis | Contoh diisi (eJPJ) | ✍️ Anda |
|-------|---------------------|---------|
| **Masuk (entry)** | Skrip lulus smoke (0 ralat fungsian); data disediakan; persekitaran dibekukan; pemantauan aktif; **kebenaran bertulis ditandatangani**; NOC/SOC dimaklumkan | |
| **Keluar (exit)** | Semua larian dirancang selesai; keputusan dianalisis berbanding NFR; laporan diserahkan; tiada isu penyekat terbuka | |
| **Gantung (suspend)** | Error % > 10% selama 2 min; CPU penjana beban > 80%; permintaan pemilik sistem; kesan pada sistem lain | |
| **Sambung (resume)** | Punca dikenal pasti & dibaiki; kelulusan pengurus ujian | |
| **Lulus/gagal** | LULUS jika NFR-01 hingga NFR-04 dipenuhi dalam larian Load; NFR-05/06 dilaporkan sebagai pemerhatian | |

---

## 10. Pemantauan (monitoring)

| Lapisan | Metrik | Alat (contoh) | Pemilik | ✍️ Anda |
|---------|--------|---------------|---------|---------|
| Penjana beban | CPU, memori, rangkaian | Activity Monitor / Task Manager / `top` | Penguji | |
| Klien (JMeter) | Response time, throughput, Error %, thread aktif | `.jtl` + HTML dashboard; (pilihan) Backend Listener → InfluxDB/Grafana | Penguji | |
| Pelayan aplikasi | CPU, memori, thread/sambungan, log ralat | APM / alat pemantauan organisasi | Pasukan aplikasi | |
| Pangkalan data | Query perlahan, kunci (lock), sambungan | Alat DBA | DBA | |

> Tanpa metrik pelayan, laporan hanya boleh berkata *"apa"* yang berlaku, bukan *"kenapa"*.

---

## 11. Risiko & mitigasi

| Risiko | Kesan | Mitigasi (contoh) | ✍️ Anda |
|--------|-------|-------------------|---------|
| Persekitaran ujian lebih kecil daripada pengeluaran | Keputusan tidak boleh diekstrapolasi secara langsung | Nyatakan nisbah; uji skala berperingkat | |
| Penjana beban menjadi kesesakan | Angka mengukur JMeter, bukan SUT | Non-GUI, tiada View Results Tree, pantau CPU < 80%, teragih jika perlu | |
| Data ujian habis / berulang | Cache palsu, ralat data | CSV cukup besar, reset data | |
| Ujian menjejaskan sistem lain (rangkaian dikongsi) | Gangguan perkhidmatan | Tetingkap masa dipersetujui, orang hubungan "STOP" | |
| Gerbang pembayaran pihak ketiga | Caj / sekatan | Guna stub; jangan sasar pihak ketiga | |

---

## 12. Kebenaran & etika

| Perkara | Contoh diisi (eJPJ) | ✍️ Anda |
|---------|---------------------|---------|
| Sasaran dibenarkan | `http://localhost:3000` sahaja (latihan) | |
| Kebenaran bertulis daripada | *Sistem sebenar:* pemilik sistem **dan** ketua infrastruktur/keselamatan | |
| Skop dalam kebenaran | Hos/URL, endpoint, beban maksimum, tetingkap masa (cth. Sabtu 10.00 malam – 2.00 pagi) | |
| Pihak dimaklumkan | NOC/SOC, pasukan aplikasi, DBA | |
| Prosedur henti | Penguji tekan Stop / `shutdown.sh`; orang hubungan: ✍️ | |

> ⚠️ Tanpa kebenaran bertulis, ujian beban terhadap sistem orang lain ialah serangan penafian perkhidmatan (DoS) — walaupun bebannya "kecil".

---

## 13. Peranan & tanggungjawab

| Peranan | Tanggungjawab | ✍️ Nama |
|---------|---------------|---------|
| Pengurus / ketua ujian | Pelan, kelulusan, keputusan lulus/gagal | |
| Jurutera ujian prestasi | Skrip, data, larian, analisis, laporan | |
| Pemilik sistem | Kebenaran, NFR, keutamaan | |
| Infrastruktur / DBA | Persekitaran, pemantauan pelayan | |

---

## 14. Penyerahan (deliverables)

- Pelan ini (diluluskan)
- Skrip `.jmx` + data CSV (dalam kawalan versi)
- Fail `.jtl` mentah + laporan HTML dashboard bagi setiap larian
- **Laporan ujian** — guna [`templat-laporan-ujian.md`](./templat-laporan-ujian.md)

---

## Lampiran A — Lembaran kerja Little's Law (isi semasa Latihan 6)

| Langkah | Formula | Nilai anda |
|---------|---------|------------|
| 1. Volum jam puncak | V (transaksi/jam) | |
| 2. Kadar sasaran | X = V ÷ 3600 | |
| 3. Masa respons transaksi dijangka | R (s) | |
| 4. Think time sepanjang perjalanan | Z (s) | |
| 5. Pengguna serentak | N = X × (R + Z) | |
| 6. Kadar permintaan HTTP | X × (bilangan permintaan setiap transaksi) | |
| 7. Pacing (jika threads < N) | Constant Throughput Timer = X × 60 sampel/minit | |
