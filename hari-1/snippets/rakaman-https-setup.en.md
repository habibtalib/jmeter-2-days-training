# HTTPS Recording with JMeter — Setup (generic)

A **generic** guide to recording **HTTPS** sites with the HTTP(S) Test Script Recorder. It is not tied to any particular host.

> ⚠️ **Ethics & law:** Record / test **only** systems that you **own** or have **written authorisation** to test (for example your own internal staging, with a written scope). Recording or testing public/production systems without permission is against the law. For training, use the local mock (`sut/`) or a permitted demo site such as `blazedemo.com`.

## Why HTTPS needs extra steps

To record HTTPS, JMeter acts as a **man-in-the-middle** (MITM): it decrypts the traffic, records it, then re-encrypts it to the server. So that the browser does not reject the connection, the browser must **trust the JMeter CA certificate**.

## Step 1 — Open the template

**File → Open →** [`rakam-https-template.jmx`](../test-plans/rakam-https-template.jmx)
(HTTP(S) Test Script Recorder on port 8888 + Recording Controller; **no host filter**, so it records HTTP **and** HTTPS.)

## Step 2 — Generate the JMeter CA certificate

Click **Start** ▶ once on the recorder. JMeter will generate:
```
<JMETER_HOME>/bin/ApacheJMeterTemporaryRootCA.crt
```
If installed with Homebrew (macOS):
```
/opt/homebrew/Cellar/jmeter/<versi>/libexec/bin/ApacheJMeterTemporaryRootCA.crt
```
On Windows (usually):
```
C:\apache-jmeter-<versi>\bin\ApacheJMeterTemporaryRootCA.crt
```
> This certificate is **valid for 7 days** only — generate it again when it expires. You can **Stop** once it has been generated.

## Step 3 — Import the certificate into the browser

**Firefox** (recommended — it has its own proxy & certificate settings):
1. **Settings → Privacy & Security → Certificates → View Certificates… → Authorities → Import…**
2. Choose `ApacheJMeterTemporaryRootCA.crt` → tick **Trust this CA to identify websites** → **OK**.

**Chrome / Edge on Windows** (uses the Windows Certificate Store):

> ⚠️ A **"cert not owner" / access denied** error means you are trying to install into the **Local Machine** store without **Administrator** access. Install into the **Current User** store only — no admin needed.

1. Double-click `ApacheJMeterTemporaryRootCA.crt` → **Install Certificate**.
2. **Store Location: Current User** (*not* Local Machine) → **Next**.
3. Choose **Place all certificates in the following store** → **Browse** → **Trusted Root Certification Authorities** → **OK** → **Next** → **Finish**.
4. Accept the security warning → restart Chrome/Edge.

PowerShell (no admin needed — Current User store):
```powershell
Import-Certificate -FilePath "$env:USERPROFILE\Desktop\ApacheJMeterTemporaryRootCA.crt" -CertStoreLocation Cert:\CurrentUser\Root
```
> **Remove it when you are done:** `certmgr.msc` → *Current User → Trusted Root Certification Authorities → Certificates* → delete **_ JMeter Root CA for recording**.

**Chrome / Edge / Safari on macOS** (uses the system keychain):
```bash
# import sebagai CA dipercayai (akan minta kata laluan)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  "/opt/homebrew/Cellar/jmeter/$(jmeter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)/libexec/bin/ApacheJMeterTemporaryRootCA.crt"
```
Check the certificate is trusted:
```bash
security dump-trust-settings -d 2>/dev/null | grep -i jmeter   # patut nampak CA JMeter
```
> **After importing into the System keychain, `--ignore-certificate-errors` is NO longer needed.** Chrome/Safari/Edge now trust the JMeter CA at system level — you can record HTTPS in **normal** Chrome (just set the proxy, Step 4).
>
> **Remove it when you are done** (it trusts a MITM for the whole machine — do not leave it in place):
> ```bash
> sudo security delete-certificate -c "_ JMeter Root CA for recording (INSTALL ONLY IF IT S YOURS)" /Library/Keychains/System.keychain
> ```

> **Alternative with no certificate install at all (throwaway Chrome):** if you do **not** want to import the CA into the keychain, run a throwaway Chrome profile that ignores certificate errors — **never** use your main profile:
> ```bash
> "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
>   --user-data-dir="/tmp/chrome-rakam" \
>   --proxy-server=127.0.0.1:8888 --proxy-bypass-list="<-loopback>" \
>   --ignore-certificate-errors --test-type --no-first-run about:blank
> ```
> (If the CA is already trusted in the System keychain, drop `--ignore-certificate-errors` — the proxy alone is enough.)

## Step 4 — Set the browser proxy

- **Firefox:** Settings → Network Settings → **Manual proxy** → HTTP Proxy `localhost` Port `8888`, tick **Also use this proxy for HTTPS**; **remove** `localhost, 127.0.0.1` from **No proxy for** if your target is localhost.
- **Chrome (command above):** the proxy is already set through the `--proxy-server` flag.

## Step 5 — Record → Stop → save

1. **Start** ▶ on the recorder (if not already started).
2. Open the **HTTPS** site (one you are authorised to test) in the configured browser. Samplers will appear under the **Recording Controller**.
3. **Stop** ⏹.
4. Tidy up: remove static assets/analytics, rename samplers, add an **HTTP Cookie Manager** (many sites use session cookies), and set up **correlation** for token/csrf/CSRF (see Day 2).
5. **Save** as a new `.jmx`.

## Step 6 — Restore the browser proxy

When you are done: Firefox → Network Settings → **Use system proxy settings** (or close the throwaway Chrome profile). Otherwise normal browsing will fail because the browser still points to the stopped JMeter proxy.

---

**Troubleshooting "nothing gets recorded":**
| Symptom | Common cause | Fix |
|--------|-------------|----------|
| Proxy not `LISTEN`ing on 8888 | **Start** not clicked yet / wrong plan open | `lsof -iTCP:8888 -sTCP:LISTEN -n -P` → Start on the correct recorder |
| Certificate warning / connection fails (HTTPS) | JMeter CA not trusted yet | Import the CA (Step 3) or use the Chrome profile with `--ignore-certificate-errors` |
| Traffic does not reach the proxy | The **normal** browser does not use the proxy | Use the browser configured for `127.0.0.1:8888` |
| Localhost not recorded | Browser bypasses loopback | Firefox: remove `localhost` from *No proxy for*; Chrome: `--proxy-bypass-list="<-loopback>"` |
| External sites not recorded | A host **include filter** is set | Clear *Requests Filtering → Includes* |
