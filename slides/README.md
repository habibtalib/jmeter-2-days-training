# Slaid Kursus Apache JMeter 2 Hari (JMETER-JPJ-2)

Dek slaid **Ujian Prestasi dengan Apache JMeter — Ujian Prestasi Portal eJPJ (tiruan)** untuk Jabatan Pengangkutan Jalan Malaysia (Hari 1: Isnin 21 Sep 2026 · Hari 2: Isnin 5 Okt 2026). Buka terus dalam pelayar:

```text
slides/jmeter-training.html
```

## Enjin

- Satu fail HTML **self-contained**: CSS + JS sendiri, tiada reveal.js, tiada CDN, tiada Google Fonts. Berfungsi dari `file://` dan dalam iframe bersandbox.
- Enjin sama seperti dek saudara **CI-KKM-10** dan **JS-PGN-5**: pentas 1280×720 diskala, `section.slide` terus di bawah `#stage`, progress bar, kaunter slaid, HUD label hari, nota penceramah, gambaran keseluruhan, cetak PDF.
- Tangkapan skrin dalam `slides/img/` (JMeter 5.6.3 terhadap mock eJPJ tempatan). Klik gambar untuk zum skrin penuh.
- `slides/vendor/reveal/` ialah peninggalan dek lama. Dek baharu tidak menggunakannya.

## Kawalan

| Kekunci | Tindakan |
|---------|----------|
| `→` `Space` `PgDn` `N` / klik separuh kanan / leret kiri | Slaid seterusnya |
| `←` `Shift+Space` `PgUp` `P` / klik separuh kiri / leret kanan | Slaid sebelumnya |
| `Home` / `End` | Slaid pertama / terakhir |
| `G` + nombor + `Enter` | Lompat ke slaid |
| `O` | Gambaran keseluruhan (klik untuk lompat) |
| `S` | Panel nota penceramah + jam + tajuk slaid seterusnya |
| `F` | Skrin penuh |
| `?` | Bantuan pintasan |
| `Esc` | Tutup panel / zum gambar |

URL `#n` membuka slaid ke-n (cth. `jmeter-training.html#42` = Hari 2).

## Struktur (90 slaid)

| Bahagian | `data-label` | Kandungan |
|----------|--------------|-----------|
| Pengenalan (9) | `Pengenalan` | Kulit, what's in it for you, agenda 2 hari (S1–S4 + masa), load testing, alat, apa & kenapa JMeter, endpoint Portal eJPJ (tiruan), **etika (localhost sahaja = elak DoS)**, cara lab berjalan |
| Hari 1 (32) | `Hari 1 · Asas JMeter` | Pembahagi + objektif O1–O9. **S1 9.00–10.30**: ujian prestasi, 5 jenis ujian, pasang Java/JMeter, PATH Windows, GUI vs non-GUI, SUT, antara muka. **S2 10.45–1.00**: pokok Test Plan, skop & susunan, Test Plan pertama, Thread Group, kira sampel, Header Manager, Listeners, percentile. **S3 2.00–3.30**: Assertion, Timer, CSV Data Set, sharing/EOF, Kes 1–5. **S4 3.45–5.00**: perakam, Firefox + sijil CA, rakam, main balik 200/401/401, laporan HTML, rumusan |
| Hari 2 (44) | `Hari 2 · Rakam, Laporan & Perancangan` | Pembahagi + objektif O1–O9 + kitaran kerja & plan. **S1 Rakam & Main Balik 9.00–10.30** (7): imbas kembali, rancang T01…T04, `rakam-template.jmx` (proxy 8888, Transaction Controller, Excludes, `${T}`), rakam dengan curl, main balik 200/401/200/401 + lulus palsu, 401 vs 403. **S2 Jadikan Rakaman Boleh Dimain Balik 10.45–1.00** (7): senarai semak 10 perkara, korelasi `token` + `csrf`, korelasi berantai + CSV, nama + Transaction Controller + think time, assertion + Summary/Aggregate, ⭐ ForEach/JSR223. **S3 Laporan & Istilah 2.00–3.30** (17): `.jtl` → dashboard (`-e -o`, `-g`, `overall_granularity`), peta dashboard, APDEX, Statistics, percentile vs average, Errors/Top 5, connect/latency/elapsed, Over Time, Throughput, Response Times, tepu, glosari ×2, plan 07 + `-Jsla_ms`, baseline R1/R2/R3, menulis dapatan. **S4 Merancang Ujian Prestasi 3.45–5.00** (10): kitaran hayat, NFR, Little's Law, pacing + campuran, jenis larian, kriteria/pemantauan/risiko, kebenaran bertulis, templat pelan + Lab 6/7, ⭐ CI/distributed/Grafana |
| Penutup (5) | `Penutup` | Apa anda kini boleh buat (rakam, laporan, rancang), rumusan 2 hari, langkah seterusnya, **borang penilaian (pelatih.my, dibuka 2.00 ptg Hari 2)**, terima kasih |

Setiap sesi dibuka dengan slaid tajuk sesi gelap (kod sesi + masa + lab + kuiz).

### Kontrak pengimport (pelatih.my)

- Setiap slaid ialah `<section class="slide …">` terus di bawah `#stage`.
- Pembahagi hari: `<section class="slide dark divider" data-label="Hari N · …">`, eyebrow bermula `Hari N`.
- Nota penceramah **hanya** dalam `<aside class="notes">…</aside>` — pengimport membuangnya untuk pelatih. Setiap slaid ada nota (apa nak cakap, isyarat demo, soalan kepada kelas).

## Tema

Token warna di `:root` sahaja (ubah di situ):

| Token | Nilai | Guna |
|-------|-------|------|
| `--navy-950/900/800/700` | `#071026` `#0C1A3A` `#132A5C` `#1C3D80` | Kulit, pembahagi, sesi |
| `--acc` / `--acc-700` | `#2563EB` / `#1D4ED8` | Aksen utama (biru JPJ), eyebrow, langkah |
| `--jpj` / `--jpj-700` | `#FFC20E` / `#8A5A00` | Kuning JPJ: sorotan, amaran, label kod |
| `--pass` / `--pass-700` | `#16A34A` / `#15803D` | Isyarat lulus (200, ✅, SLA lulus) |
| `--fail` / `--fail-700` | `#DC2626` / `#B91C1C` | Isyarat gagal (401/403/500, ❌, SLA gagal) |
| `--glow` / `--signal` | `#FFD24D` / `#4ADE80` | Aksen pada latar gelap |

Teks pada latar cerah menggunakan varian `-700` untuk kontras AA.

## Etika

Dek menekankan: kita **tidak pernah** menguji beban sistem JPJ sebenar. Semua ujian menyasarkan **Portal eJPJ (tiruan)** (`sut/`, `node server.js`, `http://localhost:3000`) dengan data sintetik. Ujian beban tanpa kebenaran bertulis = serangan DoS.

## Eksport ke PDF

Buka dek, tekan `Ctrl/Cmd + P`, pilih **Save as PDF**, landskap A4, margin *None*, tanda *Background graphics*. Gaya cetak menghasilkan satu slaid satu halaman dengan nombor halaman; nota penceramah tidak dicetak.

> **Sumber intro:** slaid pembuka (load testing → alat → JMeter) diadaptasi daripada video Simplilearn, *“JMeter Load Testing — Tutorial For Beginners”* ([YouTube](https://www.youtube.com/watch?v=NTyY8wKSvik)).
