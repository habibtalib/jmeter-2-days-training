# Latihan Hujung-ke-Hujung (Hari 1): Rakam → Main Balik

Satu flow **lengkap**: record trafik guna proxy JMeter → JMeter generate sampler → **replay** → tengok ia **fail** → faham kenapa kita perlukan **correlation** (Hari 2).

> **Sasaran:** mock local `http://localhost:3000` (dalam `sut/`) sahaja. **Jangan** record/test sistem awam tanpa kebenaran bertulis.

Anggaran masa: 15 minit.

---

## Prasyarat

1. **SUT tengah run** (biarkan terbuka sepanjang latihan):
   ```bash
   node sut/server.js          # http://localhost:3000
   ```
2. **JMeter GUI** dah dibuka.

---

## Langkah 1 — Buka perakam

Buka template yang dah siap (recorder + Recording Controller dah ada):

**File → Open →** `hari-1/test-plans/rakam-template.jmx`

Dalam tree, patutnya ada:
- **HTTP(S) Test Script Recorder** (bawah Test Plan)
- **Thread Group → Recording Controller** (tempat simpan recording, kosong buat masa ni)

---

## Langkah 2 — Mula proxy

Pilih node **HTTP(S) Test Script Recorder** → klik butang hijau **Start** ▶.
- Proxy JMeter sekarang **listen di port 8888**.
- Kalau keluar dialog **Root CA Certificate**, klik **OK** (untuk `http://` certificate ni tak digunakan).

> Check proxy dah hidup (buka terminal lain): `lsof -iTCP:8888 -sTCP:LISTEN -n -P` — patutnya nampak `java … :8888 (LISTEN)`.

---

## Langkah 3 — Jana trafik untuk dirakam

Proxy akan record **apa-apa** HTTP client yang lalu melaluinya — bukan browser sahaja. Sebab SUT ni API (banyak **POST**), cara paling senang & reliable ialah **`curl` melalui proxy** (`-x http://localhost:8888`).

Run flow renew cukai jalan penuh:

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

> **Alternatif guna browser:** setting **Firefox** ke proxy `127.0.0.1:8888` (tengok README §4.3, langkah B4–B6 — termasuk `about:config` → `network.proxy.allow_hijacking_localhost` = `true`, kalau tak Firefox bypass proxy untuk localhost) dan buka `http://localhost:3000/portal` (borang log masuk → kenderaan → bayar). Flow portal tu record request borang `/portal/...`, bukan `/api/...` — untuk API JSON ni, `curl` lebih ringkas.
>
> ⚠️ **Pastikan client yang anda guna betul-betul lalu proxy.** Browser biasa anda **tidak** lalu proxy kalau tak di-configure. Kalau tiada apa-apa yang ter-record, hampir confirm trafik tak lalu `:8888`.

Lepas 3 command tu, **3 sampler** patutnya muncul bawah **Recording Controller** dalam JMeter.

---

## Langkah 4 — Berhenti & kemas

1. Klik **Stop** ⏹ pada recorder.
2. Tengok 3 sampler yang ter-record: `/api/log-masuk`, `/api/kenderaan`, `/api/kenderaan/WXY1234/bayar-cukai`.
3. **Ini yang penting:** buka sampler #2 & #3 → header **`Authorization: Bearer <token>`** dan body **`csrf`** ada **nilai TETAP** (hardcoded) dari session recording tadi. Recorder **tidak** buat correlation langsung.
4. Save: **File → Save Test Plan As…** (contohnya `rakaman-saya.jmx`).

---

## Langkah 5 — Main balik (playback)

1. `rakam-template.jmx` dah ada **View Results Tree** (bawah Test Plan) — pilih ia untuk debug. (Kalau plan anda tiada: klik kanan Thread Group → Add → Listener → View Results Tree.)
2. **Penting — expire-kan session recording dulu:** restart SUT supaya token lama dah tak valid:
   ```bash
   # Ctrl+C pada tetingkap SUT, kemudian:
   node sut/server.js
   ```
3. Klik **Start (▶)** untuk **replay** plan yang dah di-record.

**Apa yang jadi:**

| Sampler | Kod | Sebab |
|---------|-----|-------|
| `POST /api/log-masuk` | **200** | Log masuk sentiasa berjaya (apa-apa kata laluan pun boleh) |
| `GET /api/kenderaan` | **401** | Token hardcoded dah **expired** (session baru lepas restart) |
| `POST …/bayar-cukai` | **401** | Token lama dah expired → terus ditolak sebelum `csrf` sempat di-check |

> Inilah **sebab utama kita perlukan correlation**: nilai `token` & `csrf` **berubah setiap session**. Recording simpan nilai tu sebagai teks tetap, jadi replay terus fail bila session berubah.

---

## Bukti pantas (tanpa GUI)

Hasil recording "mentah" ni dah disediakan sebagai [`test-plans/04-rakaman-mentah.jmx`](../test-plans/04-rakaman-mentah.jmx). Check behaviour replay terus dari terminal:

```bash
node sut/server.js &     # pastikan SUT berjalan
jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/pb.jtl
```

Result yang dijangka (dah disahkan):

```
/api/log-masuk                     -> HTTP 200  (success=true)
/api/kenderaan                     -> HTTP 401  (success=false)
/api/kenderaan/WXY1234/bayar-cukai -> HTTP 401  (success=false)
```

---

## Langkah 6 — Jana laporan HTML dari rakaman

Tambah `-e -o <folder>` masa run untuk generate **HTML dashboard report** terus dari replay:

```bash
# folder output MESTI kosong / belum wujud
jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx \
  -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
open /tmp/laporan-rakaman/index.html          # Windows: start /tmp\laporan-rakaman\index.html
```

Atau generate **kemudian** dari `.jtl` yang dah ada:
```bash
jmeter -g /tmp/rec.jtl -o /tmp/laporan-rakaman/
```

**Apa yang report tunjuk:**

| Rakaman | Error % | Sebab |
|---------|---------|-------|
| **Mentah** (`04-rakaman-mentah.jmx`) | **~67%** | Token/csrf hardcoded → 401 masa replay |
| **Dikorelasi** (`hari-2/…/05-transaksi-penuh.jmx`) | **0%** | JSON Extractor tangkap token/csrf masa runtime |

> Inilah gunanya report: ia **tunjuk dengan jelas** kesan correlation — Error % turun dari ~67% ke 0% lepas recording dibersihkan. (Report penuh: APDEX, percentile 90/95/99, throughput, error %.)

> **Nota:** recording biasa run 1 user × 1 loop → sampel sikit → report nipis. Untuk report yang bermakna, naikkan threads/loops atau guna [`hari-2/run/run-nogui.sh`](../../hari-2/run/run-nogui.sh).

---

## Kesimpulan

Anda dah siapkan **satu kitaran penuh**: **record → generate sampler → replay → fail**.
Fail tu memang **dijangka & ada pengajarannya** — ia tunjuk had recording biasa.

**Langkah seterusnya (Hari 2):** ganti nilai tetap dengan **JSON Extractor** untuk tangkap `token` + `csrf` masa runtime (correlation), supaya replay **berjaya**. Tengok [`hari-2/test-plans/04-korelasi-log-masuk.jmx`](../../hari-2/test-plans/04-korelasi-log-masuk.jmx).
