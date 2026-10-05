# Day 1 Lab — JMeter Fundamentals & Load Testing

[⬅️ Day 1 README](../README.md) · [🎤 Trainer Notes](../nota-penceramah.md) · [🎬 Record → Replay](./rakaman-e2e.md) · [🔒 HTTPS Recording](./rakaman-https-setup.md) · [🔑 Reference test plans](../test-plans/)

> **Lab rule:** Before every run, **predict** first — how many samples? What Error %? Will throughput go up or down? Write down your prediction, then click **Start**. Reference files (answers) are in `hari-1/test-plans/`. Try to build it yourself first; open a reference file only after the checkpoint or if you have been stuck for more than 10 minutes.

> ⚠️ **Ethics:** Every exercise targets **`http://localhost:3000`** only — always confirm Server=`localhost`, Port=`3000` before you click Start.

> 📊 **Evidence of progress:** JMeter runs on your own machine, so the LMS cannot see your runs. Tick each ✅ Checkpoint honestly; the last item of every checkpoint is the **session quiz** in the README — that is the evidence that gets assessed.

Make sure the **mock server is running** first (keep this terminal open all day):

```bash
cd sut && node server.js      # biarkan terbuka
```

| Exercise | Session | Focus | Reference file |
|---------|------|-------|--------------|
| 0 | S1 | Setup: Java, JMeter (PATH), SUT | — |
| 1 | S2 | First Test Plan | `01-hello-jpj.jmx` |
| 2 | S3 | Load test + assertion + timer | `02-cukai-beban.jmx` |
| 3 | S3 | CSV parameterisation | `03-csv-berparameter.jmx` |
| 4 | S3 | Make an assertion FAIL | `03-csv-berparameter.jmx` + fake row |
| 5 | S3 | Effect of server latency | `02-cukai-beban.jmx` |
| 6 | S4 | Record & watch the replay fail | `rakam-template.jmx`, `04-rakaman-mentah.jmx` |
| 7 ⭐ | S3 | Challenge: two samplers, correct scope | — |

---

## Lab 0 — Setup: Java, JMeter & SUT

**Session:** S1

### 🎯 Objectives
- Install Java + JMeter and run `jmeter` from any folder (O2)
- Run the mock SUT and verify the health endpoint (O2)
- State the course's authorised target and the ethics conditions (O1)

### Prerequisites
- Node.js 18+ (`node --version`)
- JDK 17/21 installer and the JMeter 5.6.x zip (from the internet, or on USB from the trainer)
- README §1.3–1.8 has been covered

### Steps

1. Verify Java:
   ```bash
   java --version        # 11 atau lebih baru (disyorkan 17/21)
   ```
2. Install JMeter (README §1.5). **Windows:** unzip to `C:\apache-jmeter-5.6.3`, add `C:\apache-jmeter-5.6.3\bin` to **User variables → Path**, then **close & reopen** the terminal.
3. Verify from a **different** folder (not `bin`):
   ```bash
   cd ~            # Windows: cd %USERPROFILE%
   jmeter -v
   ```

![Terminal: java --version and jmeter -v](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-01-java-jmeter-versi.png)
*`java --version` (Temurin 21) and `jmeter -v` from the home folder — the Apache JMeter **5.6.3** banner appears. The `WARN`/`WARNING` lines above the banner can be ignored.*

4. Start the SUT in a separate terminal and keep it open:
   ```bash
   cd sut
   node server.js
   ```
5. In a second terminal (or a browser):
   ```bash
   curl -s http://localhost:3000/api/health
   ```
   Expected: `{"status":"ok","masa":"…"}`. Open `http://localhost:3000` in a browser for the list of endpoints.

![Terminal: SUT running and curl /api/health](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-02-sut-health.png)
*Terminal 1: the SUT banner (latency 40–180 ms, error rate 1.0%, web portal). Terminal 2: `curl` to `/api/health` returns `{"status":"ok",…}`. (This capture used `PORT=3037`; in class use the default port `3000`.)*

