# Apache JMeter 2 Hari — Fail Lab (Portal eJPJ tiruan)

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

Langkah demi langkah setiap latihan: buka kursus anda di **pelatih.my → Latihan**.
