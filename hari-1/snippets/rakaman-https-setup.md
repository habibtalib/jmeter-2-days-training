# Rakaman HTTPS dengan JMeter — Persediaan (generik)

Panduan **generik** untuk merakam laman **HTTPS** dengan HTTP(S) Test Script Recorder. Tidak terikat kepada mana-mana hos tertentu.

> ⚠️ **Etika & undang-undang:** Rakam / uji **hanya** sistem yang anda **miliki** atau ada **kebenaran bertulis** untuk uji (cth. staging dalaman anda sendiri, dengan skop bertulis). Merakam atau menguji sistem awam/pengeluaran tanpa kebenaran adalah menyalahi undang-undang. Untuk latihan, gunakan mock tempatan (`sut/`) atau laman demo yang dibenarkan seperti `blazedemo.com`.

## Kenapa HTTPS perlu langkah tambahan

Untuk merakam HTTPS, JMeter bertindak sebagai **man-in-the-middle** (MITM): ia menyahsulit trafik, merakamnya, kemudian menyulit semula ke pelayan. Supaya pelayar tidak menolak sambungan, ia mesti **mempercayai sijil CA JMeter**.

## Langkah 1 — Buka templat

**File → Open →** [`rakam-https-template.jmx`](../test-plans/rakam-https-template.jmx)
(HTTP(S) Test Script Recorder port 8888 + Recording Controller; **tiada penapis hos**, jadi ia rakam HTTP **dan** HTTPS.)

## Langkah 2 — Jana sijil CA JMeter

Klik **Start** ▶ sekali pada perakam. JMeter menjana:
```
<JMETER_HOME>/bin/ApacheJMeterTemporaryRootCA.crt
```
Pada pemasangan Homebrew (macOS):
```
/opt/homebrew/Cellar/jmeter/<versi>/libexec/bin/ApacheJMeterTemporaryRootCA.crt
```
> Sijil ini **sah 7 hari** sahaja — jana semula bila luput. Boleh **Stop** dahulu selepas ia dijana.

## Langkah 3 — Import sijil ke pelayar

**Firefox** (disyorkan — proxy & sijil tersendiri):
1. **Settings → Privacy & Security → Certificates → View Certificates… → Authorities → Import…**
2. Pilih `ApacheJMeterTemporaryRootCA.crt` → tandakan **Trust this CA to identify websites** → **OK**.

**Chrome / Edge** (guna keychain sistem — macOS):
```bash
# import sebagai CA dipercayai (akan minta kata laluan)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  "/opt/homebrew/Cellar/jmeter/$(jmeter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)/libexec/bin/ApacheJMeterTemporaryRootCA.crt"
```
> **Alternatif pantas (Chrome sekali-guna):** jalankan satu profil Chrome sekali guna yang abai sijil — **jangan** guna profil utama anda:
> ```bash
> "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
>   --user-data-dir="/tmp/chrome-rakam" \
>   --proxy-server=127.0.0.1:8888 --proxy-bypass-list="<-loopback>" \
>   --ignore-certificate-errors --test-type --no-first-run about:blank
> ```

## Langkah 4 — Tetapkan proxy pelayar

- **Firefox:** Settings → Network Settings → **Manual proxy** → HTTP Proxy `localhost` Port `8888`, tandakan **Also use this proxy for HTTPS**; **kosongkan** `localhost, 127.0.0.1` dari **No proxy for** jika mensasar localhost.
- **Chrome (arahan di atas):** proxy sudah ditetapkan melalui bendera `--proxy-server`.

## Langkah 5 — Rakam → Stop → simpan

1. **Start** ▶ pada perakam (jika belum).
2. Layari laman **HTTPS** (yang anda dibenarkan) dalam pelayar yang dikonfigur. Sampler muncul di bawah **Recording Controller**.
3. **Stop** ⏹.
4. Kemas: buang aset statik/analitik, namakan sampler, tambah **HTTP Cookie Manager** (banyak laman guna cookie sesi), **korelasi** token/csrf/CSRF (lihat Hari 2).
5. **Simpan** sebagai `.jmx` baharu.

## Langkah 6 — Pulihkan proxy pelayar

Selepas selesai: Firefox → Network Settings → **Use system proxy settings** (atau tutup profil Chrome sekali-guna). Jika tidak, pelayaran biasa akan gagal kerana masih menghala ke proxy JMeter yang telah berhenti.

---

**Nyahpepijat "tiada apa dirakam":**
| Gejala | Punca biasa | Betulkan |
|--------|-------------|----------|
| Proxy tak `LISTEN` di 8888 | Belum klik **Start** / plan salah | `lsof -iTCP:8888 -sTCP:LISTEN -n -P` → Start pada perakam betul |
| Amaran sijil / sambungan gagal (HTTPS) | CA JMeter tak dipercayai | Import CA (Langkah 3) atau guna profil Chrome `--ignore-certificate-errors` |
| Trafik tak sampai ke proxy | Pelayar **biasa** tak melalui proxy | Guna pelayar yang dikonfigur ke `127.0.0.1:8888` |
| Localhost tak dirakam | Pelayar pintas loopback | Firefox: buang `localhost` dari *No proxy for*; Chrome: `--proxy-bypass-list="<-loopback>"` |
| Laman luar tak dirakam | Ada **include filter** hos | Kosongkan *Requests Filtering → Includes* |