![Browser: Portal eJPJ (TIRUAN) info page](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab0-03-browser-info-page.png)
*The `http://localhost:3000/` info page in a browser — the list of API endpoints and a link to the `/portal` web portal.*

6. Open the GUI: `jmeter` (or `bin\jmeter.bat`). Identify the **test tree** (left), the **configuration panel** (right), the **Start / Stop / Clear All** buttons, and the **Log** icon (warning triangle, top right).

### ✅ Checkpoint
- [ ] `java --version` shows version 11 or newer
- [ ] `jmeter -v` runs from a folder other than `bin` and shows version 5.6.x
- [ ] The SUT is running and `http://localhost:3000/api/health` returns `{"status":"ok",…}`
- [ ] The JMeter GUI opens without errors
- [ ] Pass **Quiz S1** (at least half correct) (Kuiz S1)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `'jmeter' is not recognized…` (Windows) | `bin` is not in PATH, or an old terminal | Add it to **User variables → Path**; **open a new terminal** |
| `jmeter` complains Java is not found | No JDK / wrong `JAVA_HOME` | Install JDK 11+; set `JAVA_HOME` to the JDK folder; add `%JAVA_HOME%\bin` to PATH; `java -version` |
| `EADDRINUSE :::3000` when running `node server.js` | Another SUT is already running on port 3000 | Use the existing SUT window, or stop it (Ctrl+C); `PORT=3001 node server.js` only if necessary (and change Defaults) |
| JMeter GUI very slow / tiny fonts | High-resolution screen / low memory | **Options → Zoom In**; close other applications |
| `curl` missing (older Windows) | — | Open `http://localhost:3000/api/health` in a browser |

### ⭐ Challenge
Start the SUT with `ERROR_RATE=0.2 node server.js` and read `sut/server.js` — which endpoint is affected by `ERROR_RATE`? (Answer: only `POST …/bayar-cukai`.) Restore it with a plain `node server.js`.

---

## Lab 1 — Your first Test Plan

**Session:** S2

### 🎯 Objectives
- Build a Test Plan with a Thread Group, HTTP Request Defaults, HTTP Request and View Results Tree (O3)
- Read the Sampler result / Request / Response data tabs in View Results Tree

### Prerequisites
- Exercise 0 completed; SUT running
- README §2.1–2.2

### Steps

1. Open JMeter (GUI). **Right-click Test Plan → Add → Threads (Users) → Thread Group** — 1 user, ramp-up 1, 1 loop.
2. **Right-click Thread Group → Add → Config Element → HTTP Request Defaults**: Protocol `http`, server `localhost`, port `3000`. *(The reference plan puts Defaults under the Test Plan — same effect.)*
3. **Right-click Thread Group → Add → Sampler → HTTP Request** → `GET /api/health` (leave Server/Port empty).
4. Add a second sampler `GET /` (the info page).
5. **Right-click Thread Group → Add → Listener → View Results Tree**.
6. **File → Save** as `lab1-saya.jmx`, then run it (▶). Confirm the response `{"status":"ok"}` and code **200**.

![View Results Tree: Sampler result tab with Response code 200](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-01-vrt-sampler-result.png)
*The `01-hello-jpj.jmx` plan after a run: two green samples in View Results Tree; the **Sampler result** tab for `GET /api/health` shows `Response code:200` and `Response message:OK`.*

![View Results Tree: Response data tab](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-02-vrt-response-data.png)
*The **Response data → Response Body** tab: `{"status":"ok","masa":"…"}`.*

7. In View Results Tree, click the `/api/health` sample → **Request** tab — see the full URL `http://localhost:3000/api/health` built from Defaults + Path.

![View Results Tree: Request tab with the full URL](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab1-03-vrt-request-url.png)
*Step 7: the **Request** tab shows the full URL `GET http://localhost:…/api/health` — server and port come from HTTP Request Defaults, the path from the sampler. (Captured on port 3037.)*

