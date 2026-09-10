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

## Kandungan Deck (32 slaid)

| Bahagian | Tajuk |
|----------|-------|
| Pembuka | Gambaran kursus, hasil pembelajaran, rentak kelas, peta jalan, apa itu performance testing, jenis ujian (Load/Stress/Spike/Soak/Scalability), SUT mock eJPJ + etika, endpoint mock |
| Hari 1 | Pasang JMeter (Java), GUI vs non-GUI, anatomi Test Plan, peranan elemen, Thread Group, HTTP Request Sampler, Config Elements, Listeners, CSV Data Set Config, Assertions, Timers |
| Hari 2 | Correlation (token/csrf), Extractors (JSON/Regex/Boundary), Logic Controllers, JSR223 Groovy + functions, larian non-GUI + laporan HTML, membaca metrik (throughput/percentile/error %), ujian teragih, CI/CD + monitoring, amalan terbaik |
| Penutup | Ringkasan aliran kerja + langkah seterusnya |

## Etika Ujian

Deck menekankan satu prinsip penting: kita **tidak pernah** menguji beban laman JPJ produksi sebenar. Semua ujian dijalankan terhadap **Portal eJPJ (tiruan)** — aplikasi mock tempatan (`sut/`, `node server.js`, http://localhost:3000) sebagai System Under Test.

## Eksport ke PDF

Buka deck dengan:

```text
slides/jmeter-training.html?print-pdf
```

Kemudian guna dialog cetak pelayar dan pilih "Save as PDF".
