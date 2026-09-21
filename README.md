# Kursus Apache JMeter 2 Hari — Ujian Prestasi Portal eJPJ

Kursus latihan amali **Apache JMeter** untuk ujian prestasi (performance/load testing), dengan nota dalam **Bahasa Melayu** dan istilah teknikal (Thread Group, ramp-up, throughput, percentile, correlation, assertion) dikekalkan dalam **Bahasa Inggeris**. Sepanjang 2 hari, peserta membina ujian beban lengkap terhadap **Portal eJPJ (tiruan)** — sebuah salinan tempatan yang meniru perkhidmatan dalam talian **Jabatan Pengangkutan Jalan (JPJ)**: log masuk, semak kenderaan, bayar cukai jalan, dan semak/bayar saman.

> ⚠️ **Etika & undang-undang:** Kursus ini menguji **hanya** aplikasi tiruan tempatan (`sut/`, `http://localhost:3000`). Menjalankan ujian beban terhadap sistem pengeluaran/awam yang anda **tidak** miliki atau tanpa kebenaran bertulis adalah menyalahi undang-undang (setara serangan **DoS**). Semua data adalah **sintetik/rekaan** — bukan data rasmi JPJ.

## Projek: Ujian Beban Portal eJPJ

Ujian ini menjawab soalan pengurusan seperti:

- Berapa **pengguna serentak** boleh portal tampung sebelum masa respons merosot?
- Apakah **95th percentile** masa transaksi "Pembaharuan Cukai Jalan"?
- Di manakah **titik pecah** (breaking point) sistem?
- Adakah **peratus ralat** kekal di bawah SLA semasa lonjakan (cth. hari cukai naik harga)?
- Bagaimana **latensi & throughput** berubah bila beban dinaikkan?

## Ringkasan Kursus

| Hari | Topik | Fokus | Hasil |
|------|-------|-------|-------|
| [**Hari 1**](./hari-1/) | Asas JMeter & Ujian Beban | Pasang JMeter, Test Plan, Thread Group, Sampler, Config, Listener, Assertion, Timer, CSV Data Set | Ujian beban berparameter + Assertion siap |
| [**Hari 2**](./hari-2/) | Lanjutan, Analisis & CI | Korelasi (Extractor), Logic Controllers, JSR223 Groovy, non-GUI + laporan HTML, SLA, CI/CD | Senario transaksi penuh + laporan prestasi |

## Keperluan Sistem

- **Java JDK 11+** (disyorkan 17/21 LTS) — JMeter berjalan atas Java
- **Apache JMeter 5.6+**
- **Node.js 18+** — untuk menjalankan Sistem Under Test tiruan (tiada `npm install` diperlukan)
- Minimum 8GB RAM untuk beban lebih besar
- Windows, macOS, atau Linux (JMeter merentas platform)

## Perisian yang Diperlukan