> Compare with `test-plans/01-hello-jpj.jmx`.

### ✅ Checkpoint
- [ ] The Test Plan runs and View Results Tree shows code **200** with the response `{"status":"ok"}`
- [ ] The plan structure matches `test-plans/01-hello-jpj.jmx` (Thread Group → HTTP Request Defaults → HTTP Request → Listener)
- [ ] The **Request** tab shows the full URL inherited from HTTP Request Defaults
- [ ] Pass **Quiz S2** (at least half correct) (Kuiz S2)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `Non HTTP response code: java.net.ConnectException` | SUT not running / wrong port | Start `node server.js`; check Port `3000` in Defaults |
| `UnknownHostException` | Server Name contains `http://` or a space | Server Name = `localhost` only (the protocol has its own field) |
| View Results Tree is empty | Listener out of scope (e.g. under another Thread Group) or the plan was not run | Put the listener under the same Thread Group; check the Log icon |
| Start button greyed out | The plan is still running | Wait, or click **Stop** |

### ⭐ Challenge
Add an **HTTP Header Manager** with `Accept: application/json` and confirm the header appears in the **Request → Request Headers** tab.

---

## Lab 2 — Load test + assertion + timer

**Session:** S3

### 🎯 Objectives
- Set a 20 / 10 / 5 load model and predict the number of samples (O4)
- Add a Response Assertion, a Duration Assertion and a Constant Timer (O7)
- Read Throughput, Average, Error % and 95% Line (O6)

### Prerequisites
- Exercise 1 completed
- README §2.3–2.5 and §3.1–3.2

### Steps

1. Change the Thread Group to **20 users**, **ramp-up 10s**, **5 loops**.

![Thread Group: 20 threads, ramp-up 10, 5 loops](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-01-thread-group-20-10-5.png)
*The Thread Group in `02-cukai-beban.jmx`: **Number of Threads 20**, **Ramp-up period 10**, **Loop Count 5**. The tree on the left shows how the sampler, assertions, timer and listeners are arranged.*

2. Sampler: `GET /api/kenderaan/WXY1234/cukai` (remove/disable the other samplers).
3. Add a **Response Assertion** (right-click the sampler → Add → Assertions) — Field to Test *Text Response*, *Substring*, pattern `amaun`.
4. Add a **Duration Assertion** (right-click the same sampler → Add → Assertions → Duration Assertion) — *Duration in milliseconds* `2000`.

![Response Assertion: Text Response, Substring, amaun](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-02-response-assertion-amaun.png)
*The Response Assertion (a child of the sampler): **Field to Test = Text Response**, **Pattern Matching Rules = Substring**, pattern `amaun`.*

5. Add a **Constant Timer** of 300 ms (think time) under the Thread Group (right-click Thread Group → Add → Timer → Constant Timer; *Thread Delay* `300`).
6. Add a **Summary Report** and an **Aggregate Report** (right-click Thread Group → Add → Listener). **Disable** View Results Tree (right-click → **Disable**) — it is a heavy listener under load.
7. **Predict** the total number of requests, then **Clear All** and run. Record: **Throughput**, **Average**, **Error %**, **95% Line**.

![Summary Report: 100 samples, 0% error](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab2-03-summary-report-100.png)
*The Summary Report after the run: **# Samples = 100** (20 × 5), **Error % = 0.00%**, Average 107 ms, Throughput 8.9/sec. Your numbers will differ slightly.*

> **Question:** How many requests in total do you expect? (20 × 5 = 100). Verify it.
> Compare with `test-plans/02-cukai-beban.jmx`.

