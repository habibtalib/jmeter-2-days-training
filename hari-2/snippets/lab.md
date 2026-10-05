# Lab Hari 2 — Rakam & Main Balik, Laporan Prestasi & Merancang Ujian

[⬅️ README Hari 2](../README.md) · [🎤 Nota Penceramah](../nota-penceramah.md) · [🗂️ Test plans rujukan](../test-plans/) · [📋 Templat Pelan Ujian](./templat-pelan-ujian.md) · [📝 Templat Laporan Ujian](./templat-laporan-ujian.md)

> **Peraturan lab:** Sentiasa buka dua window — **Terminal A**: mock server (`node sut/server.js` dari root repo, jangan tutup), **Terminal B / JMeter GUI**: untuk latihan. Kalau ada benda "tak jalan", check ikut turutan ni: (1) log Terminal A, (2) View Results Tree → tab **Request** & **Response data**, (3) Debug Sampler, (4) `jmeter.log` (ikon ⚠️ kuning di penjuru kanan atas GUI).

> ⚠️ **Etika:** semua latihan **hanya** target `http://localhost:3000` (Portal eJPJ tiruan, data sintetik). Setiap kali buka plan, check dulu **HTTP Request Defaults → Server Name or IP = `localhost`, Port = `3000`** sebelum tekan Start.

> 💡 Save plan latihan anda dalam `hari-2/test-plans/` (contoh `latihan-01-rakaman.jmx`) supaya path CSV `../data/pengguna.csv` betul. Simpan hasil run dalam folder `hasil/` (dah ada dalam `.gitignore`). Plan rujukan tu "skema jawapan" — cuba buat sendiri dulu.

| Latihan | Sesi | Plan / bahan rujukan | Hasil |
|---------|------|----------------------|-------|
| 1 — Record flow bayar cukai | S1 | `hari-1/test-plans/rakam-template.jmx` | 4 sampler dalam 4 Transaction Controller yang ada nama |
| 2 — Replay & diagnose 401/403 | S1 | `hari-1/test-plans/04-rakaman-mentah.jmx` | 200 / 401 / 200 / 401 dapat diterangkan; 403 berjaya dihasilkan |
| 3 — Buat recording boleh di-replay | S2 | `04-korelasi-log-masuk.jmx`, `05-transaksi-penuh.jmx` | 80 sample HTTP + 20 transaksi, Error % ≈ 0 |
| 4 — Generate HTML dashboard & baca setiap bahagian | S3 | `05-transaksi-penuh.jmx` (atau plan Latihan 3) | Worksheet dashboard lengkap |
| 5 — Senario peak `07` + SLA → 3 dapatan | S3 | `07-beban-puncak-cukai.jmx`, `templat-laporan-ujian.md` | Dua report + tiga dapatan bertulis |
| 6 — Rancang test + Little's Law | S4 | `templat-pelan-ujian.md` | Test plan diisi + kiraan N & pacing |
| 7 — Pembentangan mini | S4 | Test plan (Lat. 6) + report (Lat. 5) | Pembentangan 3 minit |
| 8 — Report multi-lokasi (agent distributed) | S3 | `09-berbilang-lokasi.jmx`, `run/run-berbilang-lokasi.sh` | Report gabungan + per lokasi, jadual perbandingan, 2 dapatan |
| 9 — CPU pelayan (PerfMon) + p95/p99 chatbot | S3 | `10b-chatbot-perfmon.jmx`, `run/run-chatbot-perfmon.sh`, ServerAgent | `perfmon.jtl` + 3 PNG + dashboard, knee point, NFR p95/p99 + 1 dapatan |

---

## Latihan 1 — Rakam aliran bayar cukai

**Sesi:** S1

### 🎯 Objektif
- Rancang user journey 4 langkah dan nama transaksi sebelum mula record (O1)
- Setup HTTP(S) Test Script Recorder: port 8888, Grouping ke Transaction Controller, Excludes, think time `${T}` (O1)
- Record log masuk → senarai kenderaan → semak cukai → bayar cukai melalui proxy (O1)

### Prasyarat
- SUT tengah run: `node sut/server.js` → <http://localhost:3000/api/health> return `{"status":"ok",...}`
- `curl` ada (macOS/Linux dah built-in; Windows: **Git Bash**)
- README §1.2–1.5

### Langkah
1. **Rancang:** salin jadual README §1.2 ke kertas/nota anda. Untuk setiap langkah, tanda nilai yang anda **jangka** dinamik (token, csrf, no_pendaftaran, amaun).

   ![README §1.2: jadual rancangan rakaman T01–T04](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-05-rancang-jadual-transaksi.png)
   *Jadual README §1.2 yang anda salin: satu baris = satu tindakan user = satu transaksi `T0x_…`, dengan nilai yang dijangka dinamik.*

2. **File → Open →** `hari-1/test-plans/rakam-template.jmx` → **File → Save As** → `hari-2/test-plans/latihan-01-rakaman.jmx`.

   ![rakam-template.jmx dibuka dalam JMeter](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-06-rakam-template-dibuka.png)
   *`rakam-template.jmx` lepas **Open**: Thread Group → Recording Controller, View Results Tree dan HTTP(S) Test Script Recorder.*

3. **Klik kanan Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, Server `localhost`, Port `3000`. (Recorder akan biarkan Server/Port sampler kosong.)

   ![HTTP Request Defaults http localhost 3000 bawah Thread Group](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-07-http-request-defaults.png)
   ***HTTP Request Defaults** bawah Thread Group: `http` · `localhost` · `3000`.*

4. Klik **HTTP(S) Test Script Recorder**:
   - Port: `8888` · Target Controller: `Test Plan > Thread Group > Recording Controller`
   - **Grouping:** `Put each group in a new transaction controller`
   - **Capture HTTP Headers:** tick
   - **Requests Filtering → URL Patterns to Exclude:** regex untuk static asset dah ada — tambah baris `.*google-analytics.*` dan `.*googletagmanager.*` (amalan biasa untuk site sebenar)

   ![Recorder tab Test Plan Creation: port 8888, Target Controller, Grouping transaction controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-08-recorder-test-plan-creation.png)
   *Tab **Test Plan Creation**: Port `8888`, Target Controller `… > Thread Group > Recording Controller`, Grouping **Put each group in a new transaction controller**, **Capture HTTP Headers** ditick.*

   ![Recorder tab Requests Filtering: URL Patterns to Exclude dengan google-analytics dan googletagmanager](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-09-recorder-requests-filtering.png)
   *Tab **Requests Filtering**: regex static asset asal + dua baris baru `.*google-analytics.*` dan `.*googletagmanager.*`.*

5. **Klik kanan HTTP(S) Test Script Recorder → Add → Timer → Constant Timer**: Thread Delay `${T}`.

   ![Constant Timer Thread Delay ${T} bawah recorder](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-10-constant-timer-t.png)
   ***Constant Timer** child kepada recorder, Thread Delay `${T}` — recorder akan tukar `${T}` jadi gap sebenar (ms).*

6. Klik **Start** ▶. Kalau keluar dialog sijil Root CA, klik **OK** (tak digunakan untuk `http://`). Window **Recorder: Transactions Control** akan keluar — biarkan terbuka.

   ![Recorder lepas Start: butang Stop dan Restart aktif](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-11-recorder-dah-start.png)
   *Lepas **Start**: butang Start kelabu, **Stop** dan **Restart** aktif — proxy sedang mendengar.*

   ![Window Recorder: Transactions Control](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-12-recorder-transactions-control.png)
   *Window **Recorder: Transactions Control** — field **Transaction name** (prefix), **Naming scheme**, **Create new transaction after request (ms)**. Biarkan terbuka.*

