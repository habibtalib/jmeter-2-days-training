# Kamus Data — Hari 1

Fail data sintetik untuk latihan Apache JMeter. **Bukan** data rasmi JPJ; nombor pendaftaran & model adalah rekaan semata-mata untuk parameterisasi ujian.

## `kenderaan.csv`

Digunakan oleh **CSV Data Set Config** untuk menyuap nombor pendaftaran berlainan ke setiap thread/lelaran (lihat `hari-1/test-plans/03-csv-berparameter.jmx`).

| Lajur | Jenis | Keterangan | Contoh |
|-------|-------|------------|--------|
| `no_pendaftaran` | Teks | Nombor pendaftaran kenderaan (kunci sebut harga cukai) | `WXY1234` |
| `model` | Teks | Model kenderaan (rujukan/paparan sahaja) | `Perodua Myvi 1.5` |

Kelima-lima nombor pendaftaran ini **wujud** dalam pangkalan data tiruan `sut/server.js`, jadi endpoint `GET /api/kenderaan/:no_pendaftaran/cukai` akan memulangkan **200 OK**. Cuba tambah satu baris palsu (cth. `ABC0000`) untuk melihat **404** dan bagaimana **Response Assertion** menangkapnya.