### ✅ Checkpoint
- [ ] Thread Group set to 20 users, ramp-up 10s, 5 loops
- [ ] Response Assertion (`amaun`) and Duration Assertion (2000 ms) added, plus a 300 ms Constant Timer
- [ ] Summary Report shows **100** requests with 0% Error %
- [ ] **Throughput**, **Average** and **Error %** values recorded
- [ ] Pass **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| `# Samples` = 200 or 300, not 100 | Old samplers (`/api/health`, `/`) are still enabled | Disable/remove the other samplers |
| Doubled / mixed numbers | Results from an earlier run were not cleared | **Clear All** before every run |
| Every sample fails the assertion | Pattern misspelt / wrong Field to Test | *Text Response* + *Substring* + `amaun` (lowercase) |
| Throughput far lower than expected | The timer adds pauses (correct!) or ramp-up is still in progress | Compare with a run without the timer — that is the lesson |
| JMeter freezes during a run | View Results Tree enabled with many samples | Disable View Results Tree under load |

### ⭐ Challenge
Replace the Constant Timer with a **Gaussian Random Timer** (Deviation 300, Constant Delay Offset 1000). Run again — compare Throughput. Then lower the Duration Assertion to `100` ms and watch Error % — this is how an SLA "bites".

---

## Lab 3 — Parameterisation with CSV

**Session:** S3

### 🎯 Objectives
- Feed different registration numbers through CSV Data Set Config and `${no_pendaftaran}` (O8)

### Prerequisites
- Exercise 2 completed
- README §3.3; the file `hari-1/data/kenderaan.csv` exists

### Steps

1. Save your plan **in the `hari-1/test-plans/` folder** (so that the relative path `../data/` is correct).
2. Add a **CSV Data Set Config** (right-click Thread Group → Add → Config Element → CSV Data Set Config; the reference plan puts it under the Test Plan — same effect) reading `../data/kenderaan.csv`
   (variable names: `no_pendaftaran,model`; ignore first line: **True**; recycle: **True**; stop thread: **False**; sharing mode: **All threads**).

![CSV Data Set Config: ../data/kenderaan.csv, no_pendaftaran,model](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab3-01-csv-data-set-config.png)
*CSV Data Set Config: Filename `../data/kenderaan.csv`, Variable Names `no_pendaftaran,model`, Ignore first line **True**, Recycle on EOF **True**, Stop thread on EOF **False**, Sharing mode **All threads**.*

3. Change the sampler path to `/api/kenderaan/${no_pendaftaran}/cukai`.
4. Change the Thread Group to **10 / 5 / 10** (threads / ramp-up / loops) and re-enable View Results Tree. Run it (10 users × 10 loops). In View Results Tree, confirm that
   each request uses a different registration number.

![View Results Tree: each sample uses a different registration number](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab3-02-vrt-nombor-berlainan.png)
*View Results Tree: the sample labels change with each CSV row (`WXY1234`, `VAB88`, `JQK77`, `BMT30…`, `PKL90…`); the **Request** tab shows `${no_pendaftaran}` already substituted — `…/api/kenderaan/VAB88/cukai`.*

> Compare with `test-plans/03-csv-berparameter.jmx`.

### ✅ Checkpoint
- [ ] CSV Data Set Config reads `../data/kenderaan.csv` with the variables `no_pendaftaran,model`
- [ ] The sampler path uses `${no_pendaftaran}`
- [ ] View Results Tree shows a different registration number for each request
- [ ] Pass **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| The URL contains `${no_pendaftaran}` literally | CSV not read — wrong path or the plan was saved in another folder | Save the `.jmx` in `hari-1/test-plans/`; check the Log for "File … not found" |
| One request to `/api/kenderaan/no_pendaftaran/cukai` → 404 | *Ignore first line* = False | Set it to **True** |
| Every thread uses the same number | CSV placed as a sampler child in an odd scope, or *Sharing mode* is not All threads + 1 row of data | Put the CSV directly under the Thread Group; check the file has 5 data rows |
| The `model` variable is empty | Space in *Variable Names* (`no_pendaftaran, model`) | No space after the comma |

