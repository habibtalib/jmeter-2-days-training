# Day 2 Lab — Record & Playback, Performance Reports & Test Planning

[⬅️ Day 2 README](../README.md) · [🎤 Trainer Notes](../nota-penceramah.md) · [🗂️ Reference test plans](../test-plans/) · [📋 Test Plan Template](./templat-pelan-ujian.md) · [📝 Test Report Template](./templat-laporan-ujian.md)

> **Lab rule:** Keep two windows open at all times — **Terminal A**: the mock server (`node sut/server.js` from the repo root, do not close it), **Terminal B / JMeter GUI**: the exercises. When something "doesn't work", check in this order: (1) the Terminal A log, (2) View Results Tree → the **Request** & **Response data** tabs, (3) Debug Sampler, (4) `jmeter.log` (the yellow ⚠️ icon at the top-right corner of the GUI).

> ⚠️ **Ethics:** every exercise targets **only** `http://localhost:3000` (the mock eJPJ Portal, synthetic data). Every time you open a plan, check **HTTP Request Defaults → Server Name or IP = `localhost`, Port = `3000`** before pressing Start.

> 💡 Save your exercise plans in `hari-2/test-plans/` (e.g. `latihan-01-rakaman.jmx`) so that the CSV path `../data/pengguna.csv` resolves. Save run results in the `hasil/` folder (already in `.gitignore`). The reference plans are the "answer key" — try it yourself first.

| Lab | Session | Reference plan / material | Outcome |
|---------|------|----------------------|-------|
| 1 — Record the tax payment flow | S1 | `hari-1/test-plans/rakam-template.jmx` | 4 samplers in 4 named Transaction Controllers |
| 2 — Playback & 401/403 diagnosis | S1 | `hari-1/test-plans/04-rakaman-mentah.jmx` | 200 / 401 / 200 / 401 explained; 403 reproduced |
| 3 — Make the recording replayable | S2 | `04-korelasi-log-masuk.jmx`, `05-transaksi-penuh.jmx` | 80 HTTP samples + 20 transactions, Error % ≈ 0 |
| 4 — Generate the HTML dashboard & read every section | S3 | `05-transaksi-penuh.jmx` (or your Lab 3 plan) | Completed dashboard worksheet |
| 5 — Peak scenario `07` + SLA → 3 findings | S3 | `07-beban-puncak-cukai.jmx`, `templat-laporan-ujian.md` | Two reports + three written findings |
| 6 — Test planning + Little's Law | S4 | `templat-pelan-ujian.md` | Completed plan + N & pacing calculation |
| 7 — Mini presentation | S4 | Plan (Lab 6) + report (Lab 5) | 3-minute presentation |
| 8 — Multi-site report (distributed agents) | S3 | `09-berbilang-lokasi.jmx`, `run/run-berbilang-lokasi.sh` | Combined + per-site reports, comparison table, 2 findings |
| 9 — Server CPU (PerfMon) + chatbot p95/p99 | S3 | `10b-chatbot-perfmon.jmx`, `run/run-chatbot-perfmon.sh`, ServerAgent | `perfmon.jtl` + 3 PNGs + dashboard, knee point, p95/p99 NFR + 1 finding |

---

## Lab 1 — Record the tax payment flow

**Session:** S1

### 🎯 Objective
- Plan the 4-step user journey and its transaction names before recording (O1)
- Set up the HTTP(S) Test Script Recorder: port 8888, Grouping into Transaction Controllers, Excludes, think time `${T}` (O1)
- Record login → vehicle list → tax check → tax payment through the proxy (O1)

### Prerequisites
- SUT running: `node sut/server.js` → <http://localhost:3000/api/health> returns `{"status":"ok",...}`
- `curl` available (built in on macOS/Linux; Windows: **Git Bash**)
- README §1.2–1.5

### Steps
1. **Plan:** copy the table from README §1.2 onto your paper/notes. For each step, mark the values you **expect** to be dynamic (token, csrf, no_pendaftaran, amaun).

   ![README §1.2: recording plan table T01–T04](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-05-rancang-jadual-transaksi.png)
   *The README §1.2 table you copy: one row = one user action = one `T0x_…` transaction, with the values you expect to be dynamic.*

2. **File → Open →** `hari-1/test-plans/rakam-template.jmx` → **File → Save As** → `hari-2/test-plans/latihan-01-rakaman.jmx`.

   ![rakam-template.jmx opened in JMeter](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-06-rakam-template-dibuka.png)
   *`rakam-template.jmx` after **Open**: Thread Group → Recording Controller, View Results Tree and the HTTP(S) Test Script Recorder.*

