# Apache JMeter 3 Hari — Fail Lab (Portal eJPJ tiruan)

Fail untuk **buat latihan** kursus *Web Load & Performance Test Automation using JMeter*.
**Nota, langkah latihan, kuiz dan slaid ada di [pelatih.my](https://pelatih.my)** — repo ni simpan fail yang anda run sahaja.

*Lab files for the JMeter course; notes, step-by-step labs and quizzes are on pelatih.my.*

> ⚠️ **Etika:** semua test plan halakan ke **`http://localhost:3000`** (mock dalam `sut/`). Jangan test sistem sebenar (termasuk portal JPJ) tanpa kebenaran bertulis — itu dikira serangan DoS.

## Persediaan

- Java 17+ (`java --version`)
- Apache JMeter 5.6.3 (`jmeter -v`)
- Node.js 18+ (`node --version`)

```bash
git clone https://github.com/habibtalib/jmeter-2-days-training.git
cd jmeter-2-days-training
node sut/server.js          # Portal eJPJ tiruan → http://localhost:3000 (biar terbuka)
```

Dah ada salinan lama? `git pull` untuk dapat fail terkini.

## Isi repo

| Folder | Isi |
|---|---|
| `sut/` | Mock Portal eJPJ (API + portal web + chatbot) — `node sut/server.js` |
| `hari-1/test-plans/` | Plan rujukan Hari 1: `01` hello, `02` beban + assertion + timer, `03` CSV, `04` rakaman mentah (sengaja gagal), templat perakam |
| `hari-1/data/` | `kenderaan.csv` + kamus data |
| `hari-2/test-plans/` | `04` korelasi, `05` transaksi penuh, `06` non-GUI, `07` beban puncak + SLA, `08` ForEach, `09` berbilang lokasi, `10`/`10b` chatbot (+ PerfMon) |
| `hari-2/data/` | `pengguna.csv`, `kenderaan.csv`, `soalan-chatbot.csv` + kamus data |
| `hari-2/run/` | Skrip run non-GUI + laporan HTML (`run-nogui`, `run-berbilang-lokasi`, `run-chatbot-perfmon`; `.sh` dan `.bat`) |
| `hari-2/snippets/` | Contoh Groovy (JSR223), templat pelan ujian & laporan ujian |
| `img/` | Screenshot yang dipaparkan dalam latihan di pelatih.my |

## Fail ikut hari

| Hari | Latihan (di pelatih.my) | Fail |
|---|---|---|
| **Hari 1** | Latihan 0–7 | `hari-1/test-plans/01`–`04`, `rakam-template.jmx`, `hari-1/data/kenderaan.csv` |
| **Hari 2** | Latihan 1–5 | `hari-2/test-plans/04`–`08`, `hari-2/data/pengguna.csv`, `hari-2/run/run-nogui.*`, `templat-laporan-ujian.md` |
| **Hari 3** | Latihan 1 — laporan berbilang lokasi | `hari-2/test-plans/09-berbilang-lokasi.jmx`, `hari-2/run/run-berbilang-lokasi.sh` / `.bat`, `laporan-lokasi.js` |
| | Latihan 2 — CPU pelayan (PerfMon) + chatbot p95/p99 | `hari-2/test-plans/10-chatbot-beban.jmx`, `10b-chatbot-perfmon.jmx`, `hari-2/run/run-chatbot-perfmon.sh` / `.bat`, `hari-2/data/soalan-chatbot.csv` |
| | Latihan 3 — rancang ujian prestasi | `hari-2/snippets/templat-pelan-ujian.md` |
| | Latihan 4 — pembentangan mini | `hari-2/snippets/templat-laporan-ujian.md` |

> Hari 3 guna semula fail dalam folder `hari-2/` — tak ada folder `hari-3/` di sini. Dah clone sebelum ni? `git pull` sahaja.

Langkah demi langkah setiap latihan: buka kursus anda di **pelatih.my → Latihan**.