### ⭐ Challenge
Add a sampler `GET /api/saman?no_kp=${no_kp}` using a **second CSV** with a `no_kp` column (three synthetic users: `800101015500`, `900202025600`, `850303035700`). Save the new file in `hari-1/data/` under a name of your own.

---

## Lab 4 — Make an assertion FAIL (learning from failure)

**Session:** S3

### 🎯 Objectives
- Prove that an assertion catches a wrong response and raises Error % (O7)

### Prerequisites
- Exercise 3 completed (the CSV-parameterised plan runs with 0% errors)

### Steps

1. Add one fake row to `hari-1/data/kenderaan.csv`, e.g.: `ABC0000,Kereta Hantu`.

![kenderaan.csv with the fake ABC0000 row](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-01-csv-baris-palsu.png)
*The fake row `ABC0000,Kereta Hantu` added at the end of the CSV — no blank line before it, and the header is unchanged.*

2. Run Exercise 3 again. Notice that the `ABC0000` request **fails**
   the assertion (`amaun` is missing — the endpoint returns **404**).
3. In View Results Tree, click the red sample → **Sampler result** tab → read the *Assertion failure message*. Compare the response code (`404`) with the body `{"ralat":"Kenderaan tidak dijumpai"}`.

![View Results Tree: red ABC0000 sample with Response code 404](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-02-vrt-404.png)
*The `ABC0000` sample is red — the **Sampler result** tab shows `Response code:404` and `Response message:Not Found`.*

![View Results Tree: Assertion result with the Assertion failure message](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-03-vrt-assertion-gagal.png)
*Expand the red sample and click the Response Assertion node — the **Assertion failure message** shows the custom message `Kenderaan ABC0000 tidak memulangkan sebut harga (mungkin 404)` (set in the *Custom failure message* of the reference plan `03-csv-berparameter.jmx`; your own plan shows the default message `Test failed: text expected to contain /amaun/`).*

4. Watch **Error %** rise in the Summary Report. **Predict first:** with 6 data rows and Recycle = True, roughly what percentage of samples will fail?
5. Remove the fake row when you are done.

![Summary Report: ABC0000 row at 100% error, TOTAL 16% Error](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab4-04-summary-error.png)
*Answer to step 4: only the `ABC0000` row fails (100%), so the TOTAL Error % ≈ 1/6 — here 16.00% (16 of 100 samples).*

### ✅ Checkpoint
- [ ] The `ABC0000` request fails the assertion (the endpoint returns **404**)
- [ ] Error % in the Summary Report increases
- [ ] The fake row is removed from `kenderaan.csv` afterwards
- [ ] Pass **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| The fake row is never used | File not saved, or a blank line before the fake row | Save the file; make sure there are no blank lines |
| Error % = 100% | Fake row added to the header row / broken format | Open the CSV in a text editor (not Excel) and check |
| Forgot to remove the fake row → the next exercise fails | — | `git checkout hari-1/data/kenderaan.csv` or delete the row manually |

### ⭐ Challenge
Instead of changing the original file, copy it to `kenderaan-rosak.csv` and change the CSV Data Set Config Filename. Then add a second Response Assertion with **Field to Test = Response Code**, pattern `200` — two assertions, different failure messages.

---

## Lab 5 — Effect of latency on performance

**Session:** S3

### 🎯 Objectives
- Observe the relationship between server latency, throughput and percentiles (O6)

### Prerequisites
- Exercise 2 completed with the Throughput / Average values recorded

### Steps

1. Stop the server (Ctrl+C). Restart it with high latency:
   ```bash
   LATENCY_MIN=300 LATENCY_MAX=900 node server.js
   ```
   Windows PowerShell: `$env:LATENCY_MIN=300; $env:LATENCY_MAX=900; node server.js`