3. **Right-click Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, Server `localhost`, Port `3000`. (The recorder will leave the samplers' Server/Port empty.)

   ![HTTP Request Defaults http localhost 3000 under Thread Group](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-07-http-request-defaults.png)
   ***HTTP Request Defaults** under the Thread Group: `http` · `localhost` · `3000`.*

4. Click **HTTP(S) Test Script Recorder**:
   - Port: `8888` · Target Controller: `Test Plan > Thread Group > Recording Controller`
   - **Grouping:** `Put each group in a new transaction controller`
   - **Capture HTTP Headers:** ticked
   - **Requests Filtering → URL Patterns to Exclude:** the static-asset regex is already there — add the lines `.*google-analytics.*` and `.*googletagmanager.*` (good practice for real sites)

   ![Recorder Test Plan Creation tab: port 8888, Target Controller, Grouping transaction controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-08-recorder-test-plan-creation.png)
   ***Test Plan Creation** tab: Port `8888`, Target Controller `… > Thread Group > Recording Controller`, Grouping **Put each group in a new transaction controller**, **Capture HTTP Headers** ticked.*

   ![Recorder Requests Filtering tab: URL Patterns to Exclude with google-analytics and googletagmanager](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-09-recorder-requests-filtering.png)
   ***Requests Filtering** tab: the original static-asset regex + the two new lines `.*google-analytics.*` and `.*googletagmanager.*`.*

5. **Right-click HTTP(S) Test Script Recorder → Add → Timer → Constant Timer**: Thread Delay `${T}`.

   ![Constant Timer Thread Delay ${T} under the recorder](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-10-constant-timer-t.png)
   ***Constant Timer** as a child of the recorder, Thread Delay `${T}` — the recorder replaces `${T}` with the real gap (ms).*

6. Click **Start** ▶. If the Root CA certificate dialog appears, click **OK** (it is not used for `http://`). The **Recorder: Transactions Control** window appears — leave it open.

   ![Recorder after Start: Stop and Restart enabled](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-11-recorder-dah-start.png)
   *After **Start**: Start is greyed out, **Stop** and **Restart** are enabled — the proxy is listening.*

   ![Recorder: Transactions Control window](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-12-recorder-transactions-control.png)
   *The **Recorder: Transactions Control** window — **Transaction name** (prefix), **Naming scheme**, **Create new transaction after request (ms)**. Leave it open.*

7. Terminal B: confirm the proxy is up — `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (Windows: `netstat -ano | findstr :8888`).

   ![lsof shows java LISTEN on the proxy port](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-13-lsof-proxy-listen.png)
   *Real `lsof` output: the `java` (JMeter) process is **LISTEN**ing — the proxy is up. (this capture used our own mock instance on port 3917 and proxy 18888 so it would not disturb the class — you use 3000 / 8888)*

8. Before each step, type the transaction name (`T01_LogMasuk`, `T02_SenaraiKenderaan`, `T03_SemakCukai`, `T04_BayarCukai`) into the prefix/transaction name field of the *Recorder: Transactions Control* window. Then run that step's curl block from README §1.4 — **wait > 5 s** between blocks.

   ![Transactions Control: Transaction name T01_LogMasuk](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-14-prefix-t01-logmasuk.png)
   *Before the first block: type `T01_LogMasuk` into **Transaction name**.*

   ![T01 curl block through the proxy: token and csrf response](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-15-curl-t01-logmasuk.png)
   *The `T01_LogMasuk` block through the proxy (`-x $P`): the real response contains a fresh `token` and `csrf`.*

9. After step 4 shows `"status":"BERJAYA"`, click **Stop** ⏹ and **File → Save**.

   ![T04 curl block pay tax: status BERJAYA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-16-curl-t04-berjaya.png)
   *The `T04_BayarCukai` block: the last response is `"status":"BERJAYA"` — now click **Stop** and **File → Save**.*

10. Expand the **Recording Controller**: note the name of each Transaction Controller and sampler. Open the `T02` Header Manager — copy the first 8 characters of the `Authorization` value. Open the `T04` sampler body — find `csrf`.

    ![Recording Controller with Transaction Controllers T01 to T04](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-17-recording-controller-t01-t04.png)
    *The real recording: four Transaction Controllers `T01_…`–`T04_…`, each with a sampler (`T01_LogMasuk/api/log-masuk-1`, …) + Constant Timer + HTTP Header Manager.*

    ![T02 Header Manager: Authorization Bearer recorded token](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-18-header-manager-t02-bearer.png)
    *`T02` Header Manager: `Authorization: Bearer <recorded-token>` — a **hardcoded** value.*

    ![T04 sampler Body Data with literal csrf](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-19-body-t04-csrf.png)
    *`T04` sampler Body Data: the literal `"csrf":"…"` from the recording session.*

![Mock eJPJ portal: login form](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-01-portal-log-masuk.png)
*The flow being recorded (browser version): <http://localhost:3000/portal> → **Log Masuk** form (POST `/portal/log-masuk`). With the browser proxy set to `localhost:8888`, every click becomes a sampler.*

![eJPJ portal: My Vehicles list](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-02-portal-senarai-kenderaan.png)
*After login → **Kenderaan Saya** (GET `/portal/kenderaan`, needs the `SESI_EJPJ` session cookie). Click **Bayar cukai** for WXY1234.*

![eJPJ portal: tax payment form with hidden csrf field](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-03-portal-borang-bayar-csrf.png)
*The **Bayar Cukai Jalan** form: the red box shows the hidden `csrf` and `amaun` fields (as seen in DevTools → Elements). `csrf` is a dynamic value — you correlate it in Lab 3.*

![eJPJ portal: payment receipt with status BERJAYA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab1-04-portal-resit-berjaya.png)
*Final step: the receipt shows **Status: BERJAYA**. This is the text used by the Response Assertion.*

![HTTP(S) Test Script Recorder: proksi port 8888, Target Controller Recording Controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-29-gui-recorder-settings.png)
*HTTP(S) Test Script Recorder: proxy on port 8888, requests recorded into the Recording Controller. (The original template shows "Add separators between groups" — change Grouping as in step 4.)*

### ✅ Checkpoint
- [ ] The 4-step planning table (action, request, transaction name, dynamic data) was written before recording
- [ ] Grouping set to *Put each group in a new transaction controller* and Constant Timer `${T}` added under the recorder
- [ ] The Recording Controller contains **4** groups / Transaction Controllers, each with one `/api/...` sampler, with no static assets
- [ ] You can point to where the recording session's `token` and `csrf` are hard-coded in the plan
- [ ] Passed **Quiz S1** (at least half correct) (Kuiz S1)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `curl: (7) Failed to connect to localhost port 8888` | The recorder has not been **Started** | Click Start on the HTTP(S) Test Script Recorder |
| curl succeeds but no sampler is recorded | Forgot `-x $P`, or variable `P` is not set in that terminal | Re-run the `P=…` and `B=…` lines; check `echo $P` |
| `Could not create script recorder - port in use` | Port 8888 is in use (another recorder / another application) | Close other JMeter tabs that are recording; or change the port (and `P`) |
| All 4 requests in one Transaction Controller | Gap between steps < 5 s | Re-record with `sleep 6` between blocks; or split them manually (drag the samplers) |
| Error "Target Controller is configured to Use Recording Controller but no such controller exists" | The Recording Controller was deleted | **Right-click Thread Group → Add → Logic Controller → Recording Controller** |
| `TOKEN` empty in step 2 | The login response never arrived (SUT down) | Check Terminal A; run the T01 block again |

### ⭐ Challenge
1. Re-record with Naming scheme **Use format string** and the format `#{counter,number,000} - #{method} #{path}`. Compare the sampler names.
2. Record with Grouping **Add separators between groups** (the template's original setting). When is this option more suitable than Transaction Controllers?

---

## Lab 2 — Playback & 401/403 diagnosis

**Session:** S1

### 🎯 Objective
- Replay the recording after the recording session has expired and record the code of each step (O2)
- Use the View Results Tree **Sampler result**, **Request** and **Response data** tabs to find the root cause (O2)
- Distinguish 401 (token) from 403 (csrf) through an experiment (O2)

### Prerequisites
- Lab 1 completed (`latihan-01-rakaman.jmx`), or use the fallback `hari-1/test-plans/04-rakaman-mentah.jmx` (the fallback has only 3 samplers — no tax check — and its token comes from another session, so step 1 already gives 200 / 401 / 401)
- README §1.6–1.7

### Steps
1. **First playback — without restarting the SUT:** Start ▶. Note the code of each step. (Expected: all 200 — a "false pass", the recording session is still alive.)

   ![View Results Tree first replay: all green](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-03-vrt-replay-pertama-200.png)
   *First replay without a restart: all green, `T02` = **200** — a "false pass" because the recording session is still alive.*

2. **Expire the session:** Terminal A → **Ctrl+C** → `node sut/server.js`.

   ![Terminal A: Ctrl+C and the SUT restarted](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-04-restart-sut.png)
   *Terminal A after **Ctrl+C** → restart: the `Portal eJPJ (TIRUAN) berjalan di …` banner appears again = all old sessions are gone. (this capture used our own mock instance on port 3917 and proxy 18888 so it would not disturb the class — you use 3000 / 8888)*

3. **Second playback:** click the **Clear All** icon (broom) on the toolbar, then Start ▶. Fill in the table:

   | Transaction | Code | Response message | `ralat` message in Response data |
   |-----------|-----|------------------|-----------------------------------|
   | T01_LogMasuk | | | |
   | T02_SenaraiKenderaan | | | |
   | T03_SemakCukai | | | |
   | T04_BayarCukai | | | |

   ![View Results Tree second replay: T02 401 Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-05-vrt-t02-401.png)
   *Second replay: `T01` green, `T02` red — **Sampler result** `Response code:401`, `Response message:Unauthorized`; `T03` green, `T04` red.*

4. Click `T02` (red) → **Request** tab: compare the `Authorization: Bearer …` value with the **token** in the `T01` **Response data**. Same or different?

   ![T02 Request tab: Authorization Bearer old token](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-06-request-t02-bearer-lama.png)
   *`T02` **Request → Request Headers** tab: the token that was **sent** (the recorded one). (this capture used our own mock instance on port 3917 and proxy 18888 so it would not disturb the class — you use 3000 / 8888)*

   ![T01 Response data: new token from the server](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-07-response-t01-token-baru.png)
   *`T01` **Response data** tab: the **new** `token` issued by the server — not the same as the token in the `T02` Request tab.*

5. **403 experiment (token only):** **Right-click the login sampler → Add → Post Processors → JSON Extractor**: Names `token`, JSON Path `$.token`, Match No. `1`, Default `TOKEN_TAK_JUMPA`. In the `T02` **and** `T04` Header Managers, change the `Authorization` value to `Bearer ${token}`. Do **not** touch `csrf`. Start ▶.

   ![JSON Extractor token $.token TOKEN_TAK_JUMPA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-08-json-extractor-token.png)
   ***JSON Extractor** as a child of the login sampler: Names `token`, JSON Path `$.token`, Match No. `1`, Default `TOKEN_TAK_JUMPA`.*

   ![T04 Header Manager: Authorization Bearer ${token}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-09-header-bearer-token-var.png)
   *`T04` (and `T02`) Header Manager: `Authorization` = `Bearer ${token}`. The `csrf` in the body is untouched.*

6. Note: `T02` = ?, `T04` = ? and the `T04` error message.

   ![View Results Tree: T02 green, T04 403 Forbidden](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-10-vrt-t04-403.png)
   *With only the token correlated: `T02` green (200), `T04` red — `Response code:403`.*

   ![T04 Response data: Token CSRF tidak sah](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-11-t04-403-csrf-tidak-sah.png)
   *`T04` Response data: `{"ralat":"Token CSRF tidak sah — sila log masuk semula"}` — the cause is now `csrf`, not the token.*

7. Compare with the non-GUI fallback (Terminal B, repo root):
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l hasil/r04.jtl
   # summary = 3 ... Err: 2 (66.67%)
   ```

   ![jmeter -n 04-rakaman-mentah: summary 3 Err 2 66.67%](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-12-nogui-r04-summary.png)
   *Real non-GUI run of backup `04`: `summary = 3 … Err: 2 (66.67%)`. (this capture used our own mock instance on port 3917 and proxy 18888 so it would not disturb the class — you use 3000 / 8888)*

8. Save the plan (**File → Save**) — it becomes the starting point for Lab 3.

   ![JMeter File menu: Save and Save Test Plan as](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-13-menu-file.png)
   ***File** menu: **Save** (⌘S / Ctrl+S) writes the same file; **Save Test Plan as** for a new name.*

![View Results Tree: log-masuk green, kenderaan and bayar-cukai red](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-01-vrt-401-merah.png)
*Replay after the SUT restart: **View Results Tree** — `/api/log-masuk` green (200), `/api/kenderaan` and `/api/kenderaan/WXY1234/bayar-cukai` red (**401**). Click a red sampler → **Sampler result** / **Request** / **Response data** tabs to investigate.*

![Replay HTML dashboard: Statistics and Errors 401/Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-02-dashboard-statistics-errors-401.png)
*The same replay in non-GUI mode (`-e -o`): **Statistics** shows Error % 66.67% (2 of 3), **Errors** = `401/Unauthorized` × 2 — matching `summary = 3 ... Err: 2 (66.67%)`.*

### ✅ Checkpoint
- [ ] Playback without a restart shows 4 × 200 and you can explain why it is a "false pass"
- [ ] After restarting the SUT: login **200**, list **401**, tax check **200**, payment **401** — recorded in the table
- [ ] The **Request** tab was used to prove that the token sent ≠ the token just issued
- [ ] With only `token` correlated, payment becomes **403** `Token CSRF tidak sah — sila log masuk semula`
- [ ] Passed **Quiz S1** (at least half correct) (Kuiz S1)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| All 200 even after a "restart" | The SUT was not really restarted (the old process is still running) | Make sure Ctrl+C stops the process; Terminal A shows the start-up message again |
| All samplers `Non HTTP response code: java.net.ConnectException` | The SUT is not running | Terminal A: `node sut/server.js` |
| `T03_SemakCukai` green — "shouldn't everything fail?" | The quote endpoint does not require a token | Correct — that is exactly why we need assertions & a check on every step, not just "something is green" |
| 403 experiment still gives 401 | The `Authorization` header in `T04` has not been changed, or there is no space after `Bearer` | The value must be `Bearer ${token}` in **every** relevant Header Manager |
| `Bearer TOKEN_TAK_JUMPA` in the Request tab | The JSON Extractor is not a child of the login sampler | Drag the extractor under the login sampler |

---

## Lab 3 — Make the recording replayable

**Session:** S2

### 🎯 Objective
- Correlate `token` + `csrf` and the vehicle data, and parameterise users with CSV (O3)
- Name the samplers, wrap them in a Transaction Controller, add random think time and assertions (O4)
- Run 10 users × 2 loops and read the Summary & Aggregate Report (O4)

### Prerequisites
- Lab 2 completed (plan with `token` correlated). If you use the fallback `04-rakaman-mentah` (3 samplers, no quote): step 4 skips the quote path, and the 10 × 2 run gives **60** HTTP samples, not 80
- README §2.1–2.9; open `test-plans/05-transaksi-penuh.jmx` in another tab as the answer key

### Steps
1. **File → Save As** → `hari-2/test-plans/latihan-03-boleh-main-balik.jmx`.

   ![JMeter File menu: Save Test Plan as](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab2-13-menu-file.png)
   ***File → Save Test Plan as** → `latihan-03-boleh-main-balik.jmx`.*

2. **Correlate `csrf`:** open the login JSON Extractor → Names `token;csrf`, JSON Path `$.token;$.csrf`, Match No. `1;1`, Default `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`. In the payment body, change the `csrf` value to `${csrf}`.

   ![JSON Extractor token;csrf](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-01-json-extractor-token-csrf.png)
   *Login JSON Extractor: Names `token;csrf`, JSON Path `$.token;$.csrf`, Match No. `1;1`, Default `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`.*

   ![Pay body: csrf ${csrf}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-02-body-bayar-csrf-var.png)
   *Pay sampler body: `"csrf":"${csrf}"`.*

3. **Parameterisation:** **Right-click Thread Group → Add → Config Element → CSV Data Set Config**: Filename `../data/pengguna.csv`, Variable Names `no_kp,kata_laluan`, Ignore first line `True`, Recycle on EOF `True`, Sharing mode `All threads`. Login body → `{ "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }`; the list sampler's `no_kp` parameter → `${no_kp}`.

   ![CSV Data Set Config pengguna.csv no_kp,kata_laluan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-03-csv-data-set-config.png)
   ***CSV Data Set Config** under the Thread Group: `../data/pengguna.csv`, `no_kp,kata_laluan`, Ignore first line `True`, Recycle on EOF `True`, Sharing mode `All threads`.*

   ![Login body using ${no_kp} and ${kata_laluan}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-04-body-log-masuk-csv.png)
   *Login body: `{ "no_kp": "${no_kp}", "kata_laluan": "${kata_laluan}" }`.*

   ![List sampler: no_kp parameter ${no_kp}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-05-parameter-no-kp.png)
   *List sampler, **Parameters** tab: `no_kp` = `${no_kp}`.*

4. **Chained correlation:** **Right-click the list sampler → Add → Post Processors → JSON Extractor** (`Ekstrak kenderaan pertama`): Names `no_pendaftaran;amaun`, Paths `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai`, Match No. `1;1`, Default `NONE;0`. Change the quote path → `/api/kenderaan/${no_pendaftaran}/cukai`, the payment path → `/api/kenderaan/${no_pendaftaran}/bayar-cukai`, the payment body → `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": ${amaun} }`.

   ![JSON Extractor Ekstrak kenderaan pertama](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-06-ekstrak-kenderaan-pertama.png)
   *`Ekstrak kenderaan pertama` under the list sampler: `no_pendaftaran;amaun`, `$.kenderaan[0].no_pendaftaran;$.kenderaan[0].amaun_cukai`, `1;1`, `NONE;0`.*

   ![Pay sampler: path ${no_pendaftaran} and body ${amaun}](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-07-bayar-path-body-berantai.png)
   *Pay sampler: Path `/api/kenderaan/${no_pendaftaran}/bayar-cukai`, body `{ "csrf": "${csrf}", "tempoh_bulan": 12, "amaun": ${amaun} }`.*

5. **Names:** rename the samplers `1. POST /api/log-masuk`, `2. GET /api/kenderaan`, `3. GET /api/kenderaan/${no_pendaftaran}/cukai`, `4. POST /api/kenderaan/${no_pendaftaran}/bayar-cukai`.

   ![Samplers renamed 1. to 4.](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-08-nama-sampler-1-4.png)
   *After renaming: `1. POST /api/log-masuk`, `2. GET /api/kenderaan`, `3. GET …/${no_pendaftaran}/cukai`, `4. POST …/${no_pendaftaran}/bayar-cukai`.*

6. **Transaction Controller:** **Right-click Thread Group → Add → Logic Controller → Transaction Controller** `Pembaharuan Cukai Jalan`. Drag the Recording Controller (or all four samplers) **into it**. Leave *Generate parent sample* and *Include duration of timer…* **unticked**.

   ![Transaction Controller Pembaharuan Cukai Jalan containing the Recording Controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-09-transaction-controller-pembaharuan.png)
   *Transaction Controller `Pembaharuan Cukai Jalan` — the Recording Controller has been dragged inside; both checkboxes unticked.*

7. **Think time:** delete the recorded Constant Timer (one under the first sampler of each group, values such as `6012`). **Right-click Transaction Controller `Pembaharuan Cukai Jalan` → Add → Timer → Uniform Random Timer** (`Think Time (1-3s)`): Random Delay Maximum `2000`, Constant Delay Offset `1000`. The timer becomes a child of that TC, level with the samplers (same as `05`) — not under `T01…T04` and not a child of a sampler. Scope = all 4 samplers in the TC → 4 pauses per iteration (under the Thread Group gives the same effect here, because every sampler is inside the TC).

   ![Uniform Random Timer Think Time as a Transaction Controller child](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-10-uniform-random-timer-tc.png)
   *`Think Time (1-3s)` (Uniform Random Timer, `2000` / `1000`) — a direct child of `Pembaharuan Cukai Jalan`, level with the Recording Controller; the recorded Constant Timers are deleted.*

8. **Assertion:** **Right-click the payment sampler → Add → Assertions → Response Assertion**: Text Response, Substring, pattern `BERJAYA`.

   ![Response Assertion Substring BERJAYA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-11-response-assertion-berjaya.png)
   ***Response Assertion** under the pay sampler: Text Response, Substring, `BERJAYA`.*

9. **(Recommended) If Controller:** **Right-click Transaction Controller `Pembaharuan Cukai Jalan` → Add → Logic Controller → If Controller** `Jika ada kenderaan`, Condition `${__groovy(vars.get("no_pendaftaran") != "NONE" && vars.get("token") != "TOKEN_TAK_JUMPA")}`; drag samplers 3 & 4 into it.

   ![If Controller Jika ada kenderaan with __groovy](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-12-if-controller-jika-ada-kenderaan.png)
   *If Controller `Jika ada kenderaan` (Interpret Condition as Variable Expression ticked) — steps 3 & 4 (`T03_SemakCukai`, `T04_BayarCukai`) dragged inside.*

10. **Functional test first:** Thread Group 1 user, 1 loop, View Results Tree enabled. Start → all green, the payment Request contains the real token/csrf.

    ![View Results Tree functional test all green, pay Request body](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-13-vrt-bayar-csrf-sebenar.png)
    *Functional test 1 user × 1 loop: all green; the pay Request sends the real `csrf` + `amaun` from the extractor. (this capture used our own mock instance on port 3917 and proxy 18888 so it would not disturb the class — you use 3000 / 8888)*

11. **Small run:** Thread Group `10` users, Ramp-up `10`, Loop Count `2`. **Disable** View Results Tree. **Add → Listener → Summary Report** and **Aggregate Report**. Start.

    ![Thread Group 10 users ramp-up 10 loop 2](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-14-thread-group-10-10-2.png)
    *Thread Group: `10` users, Ramp-up `10`, Loop Count `2`.*

    ![Summary Report small run](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-15-summary-report.png)
    *Summary Report after the small run (View Results Tree disabled — greyed out in the tree).*

12. Note from the Aggregate Report: # Samples for the `Pembaharuan Cukai Jalan` row and the total samples of the 4 steps; Average, 95% Line of the transaction row; Error %.

    ![Aggregate Report: Pembaharuan Cukai Jalan row 20 samples](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab3-16-aggregate-report.png)
    *Aggregate Report: `Pembaharuan Cukai Jalan` = 20 samples (10 users × 2 loops), transaction Average/95% Line, Error % 0. The sampler 3 & 4 labels split per vehicle because the names contain `${no_pendaftaran}`.*

> Compare with [`test-plans/05-transaksi-penuh.jmx`](../test-plans/05-transaksi-penuh.jmx) (verified: 80 HTTP samples + 20 transaction rows, 0% errors; transaction ≈ 440 ms).

![JSON Extractor Ekstrak token + csrf dalam plan 05](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-27-gui-json-extractor-05.png)
*The JSON Extractor captures token and csrf from the login response (step 2). Read the right-hand panel — the tree rows that are also highlighted are a screenshot artefact.*

![Transaction Controller Pembaharuan Cukai Jalan dalam plan 05](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-28-gui-transaction-controller-05.png)
*The Transaction Controller groups the renewal steps into one measurable transaction (step 6) — both options unticked.*

![Jadual Statistics plan 05 dengan baris transaksi Pembaharuan Cukai Jalan](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-24-transaction-statistics-05.png)
*The Transaction Controller adds one business-level row: the overall renewal time (≈ 449 ms = sum of the 4 steps; think time is not counted).*

### ✅ Checkpoint
- [ ] `token`, `csrf`, `no_pendaftaran` and `amaun` are extracted at run time — no recorded values left in headers/body/path
- [ ] The CSV `pengguna.csv` supplies 3 different `no_kp` values (see the Request or the different vehicle labels: `WXY1234`, `JQK7788`, `BMT3030`)
- [ ] Samplers renamed, wrapped in the Transaction Controller `Pembaharuan Cukai Jalan`, with a Uniform Random Timer and Response Assertion `BERJAYA`
- [ ] 10 × 2 run: **80** HTTP samples + **20** transaction rows in the Aggregate Report, Error % ≈ 0 (≤ 1 synthetic 500 error accepted)
- [ ] Passed **Quiz S2** (at least half correct) (Kuiz S2)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `${no_kp}` sent literally | CSV not found — plan not saved in `hari-2/test-plans/` | Save As into that folder; or use an absolute path |
| Login **401** `No. KP atau kata laluan tidak sah` | Empty body / no `Content-Type: application/json` | Check the login sampler's Header Manager (recorded) or add one at Thread Group level |
| Payment **403** | `csrf` not yet correlated / misspelt `${csrf}` | Extractor Names & Paths must have the same count, separated by `;` |
| Path `/api/kenderaan/NONE/cukai` → 404 | The vehicle extractor is not a child of the list sampler | Drag the extractor under `2. GET /api/kenderaan` |
| Payment 400/500 with a literal `"amaun": ${amaun}` | `amaun` not extracted | Two names, two paths: `no_pendaftaran;amaun` |
| No transaction row | Samplers are **below**, not **inside**, the Transaction Controller | Drag the samplers onto the controller name |
| Run is very slow | The recorded Constant Timer `${T}` (6 s+) is still there | Delete the recorded timer; use the Uniform Random Timer |
| Occasionally 1 error 500 | The SUT's 1% `ERROR_RATE` — intentional | Expected behaviour; for a clean run: `ERROR_RATE=0 node sut/server.js` |

### ⭐ Challenge
1. Replace the `token` JSON Extractor with a **Regular Expression Extractor** (`"token":"([^"]+)"`, Template `$1$`) or a **Boundary Extractor** (Left `"token":"`, Right `"`). The result must be the same.
2. Take `amaun` + `tempoh_bulan` from the **quote** response (`$.amaun;$.tempoh_bulan`) as plan `07` does.
3. Open [`08-foreach-kenderaan.jmx`](../test-plans/08-foreach-kenderaan.jmx): Match No. `-1` + ForEach Controller → 3 users pay for **5** vehicles (16 HTTP samples). Untick *Add "_" before number ?* and observe 0 iterations with no error.
4. Add a **JSR223 PostProcessor** (Groovy, *Cache compiled script if available*) from block "2)" in [`jsr223-groovy.groovy`](./jsr223-groovy.groovy) under the login.

---

## Lab 4 — Generate the HTML dashboard & read every section

**Session:** S3

### 🎯 Objective
- Generate the HTML dashboard during a run (`-e -o`) and afterwards from a `.jtl` (`-g -o`) (O5)
- Adjust graph granularity with `-Jjmeter.reportgenerator.overall_granularity` (O5)
- Record real values and interpret every dashboard section using the correct terms (O6)

### Prerequisites
- SUT running; **stop** any GUI run (you may leave the GUI open without a run)
- `jmeter --version` shows 5.6.x
- README §3.1–3.5

### Steps
1. Terminal B, from the repo root — run your clean recorded plan (or the `05` reference) in non-GUI mode:
   ```bash
   mkdir -p hasil                    # Windows: mkdir hasil — folder induk -o mesti wujud
   jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx \
     -l hasil/r05.jtl -e -o hasil/laporan05
   ```
   (Lab 3 plan: replace `05-transaksi-penuh.jmx` with `latihan-03-boleh-main-balik.jmx` — make sure View Results Tree is **disabled**.)

   ![jmeter -n plan 05 with -e -o: summary 80 samples 0 errors](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-01-nogui-r05-summary.png)
   *Real non-GUI run of plan `05` with `-e -o`: `summary = 80 … Err: 0 (0.00%)`. (this capture ran against our own mock instance on port 3917 so it would not disturb the class — you use 3000)*

2. Look at the `summary =` line in the terminal (total samples, `Err:`). Open `hasil/laporan05/index.html`.

   ![hasil/laporan05/index.html: Test and Report information, APDEX, Requests Summary](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-02-laporan05-index.png)
   *`hasil/laporan05/index.html`: Source file `r05.jtl`, Start/End Time, APDEX per label and Requests Summary (PASS 100%).*

3. Generate a **second** dashboard from the same `.jtl` with a graph point every 5 s:
   ```bash
   jmeter -g hasil/r05.jtl -o hasil/laporan05-5s \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```
   Compare *Charts → Over Time → Response Times Over Time* in both reports.

   ![jmeter -g to laporan05-5s succeeds](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-03-jmeter-g-5s.png)
   *`jmeter -g` from the same `.jtl` → a new `hasil/laporan05-5s` folder (no output on success).*

   ![Response Times Over Time laporan05 default granularity](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-04-rt-over-time-1s.png)
   *`laporan05` — Response Times Over Time at the default granularity.*

   ![Response Times Over Time laporan05-5s granularity 5 sec](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-05-rt-over-time-5s.png)
   *`laporan05-5s` — x-axis `granularity: 5 sec`: fewer points, smoother lines.*

4. Try generating into `hasil/laporan05-5s` once more — note the error message.

   ![Second jmeter -g: Cannot write ... folder is not empty](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-06-folder-not-empty.png)
   *Generating a second time into the same folder: `An error occurred: Cannot write to '…/hasil/laporan05-5s' as folder is not empty`.*

5. Fill in the **worksheet** with **real** values from your dashboard:

   | # | Section | What you record | Your value | Interpretation (1 sentence) |
   |---|----------|---------------------|------------|-------------------|
   | 1 | Test and Report information | Source file, Start/End Time | | Complete run? |
   | 2 | APDEX | Total; transaction row; T & F | | Why is the transaction < 1.0? |
   | 3 | Requests Summary | PASS % / FAIL % | | |
   | 4 | Statistics — Total | #Samples, Error %, Average, 95th pct, Transactions/s | | Does Total include transactions? |
   | 5 | Statistics — transaction row | #Samples, Average, Median, 90th/95th/99th pct, Max | | Gap from Median → 99th? |
   | 6 | Statistics — slowest step | Label + 95th pct | | |
   | 7 | Errors / Top 5 Errors by sampler | Error type, count | | |
   | 8 | Over Time → Active Threads Over Time | Ramp-up shape | | Did the load model happen? |
   | 9 | Over Time → Response Time Percentiles Over Time | Early vs late p95 | | Stable? |
   | 10 | Throughput → Hits Per Second vs Transactions Per Second (series `Pembaharuan Cukai Jalan-success`) | Ratio | | Why ≈ 4 : 1? (Hits vs **Total** Transactions Per Second is ≈ 4 : 5 — Total also counts the transaction rows) |
   | 11 | Throughput → Codes Per Second | Codes that appear | | |
   | 12 | Response Times → Response Time Overview | Count in each bar | | |
   | 13 | Response Times → Response Time Distribution | Most frequent range | | |
   | 14 | Latency vs Response time (`.jtl` or Latencies Over Time) | One login sample | | Time on the server or in transfer? |

   ![laporan05 Statistics: Total and the Pembaharuan Cukai Jalan row](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-07-statistics-laporan05.png)
   *The real `laporan05` Statistics table — the source for worksheet #4–#6 (Total, the `Pembaharuan Cukai Jalan` transaction row, slowest step).*

6. Open `hasil/laporan05/statistics.json` in an editor; find `pct2ResTime` for `Pembaharuan Cukai Jalan` and confirm it matches the **95th pct** in the table.

   ![statistics.json Pembaharuan Cukai Jalan pct2ResTime](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab4-08-statistics-json-pct2.png)
   *The `Pembaharuan Cukai Jalan` entry in `statistics.json` (shown with `jq`; an editor works too): `pct2ResTime` = the table's 95th pct.*

**Visual reference for the worksheet** (real example from the peak run `07`, 50 users — your numbers for `05` will differ; the screens look the same):

![Dashboard: Test and Report information, APDEX dan Requests Summary](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-10-dashboard-info-apdex.png)
*#1–#3 — The first screen of the HTML dashboard: run information, APDEX per label and the pass/fail breakdown.*

![Jadual Statistics larian puncak](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-12-statistics-table.png)
*#4–#6 — Statistics table: read p90/p95/p99 and Error % first, then throughput.*

![Active Threads Over Time: ramp-up 0 ke 50 dalam 10 s](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-16-active-threads-over-time.png)
*#8 — Active Threads Over Time: confirm the load model (ramp-up, hold) actually happened.*

![Response Times Over Time setiap label](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-15-response-times-over-time.png)
*#9 — Response Times Over Time: the transaction line sits above the individual requests. (Percentiles Over Time is read the same way — stable or rising?)*

![Transactions Per Second setiap label](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-17-transactions-per-second.png)
*#10–#11 — Transactions Per Second for each label (success / failure series).*

![Lengkung Response Time Percentiles](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-18-response-time-percentiles.png)
*#12 — Percentile curve: read p90/p95 on the x-axis. The transaction tail rises near p99.*

![Response Time Distribution](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-19-response-time-distribution.png)
*#13 — Response Time Distribution: the number of samples in each time range.*

![Latencies Over Time](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-20-latencies-over-time.png)
*#14 — Latencies Over Time: time to first byte, compared with the full response time.*

### ✅ Checkpoint
- [ ] `hasil/laporan05/index.html` generated with `-e -o` and opened
- [ ] Second dashboard generated with `-g … -o` and `overall_granularity=5000`; you can explain the difference in the number of graph points
- [ ] The 14-row worksheet filled in with real values and a one-sentence interpretation for each
- [ ] You can explain why the Statistics **Total** ≠ a sum that includes the transaction rows, and why failed samples count as Frustrated in APDEX
- [ ] Passed **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `Cannot write to '…' as folder is not empty` | The `-o` folder already exists | Use a new folder, or delete the old one |
| `… as folder does not exist and parent folder is not writable` | The parent folder (`hasil/`) does not exist yet — JMeter checks before the test starts | `mkdir -p hasil` (Windows: `mkdir hasil`), then repeat |
| `jmeter: command not found` | JMeter is not on the PATH | Day 1 — Setup; or use the full path `…/bin/jmeter` |
| Over Time graphs show only 1–2 points | Default granularity is 60 s | Regenerate with `-Jjmeter.reportgenerator.overall_granularity=5000` |
| Dashboard empty / no rows | Empty `.jtl` — SUT down or the plan failed early | Check `summary =` and `jmeter.log` |
| Your plan: all samples `Non HTTP response code` | The recorded samplers have no Server/Port (recorded together with HTTP Request Defaults) but those Defaults were deleted/disabled | Make sure HTTP Request Defaults `localhost`/`3000` is enabled in the plan |

---

## Lab 5 — Peak scenario `07` + SLA → three findings

**Session:** S3

### 🎯 Objective
- Run the peak scenario `07` with two SLA thresholds and compare the reports (O7)
- Trace SLA breaches in Statistics, Errors, Top 5 Errors and Transactions Per Second (O7)
- Write three findings (evidence → impact → cause → recommendation) in the report template (O7)

### Prerequisites
- Lab 4 completed; the normal SUT running (`node sut/server.js`)
- [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) open — read the part B example
- README §3.6–3.8

### Steps
1. Open `07-beban-puncak-cukai.jmx` in the GUI **once** to see: Thread Group `${__P(pengguna,300)}`, Transaction Controller `Pembaharuan Cukai Jalan (Puncak)`, Duration Assertion `${__P(sla_ms,2000)}`, Think Time Rush 0.5–1.5 s. Do not Start in the GUI.

   ![Plan 07 Thread Group Lonjakan Pembaharuan Cukai with __P(pengguna,300)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-01-plan07-thread-group.png)
   *Plan `07` — Thread Group `Lonjakan Pembaharuan Cukai`: Number of Threads `${__P(pengguna,300)}`, ramp-up/duration also from `-J`.*

   ![Duration Assertion SLA Bayaran __P(sla_ms,2000)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-02-plan07-duration-assertion.png)
   *Duration Assertion `SLA Bayaran < ${__P(sla_ms,2000)}ms` under the pay sampler; `Think Time Rush (0.5-1.5s)` at the end of the TC.*

2. **R1 — SLA 2000 ms** (≈ 1 minute):
   ```bash
   jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
     -l hasil/r07-sla2000.jtl -e -o hasil/laporan07-sla2000 \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```

   ![R1 SLA 2000 ms: summary 2446 samples](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-03-r1-sla2000-summary.png)
   *Real R1: `summary = 2446 in 00:01:00 … Err: 3 (0.12%)` — only the synthetic 500s. (this capture ran against our own mock instance on port 3917 so it would not disturb the class — you use 3000)*

3. **R2 — SLA 150 ms**, same system:
   ```bash
   jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
     -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=150 \
     -l hasil/r07-sla150.jtl -e -o hasil/laporan07-sla150 \
     -Jjmeter.reportgenerator.overall_granularity=5000
   ```

   ![R2 SLA 150 ms: summary with higher Err](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-04-r2-sla150-summary.png)
   *Real R2, same system: `Err: 163 (6.83%)` — the strict SLA turns slow responses into errors. (this capture ran against our own mock instance on port 3917 so it would not disturb the class — you use 3000)*

4. Fill in the comparison table:

   | Metric (row `Pembaharuan Cukai Jalan (Puncak)`) | R1 (2000 ms) | R2 (150 ms) |
   |---------------------------------------------------|-------------:|------------:|
   | #Samples | | |
   | Error % | | |
   | 95th pct (ms) | | |
   | Transactions/s | | |
   | APDEX (transaction row) | | |
   | Error % `Total` | | |

   (Our reference run: R1 → 598 samples, 1.00%, 583 ms, 10.46/s, APDEX 0.862; R2 → 607 samples, **21.75%**, 572 ms, 10.54/s, APDEX 0.717.)

   ![R1 Statistics SLA 2000 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-05-r1-statistics.png)
   *R1 Statistics (2000 ms): the `Pembaharuan Cukai Jalan (Puncak)` row — #Samples, Error %, 95th pct, Transactions/s for the comparison table.*

   ![R2 Statistics SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-06-r2-statistics.png)
   *R2 Statistics (150 ms): Error % rises on the pay samplers and the transaction row.*

5. In R2, open **Errors**: how many `The operation lasted too long…` rows are there? Why so many? Open **Top 5 Errors by sampler** and **Charts → Throughput → Codes Per Second** — is there only code `200`? Why?

   ![R2 Errors: many The operation lasted too long rows](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-07-r2-errors-operation-lasted-too-long.png)
   *R2 Errors (top only): one row per ms value `The operation lasted too long: It took … milliseconds` — hence many rows; `500/Internal Server Error` sits among them.*

   ![R2 Codes Per Second](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-08-r2-codes-per-second.png)
   *R2 Codes Per Second: almost all `200` — an SLA breach is an **assertion** failure, not an HTTP code.*

6. **Quick Little's Law:** with R1's Transactions/s, R ≈ the transaction Average (s), Z ≈ 4 s → compute X × (R + Z). Compare with Active Threads Over Time.

   ![R1 Active Threads Over Time: ramp 0 to 50](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-09-r1-active-threads.png)
   *R1 Active Threads Over Time: rises to 50 in ~10 s — compare with N = X × (R + Z).*

7. Copy part **A** of `templat-laporan-ujian.md` to `hasil/laporan-pasangan-<nama>.md` and write **three findings** using **your** numbers (suggested: F1 response time vs NFR, F2 500 errors & Error %, F3 effect of the SLA threshold).

   ![Copy templat-laporan-ujian.md into hasil](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-10-salin-templat-laporan.png)
   *Copy the report template to `hasil/laporan-pasangan-<nama>.md`; sections **A1–A8** are the blank template.*

   ![Report template section A5 Findings](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-11-templat-a5-dapatan.png)
   *Section **A5. Dapatan** (findings): write D1–D3 using numbers from your own run.*

**Visual reference for R2 (SLA 150 ms)** — our real run:

![Statistics larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-26-statistics-sla-breach.png)
*A stricter SLA (150 ms) turns slow responses into Error %, without any code change.*

![APDEX larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-14-apdex-sla-breach.png)
*The APDEX score drops for labels that fail the SLA.*

![Jadual Errors larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-13-errors-table.png)
*Errors table: SLA breaches flagged by the Duration Assertion count as errors. One row per message, so the same error is split across rows (step 5).*

![Top 5 Errors by sampler larian SLA 150 ms](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-25-top5-errors-by-sampler.png)
*Top 5 Errors by sampler: shows which request breaches the SLA — only the 3 `bayar-cukai` POSTs.*

### ✅ Checkpoint
- [ ] Two `07` reports generated (`laporan07-sla2000`, `laporan07-sla150`) with 5 s granularity
- [ ] The R1 vs R2 comparison table filled in and you can explain why Error % rises even though the response times are the same
- [ ] You point to three places where the SLA breach is visible (Statistics/Error %, Errors/Top 5, the Transactions Per Second `-failure` series) and why *Codes Per Second* does not show it
- [ ] Three findings written with evidence (numbers + dashboard section), impact, cause and recommendation
- [ ] Passed **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| R2 Error % same as R1 | `-Jsla_ms` written with a space (`-J sla_ms=150`) or as `-D` | Write `-Jsla_ms=150` with no space |
| Laptop very slow / loud fan | JMeter + SUT on the same machine | Reduce to `-Jpengguna=25`; note it as a limitation in the report |
| `folder is not empty` | `-o` folder name reused | A new name for every run |
| R1 Error % > 1% | The SUT's 1% synthetic 500 errors | Normal at the boundary — that is your finding F2 |
| A finding reads "system OK" | No numbers/evidence | Every finding: numbers + dashboard section name |

### ⭐ Challenge
1. **R3 — slow mock without disturbing the main SUT:** Terminal C: `PORT=3001 LATENCY_MIN=500 LATENCY_MAX=1500 node sut/server.js`, then run R1 with `-Jport=3001` into a new folder. Compare Transactions/s and p95 with R1, and verify Little's Law (our run: 5.78/s, p95 4969 ms). Stop Terminal C when done.
2. Regenerate R1 with `-Jjmeter.reportgenerator.apdex_satisfied_threshold=300 -Jjmeter.reportgenerator.apdex_tolerated_threshold=1000`. How does APDEX change, and who should choose T/F?
3. Step-up stress: run R1 with `-Jpengguna=100` and `150`. Does throughput keep rising? What is the limit — the SUT or the laptop CPU?

---

## Lab 6 — Performance test planning + Little's Law

**Session:** S4

### 🎯 Objective
- Fill in a performance test plan: NFRs, load model, run types, criteria, monitoring, risks, authorisation (O8)
- Calculate the number of concurrent users with Little's Law and the pacing setting (O8)

### Prerequisites
- [`templat-pelan-ujian.md`](./templat-pelan-ujian.md) — read the completed eJPJ example
- README §4.1–4.7

### Steps
1. Copy the template to `hasil/pelan-pasangan-<nama>.md`.

   ![Copy templat-pelan-ujian.md into hasil](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-03-salin-templat-pelan.png)
   *Copy the template to `hasil/pelan-pasangan-<nama>.md` (example: `aminah`).*

2. Choose a scenario (pick one): **(a)** road tax renewal on a price-increase day (as in the example, change the numbers), **(b)** summons payment on the last day of a summons discount, **(c)** an internal system of your organisation (conceptually only — no runs).

   ![Plan template section 1 Background and objectives](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-04-pelan-latar-objektif.png)
   *Template section **1. Latar belakang & objektif** — adapt the scenario & Q1–Q4 to option (a), (b) or (c).*

3. Fill in sections 1–3: objectives (Q1–Q4), scope, and **at least 4 measurable NFRs**.

   ![Plan template section 3 NFR/SLA](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-05-pelan-nfr.png)
   *Section **3. NFR / SLA**: every NFR has a transaction, load, percentile metric, threshold and duration.*

4. **Appendix A — Little's Law:** set the peak-hour volume V, compute X = V ÷ 3600, estimate R and Z, compute **N = X × (R + Z)**, the hits/s rate, and the **Constant Throughput Timer** setting (X × 60 samples/minute, as a child of the first sampler).

   ![Plan template Appendix A Little's Law worksheet](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-06-pelan-lampiran-a.png)
   ***Lampiran A** (Appendix A) — the Little's Law worksheet: V → X → N, hits/s and Constant Throughput Timer.*

5. **Check against lab data:** use R1 from Lab 5 — do 50 users × (R + 4 s) give the expected Transactions/s?

   ![R1 Statistics for the Little's Law cross-check](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab5-05-r1-statistics.png)
   *Lab 5 R1 data: take the transaction row's Transactions/s and Average to cross-check 50 users × (R + 4 s).*

6. Fill in section 5 (transaction mix), 8 (baseline → load → stress → spike → soak schedule with `-J` configuration), 9 (entry/exit/suspension criteria), 10 (monitoring), 11 (at least 3 risks) and 12 (authorisation & stop procedure).

   ![Plan template section 8 Test types and run schedule](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-07-pelan-jenis-ujian.png)
   *Section **8. Jenis ujian & jadual larian** (test types & run schedule): baseline → load → stress → spike → soak with `-J` config.*

![Test plan template: workload model and Little's Law](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-01-pelan-model-beban-littles-law.png)
*Filled example in `templat-pelan-ujian.md` §4.1–4.2: V = 36,000/hour → X = 10 transactions/s → **N = 10 × (2 + 58) = 600** concurrent users. Fill the ✍️ column with your scenario's numbers.*

![Test plan template: pacing and Appendix A](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab6-02-pelan-pacing-lampiran-a.png)
*§4.3 pacing (Constant Throughput Timer = X × 60 samples/minute) and **Appendix A** — the Little's Law worksheet you fill in step 4.*

### ✅ Checkpoint
- [ ] At least 4 NFRs written with transaction, load, percentile metric, threshold and duration
- [ ] Little's Law calculation complete: V → X → N, hits/s rate, and pacing setting
- [ ] Run-type schedule (baseline, load, stress, spike, soak) with JMeter configuration
- [ ] Entry/exit criteria, monitoring, 3 risks and the written authorisation section filled in
- [ ] Passed **Quiz S4** (at least half correct) (Kuiz S4)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| N very small (e.g. 10) for a large volume | Z forgotten (only R used) | N = X × (R **+ Z**); think time usually dominates |
| N makes no sense (millions) | Mixed units (minutes vs seconds) | Convert everything to **seconds** |
| Pacing does not reach the target | Constant Throughput Timer is in **samples/minute**, or threads < N | Target = X × 60; add threads |
| NFR "the system must be stable" | Not measurable | Add metric + threshold + load + duration |

---

## Lab 7 — Mini presentation (pairs)

**Session:** S4

### 🎯 Objective
- Present the test plan and one report finding to "management" in 3 minutes (O9)

### Prerequisites
- Lab 5 (findings) and Lab 6 (plan) completed

### Steps
1. Prepare 4 parts (maximum 45 seconds each):
   - **Key NFR** — one measurable sentence
   - **Load model** — X, R, Z → N (show the calculation)
   - **Run types** — the order and why baseline comes first
   - **One finding** from Lab 5 — Evidence (numbers + dashboard section) → Impact → Recommendation

   ![Plan template 4.2 Little's Law concurrent users](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-03-pelan-littles-law-n.png)
   *For the **Load model** part: the X, R, Z → N calculation from §4.2 of your plan.*

2. Close with one sentence: *"Before the real test, we need written authorisation from …"*

   ![Plan template section 12 Authorisation and ethics](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-04-pelan-kebenaran-etika.png)
   *Section **12. Kebenaran & etika** (authorisation & ethics) — the source of the closing "written authorisation from …" sentence.*

3. Present (another pair asks **one** question: "How do you know …?").
4. Note one piece of feedback you received.

![Report template: executive summary and results against NFRs](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-01-laporan-ringkasan-nfr.png)
*Presentation material: `templat-laporan-ujian.md` B1 (executive summary — one sentence + 3 key points) and B3 (results against NFRs with the dashboard source).*

![Report template: finding D2 evidence impact cause recommendation](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab7-02-laporan-dapatan-d2.png)
*Example for the "one finding" slot: **D2** — Evidence (numbers + dashboard section) → Impact → Cause → Recommendation.*

### ✅ Checkpoint
- [ ] Presentation ≤ 3 minutes covering the NFR, the N calculation, run types and one finding
- [ ] The finding is backed by real numbers and dashboard section names
- [ ] The other pair's question answered and one piece of feedback noted
- [ ] Passed **Quiz S4** (at least half correct) (Kuiz S4)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| Over time | Reading tables row by row | One key number per part |
| "This graph goes up…" with no conclusion | No impact/recommendation | End every finding with "so…" |
| No mention of authorisation | Forgot the ethics | Mandatory closing sentence (step 2) |

### ⭐ Challenge
1. **CI SLA gate:** run the `jq` + `awk` block in README §4.9 on `laporan07-sla2000` and `laporan07-sla150`; show the exit code (`echo $?`).
2. Explain in one minute how you would monitor a 4-hour soak test (Backend Listener + Grafana vs the HTML dashboard).

---

## Lab 8 — Multi-site report (distributed agents)

**Session:** S3

> 🎬 **5 Oct class: trainer demo (5 minutes)** — S3 time goes to Lab 9 (server CPU + chatbot). Watch the demo, then do this lab yourself as **homework** (all steps and screenshots are below); tick the checkpoint when done.

### 🎯 Objective
- Run one distributed test (1 controller + 2 `jmeter-server` agents representing the KL and PENANG sites) and generate **one combined report** (O5)
- Generate **per-site reports** from the same run by splitting the JTL by the `[LOKASI]` label prefix (O5)
- Compare sites (samples, Error %, average, p90/p95, TPS) and write **two site findings** (O6, O7)

### Prerequisites
- Lab 4 completed; README §3.9 read
- Java + JMeter 5.6.x (`jmeter --version`) and Node.js (`node --version`)
- Ports **3000, 3001, 1099, 1100, 4001, 4002** free — **stop the Terminal A SUT first** (the script starts its own SUTs on 3000 and 3001)
- Reference plan: [`../test-plans/09-berbilang-lokasi.jmx`](../test-plans/09-berbilang-lokasi.jmx); script: [`../run/run-berbilang-lokasi.sh`](../run/run-berbilang-lokasi.sh) (Windows: `run-berbilang-lokasi.bat`)

### Steps
1. **Run the script** (≈ 45 s; its output is cleaned on every run):
   ```bash
   cd hari-2/run
   ./run-berbilang-lokasi.sh            # Windows: run-berbilang-lokasi.bat
   ```
   Watch the console: 2 SUTs → 2 agents (`OK Ejen KL mendengar pada port 1099`) → `Configuring remote engine` × 2 → `summary` (arriving in bursts — sample sender StrippedBatch) → JTL split → comparison table.

   ![run-berbilang-lokasi.sh: 2 SUTs, 2 agents, Configuring remote engine, summary](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-01-skrip-berbilang-lokasi.png)
   *Real console: 2 SUTs → 2 agents (`OK Ejen KL mendengar …`) → `Configuring remote engine` × 2 → `summary = 240 …`. (this capture used a copy of the script with shifted ports — SUT 3927/3928, agents 11099/11100 — so it would not disturb the class; you will see 3000/3001 and 1099/1100)*

2. **Open the combined report** `hari-2/run/laporan/gabungan/index.html`:
   - **Statistics:** how many `[KL] …` and `[PENANG] …` rows are there? How many samples are in the **Total** row, and are the transaction rows counted in it?
   - **Charts → Over Time → Active Threads Over Time:** how many series? What are they called? (hint: the agents' `host:port`)

   ![Combined report Statistics with KL and PENANG rows](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-02-gabungan-statistics.png)
   *`gabungan` report — Statistics: `[KL] …` and `[PENANG] …` rows, plus Total.*

   ![Combined Active Threads Over Time: two host:port agent series](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-03-gabungan-active-threads.png)
   *Active Threads Over Time: **two series**, one per agent (`127.0.0.1:<port>-Pengguna Pembaharuan Cukai`), stacked to 20. (this capture used a copy of the script with shifted ports — SUT 3927/3928, agents 11099/11100 — so it would not disturb the class; you will see 3000/3001 and 1099/1100)*

3. **Open the per-site reports** `laporan/KL/index.html` and `laporan/PENANG/index.html`. Compare APDEX and the Response Times Over Time graph.

   ![KL report APDEX](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-04-kl-apdex.png)
   *`laporan/KL` — APDEX.*

   ![PENANG report APDEX](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-05-penang-apdex.png)
   *`laporan/PENANG` — lower APDEX because of the 300–900 ms latency.*

   ![KL report Response Times Over Time](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-06-kl-response-times.png)
   *`laporan/KL` — Response Times Over Time.*

   ![PENANG report Response Times Over Time](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-07-penang-response-times.png)
   *`laporan/PENANG` — Response Times Over Time: a much higher y-axis.*

4. **Fill in the comparison sheet** (copy from the console in step 6 of the script, or read each `statistics.json`):

   | Site | Label | Samples | Error % | Average ms | p90 ms | p95 ms | TPS |
   |--------|-------|-------:|--------:|----------:|-------:|-------:|----:|
   | KL | Pembaharuan Cukai Jalan (transaction) | | | | | | |
   | KL | TOTAL (HTTP samples) | | | | | | |
   | PENANG | Pembaharuan Cukai Jalan (transaction) | | | | | | |
   | PENANG | TOTAL (HTTP samples) | | | | | | |
   | Combined | Total (`gabungan` report) | | | | | | |

   (Our reference run: KL transaction 476 ms / p95 640 ms; PENANG 2430 ms / p95 3000 ms; combined Total 240 samples, average 363 ms, p95 873 ms, 6.90 TPS, 0% errors.)

   ![Script step 6: KL vs PENANG location comparison table](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-08-jadual-perbandingan-lokasi.png)
   *Script step 6 — the real comparison table: KL transaction ~446 ms vs PENANG ~2391 ms.*

5. **Write two site findings** in the "Perbandingan lokasi" (site comparison) section of [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) (Evidence → Impact → Cause → Recommendation). One finding must answer: *does the combined average give a true picture?*

   ![Report template A8 Location comparison](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab8-09-templat-a8-perbandingan-lokasi.png)
   *Section **A8. Perbandingan lokasi** (location comparison) in the report template — write the two findings here.*

![Active Threads Over Time satu lokasi](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-16-active-threads-over-time.png)
*Active Threads Over Time for a single run (one series). In the `gabungan` report the same graph shows **one series per agent** (`host:port`) — compare the ramp-up shape of each site (step 2).*

### ✅ Checkpoint
- [ ] The script finished without errors; `laporan/gabungan`, `laporan/KL` and `laporan/PENANG` exist
- [ ] You show the two Active Threads series (one per agent) and the per-site Statistics rows in the combined report
- [ ] You can explain total users = threads × number of agents, and the difference between `-G` (all agents) and `-J` (local)
- [ ] The comparison sheet filled in and two site findings written with your numbers
- [ ] Passed **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `Connection refused` / `Failed to configure 127.0.0.1:1099` | The agent is not listening yet, port 1099 is blocked by a firewall, or `server.rmi.localport` is not open | Check `hasil/ejen-KL/jmeter-server.log` and `hasil/konsol-ejen-KL.log`; open 1099 **and** 4001 (and 1100/4002); on real machines set `-Djava.rmi.server.hostname=<IP ejen>` |
| `rmi_keystore.jks (No such file or directory)` | RMI SSL enabled (the default) without a keystore | Lab: `-Jserver.rmi.ssl.disable=true` on the controller **and** the agents. Production: `bin/create-rmi-keystore.sh`, copy it to every machine |
| `Cannot start. <host> is a loopback address.` | Agent without `java.rmi.server.hostname` | Add `-Djava.rmi.server.hostname=127.0.0.1` (or the agent's IP) |
| Controller `summary = 0`; agent log `Could not read file header line for file …/pengguna.csv` | The CSV is missing on the **agent** (the path is read on the agent, not the controller) | Copy `hari-2/data/` to every agent and set `-Jdata_dir=<laluan>` |
| `jmeter-server: command not found` (macOS Homebrew) | Homebrew only links `jmeter` | The script finds it itself (`$JMETER_BIN`, `$JMETER_HOME/bin`, PATH, `$(brew --prefix jmeter)/libexec/bin`); manually: use that full path or `jmeter -s` |
| `RALAT: port 3001 sudah digunakan` | The R3 slow mock (Lab 5 Challenge) or another SUT is still running | `lsof -i :3001` (Windows: `netstat -ano \| findstr :3001`) and stop that process |
| "Over time" graphs shifted / `gabung` mode looks scattered | Agent machine clocks not synchronised (NTP) or different time zones | Synchronise NTP on every machine before the test; state it in the report |

### ⭐ Challenge
1. Run `./run-berbilang-lokasi.sh gabung` (each site runs on its own → `laporan-lokasi.js gabung` → `jmeter -g`). What is different in Active Threads Over Time compared with distributed mode?
2. Generate the KL report **without** splitting the JTL: `jmeter -g hasil/semua.jtl -o laporan/KL-tapis -Jjmeter.reportgenerator.sample_filter='^\[KL\].*'`. Compare Total with `laporan/KL`. Then try `series_filter='^\[KL\].*'` — why are the graphs empty? (README §3.9)
3. `PENGGUNA=20 GELUNG=5 ./run-berbilang-lokasi.sh` — how many users in total? Does the KL vs PENANG gap change?

---

## Lab 9 — Server CPU (PerfMon) + chatbot p95/p99

**Session:** S3

### 🎯 Objective
- Install the PerfMon plugin, start **ServerAgent** and collect server CPU/Memory into `perfmon.jtl` during a chatbot load test (O5)
- Read **Active Threads**, **CPU** and **Response Times Over Time** together to find the **knee point** and the bottleneck (O6)
- Explain p95 vs p99 with your chatbot numbers and write one **p95 + p99 NFR** + one finding (O6, O7)

### Prerequisites
- Lab 4 completed; README §3.10 and §3.11 read
- Java + JMeter 5.6.x, Node.js; the SUT in Terminal A (`node sut/server.js`) — the latest repo version (with `POST /api/chatbot`)
- Plugins: **jpgc-perfmon**, **jpgc-cmd**, **jpgc-graphs-basic** (Plugins Manager — README §3.10)
- ServerAgent 2.2.3: <https://github.com/undera/perfmon-agent/releases>; port **4444** free
- Reference plan: [`../test-plans/10b-chatbot-perfmon.jmx`](../test-plans/10b-chatbot-perfmon.jmx) (without the plugin: [`10-chatbot-beban.jmx`](../test-plans/10-chatbot-beban.jmx)); script: [`../run/run-chatbot-perfmon.sh`](../run/run-chatbot-perfmon.sh) (Windows: `run-chatbot-perfmon.bat`)

![Plugins Manager: PerfMon ticked in Available Plugins](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-03-plugins-manager-available-perfmon.png)
*Options → Plugins Manager → Available Plugins: tick "PerfMon (Servers Performance Monitoring)", "Command-Line Graph Plotting Tool" and "3 Basic Graphs"; Review Changes shows what will be installed → "Apply Changes and Restart JMeter".*

### Steps
1. **Try the chatbot once** (Terminal B):
   ```bash
   curl -s -X POST http://localhost:3000/api/chatbot -H 'Content-Type: application/json' \
     -d '{"soalan":"Bagaimana nak semak saman JPJ?"}'
   # {"jawapan":"Saman JPJ boleh disemak …","token_dijana":93,"masa_ms":784}
   ```
   Try it 5 times — notice that `masa_ms` follows `token_dijana` (≈ 5 ms per token).

   ![curl to /api/chatbot](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-05-curl-chatbot.png)
   *Three real questions to the mock chatbot (our run on port 3105; you use 3000): answers follow keywords, `masa_ms` grows with `token_dijana`.*
2. **Start ServerAgent** (Terminal C — in class, your laptop = the "server"):
   ```bash
   cd ServerAgent-2.2.3
   ./startAgent.sh --udp-port 0 --tcp-port 4444        # Windows: startAgent.bat --udp-port 0 --tcp-port 4444
   ```
   Wait for `JP@GC Agent v2.2.3 started`. Test: `telnet localhost 4444` → type `test` → `Yep` (Windows without telnet: `Test-NetConnection localhost -Port 4444` → `TcpTestSucceeded : True`).

   ![ServerAgent started](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-06-serveragent-mula.png)
   *Real ServerAgent: `Binding TCP to …` and `JP@GC Agent v2.2.3 started`, then `test` → `Yep`. Our Apple Silicon Mac: x86_64 Java (Temurin 8, Rosetta) + port 4445 + a localhost-only Java policy; on Windows/Linux x64 plain `startAgent.bat`/`startAgent.sh` is enough.*
3. **Open plan `10b` in the GUI** and check the **PerfMon Metrics Collector** (under the Test Plan): two rows (`CPU`, `Memory usedperc`), port `${__P(agent_port,4444)}`, Filename `${__P(perfmon_jtl,perfmon.jtl)}`. Do not run it in the GUI — close the GUI.

   ![PerfMon Metrics Collector in plan 10b](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-01-gui-perfmon-metrics-collector.png)
   *The PerfMon Metrics Collector configuration in plan `10b`.*

   🎬 **Trainer demo (optional):** Start briefly in the GUI (agent must be running) to watch CPU rise **live** as users ramp up — then Stop. The real measurement still uses the non-GUI script (step 4), because the GUI itself uses CPU.

   ![PerfMon Metrics Collector: live CPU rising to 100% as 20 users ramp up](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-10-gui-perfmon-live.png)
   *2-minute run in the GUI: CPU (red) climbs from ~20% to 100% as users are added; Memory (blue) flat ~93% (whole laptop).*
4. **Run the script** (≈ 3.5 minutes with the defaults; small laptop: `PENGGUNA=20 RAMPUP=60 TEMPOH=120`):
   ```bash
   cd hari-2/run
   ./run-chatbot-perfmon.sh            # Windows: run-chatbot-perfmon.bat (set JMETER_HOME first)
   ```
   Watch the console: `OK SUT`, `OK ServerAgent` → `summary` every 30 s → `OK cpu-perfmon.png` … → the summary table.

   ![run-chatbot-perfmon.sh console](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-02-konsol-ringkasan.png)
   *Our run's console (ports 3105/4445; your defaults are 3000/4444): the p50/p90/p95/p99 summary and average/max CPU.*
5. **Open the three PNGs** in `hari-2/run/hasil/<time>/`: `active-threads.png`, `cpu-perfmon.png`, `response-times-over-time.png`. Put them side by side (same time axis). Note: at **how many users** does CPU start to stay ≥ 80%? When does response time start to rise?

   ![Results folder contents](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-07-folder-hasil.png)
   *The `hasil/<time>/` folder after the script (short 10-user run): `keputusan.jtl`, `perfmon.jtl`, `laporan/`, three PNGs and `perfmon.csv`. `perfmon.jtl` rows: `elapsed` = value × 1000.*

   ![Three charts on the same time axis](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-cpu-threads-rt-bertindan.png)
   *Reference run: CPU ≥ 80% from ~31 users; response time rises after that.*
6. **Open the dashboard** `laporan/index.html` → Statistics (p95, p99, Error %) → Charts → Response Times → **Response Time Percentiles**. At which percentile does the curve "break" upwards?

   ![Statistics p95 and p99](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-chatbot-statistics-p95-p99.png)
   *Reference-run Statistics: 95th pct 1665 ms vs 99th pct 6076 ms.*

   ![Response Time Percentiles](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-chatbot-response-time-percentiles.png)
   *The curve breaks upwards after ~p95 — the long tail of chatbot answers.*
7. **Fill in the sheet:**

   | Item | You | Our reference |
   |------|-----|---------------|
   | Samples / Error % | | 1877 / 4.95% |
   | p50 / p95 / p99 (ms) | | 902 / 1665 / 6076 |
   | Average / max CPU | | 73% / 100% |
   | Users when CPU stays ≥ 80% | | ~31 |
   | Throughput at maximum load | | ~14 /s |

   ![Stacked charts for the sheet](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-30-cpu-threads-rt-bertindan.png)
   *Read the sheet values from the stacked charts: when CPU stays ≥ 80%, how many threads are active at that moment, and the response-time level.*
8. **Write an NFR + one finding** in [`templat-laporan-ujian.md`](./templat-laporan-ujian.md) (example B9): *"p95 ≤ … s and p99 ≤ … s at … concurrent users"* — pass or fail with your numbers? Include CPU as the **cause**.

   ![Example B9 and finding C1](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-08-laporan-b9-c1.png)
   *Filled-in example B9 + Finding C1 in `templat-laporan-ujian.md` (rendered): the p95/p99 NFR table per load level, then Evidence → Impact → Cause → Recommendation.*
9. **Stop ServerAgent** (Ctrl+C in Terminal C) as soon as you are done — the agent has no authentication.

   ![ServerAgent stopped](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h2-lab9-09-serveragent-henti.png)
   *A real Ctrl+C on the agent, then a check from another terminal: `Connection refused` = the port is closed.*

### ✅ Checkpoint
- [ ] `perfmon.jtl` has `localhost CPU` and `localhost Memory usedperc` rows; three PNGs + `laporan/index.html` generated
- [ ] You can show the knee point (users + time) using the three charts together and explain why CPU is not in the HTML dashboard
- [ ] You can explain p95 vs p99 in an "X out of 100 questions …" sentence and why p99 needs many samples
- [ ] One p95 + p99 NFR and one finding (Evidence → Impact → CPU cause → Recommendation) written with your numbers
- [ ] ServerAgent stopped after the test
- [ ] Answered questions 6–7 of **Quiz S3** (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `RALAT: ServerAgent tidak dapat dihubungi pada localhost:4444 (Connection refused)` / JMeter log `Connection refused` | Agent not started, a different port, or a firewall blocking 4444 | Start `startAgent.sh --tcp-port 4444`; make sure `-Jagent_port` = `--tcp-port`; `telnet <server> 4444` → `test` → `Yep`; open the firewall for the JMeter machine's IP only |
| Opening `10b` → `CannotResolveClassException: kg.apc.jmeter.perfmon.PerfMonCollector` | The jpgc-perfmon plugin is not installed | Plugins Manager → *PerfMon (Servers Performance Monitoring)* → restart; or use `10-chatbot-beban.jmx` (core only) |
| Windows Firewall / antivirus asks "Allow access" for Java | The agent opens a TCP port | Allow it for **Private** networks only; the localhost lab needs no outside access |
| Empty / 0 CPU in `perfmon.jtl` (macOS Apple Silicon); agent log `UnsatisfiedLinkError … Cpu.gather` | SIGAR in ServerAgent only ships an x86_64 library | Run the agent with an x86_64 Java (Rosetta), e.g. `/Library/Java/JavaVirtualMachines/temurin-8.jdk/…/java -jar CMDRunner.jar --tool PerfMonAgent --udp-port 0 --tcp-port 4444`; or run the agent on a Windows/Linux x64 machine |
| `perfmon.jtl` empty (header only) or missing | The collector cannot reach the agent, or the collector sits in a disabled Thread Group | Check `jmeter.log` (search `PerfMon`); place the collector under the Test Plan; check host/port |
| `JMeterPluginsCMD.sh: No such file` / `AMARAN: … tiada — PNG tidak akan dijana` | jpgc-cmd not installed, or the `jmeter` on PATH is not from `$JMETER_HOME/bin` (e.g. Homebrew) | Install jpgc-cmd + jpgc-graphs-basic; set `JMETER_HOME=<JMeter folder>` before running the script |
| High Error % (> 5%) with the message `The operation lasted too long` | The 3000 ms SLA is breached — long answers / saturated server | That is a finding, not a bug. To compare: `SLA_MS=10000 ./run-chatbot-perfmon.sh` |
| CPU at 100% from the first 10 users | Small laptop (2–4 cores) — SUT + JMeter + browser share the CPU | `PENGGUNA=10 RAMPUP=60`, or `CHATBOT_KERJA=0.5 node sut/server.js`; close other applications |

### ⭐ Challenge
1. Add a third row to the collector: `CPU` with the parameter `user` — how does it differ from `combined`?
2. Regenerate the dashboard with `-Jaggregate_rpt_pct1=75 -Jaggregate_rpt_pct3=99.9` (README §3.11). What is your p99.9? How many samples are above p99.9?
3. Run `CHATBOT_PEKERJA=2 PORT=3001 node sut/server.js` (only 2 workers) and `PORT=3001 ./run-chatbot-perfmon.sh`. At how many users does the knee point fall? Does the laptop CPU reach 100%? What does that mean for a "thread pool" bottleneck?

---

## Self-check

- [ ] I can plan a user journey and record it into named Transaction Controllers, without static assets
- [ ] I can explain why a playback fails (401/403) — and why a playback that "passes" is not necessarily correct
- [ ] I can clean up a recording: correlation, CSV parameterisation, names, think time, assertions
- [ ] I can generate the HTML dashboard with `-e -o` and `-g`, and adjust graph granularity
- [ ] I can explain every dashboard section and its terms (percentile, throughput, latency, APDEX, Error %)
- [ ] I can write findings with evidence, impact, cause and recommendation
- [ ] I can generate combined and per-site reports from a distributed test (controller + agents) and compare sites
- [ ] I can calculate concurrent users with Little's Law and plan run types
- [ ] Complete the Day 2 self-assessment (Kuiz hari)
