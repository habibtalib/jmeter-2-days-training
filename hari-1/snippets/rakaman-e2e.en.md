# End-to-End Exercise (Day 1): Record → Replay

One **complete** flow: record traffic through the JMeter proxy → JMeter generates samplers → **replay** → watch it **fail** → understand why we need **correlation** (Day 2).

> **Target:** the local mock `http://localhost:3000` (in `sut/`) only. **Do not** record or test public systems without written authorisation.

Estimated time: 15 minutes.

---

## Prerequisites

1. **SUT running** (keep it open for the whole exercise):
   ```bash
   node sut/server.js          # http://localhost:3000
   ```
2. **JMeter GUI** already open.

---

## Step 1 — Open the recorder

Open the ready-made template (the recorder and Recording Controller are already in place):

**File → Open →** `hari-1/test-plans/rakam-template.jmx`

The tree should contain:
- **HTTP(S) Test Script Recorder** (under Test Plan)
- **Thread Group → Recording Controller** (where the recording is stored; empty for now)

---

## Step 2 — Start the proxy

Select the **HTTP(S) Test Script Recorder** node → click the green **Start** ▶ button.
- The JMeter proxy now **listens on port 8888**.
- If a **Root CA Certificate** dialog appears, click **OK** (this certificate is not used for `http://`).

> Check the proxy is up (open another terminal): `lsof -iTCP:8888 -sTCP:LISTEN -n -P` — you should see `java … :8888 (LISTEN)`.

---

## Step 3 — Generate traffic to record

The proxy records **any** HTTP client that goes through it — not just a browser. Because this SUT is an API (lots of **POST**s), the simplest and most reliable approach is **`curl` through the proxy** (`-x http://localhost:8888`).

Run the full road-tax renewal flow:

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

> **Browser alternative:** set **Firefox/Chrome** to use the proxy `127.0.0.1:8888` (see README §4.3, steps B4–B6) and open `http://localhost:3000`. But a browser only makes **GET** requests from the address bar — the login POST needs a form, so `curl` is simpler for this API.
>
> ⚠️ **Make sure the client you use really goes through the proxy.** Your normal browser does **not** use the proxy unless it is configured. If nothing gets recorded, the traffic is almost certainly not going through `:8888`.

After those 3 commands, **3 samplers** should appear under the **Recording Controller** in JMeter.

---

## Step 4 — Stop & tidy up

1. Click **Stop** ⏹ on the recorder.
2. Look at the 3 recorded samplers: `/api/log-masuk`, `/api/kenderaan`, `/api/kenderaan/WXY1234/bayar-cukai`.
3. **This is the important part:** open samplers #2 & #3 → the **`Authorization: Bearer <token>`** header and the **`csrf`** body hold **FIXED values** (hard-coded) from the recording session. The recorder does **no** correlation at all.
4. Save: **File → Save Test Plan As…** (for example `rakaman-saya.jmx`).

---

## Step 5 — Replay (playback)

1. `rakam-template.jmx` already has a **View Results Tree** (under the Test Plan) — select it for debugging. (If your plan has none: right-click Thread Group → Add → Listener → View Results Tree.)
2. **Important — expire the recording session first:** restart the SUT so the old token is no longer valid:
   ```bash
   # Ctrl+C pada tetingkap SUT, kemudian:
   node sut/server.js
   ```
3. Click **Start (▶)** to **replay** the recorded plan.

**What happens:**

| Sampler | Code | Reason |
|---------|-----|-------|
| `POST /api/log-masuk` | **200** | Login always succeeds (any password is accepted) |
| `GET /api/kenderaan` | **401** | The hard-coded token has **expired** (new session after the restart) |
| `POST …/bayar-cukai` | **401** | The old token has expired → rejected before `csrf` is even checked |

> This is the **main reason we need correlation**: the `token` & `csrf` values **change every session**. The recording stores them as fixed text, so the replay fails as soon as the session changes.

---

## Quick proof (without the GUI)

The "raw" recording is provided as [`test-plans/04-rakaman-mentah.jmx`](../test-plans/04-rakaman-mentah.jmx). Check the replay behaviour straight from the terminal:

```bash
node sut/server.js &     # pastikan SUT berjalan
jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/pb.jtl
```

Expected result (verified):

```
/api/log-masuk                     -> HTTP 200  (success=true)
/api/kenderaan                     -> HTTP 401  (success=false)
/api/kenderaan/WXY1234/bayar-cukai -> HTTP 401  (success=false)
```

---

## Step 6 — Generate an HTML report from the recording

Add `-e -o <folder>` to the run to generate an **HTML dashboard report** directly from the replay:

```bash
# folder output MESTI kosong / belum wujud
jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx \
  -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
open /tmp/laporan-rakaman/index.html          # Windows: start /tmp\laporan-rakaman\index.html
```

Or generate it **later** from an existing `.jtl`:
```bash
jmeter -g /tmp/rec.jtl -o /tmp/laporan-rakaman/
```

**What the report shows:**

| Recording | Error % | Reason |
|---------|---------|-------|
| **Raw** (`04-rakaman-mentah.jmx`) | **~67%** | Hard-coded token/csrf → 401 on replay |
| **Correlated** (`hari-2/…/05-transaksi-penuh.jmx`) | **0%** | JSON Extractor captures token/csrf at runtime |

> This is what the report is for: it **clearly shows** the effect of correlation — Error % drops from ~67% to 0% once the recording is cleaned up. (Full report: APDEX, 90/95/99 percentiles, throughput, error %.)

> **Note:** a typical recording runs 1 user × 1 loop → few samples → a thin report. For a meaningful report, increase threads/loops or use [`hari-2/run/run-nogui.sh`](../../hari-2/run/run-nogui.sh).

---

## Summary

You have completed **one full cycle**: **record → generate samplers → replay → fail**.
That failure is **expected and instructive** — it shows the limits of plain recording.

**Next step (Day 2):** replace the fixed values with a **JSON Extractor** that captures `token` + `csrf` at runtime (correlation), so the replay **succeeds**. See [`hari-2/test-plans/04-korelasi-log-masuk.jmx`](../../hari-2/test-plans/04-korelasi-log-masuk.jmx).