![Terminal: SUT with LATENCY_MIN=300 LATENCY_MAX=900](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab5-01-sut-latensi-tinggi.png)
*The SUT started with `LATENCY_MIN=300 LATENCY_MAX=900` — the banner shows **Latensi tiruan : 300-900 ms**. (Captured on a separate port, 3038.)*

2. **Clear All**, then run Exercise 2 again. Compare **Average**, **95% Line** and **Throughput** with the original run.

![Aggregate Report: normal SUT (40–180 ms)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab5-02-aggregate-normal.png)
*The Exercise 2 run against the normal SUT (40–180 ms): Average **107 ms**, 95% Line **169 ms**, Throughput **8.9/sec**.*

![Aggregate Report: high-latency SUT (300–900 ms)](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab5-03-aggregate-latensi-tinggi.png)
*The same plan against the high-latency SUT (300–900 ms): Average **588 ms**, 95% Line **847 ms**, Throughput drops to **7.2/sec** — same threads, but each one waits longer.*

3. Fill in the table:

   | Run | Average (ms) | 95% Line (ms) | Throughput (/s) | Error % |
   |--------|--------------|---------------|-----------------|---------|
   | Exercise 2 (40–180 ms) | | | | |
   | Exercise 5 (300–900 ms) | | | | |

4. Restore the SUT: Ctrl+C → `node server.js` (without the variables).

> **Reflection question:** Why does throughput drop when latency rises even though the number of users is the same? (Hint: each thread waits longer before it can send its next request.)

### ✅ Checkpoint
- [ ] The server is restarted with `LATENCY_MIN=300 LATENCY_MAX=900`
- [ ] Average and Throughput compared with the original Exercise 2 run
- [ ] Can explain why throughput drops when latency rises
- [ ] Pass **Quiz S3** (at least half correct) (Kuiz S3)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| Same numbers as before | The variables did not reach Node (Windows cmd) | `set LATENCY_MIN=300` and `set LATENCY_MAX=900` in cmd, or the PowerShell syntax above |
| Error % rises sharply | The 2000 ms Duration Assertion is still fine — if you lowered it in the Exercise 2 Challenge, it now fails | Restore it to 2000 ms, or use this as an SLA demo |
| The next exercise feels slow | The SUT is still in high-latency mode | Restart the SUT without the variables |

