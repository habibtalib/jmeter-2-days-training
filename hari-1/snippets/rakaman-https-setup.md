# Rakaman HTTPS dengan JMeter — Persediaan (generik)

Panduan **generik** untuk record laman **HTTPS** guna HTTP(S) Test Script Recorder. Tak terikat pada mana-mana host tertentu.

> ⚠️ **Etika & undang-undang:** Record / test **hanya** sistem yang anda **miliki** atau ada **kebenaran bertulis** untuk test (contohnya staging dalaman sendiri, dengan skop bertulis). Record atau test sistem awam/production tanpa kebenaran adalah salah di sisi undang-undang. Untuk latihan, guna mock local (`sut/`) atau laman demo yang dibenarkan macam `blazedemo.com`.

## Kenapa HTTPS perlu langkah tambahan

Untuk record HTTPS, JMeter bertindak sebagai **man-in-the-middle** (MITM): ia decrypt trafik, record, kemudian encrypt semula ke server. Supaya browser tak reject connection, browser mesti **trust certificate CA JMeter**.

## Langkah 1 — Buka templat

**File → Open →** [`rakam-https-template.jmx`](../test-plans/rakam-https-template.jmx)
(HTTP(S) Test Script Recorder port 8888 + Recording Controller; **tiada filter host**, jadi ia record HTTP **dan** HTTPS.)

## Langkah 2 — Jana sijil CA JMeter

Klik **Start** ▶ sekali pada recorder. JMeter akan generate:
```
<JMETER_HOME>/bin/ApacheJMeterTemporaryRootCA.crt
```
Kalau install guna Homebrew (macOS):
```
/opt/homebrew/Cellar/jmeter/<versi>/libexec/bin/ApacheJMeterTemporaryRootCA.crt
```
Kat Windows (biasanya):
```
C:\apache-jmeter-<versi>\bin\ApacheJMeterTemporaryRootCA.crt
```
> Certificate ni **valid 7 hari** sahaja — generate semula bila expired. Boleh **Stop** dulu lepas ia dah di-generate.

## Langkah 3 — Import sijil ke pelayar

**Firefox** (disyorkan — ada setting proxy & certificate sendiri):
1. **Settings → Privacy & Security → Certificates → View Certificates… → Authorities → Import…**
2. Pilih `ApacheJMeterTemporaryRootCA.crt` → tick **Trust this CA to identify websites** → **OK**.

**Chrome / Edge di Windows** (guna Windows Certificate Store):

> ⚠️ Error **"cert not owner" / access denied** = anda cuba install ke store **Local Machine** tanpa access **Administrator**. Install ke store **Current User** sahaja — tak perlu admin.

1. Double-click `ApacheJMeterTemporaryRootCA.crt` → **Install Certificate**.
2. **Store Location: Current User** (*bukan* Local Machine) → **Next**.
3. Pilih **Place all certificates in the following store** → **Browse** → **Trusted Root Certification Authorities** → **OK** → **Next** → **Finish**.
4. Accept security warning → restart Chrome/Edge.

PowerShell (tak perlu admin — store Current User):
```powershell
Import-Certificate -FilePath "$env:USERPROFILE\Desktop\ApacheJMeterTemporaryRootCA.crt" -CertStoreLocation Cert:\CurrentUser\Root
```
> **Buang bila dah siap:** `certmgr.msc` → *Current User → Trusted Root Certification Authorities → Certificates* → delete **_ JMeter Root CA for recording**.

**Chrome / Edge / Safari di macOS** (guna system keychain):
```bash
# import sebagai CA dipercayai (akan minta kata laluan)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  "/opt/homebrew/Cellar/jmeter/$(jmeter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)/libexec/bin/ApacheJMeterTemporaryRootCA.crt"
```
Check certificate dah di-trust:
```bash
security dump-trust-settings -d 2>/dev/null | grep -i jmeter   # patut nampak CA JMeter
```
> **Lepas import ke System keychain, `--ignore-certificate-errors` dah TAK perlu.** Chrome/Safari/Edge sekarang trust CA JMeter di peringkat sistem — anda boleh record HTTPS dalam Chrome **biasa** (cuma set proxy, Langkah 4).
>
> **Buang bila dah siap** (trust MITM untuk seluruh mesin — jangan biar kekal):
> ```bash
> sudo security delete-certificate -c "_ JMeter Root CA for recording (INSTALL ONLY IF IT S YOURS)" /Library/Keychains/System.keychain
> ```

> **Alternatif tanpa install certificate langsung (Chrome sekali guna):** kalau anda **tak** nak import CA ke keychain, run satu profile Chrome sekali guna yang ignore error certificate — **jangan** guna profile utama anda:
> ```bash
> "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
>   --user-data-dir="/tmp/chrome-rakam" \
>   --proxy-server=127.0.0.1:8888 --proxy-bypass-list="<-loopback>" \
>   --ignore-certificate-errors --test-type --no-first-run about:blank
> ```
> (Kalau CA dah di-trust dalam System keychain, buang `--ignore-certificate-errors` — proxy sahaja dah cukup.)

## Langkah 4 — Tetapkan proxy pelayar

- **Firefox:** Settings → Network Settings → **Manual proxy** → HTTP Proxy `localhost` Port `8888`, tick **Also use this proxy for HTTPS**; **buang** `localhost, 127.0.0.1` dari **No proxy for** kalau target anda localhost.
- **Chrome (command di atas):** proxy dah di-set melalui flag `--proxy-server`.

## Langkah 5 — Rakam → Stop → simpan

1. **Start** ▶ pada recorder (kalau belum).
2. Buka laman **HTTPS** (yang anda dibenarkan) dalam browser yang dah di-configure. Sampler akan muncul bawah **Recording Controller**.
3. **Stop** ⏹.
4. Kemaskan: buang static asset/analytics, rename sampler, tambah **HTTP Cookie Manager** (banyak laman guna session cookie), buat **correlation** untuk token/csrf/CSRF (tengok Hari 2).
5. **Save** sebagai `.jmx` baru.

## Langkah 6 — Pulihkan proxy pelayar

Lepas siap: Firefox → Network Settings → **Use system proxy settings** (atau tutup profile Chrome sekali guna). Kalau tak, browsing biasa akan fail sebab browser masih hala ke proxy JMeter yang dah stop.

---

**Troubleshoot "tiada apa-apa ter-record":**
| Gejala | Punca biasa | Cara betulkan |
|--------|-------------|----------|
| Proxy tak `LISTEN` di 8888 | Belum klik **Start** / buka plan yang salah | `lsof -iTCP:8888 -sTCP:LISTEN -n -P` → Start pada recorder yang betul |
| Warning certificate / connection fail (HTTPS) | CA JMeter belum di-trust | Import CA (Langkah 3) atau guna profile Chrome `--ignore-certificate-errors` |
| Trafik tak sampai ke proxy | Browser **biasa** tak lalu proxy | Guna browser yang dah di-configure ke `127.0.0.1:8888` |
| Localhost tak ter-record | Browser bypass loopback | Firefox: buang `localhost` dari *No proxy for*; Chrome: `--proxy-bypass-list="<-loopback>"` |
| Laman luar tak ter-record | Ada **include filter** host | Kosongkan *Requests Filtering → Includes* |
