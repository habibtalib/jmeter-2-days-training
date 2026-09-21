# Slaid Kursus Apache JMeter 2 Hari

Buka deck slaid reveal.js terus dalam pelayar:

```text
slides/jmeter-training.html
```

## Rangka Kerja (Framework)

Deck ini menggunakan reveal.js, yang disimpan secara tempatan (vendored) di bawah:

```text
slides/vendor/reveal/
```

Ini membolehkan deck berfungsi terus dari `file://` tanpa CDN atau pelayan pembangunan.

## Kawalan

- Anak panah kanan / bawah / Space: slaid seterusnya
- Anak panah kiri / atas: slaid sebelumnya
- Esc: gambaran keseluruhan slaid
- S: nota penceramah (speaker notes)
- Ctrl/Cmd + F: carian
- Alt + klik: zum

## Kandungan Deck (44 slaid)

| Bahagian | Tajuk |
|----------|-------|
| Pembuka | Gambaran kursus, **agenda (What's in it for you)**, hasil pembelajaran, rentak kelas, peta jalan, apa itu performance testing, jenis ujian (Load/Stress/Spike/Soak/Scalability), **apa itu load testing, alat load testing (JMeter/WebLOAD/LoadUI/LoadRunner/NeoLoad/LoadNinja), apa itu JMeter, kenapa JMeter**, SUT mock eJPJ + etika, endpoint mock |
| Hari 1 | Pasang JMeter (Java), GUI vs non-GUI, anatomi Test Plan, peranan elemen, Thread Group, HTTP Request Sampler, Config Elements, Listeners, CSV Data Set Config, Assertions, Timers |
| Hari 2 | Correlation (token/csrf), Extractors (JSON/Regex/Boundary), Logic Controllers, JSR223 Groovy + functions, larian non-GUI + laporan HTML, membaca metrik (throughput/percentile/error %), ujian teragih, CI/CD + monitoring, amalan terbaik |
| Demo | **Tangkapan skrin sebenar JMeter 5.6** — Test Plan dimuat, CSV Data Set, Thread Group, HTTP Request + Body Data, JSON Extractor (correlation), Summary Report (keputusan) |
| Penutup | Ringkasan aliran kerja + langkah seterusnya |

> **Tangkapan skrin demo** disimpan dalam `slides/img/` (ditangkap daripada Apache JMeter 5.6.3 terhadap mock eJPJ tempatan).

> **Sumber intro:** empat slaid pembuka (apa itu load testing → alat → apa itu JMeter → kenapa JMeter) diadaptasi daripada video pengenalan Simplilearn, *“JMeter Load Testing — Tutorial For Beginners”* ([YouTube](https://www.youtube.com/watch?v=NTyY8wKSvik)).

## Etika Ujian

Deck menekankan satu prinsip penting: kita **tidak pernah** menguji beban laman JPJ produksi sebenar. Semua ujian dijalankan terhadap **Portal eJPJ (tiruan)** — aplikasi mock tempatan (`sut/`, `node server.js`, http://localhost:3000) sebagai System Under Test.

## Eksport ke PDF

Buka deck dengan:

```text
slides/jmeter-training.html?print-pdf
```

Kemudian guna dialog cetak pelayar dan pilih "Save as PDF".