7. Terminal B: pastikan proxy dah hidup — `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (Windows: `netstat -ano | findstr :8888`).

   ![lsof tunjuk java LISTEN pada port proxy](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-13-lsof-proxy-listen.png)
   *Output sebenar `lsof`: process `java` (JMeter) dalam keadaan **LISTEN** — proxy hidup. (tangkapan ini guna instance mock kami sendiri pada port 3917 dan proxy 18888 supaya tak ganggu kelas — anda guna 3000 / 8888)*

8. Sebelum setiap langkah, taip nama transaksi (`T01_LogMasuk`, `T02_SenaraiKenderaan`, `T03_SemakCukai`, `T04_BayarCukai`) dalam field prefix/transaction name dalam window *Recorder: Transactions Control*. Lepas tu run blok curl untuk langkah tu daripada README §1.4 — **tunggu > 5 s** antara setiap blok.

   ![Transactions Control: Transaction name T01_LogMasuk](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-14-prefix-t01-logmasuk.png)
   *Sebelum blok pertama: taip `T01_LogMasuk` dalam **Transaction name**.*

   ![Blok curl T01 melalui proxy: respons token dan csrf](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-15-curl-t01-logmasuk.png)
   *Blok `T01_LogMasuk` melalui proxy (`-x $P`): respons sebenar ada `token` dan `csrf` baru.*

9. Lepas langkah 4 keluar `"status":"BERJAYA"`, klik **Stop** ⏹ dan **File → Save**.

   ![Blok curl T04 bayar cukai: status BERJAYA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-16-curl-t04-berjaya.png)
   *Blok `T04_BayarCukai`: respons terakhir `"status":"BERJAYA"` — sekarang klik **Stop** dan **File → Save**.*

10. Expand **Recording Controller**: catat nama setiap Transaction Controller dan sampler. Buka Header Manager `T02` — salin 8 aksara pertama nilai `Authorization`. Buka body sampler `T04` — cari `csrf`.

    ![Recording Controller dengan Transaction Controller T01 hingga T04](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-17-recording-controller-t01-t04.png)
    *Hasil rakaman sebenar: empat Transaction Controller `T01_…`–`T04_…`, setiap satu ada sampler (`T01_LogMasuk/api/log-masuk-1`, …) + Constant Timer + HTTP Header Manager.*

    ![Header Manager T02: Authorization Bearer token rakaman](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-18-header-manager-t02-bearer.png)
    *Header Manager `T02`: `Authorization: Bearer <token-rakaman>` — nilai **hardcode**.*

    ![Body Data sampler T04 dengan csrf literal](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-19-body-t04-csrf.png)
    *Body Data sampler `T04`: `"csrf":"…"` literal dari session rakaman.*

![Portal eJPJ tiruan: borang log masuk](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-01-portal-log-masuk.png)
*Aliran yang dirakam (versi browser): <http://localhost:3000/portal> → borang **Log Masuk** (POST `/portal/log-masuk`). Kalau browser di-set guna proxy `localhost:8888`, setiap klik jadi sampler.*

![Portal eJPJ: senarai Kenderaan Saya](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-02-portal-senarai-kenderaan.png)
*Lepas log masuk → **Kenderaan Saya** (GET `/portal/kenderaan`, perlu cookie session `SESI_EJPJ`). Klik **Bayar cukai** untuk WXY1234.*

![Portal eJPJ: borang bayar cukai dengan medan tersembunyi csrf](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-03-portal-borang-bayar-csrf.png)
*Borang **Bayar Cukai Jalan**: kotak merah tunjuk hidden field `csrf` dan `amaun` (dilihat melalui DevTools → Elements). `csrf` ni nilai dinamik — kena korelasi dalam Latihan 3.*

![Portal eJPJ: resit Pembayaran Berjaya status BERJAYA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-04-portal-resit-berjaya.png)
*Langkah terakhir: resit **Status: BERJAYA**. Teks ni yang kita guna untuk Response Assertion.*

![HTTP(S) Test Script Recorder: proksi port 8888, Target Controller Recording Controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-29-gui-recorder-settings.png)
*HTTP(S) Test Script Recorder: proxy port 8888, request yang di-record masuk ke dalam Recording Controller. (Template asal tunjuk “Add separators between groups” — tukar Grouping macam langkah 4.)*

### ✅ Checkpoint
- [ ] Jadual perancangan 4 langkah (tindakan, permintaan, nama transaksi, data dinamik) ditulis sebelum merakam
- [ ] Grouping ditetapkan ke *Put each group in a new transaction controller* dan Constant Timer `${T}` ditambah di bawah perakam
- [ ] Recording Controller mengandungi **4** kumpulan / Transaction Controller, setiap satu dengan satu sampler `/api/...`, tanpa aset statik
- [ ] Anda boleh menunjuk di mana `token` dan `csrf` sesi rakaman dikeras-kod dalam plan
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| `curl: (7) Failed to connect to localhost port 8888` | Recorder belum **Start** | Klik Start pada HTTP(S) Test Script Recorder |
| curl berjaya tapi tak ada sampler di-record | Terlupa `-x $P`, atau variable `P` tak di-set dalam terminal tu | Run semula baris `P=…` dan `B=…`; check `echo $P` |
| `Could not create script recorder - port in use` | Port 8888 tengah dipakai (recorder lain / app lain) | Tutup tab JMeter lain yang tengah record; atau tukar port (dan `P`) |
| Keempat-empat request masuk dalam satu Transaction Controller | Jarak antara langkah < 5 s | Record semula dengan `sleep 6` antara blok; atau asingkan secara manual (drag sampler) |
| Error "Target Controller is configured to Use Recording Controller but no such controller exists" | Recording Controller terpadam | **Klik kanan Thread Group → Add → Logic Controller → Recording Controller** |
| `TOKEN` kosong dalam langkah 2 | Response log masuk tak sampai (SUT mati) | Check Terminal A; run blok T01 sekali lagi |

### ⭐ Cabaran
1. Record semula dengan Naming scheme **Use format string** dan format `#{counter,number,000} - #{method} #{path}`. Bandingkan nama sampler.
2. Record dengan Grouping **Add separators between groups** (setting asal template). Bila option ni lebih sesuai berbanding Transaction Controller?

---

## Latihan 2 — Main balik & diagnosis 401/403

**Sesi:** S1

### 🎯 Objektif
- Replay recording selepas session recording dah expired, dan catat status code setiap langkah (O2)
- Guna tab **Sampler result**, **Request** dan **Response data** dalam View Results Tree untuk cari punca (O2)
- Bezakan 401 (token) dengan 403 (csrf) melalui eksperimen (O2)

### Prasyarat
- Latihan 1 dah siap (`latihan-01-rakaman.jmx`), atau guna backup `hari-1/test-plans/04-rakaman-mentah.jmx` (backup ni cuma ada 3 sampler — tiada semak cukai — dan token dia dari session lain, jadi langkah 1 terus dapat 200 / 401 / 401)
- README §1.6–1.7

### Langkah
1. **Replay pertama — tanpa restart SUT:** Start ▶. Catat status code setiap langkah. (Jangkaan: semua 200 — "false pass", sebab session recording masih hidup.)

   ![View Results Tree replay pertama: semua hijau](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-03-vrt-replay-pertama-200.png)
   *Replay pertama tanpa restart: semua hijau, `T02` = **200** — "false pass" sebab session rakaman masih hidup.*

2. **Buat session expired:** Terminal A → **Ctrl+C** → `node sut/server.js`.

   ![Terminal A: Ctrl+C dan SUT start semula](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-04-restart-sut.png)
   *Terminal A lepas **Ctrl+C** → start semula: banner `Portal eJPJ (TIRUAN) berjalan di …` keluar semula = semua session lama hilang. (tangkapan ini guna instance mock kami sendiri pada port 3917 dan proxy 18888 supaya tak ganggu kelas — anda guna 3000 / 8888)*

3. **Replay kedua:** klik ikon **Clear All** (berus) dekat toolbar, lepas tu Start ▶. Isi jadual:

   | Transaksi | Kod | Response message | Mesej `ralat` dalam Response data |
   |-----------|-----|------------------|-----------------------------------|
   | T01_LogMasuk | | | |
   | T02_SenaraiKenderaan | | | |
   | T03_SemakCukai | | | |
   | T04_BayarCukai | | | |

   ![View Results Tree replay kedua: T02 401 Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-05-vrt-t02-401.png)
   *Replay kedua: `T01` hijau, `T02` merah — **Sampler result** `Response code:401`, `Response message:Unauthorized`; `T03` hijau, `T04` merah.*

4. Klik `T02` (merah) → tab **Request**: bandingkan nilai `Authorization: Bearer …` dengan **token** dalam **Response data** `T01`. Sama ke tak?

   ![Tab Request T02: Authorization Bearer token lama](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-06-request-t02-bearer-lama.png)
   *Tab **Request → Request Headers** `T02`: token yang **dihantar** (token rakaman). (tangkapan ini guna instance mock kami sendiri pada port 3917 dan proxy 18888 supaya tak ganggu kelas — anda guna 3000 / 8888)*

   ![Response data T01: token baru dari server](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-07-response-t01-token-baru.png)
   *Tab **Response data** `T01`: `token` **baru** yang server keluarkan — tak sama dengan token dalam tab Request `T02`.*

5. **Eksperimen 403 (token sahaja):** **Klik kanan sampler log masuk → Add → Post Processors → JSON Extractor**: Names `token`, JSON Path `$.token`, Match No. `1`, Default `TOKEN_TAK_JUMPA`. Dalam Header Manager `T02` **dan** `T04`, tukar nilai `Authorization` jadi `Bearer ${token}`. **Jangan** usik `csrf`. Start ▶.

   ![JSON Extractor token $.token TOKEN_TAK_JUMPA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-08-json-extractor-token.png)
   ***JSON Extractor** child kepada sampler log masuk: Names `token`, JSON Path `$.token`, Match No. `1`, Default `TOKEN_TAK_JUMPA`.*

   ![Header Manager T04: Authorization Bearer ${token}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-09-header-bearer-token-var.png)
   *Header Manager `T04` (dan `T02`): `Authorization` = `Bearer ${token}`. `csrf` dalam body tak diusik.*

6. Catat: `T02` = ?, `T04` = ? dan mesej error `T04`.

   ![View Results Tree: T02 hijau, T04 403 Forbidden](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-10-vrt-t04-403.png)
   *Dengan token sahaja dikorelasi: `T02` hijau (200), `T04` merah — `Response code:403`.*

   ![Response data T04: Token CSRF tidak sah](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-11-t04-403-csrf-tidak-sah.png)
   *Response data `T04`: `{"ralat":"Token CSRF tidak sah — sila log masuk semula"}` — punca kini `csrf`, bukan token.*