### ⭐ Challenge
Increase threads to 60 (keep the high latency). Does throughput recover? What does this teach about the relationship between concurrency, response time and throughput (Little's Law: concurrency ≈ throughput × response time)?

---

## Lab 6 — Record a Test Plan & watch the replay fail

**Session:** S4

### 🎯 Objectives
- Record a flow with the HTTP(S) Test Script Recorder into a Recording Controller (O9)
- Prove that the replay fails (401) and name the values that must be correlated (O9)

### Prerequisites
- SUT running (`node sut/server.js`)
- README §4.1–4.6; full guide: [`rakaman-e2e.md`](./rakaman-e2e.md)

### Steps

1. **Right-click Test Plan → Add → Non-Test Elements → HTTP(S) Test Script Recorder.**
   Add a **Thread Group** (right-click Test Plan → Add → Threads (Users) → Thread Group), then a **Recording Controller** under the Thread Group (right-click Thread Group → Add → Logic Controller → Recording Controller) and set it as the recorder's **Target Controller**.
   *(Or open `test-plans/rakam-template.jmx` directly — everything is already set up.)*

![HTTP(S) Test Script Recorder in rakam-template.jmx](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-01-recorder-port-8888.png)
*`rakam-template.jmx`: the HTTP(S) Test Script Recorder with **Port 8888** and **Target Controller = Use Recording Controller**; the Recording Controller sits under the Thread Group.*

2. On the recorder: tab **Requests Filtering → URL Patterns to Exclude → Add** → add the static-asset regex
   `(?i).*\.(bmp|css|js|gif|ico|jpe?g|png|swf|eot|otf|ttf|mp4|woff|woff2)([?;].*)?`.
3. Click **Start**. Send requests through the JMeter proxy (port 8888):
   ```bash
   curl -s -x http://localhost:8888 -H 'Content-Type: application/json' \
     -d '{"no_kp":"800101015500","kata_laluan":"rahsia123"}' \
     http://localhost:3000/api/log-masuk
   curl -s -x http://localhost:8888 -H 'Authorization: Bearer TOKEN_PALSU' \
     'http://localhost:3000/api/kenderaan?no_kp=800101015500'
   ```
4. Click **Stop**. Look at the recorded samplers in the Recording Controller. Open the `/api/kenderaan` sampler → its child **HTTP Header Manager** → notice that `Authorization: Bearer TOKEN_PALSU` is hard-coded.

![Web portal: Log Masuk, Kenderaan Saya, Bayar Cukai Jalan, Pembayaran Berjaya](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-02-portal-aliran.png)
*The web-portal flow recorded through a browser (Challenge / [`rakaman-e2e.md`](./rakaman-e2e.md)): **Log Masuk** (log in) → **Kenderaan Saya** (my vehicles) → **Bayar Cukai Jalan** (pay road tax; the form has a hidden `csrf` field) → **Pembayaran Berjaya** (Status: BERJAYA).*

![Recorded samplers under the Recording Controller](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-03-recording-controller.png)
*The result of recording the portal flow above: each request became a sampler under the **Recording Controller**, each with its own **HTTP Header Manager**. Note that `/portal/favicon.svg` was recorded too (`svg` is not in the Excludes regex) and `/time/1/current` is a Chrome background request — delete samplers that are not part of your flow. (This recording used proxy port 8898.)*

5. Add a **View Results Tree** under the Thread Group (if you use `rakam-template.jmx`, one already sits under the Test Plan — use that). **Replay** it (Run). Notice the requests come back → **401** because the recorded token
   has expired / is fake.
6. Prove it with the reference plan, in non-GUI mode, and generate an HTML report:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx \
     -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
   Open `/tmp/laporan-rakaman/index.html` — Error % should be **~67%** (200 / 401 / 401).

![HTML report: 66.67% error, 401/Unauthorized](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab6-04-laporan-replay-401.png)
*Step 6: the HTML report for `04-rakaman-mentah.jmx` — `/api/log-masuk` passes, but `/api/kenderaan` and `…/bayar-cukai` fail with **401/Unauthorized**; TOTAL Error % is **66.67%**.*

> **Analysis question:** Which values **change every session** and must be **correlated**
> (not hard-coded)? Compare with the finished reference
> [`test-plans/04-rakaman-mentah.jmx`](../test-plans/04-rakaman-mentah.jmx) — the fix
> comes on Day 2 (correlating `token` + `csrf`).
>
> **Step-by-step end-to-end guide:** [`rakaman-e2e.md`](./rakaman-e2e.md).

### ✅ Checkpoint
- [ ] HTTP(S) Test Script Recorder and Recording Controller (Target Controller) set up, with the static-asset regex in Excludes
- [ ] The `/api/log-masuk` and `/api/kenderaan` samplers are recorded in the Recording Controller
- [ ] The replay shows **401** because the recorded token has expired / is fake
- [ ] Can explain which values change every session and must be correlated (`token`, `csrf`)
- [ ] Pass **Quiz S4** (at least half correct) (Kuiz S4)

### 🧯 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|--------------|
| No samplers recorded | Recorder not **Start**ed, or traffic is not going through `:8888` | `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (macOS/Linux) / `netstat -ano \| findstr :8888` (Windows); make sure you use `curl -x http://localhost:8888` |
| Firefox: nothing recorded from localhost | `localhost, 127.0.0.1` in **No proxy for** | Clear that box |
| `Address already in use` on Start | Port 8888 is used by another application / a second recorder | Close other plans that contain a recorder; or change the port (and the `curl -x` command) |
| `curl` in Windows cmd: `{"ralat":…}` / broken JSON | cmd.exe does not understand single quotes | Use Git Bash, or: `curl -s -x http://localhost:8888 -H "Content-Type: application/json" -d "{\"no_kp\":\"800101015500\",\"kata_laluan\":\"rahsia123\"}" http://localhost:3000/api/log-masuk` |
| Samplers recorded under Test Plan, not the Recording Controller | Target Controller not set | Select **Test Plan > Thread Group > Recording Controller** |
| `-e -o` fails: *"folder … not empty"* | The report folder already exists | Delete the folder or use a new name |
| Normal Firefox browsing fails after the exercise | Proxy still points to the stopped JMeter | Network Settings → **Use system proxy settings** |

### ⭐ Challenge
Follow [`rakaman-e2e.md`](./rakaman-e2e.md) in full: record a **3-step** flow (log in → vehicle list → pay road tax) with a **real** `TOKEN` and `CSRF`, restart the SUT, then replay. Why does pay-road-tax fail this time too, even though the token was "real" when it was recorded? For HTTPS (sites you are **authorised** to test only), follow [`rakaman-https-setup.md`](./rakaman-https-setup.md) — including importing `ApacheJMeterTemporaryRootCA.crt` and **removing it** afterwards.

---

## Lab 7 (Challenge) — Two samplers, the correct scope

**Session:** S3

### 🎯 Objectives
- Arrange elements by scope and explain the effect of each element's position (O5)

### Prerequisites
- Exercises 1–3 completed

### Steps

1. Build **one Test Plan** with **two samplers** (`/api/health` and `/api/saman?no_kp=900202025600`) under the same Thread Group.
2. Give each sampler **its own Response Assertion** (as a child): `ok` for health, `saman` for saman.
3. Add **HTTP Request Defaults** and a 500 ms **Constant Timer** under the Thread Group, plus a **Summary Report**.
4. **Predict:** total timer pause per iteration? Then move the timer so it is a child of the saman sampler only, and predict again.

![Constant Timer under the Thread Group: applies to both samplers](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-01-timer-bawah-thread-group.png)
*A 500 ms Constant Timer **under the Thread Group** — its scope covers both samplers, so 2 × 500 ms of pause per iteration. Each sampler has its own assertion; Error % 0.00%, TOTAL Throughput 1.9/sec.*

![Constant Timer as a child of the saman sampler: applies to that sampler only](https://raw.githubusercontent.com/habibtalib/jmeter-2-days-training/main/slides/img/h1-lab7-02-timer-anak-sampler-saman.png)
*The timer moved to be a **child** of the saman sampler — only 1 × 500 ms per iteration, so TOTAL Throughput rises to 2.8/sec.*

5. Arrange the elements correctly (Config → Sampler → Assertion → Listener) and explain the **scope** of each element to the person next to you.

### ✅ Checkpoint
- [ ] Two samplers, each with its own Response Assertion, passing with 0% errors
- [ ] Can explain the difference between a timer under the Thread Group (2 × 500 ms) and a child of one sampler (1 × 500 ms)
- [ ] The scope of each element explained to a colleague

---

## Self-check

- [ ] I can name five types of performance testing and state the ethics conditions before generating load
- [ ] I can run `jmeter -v` from any folder and start the mock SUT
- [ ] I can build a Test Plan with a Thread Group, HTTP Request Defaults, samplers and listeners
- [ ] I can add a Response Assertion, a Duration Assertion and a Timer
- [ ] I can parameterise requests with CSV Data Set Config
- [ ] I can read Throughput, Average, Error % and percentiles in the Summary / Aggregate Report
- [ ] I can record a Test Plan with the HTTP(S) Test Script Recorder
- [ ] I can explain why a raw recording fails on replay (401) and what correlation is
- [ ] Complete the Day 1 self-assessment (Kuiz hari)