| Perisian | Tujuan | Pautan |
|----------|--------|--------|
| Java (Temurin JDK) | Runtime JMeter | [adoptium.net](https://adoptium.net/) |
| Apache JMeter | Alat ujian prestasi | [jmeter.apache.org](https://jmeter.apache.org/download_jmeter.cgi) |
| Node.js | Menjalankan SUT tiruan | [nodejs.org](https://nodejs.org/) |

## Konsep Utama yang Dipelajari

| Lapisan | Kemahiran |
|---------|-----------|
| Model beban | Thread Group — threads, ramp-up, loop, scheduler |
| Permintaan | HTTP Request, HTTP Request Defaults, Header Manager |
| Data | CSV Data Set Config, pembolehubah `${...}`, parameterisasi |
| Korelasi | JSON / Regular Expression / Boundary Extractor (token, csrf) |
| Aliran | Transaction / If / Loop / Throughput Controller |
| Pengesahan | Response Assertion, Duration Assertion |
| Rentak | Constant / Uniform / Gaussian Timer (think time) |
| Skrip | JSR223 (Groovy), fungsi `__Random`/`__UUID`/`__P` |
| Larian | Mod non-GUI, laporan HTML dashboard, `.jtl` |
| Analisis | Throughput, percentile, error %, APDEX, SLA/NFR |

## Struktur Repositori

```
jmeter-2-days-training/
├── README.md                       # Fail ini
├── CLAUDE.md                       # Panduan untuk Claude Code
├── sut/                            # Sistem Under Test — Portal eJPJ (tiruan)
│   ├── server.js                   # Pelayan Node.js tanpa dependency
│   ├── package.json
│   └── README.md                   # Endpoint + cara jalankan
├── hari-1/                         # Hari 1 — Asas JMeter & Ujian Beban
│   ├── README.md                   # Nota lengkap langkah demi langkah
│   ├── test-plans/                 # 01-hello, 02-cukai-beban, 03-csv-berparameter, 04-rakaman-mentah (.jmx)
│   ├── data/                       # kenderaan.csv + kamus data
│   └── snippets/                   # lab.md
├── hari-2/                         # Hari 2 — Lanjutan, Analisis & CI
│   ├── README.md                   # Nota lengkap langkah demi langkah
│   ├── test-plans/                 # 04-korelasi, 05-transaksi-penuh, 06-ujian-beban-nogui, 07-beban-puncak-cukai (.jmx)
│   ├── data/                       # pengguna.csv, kenderaan.csv + kamus data
│   ├── snippets/                   # jsr223-groovy.groovy, lab.md
│   └── run/                        # run-nogui.sh / .bat (larian non-GUI + laporan HTML)
└── slides/
    ├── jmeter-training.html        # Deck reveal.js (buka dalam pelayar)
    ├── README.md
    └── vendor/reveal/              # reveal.js (vendored, berfungsi dari file://)
```

## Cara Menggunakan Repositori Ini

1. **Clone** repositori ini dan pasang **Java + JMeter + Node.js**.
2. Jalankan Sistem Under Test — biarkan terbuka sepanjang lab:
   ```bash
   cd sut && node server.js        # http://localhost:3000
   ```
3. Buka JMeter (`jmeter`), ikut [`hari-1/README.md`](./hari-1/README.md) langkah demi langkah.
4. Pada Hari 2, ikut [`hari-2/README.md`](./hari-2/README.md) untuk korelasi, senario penuh, dan larian non-GUI.
5. Rujuk fail `.jmx` dalam `test-plans/` sebagai jawapan; `snippets/lab.md` untuk latihan.

## Menjalankan Beban (non-GUI) + Laporan HTML

```bash
# pastikan sut/server.js berjalan dahulu
cd hari-2/run
./run-nogui.sh                       # lalai: 50 pengguna, ramp 30s, 120s
PENGGUNA=200 TEMPOH=300 ./run-nogui.sh
# buka: hari-2/run/hasil/<cap-masa>/laporan/index.html
```

## Sistem Under Test (SUT)

Semua ujian menyasarkan **Portal eJPJ tiruan** di `http://localhost:3000`. Lihat [`sut/README.md`](./sut/README.md) untuk senarai endpoint penuh, pengguna tiruan, dan cara melaras latensi/kadar ralat untuk demo. Aplikasi ini **tiada dependency** — hanya `node server.js`.

## Slaid Pembentangan

Deck slaid (reveal.js) untuk pengajar — buka terus dalam pelayar, tiada pelayan diperlukan:

```text
slides/jmeter-training.html
```

## Komuniti & Sumber Tambahan

- [Manual Pengguna Apache JMeter](https://jmeter.apache.org/usermanual/index.html)
- [JMeter Best Practices](https://jmeter.apache.org/usermanual/best-practices.html)
- [Senarai Fungsi JMeter](https://jmeter.apache.org/usermanual/functions.html)
- [Component Reference](https://jmeter.apache.org/usermanual/component_reference.html)

## Penyumbang

Disediakan oleh **Habib** — [bespokesb.com](https://bespokesb.com)

## Lesen

Repositori ini dilesenkan di bawah [MIT License](LICENSE).