7. Bandingkan dengan backup run non-GUI (Terminal B, root repo):
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l hasil/r04.jtl
   # summary = 3 ... Err: 2 (66.67%)
   ```

   ![jmeter -n 04-rakaman-mentah: summary 3 Err 2 66.67%](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-12-nogui-r04-summary.png)
   *Run non-GUI sebenar backup `04`: `summary = 3 … Err: 2 (66.67%)`. (tangkapan ini guna instance mock kami sendiri pada port 3917 dan proxy 18888 supaya tak ganggu kelas — anda guna 3000 / 8888)*

8. Save plan (**File → Save**) — plan ni jadi titik mula untuk Latihan 3.

   ![Menu File JMeter: Save dan Save Test Plan as](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-13-menu-file.png)
   *Menu **File**: **Save** (⌘S / Ctrl+S) simpan ke file sama; **Save Test Plan as** untuk nama baru.*

![View Results Tree: log-masuk hijau, kenderaan dan bayar-cukai merah](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-01-vrt-401-merah.png)
*Replay lepas SUT restart: **View Results Tree** — `/api/log-masuk` hijau (200), `/api/kenderaan` dan `/api/kenderaan/WXY1234/bayar-cukai` merah (**401**). Klik sampler merah → tab **Sampler result** / **Request** / **Response data** untuk siasat.*

![HTML dashboard replay: Statistics dan Errors 401/Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-02-dashboard-statistics-errors-401.png)
*Replay yang sama dalam non-GUI (`-e -o`): **Statistics** tunjuk Error % 66.67% (2 daripada 3), **Errors** = `401/Unauthorized` × 2 — sama dengan `summary = 3 ... Err: 2 (66.67%)`.*

### ✅ Checkpoint
- [ ] Main balik tanpa restart menunjukkan 4 × 200 dan anda boleh menerangkan kenapa ia "lulus palsu"
- [ ] Selepas restart SUT: log masuk **200**, senarai **401**, semak cukai **200**, bayar **401** — dicatat dalam jadual
- [ ] Tab **Request** digunakan untuk membuktikan token yang dihantar ≠ token yang baru dikeluarkan
- [ ] Dengan `token` sahaja dikorelasi, bayar menjadi **403** `Token CSRF tidak sah — sila log masuk semula`
- [ ] Lulus **Kuiz S1** (sekurang-kurangnya separuh betul) (Kuiz S1)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| Semua 200 walaupun dah "restart" | SUT sebenarnya tak restart (process lama masih run) | Pastikan Ctrl+C betul-betul stop process; Terminal A tunjuk mesej start semula |
| Semua sampler `Non HTTP response code: java.net.ConnectException` | SUT tak run | Terminal A: `node sut/server.js` |
| `T03_SemakCukai` hijau — "bukan ke semua patut fail?" | Endpoint sebut harga tak perlukan token | Betul — sebab tu kita perlu assertion & check setiap langkah, bukan setakat "ada yang hijau" |
| Eksperimen 403 masih dapat 401 | Header `Authorization` dalam `T04` belum tukar, atau tak ada space lepas `Bearer` | Nilai mesti `Bearer ${token}` dalam **setiap** Header Manager yang berkaitan |
| `Bearer TOKEN_TAK_JUMPA` dalam tab Request | JSON Extractor bukan child kepada sampler log masuk | Drag extractor ke bawah sampler log masuk |

---

## Latihan 3 — Jadikan rakaman boleh dimain balik

**Sesi:** S2

### 🎯 Objektif
- Buat correlation untuk `token` + `csrf` dan data kenderaan, dan parameterize users guna CSV (O3)
- Rename sampler, balut dengan Transaction Controller, tambah think time rawak dan assertion (O4)
- Run 10 users × 2 loop dan baca Summary & Aggregate Report (O4)

### Prasyarat
- Latihan 2 dah siap (plan dengan `token` dah di-correlate). Kalau guna backup `04-rakaman-mentah` (3 sampler, tiada sebut harga): langkah 4 abaikan path sebut harga, dan run 10 × 2 bagi **60** sample HTTP, bukan 80
- README §2.1–2.9; buka `test-plans/05-transaksi-penuh.jmx` dalam tab lain sebagai skema jawapan

### Langkah
1. **File → Save As** → `hari-2/test-plans/latihan-03-boleh-main-balik.jmx`.

   ![Menu File JMeter: Save Test Plan as](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-13-menu-file.png)
   *Menu **File → Save Test Plan as** → `latihan-03-boleh-main-balik.jmx`.*

2. **Correlation `csrf`:** buka JSON Extractor log masuk → Names `token;csrf`, JSON Path `$.token;$.csrf`, Match No. `1;1`, Default `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`. Dalam body bayar, tukar nilai `csrf` jadi `${csrf}`.

   ![JSON Extractor token;csrf](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-01-json-extractor-token-csrf.png)
   *JSON Extractor log masuk: Names `token;csrf`, JSON Path `$.token;$.csrf`, Match No. `1;1`, Default `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`.*

   ![Body bayar: csrf ${csrf}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-02-body-bayar-csrf-var.png)
   *Body sampler bayar: `"csrf":"${csrf}"`.*

3. **Parameterization:** **Klik kanan Thread Group → Add → Config Element → CSV Data Set Config**: Filename `../data/pengguna.csv`, Variable Names `no_kp,kata_laluan`, Ignore first line `True`, Recycle on EOF `True`, Sharing mode `All threads`. Body log masuk → `{ "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }`; parameter `no_kp` sampler senarai → `${no_kp}`.

   ![CSV Data Set Config pengguna.csv no_kp,kata_laluan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-03-csv-data-set-config.png)
   ***CSV Data Set Config** bawah Thread Group: `../data/pengguna.csv`, `no_kp,kata_laluan`, Ignore first line `True`, Recycle on EOF `True`, Sharing mode `All threads`.*

   ![Body log masuk guna ${no_kp} dan ${kata_laluan}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-04-body-log-masuk-csv.png)
   *Body log masuk: `{ "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }`.*

   ![Sampler senarai: parameter no_kp ${no_kp}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-05-parameter-no-kp.png)
   *Sampler senarai, tab **Parameters**: `no_kp` = `${no_kp}`.*

4. **Correlation berantai:** **Klik kanan sampler senarai → Add → Post Processors → JSON Extractor** (`Ekstrak kenderaan pertama`): Names `no_pendaftaran;amaun`, Paths `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai`, Match No. `1;1`, Default `NONE;0`. Tukar path sebut harga → `/api/kenderaan/${no_pendaftaran}/cukai`, path bayar → `/api/kenderaan/${no_pendaftaran}/bayar-cukai`, body bayar → `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": ${amaun} }`.

   ![JSON Extractor Ekstrak kenderaan pertama](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-06-ekstrak-kenderaan-pertama.png)
   *`Ekstrak kenderaan pertama` bawah sampler senarai: `no_pendaftaran;amaun`, `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai`, `1;1`, `NONE;0`.*

   ![Sampler bayar: path ${no_pendaftaran} dan body ${amaun}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-07-bayar-path-body-berantai.png)
   *Sampler bayar: Path `/api/kenderaan/${no_pendaftaran}/bayar-cukai`, body `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": ${amaun} }`.*

5. **Nama:** rename sampler jadi `1. POST /api/log-masuk`, `2. GET /api/kenderaan`, `3. GET /api/kenderaan/${no_pendaftaran}/cukai`, `4. POST /api/kenderaan/${no_pendaftaran}/bayar-cukai`.

   ![Sampler dinamakan semula 1. hingga 4.](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-08-nama-sampler-1-4.png)
   *Lepas rename: `1. POST /api/log-masuk`, `2. GET /api/kenderaan`, `3. GET …/${no_pendaftaran}/cukai`, `4. POST …/${no_pendaftaran}/bayar-cukai`.*

6. **Transaction Controller:** **Klik kanan Thread Group → Add → Logic Controller → Transaction Controller** `Pembaharuan Cukai Jalan`. Drag Recording Controller (atau keempat-empat sampler) **masuk ke dalamnya**. Biarkan *Generate parent sample* dan *Include duration of timer…* **tak di-tick**.

   ![Transaction Controller Pembaharuan Cukai Jalan dengan Recording Controller di dalamnya](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-09-transaction-controller-pembaharuan.png)
   *Transaction Controller `Pembaharuan Cukai Jalan` — Recording Controller dah di-drag masuk; dua checkbox tak di-tick.*

7. **Think time:** padam Constant Timer dari recording (satu di bawah sampler pertama setiap kumpulan, nilai macam `6012`). **Klik kanan Transaction Controller `Pembaharuan Cukai Jalan` → Add → Timer → Uniform Random Timer** (`Think Time (1-3s)`): Random Delay Maximum `2000`, Constant Delay Offset `1000`. Timer ni jadi child TC tu, sebaris dengan sampler (sama macam `05`) — bukan bawah `T01…T04` dan bukan child sampler. Scope = semua 4 sampler dalam TC → 4 pause setiap iteration (bawah Thread Group pun kesan sama, sebab semua sampler ada dalam TC).

   ![Uniform Random Timer Think Time child Transaction Controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-10-uniform-random-timer-tc.png)
   *`Think Time (1-3s)` (Uniform Random Timer, `2000` / `1000`) — child terus kepada `Pembaharuan Cukai Jalan`, sebaris dengan Recording Controller; Constant Timer rakaman dah dipadam.*

8. **Assertion:** **Klik kanan sampler bayar → Add → Assertions → Response Assertion**: Text Response, Substring, pattern `BERJAYA`.

   ![Response Assertion Substring BERJAYA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-11-response-assertion-berjaya.png)
   ***Response Assertion** bawah sampler bayar: Text Response, Substring, `BERJAYA`.*

9. **(Digalakkan) If Controller:** **Klik kanan Transaction Controller `Pembaharuan Cukai Jalan` → Add → Logic Controller → If Controller** `Jika ada kenderaan`, Condition `${__groovy(vars.get("no_pendaftaran") != "NONE" && vars.get("token") != "TOKEN_TAK_JUMPA")}`; drag sampler 3 & 4 masuk ke dalamnya.

   ![If Controller Jika ada kenderaan dengan __groovy](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-12-if-controller-jika-ada-kenderaan.png)
   *If Controller `Jika ada kenderaan` (Interpret Condition as Variable Expression ditick) — langkah 3 & 4 (`T03_SemakCukai`, `T04_BayarCukai`) di-drag masuk.*

10. **Functional test dulu:** Thread Group 1 user, 1 loop, View Results Tree enabled. Start → semua hijau, Request bayar ada token/csrf yang betul.

    ![View Results Tree functional test semua hijau, Request body bayar](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-13-vrt-bayar-csrf-sebenar.png)
    *Functional test 1 user × 1 loop: semua hijau; Request bayar hantar `csrf` sebenar + `amaun` dari extractor. (tangkapan ini guna instance mock kami sendiri pada port 3917 dan proxy 18888 supaya tak ganggu kelas — anda guna 3000 / 8888)*

11. **Run kecil:** Thread Group `10` users, Ramp-up `10`, Loop Count `2`. **Disable** View Results Tree. **Add → Listener → Summary Report** dan **Aggregate Report**. Start.

    ![Thread Group 10 users ramp-up 10 loop 2](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-14-thread-group-10-10-2.png)
    *Thread Group: `10` users, Ramp-up `10`, Loop Count `2`.*

    ![Summary Report run kecil](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-15-summary-report.png)
    *Summary Report lepas run kecil (View Results Tree disabled — kelabu dalam tree).*

12. Catat dari Aggregate Report: # Samples untuk baris `Pembaharuan Cukai Jalan` dan jumlah sample 4 langkah; Average, 95% Line baris transaksi; Error %.

    ![Aggregate Report: baris Pembaharuan Cukai Jalan 20 samples](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-16-aggregate-report.png)
    *Aggregate Report: `Pembaharuan Cukai Jalan` = 20 sample (10 users × 2 loop), Average/95% Line transaksi, Error % 0. Label sampler 3 & 4 pecah ikut kenderaan sebab nama ada `${no_pendaftaran}`.*

> Bandingkan dengan [`test-plans/05-transaksi-penuh.jmx`](../test-plans/05-transaksi-penuh.jmx) (dah disahkan: 80 sample HTTP + 20 baris transaksi, 0% error; transaksi ≈ 440 ms).

![JSON Extractor Ekstrak token + csrf dalam plan 05](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-27-gui-json-extractor-05.png)
*JSON Extractor tangkap token dan csrf daripada response log masuk (langkah 2). Tengok panel kanan — baris tree yang ikut berwarna tu cuma kesan screenshot.*

![Transaction Controller Pembaharuan Cukai Jalan dalam plan 05](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-28-gui-transaction-controller-05.png)
*Transaction Controller kumpulkan langkah pembaharuan jadi satu transaksi yang boleh diukur (langkah 6) — dua-dua option tak di-tick.*

![Jadual Statistics plan 05 dengan baris transaksi Pembaharuan Cukai Jalan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-24-transaction-statistics-05.png)
*Transaction Controller tambah satu baris peringkat business: masa keseluruhan pembaharuan (≈ 449 ms = jumlah 4 langkah; think time tak dikira).*

### ✅ Checkpoint
- [ ] `token`, `csrf`, `no_pendaftaran` dan `amaun` diekstrak pada masa larian — tiada nilai rakaman tinggal dalam header/badan/path
- [ ] CSV `pengguna.csv` memberikan 3 `no_kp` berbeza (lihat Request atau label kenderaan berbeza: `WXY1234`, `JQK7788`, `BMT3030`)
- [ ] Sampler dinamakan semula, dibungkus Transaction Controller `Pembaharuan Cukai Jalan`, dengan Uniform Random Timer dan Response Assertion `BERJAYA`
- [ ] Larian 10 × 2: **80** sampel HTTP + **20** baris transaksi dalam Aggregate Report, Error % ≈ 0 (≤ 1 ralat 500 sintetik diterima)
- [ ] Lulus **Kuiz S2** (sekurang-kurangnya separuh betul) (Kuiz S2)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| `${no_kp}` dihantar bulat-bulat (literal) | CSV tak jumpa — plan tak di-save dalam `hari-2/test-plans/` | Save As ke folder tu; atau guna full path |
| Log masuk **401** `No. KP atau kata laluan tidak sah` | Body kosong / tak ada `Content-Type: application/json` | Check Header Manager sampler log masuk (dari recording) atau tambah di level Thread Group |
| Bayar **403** | `csrf` belum di-correlate / salah eja `${csrf}` | Bilangan Names & Paths extractor mesti sama, diasingkan dengan `;` |
| Path `/api/kenderaan/NONE/cukai` → 404 | Extractor kenderaan bukan child kepada sampler senarai | Drag extractor ke bawah `2. GET /api/kenderaan` |
| Bayar 400/500 dengan `"amaun": ${amaun}` literal | `amaun` tak di-extract | Dua nama, dua path: `no_pendaftaran;amaun` |
| Tak ada baris transaksi | Sampler duduk di **bawah**, bukan **di dalam**, Transaction Controller | Drag sampler ke atas nama controller |
| Run sangat lambat | Constant Timer `${T}` dari recording (6 s+) masih ada | Padam timer recording; guna Uniform Random Timer |
| Kadang-kadang ada 1 error 500 | `ERROR_RATE` 1% dalam SUT — memang sengaja | Normal; untuk run yang bersih: `ERROR_RATE=0 node sut/server.js` |

### ⭐ Cabaran
1. Ganti JSON Extractor `token` dengan **Regular Expression Extractor** (`"token":"([^"]+)"`, Template `$1$`) atau **Boundary Extractor** (Left `"token":"`, Right `"`). Hasil mesti sama.
2. Ambil `amaun` + `tempoh_bulan` dari response **sebut harga** (`$.amaun;$.tempoh_bulan`) macam plan `07`.
3. Buka [`08-foreach-kenderaan.jmx`](../test-plans/08-foreach-kenderaan.jmx): Match No. `-1` + ForEach Controller → 3 users bayar **5** kenderaan (16 sample HTTP). Untick *Add "_" before number ?* dan perhatikan 0 iterasi tanpa error.
4. Tambah **JSR223 PostProcessor** (Groovy, *Cache compiled script if available*) dari blok "2)" dalam [`jsr223-groovy.groovy`](./jsr223-groovy.groovy) di bawah log masuk.

---

## Latihan 4 — Jana HTML dashboard & baca setiap bahagian

**Sesi:** S3

### 🎯 Objektif
- Generate HTML dashboard masa run (`-e -o`) dan kemudian daripada `.jtl` (`-g -o`) (O5)
- Adjust granularity graf dengan `-Jjmeter.reportgenerator.overall_granularity` (O5)
- Catat nilai sebenar dan tafsir setiap bahagian dashboard guna istilah yang betul (O6)

### Prasyarat
- SUT tengah run; **stop** run dalam GUI (GUI boleh biar terbuka asalkan tak ada run)
- `jmeter --version` tunjuk 5.6.x
- README §3.1–3.5

### Langkah
1. Terminal B, dari root repo — run plan recording yang dah bersih (atau rujukan `05`) secara non-GUI:
   ```bash
   mkdir -p hasil                    # Windows: mkdir hasil — folder induk -o mesti wujud
   jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx \
     -l hasil/r05.jtl -e -o hasil/laporan05
   ```
   (Plan Latihan 3: ganti `05-transaksi-penuh.jmx` dengan `latihan-03-boleh-main-balik.jmx` — pastikan View Results Tree **disabled**.)

   ![jmeter -n plan 05 dengan -e -o: summary 80 sample 0 error](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-01-nogui-r05-summary.png)
   *Run non-GUI sebenar plan `05` dengan `-e -o`: `summary = 80 … Err: 0 (0.00%)`. (tangkapan ini run terhadap instance mock kami sendiri pada port 3917 supaya tak ganggu kelas — anda guna 3000)*

2. Tengok baris `summary =` dalam terminal (jumlah sample, `Err:`). Buka `hasil/laporan05/index.html`.

   ![hasil/laporan05/index.html: Test and Report information, APDEX, Requests Summary](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-02-laporan05-index.png)
   *`hasil/laporan05/index.html`: Source file `r05.jtl`, Start/End Time, APDEX setiap label dan Requests Summary (PASS 100%).*

3. Generate dashboard **kedua** daripada `.jtl` yang sama, dengan graf setiap 5 s:
   ```bash
   jmeter -g hasil/r05.jtl -o hasil/laporan05-5s \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```
   Bandingkan *Charts → Over Time → Response Times Over Time* dalam kedua-dua report.

   ![jmeter -g ke laporan05-5s berjaya](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-03-jmeter-g-5s.png)
   *`jmeter -g` daripada `.jtl` yang sama → folder `hasil/laporan05-5s` baru (tiada output bila berjaya).*

   ![Response Times Over Time laporan05 granularity asal](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-04-rt-over-time-1s.png)
   *`laporan05` — Response Times Over Time dengan granularity asal.*

   ![Response Times Over Time laporan05-5s granularity 5 sec](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-05-rt-over-time-5s.png)
   *`laporan05-5s` — paksi-x `granularity: 5 sec`: titik lebih jarang, garisan lebih licin.*

4. Cuba generate sekali lagi ke `hasil/laporan05-5s` — catat mesej error yang keluar.

   ![jmeter -g kali kedua: Cannot write ... folder is not empty](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-06-folder-not-empty.png)
   *Generate kali kedua ke folder sama: `An error occurred: Cannot write to '…/hasil/laporan05-5s' as folder is not empty`.*

5. Isi **worksheet** dengan nilai **sebenar** dari dashboard anda:

   | # | Bahagian | Apa yang anda catat | Nilai anda | Tafsiran (1 ayat) |
   |---|----------|---------------------|------------|-------------------|
   | 1 | Test and Report information | Source file, Start/End Time | | Run lengkap? |
   | 2 | APDEX | Total; baris transaksi; T & F | | Kenapa transaksi < 1.0? |
   | 3 | Requests Summary | PASS % / FAIL % | | |
   | 4 | Statistics — Total | #Samples, Error %, Average, 95th pct, Transactions/s | | Total termasuk transaksi? |
   | 5 | Statistics — baris transaksi | #Samples, Average, Median, 90th/95th/99th pct, Max | | Jurang Median → 99th? |
   | 6 | Statistics — langkah paling lambat | Label + 95th pct | | |
   | 7 | Errors / Top 5 Errors by sampler | Jenis error, bilangan | | |
   | 8 | Over Time → Active Threads Over Time | Bentuk ramp-up | | Load model betul-betul berlaku? |
   | 9 | Over Time → Response Time Percentiles Over Time | p95 awal vs akhir | | Stabil? |
   | 10 | Throughput → Hits Per Second vs Transactions Per Second (siri `Pembaharuan Cukai Jalan-success`) | Nisbah | | Kenapa ≈ 4 : 1? (Hits vs **Total** Transactions Per Second pula ≈ 4 : 5 — Total kira baris transaksi juga) |
   | 11 | Throughput → Codes Per Second | Kod yang keluar | | |
   | 12 | Response Times → Response Time Overview | Bilangan setiap bar | | |
   | 13 | Response Times → Response Time Distribution | Julat paling banyak | | |
   | 14 | Latency vs Response time (`.jtl` atau Latencies Over Time) | Satu sample log masuk | | Masa di server atau masa transfer? |

   ![Statistics laporan05: Total dan baris Pembaharuan Cukai Jalan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-07-statistics-laporan05.png)
   *Jadual Statistics `laporan05` sebenar — sumber nilai worksheet #4–#6 (Total, baris transaksi `Pembaharuan Cukai Jalan`, langkah paling lambat).*

6. Buka `hasil/laporan05/statistics.json` dalam editor; cari `pct2ResTime` untuk `Pembaharuan Cukai Jalan` dan pastikan nilainya sama dengan **95th pct** dalam jadual.

   ![statistics.json Pembaharuan Cukai Jalan pct2ResTime](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-08-statistics-json-pct2.png)
   *Entri `Pembaharuan Cukai Jalan` dalam `statistics.json` (dibuka dengan `jq`; editor pun sama): `pct2ResTime` = 95th pct dalam jadual.*

**Rujukan visual worksheet** (contoh sebenar daripada run peak `07`, 50 users — angka anda untuk `05` akan lain; tapi rupa skrinnya sama):

![Dashboard: Test and Report information, APDEX dan Requests Summary](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-10-dashboard-info-apdex.png)
*#1–#3 — Skrin pertama HTML dashboard: info run, APDEX setiap label dan pecahan pass/fail.*

![Jadual Statistics larian puncak](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-12-statistics-table.png)
*#4–#6 — Jadual Statistics: baca p90/p95/p99 dan Error % dulu, lepas tu baru throughput.*

![Active Threads Over Time: ramp-up 0 ke 50 dalam 10 s](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-16-active-threads-over-time.png)
*#8 — Active Threads Over Time: pastikan load model (ramp-up, hold) memang berlaku.*

![Response Times Over Time setiap label](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-15-response-times-over-time.png)
*#9 — Response Times Over Time: garisan transaksi duduk di atas request individu. (Percentiles Over Time dibaca dengan cara yang sama — stabil atau naik?)*

![Transactions Per Second setiap label](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-17-transactions-per-second.png)
*#10–#11 — Transactions Per Second untuk setiap label (siri success / failure).*

![Lengkung Response Time Percentiles](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-18-response-time-percentiles.png)
*#12 — Graf percentile: baca p90/p95 pada paksi-x. Hujung (tail) transaksi naik dekat p99.*

![Response Time Distribution](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-19-response-time-distribution.png)
*#13 — Response Time Distribution: bilangan sample dalam setiap julat masa.*

![Latencies Over Time](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-20-latencies-over-time.png)
*#14 — Latencies Over Time: masa sampai byte pertama, berbanding response time penuh.*

### ✅ Checkpoint
- [ ] `hasil/laporan05/index.html` dijana dengan `-e -o` dan dibuka
- [ ] Dashboard kedua dijana dengan `-g … -o` dan `overall_granularity=5000`; anda boleh menerangkan beza bilangan titik graf
- [ ] Lembaran kerja 14 baris diisi dengan nilai sebenar dan satu ayat tafsiran setiap satu
- [ ] Anda boleh menerangkan kenapa **Total** Statistics ≠ jumlah termasuk baris transaksi, dan kenapa sampel gagal dikira Frustrated dalam APDEX
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| `Cannot write to '…' as folder is not empty` | Folder `-o` dah wujud | Guna folder baru, atau padam yang lama |
| `… as folder does not exist and parent folder is not writable` | Folder induk (`hasil/`) belum wujud — JMeter check dulu sebelum test start | `mkdir -p hasil` (Windows: `mkdir hasil`), lepas tu ulang |
| `jmeter: command not found` | JMeter tak ada dalam PATH | Hari 1 — Persediaan; atau guna full path `…/bin/jmeter` |
| Graf Over Time cuma ada 1–2 titik | Granularity default 60 s | Generate semula dengan `-Jjmeter.reportgenerator.overall_granularity=5000` |
| Dashboard kosong / tak ada baris | `.jtl` kosong — SUT mati atau plan fail awal-awal | Check `summary =` dan `jmeter.log` |
| Plan anda: semua sample `Non HTTP response code` | Sampler dari recording tak ada Server/Port (bergantung pada HTTP Request Defaults) tapi Defaults tu dah dipadam/disable | Pastikan HTTP Request Defaults `localhost`/`3000` enabled dalam plan |

---

## Latihan 5 — Senario puncak `07` + SLA → tiga dapatan

**Sesi:** S3

### 🎯 Objektif
- Run senario peak `07` dengan dua threshold SLA dan bandingkan report (O7)
- Jejak SLA breach dalam Statistics, Errors, Top 5 Errors dan Transactions Per Second (O7)
- Tulis tiga dapatan (bukti → kesan → punca → cadangan) dalam template report (O7)

### Prasyarat
- Latihan 4 dah siap; SUT biasa tengah run (`node sut/server.js`)
- [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) dibuka — baca contoh bahagian B
- README §3.6–3.8

### Langkah
1. Buka `07-beban-puncak-cukai.jmx` dalam GUI **sekali** untuk tengok: Thread Group `${__P(pengguna,300)}`, Transaction Controller `Pembaharuan Cukai Jalan (Puncak)`, Duration Assertion `${__P(sla_ms,2000)}`, Think Time Rush 0.5–1.5 s. Jangan Start dalam GUI.

   ![Plan 07 Thread Group Lonjakan Pembaharuan Cukai dengan __P(pengguna,300)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-01-plan07-thread-group.png)
   *Plan `07` — Thread Group `Lonjakan Pembaharuan Cukai`: Number of Threads `${__P(pengguna,300)}`, ramp-up/tempoh juga dari `-J`.*

   ![Duration Assertion SLA Bayaran __P(sla_ms,2000)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-02-plan07-duration-assertion.png)
   *Duration Assertion `SLA Bayaran < ${__P(sla_ms,2000)}ms` bawah sampler bayar; `Think Time Rush (0.5-1.5s)` di hujung TC.*

2. **R1 — SLA 2000 ms** (≈ 1 minit):
   ```bash
   jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
     -l hasil/r07-sla2000.jtl -e -o hasil/laporan07-sla2000 \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```

   ![R1 SLA 2000 ms: summary 2446 sample](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-03-r1-sla2000-summary.png)
   *R1 sebenar: `summary = 2446 in 00:01:00 … Err: 3 (0.12%)` — error cuma 500 sintetik. (tangkapan ini run terhadap instance mock kami sendiri pada port 3917 supaya tak ganggu kelas — anda guna 3000)*

3. **R2 — SLA 150 ms**, sistem yang sama:
   ```bash
   jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=150 \
     -l hasil/r07-sla150.jtl -e -o hasil/laporan07-sla150 \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```

   ![R2 SLA 150 ms: summary dengan Err lebih tinggi](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-04-r2-sla150-summary.png)
   *R2 sebenar, sistem yang sama: `Err: 163 (6.83%)` — SLA ketat tukar response lambat jadi error. (tangkapan ini run terhadap instance mock kami sendiri pada port 3917 supaya tak ganggu kelas — anda guna 3000)*

4. Isi jadual perbandingan:

   | Metrik (baris `Pembaharuan Cukai Jalan (Puncak)`) | R1 (2000 ms) | R2 (150 ms) |
   |---------------------------------------------------|-------------:|------------:|
   | #Samples | | |
   | Error % | | |
   | 95th pct (ms) | | |
   | Transactions/s | | |
   | APDEX (baris transaksi) | | |
   | Error % `Total` | | |

   (Rujukan run kami: R1 → 598 sample, 1.00%, 583 ms, 10.46/s, APDEX 0.862; R2 → 607 sample, **21.75%**, 572 ms, 10.54/s, APDEX 0.717.)

   ![Statistics R1 SLA 2000 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-05-r1-statistics.png)
   *Statistics R1 (2000 ms): baris `Pembaharuan Cukai Jalan (Puncak)` — #Samples, Error %, 95th pct, Transactions/s untuk jadual perbandingan.*

   ![Statistics R2 SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-06-r2-statistics.png)
   *Statistics R2 (150 ms): Error % naik pada sampler bayar dan baris transaksi.*

5. Dalam R2, buka **Errors**: berapa baris `The operation lasted too long…`? Kenapa banyak? Buka **Top 5 Errors by sampler** dan **Charts → Throughput → Codes Per Second** — ada kod `200` sahaja ke? Kenapa?

   ![Errors R2: banyak baris The operation lasted too long](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-07-r2-errors-operation-lasted-too-long.png)
   *Errors R2 (atas sahaja): satu baris untuk setiap nilai ms `The operation lasted too long: It took … milliseconds` — sebab tu banyak baris; `500/Internal Server Error` terselit di antaranya.*

   ![Codes Per Second R2](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-08-r2-codes-per-second.png)
   *Codes Per Second R2: hampir semuanya `200` — SLA breach ialah kegagalan **assertion**, bukan kod HTTP.*

6. **Little's Law cepat:** guna Transactions/s R1, R ≈ Average transaksi (s), Z ≈ 4 s → kira X × (R + Z). Bandingkan dengan Active Threads Over Time.

   ![Active Threads Over Time R1: ramp 0 ke 50](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-09-r1-active-threads.png)
   *Active Threads Over Time R1: naik ke 50 dalam ~10 s — bandingkan dengan N = X × (R + Z).*

7. Salin bahagian **A** `templat-laporan-ujian.md` ke `hasil/laporan-pasangan-<nama>.md` dan tulis **tiga dapatan** guna angka **anda sendiri** (cadangan: D1 response time vs NFR, D2 error 500 & Error %, D3 kesan threshold SLA).

   ![Salin templat-laporan-ujian.md ke hasil](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-10-salin-templat-laporan.png)
   *Salin template laporan ke `hasil/laporan-pasangan-<nama>.md`; bahagian **A1–A8** ialah template kosong.*

   ![Templat laporan bahagian A5 Dapatan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-11-templat-a5-dapatan.png)
   *Bahagian **A5. Dapatan**: tulis D1–D3 dengan angka run anda sendiri.*

**Rujukan visual R2 (SLA 150 ms)** — run sebenar kami:

![Statistics larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-26-statistics-sla-breach.png)
*SLA yang lebih ketat (150 ms) tukar response lambat jadi Error %, tanpa ubah apa-apa kod.*

![APDEX larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-14-apdex-sla-breach.png)
*Skor APDEX jatuh untuk label yang fail SLA.*

![Jadual Errors larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-13-errors-table.png)
*Jadual Errors: SLA breach oleh Duration Assertion dikira sebagai error. Satu baris untuk setiap mesej, jadi error yang sama boleh terpecah (langkah 5).*

![Top 5 Errors by sampler larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-25-top5-errors-by-sampler.png)
*Top 5 Errors by sampler: tunjuk request mana yang breach SLA — hanya 3 POST `bayar-cukai`.*

### ✅ Checkpoint
- [ ] Dua laporan `07` dijana (`laporan07-sla2000`, `laporan07-sla150`) dengan butiran 5 s
- [ ] Jadual perbandingan R1 vs R2 diisi dan anda boleh menerangkan kenapa Error % naik walaupun masa respons sama
- [ ] Anda menunjuk tiga tempat pelanggaran SLA kelihatan (Statistics/Error %, Errors/Top 5, siri `-failure` Transactions Per Second) dan kenapa *Codes Per Second* tidak menunjukkannya
- [ ] Tiga dapatan ditulis dengan bukti (angka + bahagian dashboard), kesan, punca dan cadangan
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| Error % R2 sama dengan R1 | `-Jsla_ms` ditulis dengan space (`-J sla_ms=150`) atau guna `-D` | Tulis `-Jsla_ms=150` tanpa space |
| Laptop jadi sangat lambat / kipas bising | JMeter + SUT dalam mesin yang sama | Kurangkan ke `-Jpengguna=25`; catat sebagai limitation dalam report |
| `folder is not empty` | Nama folder `-o` diguna semula | Guna nama baru untuk setiap run |
| Error % R1 > 1% | Error 500 sintetik 1% dari SUT | Normal kalau dekat-dekat 1% — itulah dapatan D2 anda |
| Dapatan cuma tulis "sistem OK" | Tak ada angka/bukti | Setiap dapatan: angka + nama bahagian dashboard |

### ⭐ Cabaran
1. **R3 — mock lambat tanpa kacau SUT utama:** Terminal C: `PORT=3001 LATENCY_MIN=500 LATENCY_MAX=1500 node sut/server.js`, lepas tu run R1 dengan `-Jport=3001` ke folder baru. Bandingkan Transactions/s dan p95 dengan R1, dan sahkan Little's Law (run kami: 5.78/s, p95 4969 ms). Stop Terminal C bila dah siap.
2. Generate semula R1 dengan `-Jjmeter.reportgenerator.apdex_satisfied_threshold=300 -Jjmeter.reportgenerator.apdex_tolerated_threshold=1000`. Macam mana APDEX berubah, dan siapa patut tentukan T/F?
3. Stress berperingkat: run R1 dengan `-Jpengguna=100` dan `150`. Throughput masih naik ke? Apa yang hadkan — SUT atau CPU laptop?

---

## Latihan 6 — Rancang ujian prestasi + Little's Law

**Sesi:** S4

### 🎯 Objektif
- Isi test plan prestasi: NFR, load model, jenis run, kriteria, monitoring, risiko, kebenaran (O8)
- Kira bilangan concurrent users guna Little's Law dan setting pacing (O8)

### Prasyarat
- [`templat-pelan-ujian.md`](./templat-pelan-ujian.md) — baca contoh eJPJ yang dah diisi
- README §4.1–4.7

### Langkah
1. Salin template ke `hasil/pelan-pasangan-<nama>.md`.

   ![Salin templat-pelan-ujian.md ke hasil](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-03-salin-templat-pelan.png)
   *Salin template ke `hasil/pelan-pasangan-<nama>.md` (contoh: `aminah`).*

2. Pilih satu senario: **(a)** pembaharuan cukai jalan pada hari harga naik (macam contoh, tukar angka), **(b)** bayar saman pada hari terakhir diskaun saman, **(c)** sistem dalaman organisasi anda (konsep sahaja — tak ada run).

   ![Templat pelan bahagian 1 Latar belakang dan objektif](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-04-pelan-latar-objektif.png)
   *Bahagian **1. Latar belakang & objektif** dalam template — tukar senario & Q1–Q4 ikut pilihan (a), (b) atau (c).*

3. Isi bahagian 1–3: objektif (Q1–Q4), skop, dan **sekurang-kurangnya 4 NFR** yang boleh diukur.

   ![Templat pelan bahagian 3 NFR/SLA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-05-pelan-nfr.png)
   *Bahagian **3. NFR / SLA**: setiap NFR ada transaksi, beban, metrik percentile, ambang dan tempoh.*

4. **Lampiran A — Little's Law:** tetapkan volum peak hour V, kira X = V ÷ 3600, anggar R dan Z, kira **N = X × (R + Z)**, kadar hits/s, dan setting **Constant Throughput Timer** (X × 60 sample/minit, letak sebagai child kepada sampler pertama).

   ![Templat pelan Lampiran A lembaran kerja Little's Law](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-06-pelan-lampiran-a.png)
   ***Lampiran A** — lembaran kerja Little's Law: V → X → N, hits/s dan Constant Throughput Timer.*

5. **Cross-check dengan data lab:** guna R1 Latihan 5 — 50 users × (R + 4 s) bagi Transactions/s macam yang dijangka ke?

   ![Statistics R1 untuk cross-check Little's Law](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-05-r1-statistics.png)
   *Data R1 Latihan 5: ambil Transactions/s dan Average baris transaksi untuk cross-check 50 users × (R + 4 s).*

6. Isi bahagian 5 (transaction mix), 8 (jadual baseline → load → stress → spike → soak dengan config `-J`), 9 (kriteria entry/exit/suspend), 10 (monitoring), 11 (sekurang-kurangnya 3 risiko) dan 12 (kebenaran & prosedur stop).

   ![Templat pelan bahagian 8 Jenis ujian dan jadual larian](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-07-pelan-jenis-ujian.png)
   *Bahagian **8. Jenis ujian & jadual larian**: baseline → load → stress → spike → soak dengan config `-J`.*

![Templat pelan ujian: workload model dan Little's Law](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-01-pelan-model-beban-littles-law.png)
*Contoh diisi `templat-pelan-ujian.md` §4.1–4.2: V = 36,000/jam → X = 10 transaksi/s → **N = 10 × (2 + 58) = 600** concurrent users. Isi lajur ✍️ Anda dengan angka senario anda.*

![Templat pelan ujian: pacing dan Lampiran A](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-02-pelan-pacing-lampiran-a.png)
*§4.3 pacing (Constant Throughput Timer = X × 60 sample/minit) dan **Lampiran A** — worksheet Little's Law yang anda isi dalam langkah 4.*

### ✅ Checkpoint
- [ ] Sekurang-kurangnya 4 NFR ditulis dengan transaksi, beban, metrik percentile, ambang dan tempoh
- [ ] Pengiraan Little's Law lengkap: V → X → N, kadar hits/s, dan tetapan pacing
- [ ] Jadual jenis larian (baseline, load, stress, spike, soak) dengan konfigurasi JMeter
- [ ] Kriteria masuk/keluar, pemantauan, 3 risiko dan bahagian kebenaran bertulis diisi
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| N terlalu kecil (contoh 10) untuk volum besar | Lupa Z (guna R sahaja) | N = X × (R **+ Z**); biasanya think time yang paling besar |
| N tak masuk akal (berjuta-juta) | Unit bercampur (minit vs saat) | Tukar semua ke **saat** |
| Pacing tak capai target | Constant Throughput Timer dalam unit **sample/minit**, atau threads < N | Target = X × 60; tambah threads |
| NFR "sistem mesti stabil" | Tak boleh diukur | Tambah metrik + threshold + load + tempoh |

---

## Latihan 7 — Pembentangan mini (pasangan)

**Sesi:** S4

### 🎯 Objektif
- Present test plan dan satu dapatan report kepada "pengurusan" dalam 3 minit (O9)

### Prasyarat
- Latihan 5 (dapatan) dan Latihan 6 (test plan) dah siap

### Langkah
1. Sediakan 4 bahagian (maksimum 45 saat setiap satu):
   - **NFR utama** — satu ayat yang boleh diukur
   - **Load model** — X, R, Z → N (tunjuk kiraan)
   - **Jenis run** — turutan dan kenapa baseline dulu
   - **Satu dapatan** dari Latihan 5 — Bukti (angka + bahagian dashboard) → Kesan → Cadangan

   ![Templat pelan 4.2 Little's Law bilangan pengguna serentak](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-03-pelan-littles-law-n.png)
   *Untuk bahagian **Load model**: kiraan X, R, Z → N daripada §4.2 pelan anda.*

2. Tutup dengan satu ayat: *"Sebelum ujian sebenar, kami perlukan kebenaran bertulis daripada …"*

   ![Templat pelan bahagian 12 Kebenaran dan etika](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-04-pelan-kebenaran-etika.png)
   *Bahagian **12. Kebenaran & etika** — sumber ayat penutup "kebenaran bertulis daripada …".*

3. Present (pasangan lain tanya **satu** soalan: "Macam mana anda tahu …?").
4. Catat satu feedback yang anda dapat.

![Templat laporan: ringkasan eksekutif dan keputusan berbanding NFR](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-01-laporan-ringkasan-nfr.png)
*Bahan pembentangan: `templat-laporan-ujian.md` B1 (ringkasan eksekutif — satu ayat + 3 perkara utama) dan B3 (keputusan berbanding NFR dengan sumber dashboard).*

![Templat laporan: dapatan D2 bukti kesan punca cadangan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-02-laporan-dapatan-d2.png)
*Contoh satu dapatan untuk slot "Satu dapatan": **D2** — Bukti (angka + bahagian dashboard) → Kesan → Punca → Cadangan.*

### ✅ Checkpoint
- [ ] Pembentangan ≤ 3 minit merangkumi NFR, pengiraan N, jenis larian dan satu dapatan
- [ ] Dapatan disokong angka sebenar dan nama bahagian dashboard
- [ ] Soalan pasangan lain dijawab dan satu maklum balas dicatat
- [ ] Lulus **Kuiz S4** (sekurang-kurangnya separuh betul) (Kuiz S4)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| Lebih masa | Baca jadual satu-satu | Satu angka utama untuk setiap bahagian |
| "Graf ni naik…" tapi tak ada kesimpulan | Tak ada kesan/cadangan | Habiskan setiap dapatan dengan "jadi…" |
| Tak sebut pasal kebenaran | Terlupa etika | Ayat penutup wajib (langkah 2) |

### ⭐ Cabaran
1. **SLA gate dalam CI:** run blok `jq` + `awk` dalam README §4.9 pada `laporan07-sla2000` dan `laporan07-sla150`; tunjuk exit code (`echo $?`).
2. Terangkan dalam satu minit macam mana anda akan monitor soak test 4 jam (Backend Listener + Grafana vs HTML dashboard).

---

## Latihan 8 — Laporan berbilang lokasi (ejen teragih)

**Sesi:** S3

> 🎬 **Kelas 5 Okt: demo oleh jurulatih (5 minit)** — masa S3 diberi kepada Latihan 9 (CPU pelayan + chatbot). Tengok demo, kemudian buat latihan ni sendiri sebagai **kerja rumah** (semua langkah dan screenshot ada di bawah); checkpoint boleh ditanda bila siap.

### 🎯 Objektif
- Run satu distributed test (1 controller + 2 agent `jmeter-server` mewakili lokasi KL dan PENANG) dan generate **satu report gabungan** (O5)
- Generate **report per lokasi** daripada run yang sama dengan pecahkan JTL ikut prefix label `[LOKASI]` (O5)
- Bandingkan lokasi (sample, Error %, average, p90/p95, TPS) dan tulis **dua dapatan lokasi** (O6, O7)

### Prasyarat
- Latihan 4 dah siap; README §3.9 dah baca
- Java + JMeter 5.6.x (`jmeter --version`) dan Node.js (`node --version`)
- Port **3000, 3001, 1099, 1100, 4001, 4002** kosong — **stop SUT dalam Terminal A dulu** (script akan start SUT sendiri pada 3000 dan 3001)
- Plan rujukan: [`../test-plans/09-berbilang-lokasi.jmx`](../test-plans/09-berbilang-lokasi.jmx); script: [`../run/run-berbilang-lokasi.sh`](../run/run-berbilang-lokasi.sh) (Windows: `run-berbilang-lokasi.bat`)

### Langkah
1. **Run script** (≈ 45 s; output dibersihkan setiap kali run):
   ```bash
   cd hari-2/run
   ./run-berbilang-lokasi.sh            # Windows: run-berbilang-lokasi.bat
   ```
   Tengok console: 2 SUT → 2 agent (`OK Ejen KL mendengar pada port 1099`) → `Configuring remote engine` × 2 → `summary` (keluar berkelompok — sample sender StrippedBatch) → pecah JTL → jadual perbandingan.

   ![run-berbilang-lokasi.sh: 2 SUT, 2 ejen, Configuring remote engine, summary](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-01-skrip-berbilang-lokasi.png)
   *Console sebenar: 2 SUT → 2 ejen (`OK Ejen KL mendengar …`) → `Configuring remote engine` × 2 → `summary = 240 …`. (tangkapan ini guna salinan skrip dengan port dianjak — SUT 3927/3928, ejen 11099/11100 — supaya tak ganggu kelas; anda nampak 3000/3001 dan 1099/1100)*

2. **Buka report gabungan** `hari-2/run/laporan/gabungan/index.html`:
   - **Statistics:** berapa baris `[KL] …` dan `[PENANG] …`? Berapa sample dalam baris **Total**, dan baris transaksi dikira sekali ke?
   - **Charts → Over Time → Active Threads Over Time:** berapa siri? Apa namanya? (hint: `host:port` agent)

   ![Laporan gabungan Statistics dengan baris KL dan PENANG](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-02-gabungan-statistics.png)
   *Laporan `gabungan` — Statistics: baris `[KL] …` dan `[PENANG] …`, dan Total.*

   ![Active Threads Over Time gabungan: dua siri host:port ejen](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-03-gabungan-active-threads.png)
   *Active Threads Over Time: **dua siri**, satu per ejen (`127.0.0.1:<port>-Pengguna Pembaharuan Cukai`), bertindih jadi 20. (tangkapan ini guna salinan skrip dengan port dianjak — SUT 3927/3928, ejen 11099/11100 — supaya tak ganggu kelas; anda nampak 3000/3001 dan 1099/1100)*

3. **Buka report per lokasi** `laporan/KL/index.html` dan `laporan/PENANG/index.html`. Bandingkan APDEX dan graf Response Times Over Time.

   ![Laporan KL APDEX](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-04-kl-apdex.png)
   *`laporan/KL` — APDEX.*

   ![Laporan PENANG APDEX](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-05-penang-apdex.png)
   *`laporan/PENANG` — APDEX lebih rendah sebab latensi 300–900 ms.*

   ![Laporan KL Response Times Over Time](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-06-kl-response-times.png)
   *`laporan/KL` — Response Times Over Time.*

   ![Laporan PENANG Response Times Over Time](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-07-penang-response-times.png)
   *`laporan/PENANG` — Response Times Over Time: paksi-y jauh lebih tinggi.*

4. **Isi worksheet perbandingan** (salin dari console langkah 6 script, atau baca setiap `statistics.json`):

   | Lokasi | Label | Sampel | Ralat % | Purata ms | p90 ms | p95 ms | TPS |
   |--------|-------|-------:|--------:|----------:|-------:|-------:|----:|
   | KL | Pembaharuan Cukai Jalan (transaksi) | | | | | | |
   | KL | TOTAL (sampel HTTP) | | | | | | |
   | PENANG | Pembaharuan Cukai Jalan (transaksi) | | | | | | |
   | PENANG | TOTAL (sampel HTTP) | | | | | | |
   | Gabungan | Total (laporan `gabungan`) | | | | | | |

   (Rujukan run kami: transaksi KL 476 ms / p95 640 ms; PENANG 2430 ms / p95 3000 ms; Total gabungan 240 sample, average 363 ms, p95 873 ms, 6.90 TPS, 0% error.)

   ![Langkah 6 skrip: jadual perbandingan lokasi KL vs PENANG](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-08-jadual-perbandingan-lokasi.png)
   *Langkah 6 skrip — jadual perbandingan sebenar: transaksi KL ~446 ms vs PENANG ~2391 ms.*

5. **Tulis dua dapatan lokasi** dalam bahagian "Perbandingan lokasi" [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) (Bukti → Kesan → Punca → Cadangan). Satu dapatan mesti jawab: *average gabungan tu bagi gambaran yang betul ke?*

   ![Templat laporan A8 Perbandingan lokasi](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-09-templat-a8-perbandingan-lokasi.png)
   *Bahagian **A8. Perbandingan lokasi** dalam template laporan — tulis dua dapatan di sini.*

![Active Threads Over Time satu lokasi](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-16-active-threads-over-time.png)
*Active Threads Over Time untuk satu run (satu siri). Dalam report `gabungan`, graf yang sama tunjuk **satu siri untuk setiap agent** (`host:port`) — bandingkan bentuk ramp-up setiap lokasi (langkah 2).*

### ✅ Checkpoint
- [ ] Skrip selesai tanpa ralat; `laporan/gabungan`, `laporan/KL` dan `laporan/PENANG` wujud
- [ ] Anda menunjukkan dua siri Active Threads (satu per ejen) dan baris Statistics per lokasi dalam laporan gabungan
- [ ] Anda boleh menerangkan jumlah pengguna = threads × bilangan ejen, dan beza `-G` (semua ejen) dengan `-J` (setempat)
- [ ] Lembaran perbandingan diisi dan dua dapatan lokasi ditulis dengan angka anda
- [ ] Lulus **Kuiz S3** (sekurang-kurangnya separuh betul) (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| `Connection refused` / `Failed to configure 127.0.0.1:1099` | Agent belum listen, port 1099 kena block dengan firewall, atau `server.rmi.localport` tak dibuka | Check `hasil/ejen-KL/jmeter-server.log` dan `hasil/konsol-ejen-KL.log`; buka 1099 **dan** 4001 (dan 1100/4002); pada mesin sebenar set `-Djava.rmi.server.hostname=<IP ejen>` |
| `rmi_keystore.jks (No such file or directory)` | SSL RMI aktif (default) tapi tak ada keystore | Lab: `-Jserver.rmi.ssl.disable=true` pada controller **dan** agent. Production: `bin/create-rmi-keystore.sh`, salin ke semua mesin |
| `Cannot start. <host> is a loopback address.` | Agent tak ada `java.rmi.server.hostname` | Tambah `-Djava.rmi.server.hostname=127.0.0.1` (atau IP agent) |
| Controller `summary = 0`; log agent `Could not read file header line for file …/pengguna.csv` | CSV tak ada pada **agent** (path dibaca pada agent, bukan controller) | Salin `hari-2/data/` ke setiap agent dan set `-Jdata_dir=<laluan>` |
| `jmeter-server: command not found` (macOS Homebrew) | Homebrew cuma link `jmeter` | Script akan cari sendiri (`$JMETER_BIN`, `$JMETER_HOME/bin`, PATH, `$(brew --prefix jmeter)/libexec/bin`); kalau manual: guna full path tu atau `jmeter -s` |
| `RALAT: port 3001 sudah digunakan` | Mock lambat R3 (Cabaran Latihan 5) atau SUT lain masih run | `lsof -i :3001` (Windows: `netstat -ano \| findstr :3001`) dan stop process tu |
| Graf "over time" teranjak / Mod `gabung` nampak bersepah | Jam mesin agent tak sync (NTP) atau timezone berbeza | Sync NTP dalam semua mesin sebelum test; nyatakan dalam report |

### ⭐ Cabaran
1. Run `./run-berbilang-lokasi.sh gabung` (setiap lokasi run sendiri → `laporan-lokasi.js gabung` → `jmeter -g`). Apa yang berbeza dalam Active Threads Over Time berbanding mod distributed?
2. Generate report KL **tanpa** pecahkan JTL: `jmeter -g hasil/semua.jtl -o laporan/KL-tapis -Jjmeter.reportgenerator.sample_filter='^\[KL\].*'`. Bandingkan Total dengan `laporan/KL`. Lepas tu cuba `series_filter='^\[KL\].*'` — kenapa graf kosong? (README §3.9)
3. `PENGGUNA=20 GELUNG=5 ./run-berbilang-lokasi.sh` — berapa jumlah users? Jurang KL vs PENANG berubah tak?

---

## Latihan 9 — CPU pelayan (PerfMon) + p95/p99 chatbot

**Sesi:** S3

### 🎯 Objektif
- Pasang plugin PerfMon, start **ServerAgent** dan kumpul CPU/Memory pelayan ke `perfmon.jtl` semasa load test chatbot (O5)
- Baca **Active Threads**, **CPU** dan **Response Times Over Time** bersama untuk cari **knee point** dan bottleneck (O6)
- Terangkan p95 vs p99 dengan angka chatbot anda dan tulis satu **NFR p95 + p99** + satu dapatan (O6, O7)

### Prasyarat
- Latihan 4 dah siap; README §3.10 dan §3.11 dah baca
- Java + JMeter 5.6.x, Node.js; SUT dalam Terminal A (`node sut/server.js`) — versi repo terkini (ada `POST /api/chatbot`)
- Plugin: **jpgc-perfmon**, **jpgc-cmd**, **jpgc-graphs-basic** (Plugins Manager — README §3.10)
- ServerAgent 2.2.3: <https://github.com/undera/perfmon-agent/releases>; port **4444** kosong
- Plan rujukan: [`../test-plans/10b-chatbot-perfmon.jmx`](../test-plans/10b-chatbot-perfmon.jmx) (tanpa plugin: [`10-chatbot-beban.jmx`](../test-plans/10-chatbot-beban.jmx)); script: [`../run/run-chatbot-perfmon.sh`](../run/run-chatbot-perfmon.sh) (Windows: `run-chatbot-perfmon.bat`)

![Plugins Manager: PerfMon ditanda dalam Available Plugins](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-03-plugins-manager-available-perfmon.png)
*Options → Plugins Manager → Available Plugins: tanda "PerfMon (Servers Performance Monitoring)", "Command-Line Graph Plotting Tool" dan "3 Basic Graphs"; Review Changes tunjuk apa yang akan dipasang → "Apply Changes and Restart JMeter".*

### Langkah
1. **Uji chatbot sekali** (Terminal B):
   ```bash
   curl -s -X POST http://localhost:3000/api/chatbot -H 'Content-Type: application/json' \
     -d '{"soalan":"Bagaimana nak semak saman JPJ?"}'
   # {"jawapan":"Saman JPJ boleh disemak …","token_dijana":93,"masa_ms":784}
   ```
   Cuba 5 kali — perhatikan `masa_ms` ikut `token_dijana` (≈ 5 ms setiap token).

   ![curl ke /api/chatbot](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-05-curl-chatbot.png)
   *Tiga soalan sebenar ke chatbot tiruan (run kami pada port 3105; anda guna 3000): jawapan ikut kata kunci, `masa_ms` naik ikut `token_dijana`.*
2. **Start ServerAgent** (Terminal C — dalam kelas, laptop anda = "pelayan"):
   ```bash
   cd ServerAgent-2.2.3
   ./startAgent.sh --udp-port 0 --tcp-port 4444        # Windows: startAgent.bat --udp-port 0 --tcp-port 4444
   ```
   Tunggu `JP@GC Agent v2.2.3 started`. Uji: `telnet localhost 4444` → taip `test` → `Yep` (Windows tanpa telnet: `Test-NetConnection localhost -Port 4444` → `TcpTestSucceeded : True`).

   ![ServerAgent dimulakan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-06-serveragent-mula.png)
   *ServerAgent sebenar: `Binding TCP to …` dan `JP@GC Agent v2.2.3 started`, kemudian `test` → `Yep`. Mac Apple Silicon kami: Java x86_64 (Temurin 8, Rosetta) + port 4445 + polisi Java localhost sahaja; Windows/Linux x64 cukup `startAgent.bat`/`startAgent.sh`.*
3. **Buka plan `10b` dalam GUI** dan check **PerfMon Metrics Collector** (bawah Test Plan): dua baris (`CPU`, `Memory usedperc`), port `${__P(agent_port,4444)}`, Filename `${__P(perfmon_jtl,perfmon.jtl)}`. Jangan run dalam GUI — tutup GUI.

   ![PerfMon Metrics Collector dalam plan 10b](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-01-gui-perfmon-metrics-collector.png)
   *Konfigurasi PerfMon Metrics Collector dalam plan `10b`.*
4. **Run script** (≈ 3.5 minit dengan default; laptop kecil: `PENGGUNA=20 RAMPUP=60 TEMPOH=120`):
   ```bash
   cd hari-2/run
   ./run-chatbot-perfmon.sh            # Windows: run-chatbot-perfmon.bat (set JMETER_HOME dulu)
   ```
   Tengok console: `OK SUT`, `OK ServerAgent` → `summary` setiap 30 s → `OK cpu-perfmon.png` … → jadual ringkasan.

   ![Console run-chatbot-perfmon.sh](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-02-konsol-ringkasan.png)
   *Console run kami (port 3105/4445; default anda 3000/4444): ringkasan p50/p90/p95/p99 dan CPU purata/maks.*
5. **Buka tiga PNG** dalam `hari-2/run/hasil/<masa>/`: `active-threads.png`, `cpu-perfmon.png`, `response-times-over-time.png`. Letak sebelah-menyebelah (paksi masa sama). Catat: pada **berapa pengguna** CPU mula kekal ≥ 80%? Bila response time mula naik?

   ![Kandungan folder hasil](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-07-folder-hasil.png)
   *Folder `hasil/<masa>/` selepas script (run pendek 10 pengguna): `keputusan.jtl`, `perfmon.jtl`, `laporan/`, tiga PNG dan `perfmon.csv`. Baris `perfmon.jtl`: `elapsed` = nilai × 1000.*

   ![Tiga graf atas paksi masa yang sama](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-cpu-threads-rt-bertindan.png)
   *Run rujukan: CPU ≥ 80% dari ~31 pengguna; response time naik selepas tu.*
6. **Buka dashboard** `laporan/index.html` → Statistics (p95, p99, Error %) → Charts → Response Times → **Response Time Percentiles**. Kat percentile berapa lengkung mula "patah" ke atas?

   ![Statistics p95 dan p99](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-chatbot-statistics-p95-p99.png)
   *Statistics run rujukan: 95th pct 1665 ms vs 99th pct 6076 ms.*

   ![Response Time Percentiles](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-chatbot-response-time-percentiles.png)
   *Lengkung patah ke atas selepas ~p95 — ekor panjang jawapan chatbot.*
7. **Isi lembaran:**

   | Perkara | Anda | Rujukan kami |
   |---------|------|--------------|
   | Sampel / Error % | | 1877 / 4.95% |
   | p50 / p95 / p99 (ms) | | 902 / 1665 / 6076 |
   | CPU purata / maks | | 73% / 100% |
   | Pengguna bila CPU kekal ≥ 80% | | ~31 |
   | Throughput pada beban maksimum | | ~14 /s |

   ![Graf bertindan untuk lembaran](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-cpu-threads-rt-bertindan.png)
   *Baca nilai lembaran daripada graf bertindan: bila CPU kekal ≥ 80%, berapa thread aktif ketika itu, dan paras response time.*
8. **Tulis NFR + satu dapatan** dalam [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) (contoh B9): *"p95 ≤ … s dan p99 ≤ … s pada … pengguna serentak"* — lulus atau gagal dengan angka anda? Sertakan CPU sebagai **punca**.

   ![Contoh B9 dan dapatan C1](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-08-laporan-b9-c1.png)
   *Contoh diisi B9 + Finding C1 dalam `templat-laporan-ujian.md` (dirender): jadual NFR p95/p99 setiap tahap beban, kemudian Bukti → Kesan → Punca → Cadangan.*
9. **Hentikan ServerAgent** (Ctrl+C dalam Terminal C) sebaik siap — ejen tiada authentication.

   ![ServerAgent dihentikan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-09-serveragent-henti.png)
   *Ctrl+C sebenar pada ejen, kemudian semak dari terminal lain: `Connection refused` = port dah ditutup.*

### ✅ Checkpoint
- [ ] `perfmon.jtl` ada baris `localhost CPU` dan `localhost Memory usedperc`; tiga PNG + `laporan/index.html` dijana
- [ ] Anda boleh tunjuk knee point (pengguna + masa) guna tiga graf bersama dan terangkan kenapa CPU tak ada dalam HTML dashboard
- [ ] Anda boleh terangkan p95 vs p99 dalam ayat "X daripada 100 soalan …" dan kenapa p99 perlukan sampel yang banyak
- [ ] Satu NFR p95 + p99 dan satu dapatan (Bukti → Kesan → Punca CPU → Cadangan) ditulis dengan angka anda
- [ ] ServerAgent dihentikan selepas test
- [ ] Jawab soalan 6–7 **Kuiz S3** (Kuiz S3)

### 🧯 Masalah lazim

| Simptom | Punca | Cara selesai |
|--------|-------|--------------|
| `RALAT: ServerAgent tidak dapat dihubungi pada localhost:4444 (Connection refused)` / log JMeter `Connection refused` | Ejen belum start, port lain, atau firewall block 4444 | Start `startAgent.sh --tcp-port 4444`; pastikan `-Jagent_port` = `--tcp-port`; `telnet <pelayan> 4444` → `test` → `Yep`; buka firewall untuk IP mesin JMeter sahaja |
| Buka `10b` → `CannotResolveClassException: kg.apc.jmeter.perfmon.PerfMonCollector` | Plugin jpgc-perfmon belum dipasang | Plugins Manager → *PerfMon (Servers Performance Monitoring)* → restart; atau guna `10-chatbot-beban.jmx` (core sahaja) |
| Windows Firewall / antivirus tanya "Allow access" untuk Java | Ejen buka port TCP | Benarkan untuk rangkaian **Private** sahaja; lab localhost tak perlukan akses luar |
| CPU kosong / 0 dalam `perfmon.jtl` (macOS Apple Silicon); log ejen `UnsatisfiedLinkError … Cpu.gather` | SIGAR dalam ServerAgent cuma ada library x86_64 | Run ejen dengan Java x86_64 (Rosetta), contoh `/Library/Java/JavaVirtualMachines/temurin-8.jdk/…/java -jar CMDRunner.jar --tool PerfMonAgent --udp-port 0 --tcp-port 4444`; atau run ejen pada mesin Windows/Linux x64 |
| `perfmon.jtl` kosong (header sahaja) atau tiada | Collector tak boleh sambung ke ejen, atau collector berada dalam Thread Group yang disabled | Semak `jmeter.log` (cari `PerfMon`); letak collector bawah Test Plan; semak host/port |
| `JMeterPluginsCMD.sh: No such file` / `AMARAN: … tiada — PNG tidak akan dijana` | Plugin jpgc-cmd belum dipasang, atau `jmeter` pada PATH bukan dari `$JMETER_HOME/bin` (contoh Homebrew) | Pasang jpgc-cmd + jpgc-graphs-basic; set `JMETER_HOME=<folder JMeter>` sebelum run script |
| Error % tinggi (> 5%) dengan mesej `The operation lasted too long` | SLA 3000 ms dilanggar — jawapan panjang / pelayan tepu | Tu dapatan, bukan bug. Untuk banding: `SLA_MS=10000 ./run-chatbot-perfmon.sh` |
| CPU 100% sejak 10 pengguna pertama | Laptop kecil (2–4 teras) — SUT + JMeter + browser share CPU | `PENGGUNA=10 RAMPUP=60`, atau `CHATBOT_KERJA=0.5 node sut/server.js`; tutup aplikasi lain |

### ⭐ Cabaran
1. Tambah baris ketiga dalam collector: `CPU` dengan parameter `user` — beza dengan `combined`?
2. Jana semula dashboard dengan `-Jaggregate_rpt_pct1=75 -Jaggregate_rpt_pct3=99.9` (README §3.11). Berapa p99.9 anda? Berapa sampel di atas p99.9?
3. Run `CHATBOT_PEKERJA=2 PORT=3001 node sut/server.js` (2 worker sahaja) dan `PORT=3001 ./run-chatbot-perfmon.sh`. Knee point jatuh ke berapa pengguna? CPU laptop sampai 100% tak? Apa maksudnya untuk bottleneck "thread pool"?

---

## Semakan kendiri

- [ ] Saya boleh merancang perjalanan pengguna dan merakamnya ke dalam Transaction Controller bernama, tanpa aset statik
- [ ] Saya boleh menerangkan kenapa main balik gagal (401/403) — dan kenapa main balik yang "lulus" belum tentu betul
- [ ] Saya boleh membersihkan rakaman: korelasi, parameterisasi CSV, nama, think time, assertion
- [ ] Saya boleh menjana HTML dashboard dengan `-e -o` dan `-g`, dan melaras butiran graf
- [ ] Saya boleh menerangkan setiap bahagian dashboard dan istilahnya (percentile, throughput, latency, APDEX, Error %)
- [ ] Saya boleh menulis dapatan dengan bukti, kesan, punca dan cadangan
- [ ] Saya boleh menjana laporan gabungan dan per lokasi daripada ujian teragih (controller + ejen) dan membandingkan lokasi
- [ ] Saya boleh mengira pengguna serentak dengan Little's Law dan merancang jenis larian
- [ ] Isi penilaian kendiri Hari 2 (Kuiz hari)
