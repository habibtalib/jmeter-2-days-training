# Latihan Hujung-ke-Hujung (Hari 1): Rakam → Main Balik

Satu aliran **lengkap**: rakam trafik dengan proxy JMeter → jana sampler → **main balik** → lihat ia **gagal** → faham kenapa **korelasi** diperlukan (Hari 2).

> **Sasaran:** hanya mock tempatan `http://localhost:3000` (dalam `sut/`). **Jangan** rakam/uji sistem awam tanpa kebenaran bertulis.

Anggaran masa: 15 minit.

---

## Prasyarat

1. **SUT berjalan** (biar terbuka sepanjang latihan):
   ```bash
   node sut/server.js          # http://localhost:3000
   ```
2. **JMeter GUI** terbuka.

---

## Langkah 1 — Buka perakam

Buka templat siap sedia (perakam + Recording Controller sudah dipasang):

**File → Open →** `hari-1/test-plans/rakam-template.jmx`

Pokok ujian sepatutnya ada:
- **HTTP(S) Test Script Recorder** (di peringkat Test Plan)
- **Thread Group → Recording Controller** (destinasi rakaman, kosong buat masa ini)

---

## Langkah 2 — Mula proxy

Pilih node **HTTP(S) Test Script Recorder** → klik hijau **Start** ▶.
- Proxy JMeter kini **mendengar di port 8888**.
- Jika muncul dialog **Root CA Certificate**, klik **OK** (untuk `http://` ia tidak digunakan).

> Sahkan proxy hidup (terminal lain): `lsof -iTCP:8888 -sTCP:LISTEN -n -P` — sepatutnya nampak `java … :8888 (LISTEN)`.

---

## Langkah 3 — Jana trafik untuk dirakam

Proxy merakam **mana-mana** klien HTTP yang melaluinya — bukan pelayar sahaja. Kerana SUT ini API (banyak **POST**), cara paling mudah & boleh dipercayai ialah **`curl` melalui proxy** (`-x http://localhost:8888`).

Jalankan aliran pembaharuan cukai penuh:

```bash
# 1) LOG MASUK (POST) — perhatikan respons memulangkan token + csrf
curl -s -x http://localhost:8888 -H 'Content-Type: application/json' \
  -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}' \
  http://localhost:3000/api/log-masuk
# contoh respons: {"token":"b3519618-…","csrf":"cefa6be3…","nama":"Pengguna 5500",…}

# salin nilai token & csrf dari respons di atas ke pemboleh ubah shell:
TOKEN='<tampal-token-di-sini>'
CSRF='<tampal-csrf-di-sini>'

# 2) SENARAI KENDERAAN (GET, perlu token)
curl -s -x http://localhost:8888 -H "Authorization: Bearer $TOKEN" \
  'http://localhost:3000/api/kenderaan?no_kp=800101015500'

# 3) BAYAR CUKAI (POST, perlu token + csrf)
curl -s -x http://localhost:8888 \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"csrf\":\"$CSRF\",\"tempoh_bulan\":12,\"amaun\":90}" \
  http://localhost:3000/api/kenderaan/WXY1234/bayar-cukai
# contoh respons: {"no_resit":"RJPJ…","status":"BERJAYA",…}
```

> **Alternatif pelayar:** konfigur **Firefox/Chrome** ke proxy `127.0.0.1:8888` (lihat Langkah 8 di README) dan layari `http://localhost:3000`. Tetapi pelayar hanya buat **GET** dari bar alamat — POST log masuk perlu borang, jadi `curl` lebih ringkas untuk API ini.
>
> ⚠️ **Guna klien yang betul-betul melalui proxy.** Pelayar biasa anda **tidak** melalui proxy melainkan dikonfigur. Jika tiada apa dirakam, hampir pasti trafik tak melalui `:8888`.

Selepas 3 arahan itu, **3 sampler** sepatutnya muncul di bawah **Recording Controller** dalam JMeter.

---

## Langkah 4 — Berhenti & kemas

1. Klik **Stop** ⏹ pada perakam.
2. Lihat 3 sampler dirakam: `/api/log-masuk`, `/api/kenderaan`, `/api/kenderaan/WXY1234/bayar-cukai`.
3. **Perhatikan yang penting:** buka sampler #2 & #3 → header **`Authorization: Bearer <token>`** dan badan **`csrf`** mengandungi **nilai TETAP** (dikeras-kod) dari sesi rakaman tadi. Perakam **tidak** korelasi apa-apa.
4. Simpan: **File → Save Test Plan As…** (cth. `rakaman-saya.jmx`).

---

## Langkah 5 — Main balik (playback)

1. Tambah **View Results Tree** di bawah Thread Group (untuk nyahpepijat).
2. **Penting — luputkan sesi rakaman dahulu:** mulakan semula SUT supaya token lama tak lagi sah:
   ```bash
   # Ctrl+C pada tetingkap SUT, kemudian:
   node sut/server.js
   ```
3. Klik **Start (▶)** untuk **main balik** plan yang dirakam.

**Apa yang berlaku:**

| Sampler | Kod | Sebab |
|---------|-----|-------|
| `POST /api/log-masuk` | **200** | Log masuk sentiasa berjaya (mana-mana kata laluan) |
| `GET /api/kenderaan` | **401** | Token dikeras-kod sudah **luput** (sesi baru selepas restart) |
| `POST …/bayar-cukai` | **401/403** | Token/csrf luput → tidak dibenarkan |

> Inilah **sebab utama korelasi**: nilai `token` & `csrf` **berubah setiap sesi**. Rakaman menangkapnya sebagai teks tetap, jadi main balik gagal sebaik sahaja sesi berubah.

---

## Bukti pantas (tanpa GUI)

Hasil rakaman "mentah" ini sudah disediakan sebagai [`test-plans/04-rakaman-mentah.jmx`](../test-plans/04-rakaman-mentah.jmx). Sahkan kelakuan main balik terus dari terminal:

```bash
node sut/server.js &     # pastikan SUT berjalan
jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/pb.jtl
```

Keputusan yang dijangka (disahkan):

```
/api/log-masuk                     -> HTTP 200  (success=true)
/api/kenderaan                     -> HTTP 401  (success=false)
/api/kenderaan/WXY1234/bayar-cukai -> HTTP 401  (success=false)
```

---

## Kesimpulan

Anda telah menyiapkan **satu kitaran penuh**: **rakam → jana sampler → main balik → gagal**.
Kegagalan itu **dijangka & mendidik** — ia menunjukkan had rakaman biasa.

**Langkah seterusnya (Hari 2):** ganti nilai tetap dengan **JSON Extractor** untuk menangkap `token` + `csrf` pada masa larian (korelasi), supaya main balik **berjaya**. Lihat [`hari-2/test-plans/04-korelasi-log-masuk.jmx`](../../hari-2/test-plans/04-korelasi-log-masuk.jmx).
