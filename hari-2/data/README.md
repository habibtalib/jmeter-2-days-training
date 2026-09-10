# Kamus Data — Hari 2

Fail data sintetik untuk senario penuh (log masuk → semak → bayar). **Bukan** data rasmi JPJ.

## `pengguna.csv`

Menyuap kelayakan log masuk ke thread berlainan (setiap thread satu pengguna).

| Lajur | Jenis | Keterangan | Contoh |
|-------|-------|------------|--------|
| `no_kp` | Teks | No. Kad Pengenalan (log masuk + kunci carian) | `800101015500` |
| `kata_laluan` | Teks | Kata laluan (mock menerima apa-apa nilai bukan-kosong) | `rahsia123` |

## `kenderaan.csv`

Memetakan setiap `no_kp` kepada kenderaan & amaun cukai — untuk senario bayar cukai berparameter penuh.

| Lajur | Jenis | Keterangan | Contoh |
|-------|-------|------------|--------|
| `no_kp` | Teks | Pemilik kenderaan | `800101015500` |
| `no_pendaftaran` | Teks | Kenderaan yang hendak dibayar cukai | `WXY1234` |
| `amaun` | Nombor | Amaun cukai (RM) | `90` |

> **Nota:** Nilai `token` dan `csrf` **tidak** disimpan dalam CSV — ia diperoleh secara dinamik pada masa larian melalui **korelasi** (JSON Extractor pada respons `/api/log-masuk`). Itulah inti pelajaran Hari 2.
