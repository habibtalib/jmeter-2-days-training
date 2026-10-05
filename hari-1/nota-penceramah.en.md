# Trainer Notes — Day 1: Apache JMeter & Load Testing Fundamentals

[📖 Day 1 README](./README.md) · [🧪 Lab](./snippets/lab.md) · [🎬 Record → Replay](./snippets/rakaman-e2e.md) · [🔒 HTTPS recording](./snippets/rakaman-https-setup.md) · [🔑 Reference test plans](./test-plans/) · [⚙️ SUT](../sut/server.js)

> 📌 **JPJ cohort status:** Day 1 for this cohort took place on **21 Sep 2026**. **Day 2 is scheduled for 5 Oct 2026.** Participants now use the Day 1 pages for **revision** — the session quizzes (Kuiz S1–S4), the Self-check and the **Day quiz** in the README, and the ✅ Checkpoints in the lab. The notes below remain as a reference for future cohorts, and the [🔁 Day 2 opening](#-day-2-opening-day-1-revision-15-minutes) section explains how to use the Day 1 material in the first 15 minutes of Day 2.

> **Key message for today:** *"JMeter is a load weapon — point it at `localhost:3000` only. And a 200 status code does not mean success."* JPJ participants are IT officers, testers and developers with varied experience; many have never run a load test. Today is **not** about memorising JMeter menus; it is about **predicting** what will happen before clicking Start (how many samples? Error %? does throughput go up or down?). If they remember only three things: **target ethics**, **scope by position**, and **percentiles, not averages**.

## Trainer summary

| Item | Value |
|---------|-------|
| Ratio | S1 ~50% explanation + installation · S2–S4 ~40% live demo · ~60% lab |
| Materials | Projector + JMeter GUI (**Options → Zoom In** twice), terminal font ≥ 18pt, Firefox (for S4), whiteboard for the scope tree and the throughput formula |
| Demo files | `hari-1/test-plans/01…04`, `rakam-template.jmx`, `rakam-https-template.jmx`; SUT `node sut/server.js` |
| Key moments | (1) S1: "200 JMeter threads = 200 attackers" — the ethics slide; (2) S2: the prediction 20 × 5 = 100 confirmed by `# Samples`; (3) S3: the fake row `ABC0000` raises Error %; (4) S4: replaying the recording → red **401** — "tomorrow we fix it" |
| Required outcome by end of day | ≥ 90% of participants: `jmeter -v` works, Latihan 1–3 ✅, and they have seen the 401 from `04-rakaman-mentah.jmx` |

---

> ⚠️ **Demo habit:** always confirm Server=`localhost`, Port=`3000` before Start.

---

## ✅ Pre-class checklist (the night before / 30 minutes early)

- [ ] **USB/shared drive** with: the **Temurin JDK 21** installer (Windows `.msi`, macOS `.pkg`), `apache-jmeter-5.6.3.zip`, the **Node.js 18+/22 LTS** installer, and a copy of the course repo — government lab Wi-Fi is often slow or blocks downloads.
- [ ] Demo machine: `java --version`, `jmeter -v`, `node --version` all run.
- [ ] `node sut/server.js` → `http://localhost:3000/api/health` returns `{"status":"ok",…}`.
- [ ] Run the non-GUI check on the demo machine:
  ```bash
  node sut/server.js &
  jmeter -n -t hari-1/test-plans/02-cukai-beban.jmx -l /tmp/r02.jtl
  jmeter -n -t hari-1/test-plans/03-csv-berparameter.jmx -l /tmp/r03.jtl
  jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/r04.jtl   # MESTI 200/401/401
  ```
- [ ] **Windows PATH:** prepare a slide/handout with the steps *User variables → Path → New → `C:\apache-jmeter-5.6.3\bin`* — the #1 source of problems in S1. Remind them: **open a new terminal**.
- [ ] **Admin rights:** check whether participants have admin rights. If not: the JDK `.msi` may fail → use the Temurin **ZIP** + `JAVA_HOME` under User variables; CA certificate → **Current User** store only (error *"cert not owner"*).
- [ ] **Firefox** is installed on participant machines (S4). If not, `curl` through the proxy is enough.
- [ ] **Ports 3000 and 8888** are free on participant machines (other applications, e.g. Docker/IIS, sometimes use 3000/8888).
- [ ] Antivirus/corporate proxy: the JMeter proxy on `localhost:8888` is sometimes blocked — test it once on one lab machine.
- [ ] Delete any old `ApacheJMeterTemporaryRootCA.crt` on the demo machine (valid 7 days) so the S4 demo shows a fresh one being generated.

---

## S1 · 9.00 – 10.30 am · Introduction to Performance Testing & Setup (90 minutes)

| Time | Minutes | Activity | Notes |
|------|-------|----------|------|
| 9.00 – 9.10 | 0–10 | Welcome, the 2-day objectives, introduce the **eJPJ Portal (mock)**. Skill-level poll (show of hands). | Poll: "Used JMeter / LoadRunner / k6 before?" "Written a script before?" "Experienced a system going down on a peak day?" Pair experienced with new participants. |
| 9.10 – 9.25 | 10–25 | README §1.1–1.2: what performance testing is, the 4 components (Load/Scenario/Metrics/Criteria), the 5 test types. | Ask participants for a JPJ example of each type (price-increase day = Spike; long holidays = Soak). |
| 9.25 – 9.35 | 25–35 | §1.3 **Ethics** — the "200 threads = 200 attackers" slide. | **Key moment #1.** Firm, not frightening. See *S1 key message* below. |
| 9.35 – 10.10 | 35–70 | **Latihan 0**: install Java + JMeter, **Windows PATH**, `jmeter -v`. | Walk around. Hand out USBs early if downloads are slow. Fast participants: help a neighbour + ⭐ Latihan 0 Challenge. |
| 10.10 – 10.20 | 70–80 | §1.6–1.7: GUI vs non-GUI; run the SUT; the endpoint table. **Live:** `curl -s http://localhost:3000/api/health`; open `/` in the browser. | Show the SUT console printing latency & error rate. |
| 10.20 – 10.30 | 80–90 | §1.8 GUI tour (tree, panels, Start/Stop/Clear All, Log). **Kuiz S1**. | Show the Log icon — "when something looks odd, open this first". |

**S1 key message — ethics (script):**
> *"JMeter cannot tell the difference between a test and an attack. Neither can the server. If you point 200 threads at the real JPJ portal without written approval, legally that is a denial-of-service attack — even if you are a JPJ officer, even if your intentions are good. That is why for these two days we only fire at `localhost:3000`. When you return to the office and want to test staging: get written approval from the system owner, state the host, load level and time window, inform the infrastructure and monitoring teams, and make sure someone is ready to press Stop."*

**Questions to ask:**
- "Why not test the real portal directly — it's more realistic?" (the law + risk of disrupting service to the public; staging with permission is the right way)
- "What is the difference between functional testing and performance testing?" (it works vs it holds up under load)
- "If the Average is 200 ms, are all users happy?" (plant the seed of percentiles for S2)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "A small load (10–50 threads) on production is harmless" | The legal position does not depend on size. And 50 threads without think time can generate hundreds of req/s. |
| "JMeter is a browser" | JMeter sends HTTP requests — it does **not** run JavaScript or render pages. Response time ≠ page load time in a browser. |
| "The GUI is enough for load testing" | The GUI is for building/debugging only; real load = non-GUI (Day 2). |
| "PATH has been added, so it must work" | Only in a **new terminal**. |

**✅ Before moving on to S2:** ≥ 90% of participants have a working `jmeter -v` **and** the SUT running. Those who don't: pair them with a colleague and continue with the GUI from `bin\jmeter.bat` — PATH can be fixed during the break.

---

## 10.30 – 10.45 am · Break

Walk around for the last 5 minutes: help participants whose PATH/Java is not yet sorted.

---

## S2 · 10.45 am – 1.00 pm · Test Plan Anatomy, Thread Group & Listeners (135 minutes)

| Time | Minutes | Activity | Notes |
|------|-------|----------|------|
| 10.45 – 10.50 | 0–5 | Recap: 3 quick questions (Spike vs Soak, a legitimate target, why non-GUI). | Pick participants from the "new" group. |
| 10.50 – 11.10 | 5–25 | §2.1 tree anatomy + category table. **Whiteboard:** draw the tree, circle the scope of each element. Write the execution order Config → Pre → Timer → Sampler → Post → Assertion → Listener. | This is the most important concept today. Repeat: *"Position = scope."* |
| 11.10 – 11.35 | 25–50 | **Demo `01-hello-jpj.jmx`** (see demo script) → **Latihan 1**. | Start the demo by openly checking HTTP Request Defaults. |
| 11.35 – 11.55 | 50–70 | §2.3 Thread Group. **Whiteboard:** the "calculate before clicking Start" table. Ask for a prediction for 20/10/5. | **Key moment #2** — the prediction of 100 is confirmed later. |
| 11.55 – 12.10 | 70–85 | §2.4 HTTP Header Manager; mention Cookie/Cache Manager. **Live:** show the headers in the Request tab. | Plant the seed: the S4 recording will create a Header Manager per sampler. |
| 12.10 – 12.35 | 85–110 | §2.5 Listeners + column dictionary. **Live:** run 20/10/5 without assertions → Summary + Aggregate. Read every column together. | Example: 99 × 100 ms + 1 × 10 s → Average 199 ms. Write it on the board. |
| 12.35 – 12.50 | 110–125 | Participants start **Latihan 2** steps 1, 2, 6, 7 (load + listeners, no assertions yet). | Check `# Samples` = 100 on 3 pairs. |
| 12.50 – 1.00 | 125–135 | **Kuiz S2** + bridge: *"All green — but is everything actually correct? After lunch: assertions."* | |

**Short script (scope):**
> *"Imagine every element is an umbrella. An umbrella under the Thread Group covers every sampler beneath it. An umbrella held by one sampler — as its child — covers only that sampler. When an assertion 'doesn't run' or a timer 'doubles up', 9 times out of 10 the umbrella is in the wrong place."*

**Questions to ask:**
- "A 300 ms timer under a Thread Group with 3 samplers — the pause per iteration?" (900 ms)
- "Ramp-up 0 with 100 threads — what happens?" (all at once = a spike; rarely realistic)
- "Why are SLAs written in percentiles?" (averages hide the tail)
- "Why is View Results Tree disabled during load?" (memory; inaccurate figures)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "Visual order in the tree = execution order" | For different types, JMeter follows a fixed order (Timers **before** the sampler). Only samplers & elements of the same type follow tree order. |
| "A 10 s ramp-up means the test finishes in 10 s" | Ramp-up is only the time to launch the threads; test duration depends on loops × time per iteration. |
| "Throughput = number of users" | Throughput = completed requests per second; it depends on threads, response time and think time. |
| "Error % of 0 = a good system" | Without assertions, Error % only counts HTTP/network errors (S3 fixes this). |

**✅ Before moving on to S3:** ≥ 80% Latihan 1 ✅ and the 20/10/5 run shows 100 samples.

---

## 1.00 – 2.00 pm · Lunch

Walk around for the last 10 minutes: make sure every participant has the 20/10/5 plan saved — S3 adds assertions to it.

---

## S3 · 2.00 – 3.30 pm · Assertions, Timers & CSV Data Set (90 minutes)

| Time | Minutes | Activity | Notes |
|------|-------|----------|------|
| 2.00 – 2.05 | 0–5 | Post-lunch energy: **standing quiz** — "Stand up if a 200 code means the response is correct." | Then show a 200 with a `{"ralat":…}` body (hypothetical example). |
| 2.05 – 2.20 | 5–20 | §3.1 Response + Duration Assertion. **Demo `02-cukai-beban.jmx`** (see script). | Show the *Assertion failure message* by lowering Duration to 100 ms live. |
| 2.20 – 2.30 | 20–30 | §3.2 Timers (Constant / Uniform / Gaussian). **Whiteboard:** throughput ≈ threads ÷ (response + think time). | Predict together: with and without the 300 ms timer. |
| 2.30 – 2.45 | 30–45 | Participants complete **Latihan 2** (assertion + timer). | Most frequent mistake: the old sampler is still enabled → 200/300 samples. |
| 2.45 – 3.00 | 45–60 | §3.3 CSV Data Set Config. **Demo `03-csv-berparameter.jmx`** → **Latihan 3**. | Stress that the path is relative to the `.jmx`, and *Ignore first line*. |
| 3.00 – 3.10 | 60–70 | **Latihan 4** — the fake row `ABC0000`. | **Key moment #3.** Ask for an Error % prediction first (~1/6). |
| 3.10 – 3.20 | 70–80 | **Latihan 5** (high latency) — or a trainer demo if time is short. | Compare the before/after table on the board. |
| 3.20 – 3.30 | 80–90 | **Kuiz S3**. Cases 1–5 (§3.4) and Latihan 7 ⭐ for fast participants / homework. | |

**Short script (assertions):**
> *"Without assertions, JMeter only asks 'did the server answer?'. With assertions, it asks 'did the server answer **correctly** and **fast enough**?'. The Error % you report to management must be the answer to the second question."*

**Questions to ask:**
- "Add a 1000 ms timer — does the Average go up?" (no; throughput goes down — timer time is not counted in sample time)
- "A 5-row CSV, 10 threads × 10 loops, Recycle True — what happens after row 5?" (it goes back to the first row)
- "When do you use Recycle False + Stop thread True?" (single-use data, e.g. unique accounts)
- "Where is `../data/` resolved from?" (the folder of the `.jmx` file)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "Timers add to response time" | Timers run **before** the sampler and are not included in sample time; they lower throughput. |
| "More assertions = better" | Every assertion costs CPU on the load generator; prefer simple Substring checks. |
| "CSV Sharing *All threads* = every thread reads the whole file" | A single queue is shared; each read takes the next row. |
| "The CSV path is relative to the terminal folder" | It is relative to the `.jmx` file. |

**✅ Before moving on to S4:** ≥ 80% Latihan 2 & 3 ✅. Latihan 4–5 can be completed at home (the README has the full steps).

---

## 3.30 – 3.45 pm · Break

Ask participants to install/open **Firefox** during the break and make sure the SUT is still running.

---

## S4 · 3.45 – 5.00 pm · Recording a Test Plan: HTTP(S) Test Script Recorder (75 minutes)

| Time | Minutes | Activity | Notes |
|------|-------|----------|------|
| 3.45 – 3.55 | 0–10 | §4.1–4.2: how the proxy records (diagram). Set up the recorder + Recording Controller + Excludes. | Faster: open `rakam-template.jmx`. |
| 3.55 – 4.05 | 10–20 | §4.3–4.4 **Live:** Start the recorder → `curl -x http://localhost:8888 …` login → samplers appear. Show the Firefox configuration + *No proxy for*. | `curl` is the most reliable for POST; Firefox to show the concept. |
| 4.05 – 4.30 | 20–45 | **Latihan 6**. | Most frequent problems: nothing recorded (No proxy for / recorder not started) and `curl` quoting in cmd.exe. |
| 4.30 – 4.40 | 45–55 | §4.5 HTTPS + CA certificate (**demo `rakam-https-template.jmx`** — generate the certificate only). | Show the Windows **Current User** vs Local Machine table. Remind them: remove the certificate after use. |
| 4.40 – 4.50 | 55–65 | §4.6–4.7 **Demo `04-rakaman-mentah.jmx`** non-GUI + `-e -o` → HTML report with ~67% errors. | **Key moment #4.** Leave the red 401s on screen. |
| 4.50 – 5.00 | 65–75 | **Kuiz S4** + **Day quiz** + bridge to Day 2 (see below). | Ask participants to save their recorded plan. |

**Questions to ask:**
- "Why does login return 200 but the next step returns 401?" (a new token is issued but not used; the old token is sent)
- "Which values in the recording change every session?" (`token`, `csrf`)
- "Why must you remove the JMeter CA certificate after recording?" (anyone holding the CA key can MITM your traffic)
- "Why exclude static assets?" (not the load we are measuring; junk samplers)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "A recording = a script ready for load" | A recording is a starting point: clean it up, parameterise, **correlate**. |
| "You need a CA certificate to record localhost" | Only for **HTTPS**. Our SUT is `http://`. |
| "The recorder can record any browser automatically" | Only traffic **routed** to the `:8888` proxy. |
| "The HTTPS template can be used on any site" | Technically yes — ethically only on sites you own / have written permission for. |

**✅ End-of-day criteria:** ≥ 90% of participants have seen the **401** from replaying a recording (Latihan 6 or `04-rakaman-mentah.jmx`) and can name `token` + `csrf` as dynamic values.

---

## 🎬 Demo script for each test plan

### `01-hello-jpj.jmx` — First Test Plan (S2, ~8 minutes)

1. **File → Open** → `hari-1/test-plans/01-hello-jpj.jmx`.
2. Click **HTTP Request Defaults** → *"First thing: where is this plan firing?"* Show `localhost` / `3000` and Thread Group 1 / 1 / 1 — use the moment as an ethics lesson (the target is always checked before Start).
3. Show the two samplers: `GET /api/health` and `GET / (halaman info)`.
4. **Start** → View Results Tree → click each sample: the Sampler result tab (200, time), Request (full URL), Response data (choose *JSON*).
5. Ask: *"The Server Name in the sampler is empty — where does the full URL come from?"* (HTTP Request Defaults).

**Expected:** 2 green samples, 200, `{"status":"ok",…}` and the HTML `<h1>Portal eJPJ (TIRUAN)</h1>`.

### `02-cukai-beban.jmx` — Load test + assertion + timer (S2/S3, ~10 minutes)

1. Open the file. Show the tree: HTTP Request Defaults (`localhost:3000`), HTTP Header Manager (`Accept: application/json`), Thread Group *"Pengguna Semak Cukai"* 20 / 10 / 5.
2. Sampler `GET /api/kenderaan/WXY1234/cukai` with the children *"Respons mengandungi 'amaun'"* and *"Tempoh < 2000ms"*. Timer *"Think Time 300ms"*.
3. Listeners: Summary Report, Aggregate Report, and *"View Results Tree (nyahaktif semasa beban)"* — explain its name.
4. **Ask for a prediction** of `# Samples` → Start → confirm **100**, Error % 0.
5. **Live:** change the Duration Assertion to `100` → Clear All → Start → Error % jumps. Open a red sample → *Assertion failure message*. Restore it to `2000`.

**Expected:** 100 samples, 0% errors (with 2000 ms), Average ~40–180 ms (the SUT's default latency).

### `03-csv-berparameter.jmx` — Parameterised CSV (S3, ~8 minutes)

1. Open the file. Show **CSV Data Set Config - kenderaan**: `../data/kenderaan.csv`, `no_pendaftaran,model`, Ignore first line True, Recycle True, Stop thread False, Sharing *All threads*.
2. Show the **Uniform Random Timer (0.5-1.5s)**: Constant Delay Offset 500 + Random Delay Maximum 1000.
3. This plan only has a Summary Report — add a **View Results Tree** first (right-click Thread Group → Add → Listener → View Results Tree) → Start (10 × 10) → show the 5 registration numbers rotating.
4. **Live (Latihan 4):** add `ABC0000,Kereta Hantu` to the CSV → Start → Error % rises → **remove that row**.

**Expected:** 100 tax samples, 0% errors; with `ABC0000` ~1/6 fail.

### `04-rakaman-mentah.jmx` — The raw recording that fails (S4, ~8 minutes)

> ⛔ **Do not "fix" this file.** Its failure is the lesson.

1. Open the file. Show the Recording Controller with 3 samplers: `/api/log-masuk`, `/api/kenderaan`, `/api/kenderaan/WXY1234/bayar-cukai`.
2. Open sampler #2's Header Manager → `Authorization: Bearer 4e6b9c2a-8f0d-4c11-9a2e-token-rakaman-luput`. Open sampler #3's body → `"csrf": "a1b2c3d4e5f6a7b8-csrf-rakaman-luput"`. *"These values were frozen at the moment of recording."*
3. Show that the HTTP(S) Test Script Recorder in the plan is **disabled** — a GUI-only element, ignored in non-GUI mode.
4. Terminal:
   ```bash
   jmeter -n -t hari-1/test-plans/04-rakaman-mentah.jmx -l /tmp/rec.jtl -e -o /tmp/laporan-rakaman/
   ```
5. Open `/tmp/laporan-rakaman/index.html` → Error % **~67%**. Then open the plan in the GUI → Start → View Results Tree: green 200, red 401, red 401 (assertion *"Sepatutnya BERJAYA (akan GAGAL tanpa korelasi)"*).
6. Close with: *"Login succeeded and handed out a new token — but nobody captured it. Tomorrow morning we capture it."*

**Expected:** `/api/log-masuk` 200 · `/api/kenderaan` 401 · `bayar-cukai` 401. If the report folder already exists → `-o` fails; delete it first.

### `rakam-https-template.jmx` — HTTPS recording setup (S4, ~6 minutes)

1. Open the file: recorder on port 8888, Recording Controller, **no host filter** (Includes empty) — it will record **everything** the browser sends through the proxy.
2. Click **Start** once → show that the file `bin/ApacheJMeterTemporaryRootCA.crt` is generated (valid 7 days) → **Stop**.
3. Show (without completing it fully if time is short) importing into Firefox **Authorities** and the Windows **Current User** table.
4. **Do not** browse the real JPJ portal or public sites during the demo. If a live demo is needed, use a demo site that permits testing (e.g. `blazedemo.com`, one or two pages only) or a staging environment with written permission.
5. Use a **clean Firefox profile** — without a host filter, browser telemetry and extensions will also be recorded.
6. Close by **removing the certificate** and restoring the Firefox proxy settings.

---

## 🧯 Catch-up plan

| Situation | Action |
|---------|----------|
| Java/JMeter installation is slow (slow Wi-Fi / no admin rights) | Hand out USBs. No admin: Temurin ZIP + `JAVA_HOME` & Path under **User variables**. Still failing: pair with a colleague; they follow on the colleague's screen until the break. |
| Windows PATH does not work | Run `C:\apache-jmeter-5.6.3\bin\jmeter.bat` directly — PATH is only a convenience. Fix it during the break. |
| Class is > 20 minutes behind going into S3 | Combine Latihan 2 & 3 (build the CSV directly on the 20/10/5 plan); Latihan 4 & 5 become trainer demos. |
| Class is > 20 minutes behind going into S4 | Skip building the recorder from scratch — use `rakam-template.jmx` + `curl`. HTTPS becomes slides only. Make sure **everyone** sees the 401 from `04-rakaman-mentah.jmx` (non-GUI, 1 minute). |
| Firefox missing / blocked by policy | `curl` through the proxy (Latihan 6 step 3). Windows cmd: use the double-quote version in 🧯 Latihan 6, or Git Bash. |
| Port 8888 busy | Change the recorder port (e.g. 8889) and `curl -x http://localhost:8889`. |
| Fast / experienced participants | ⭐ The challenge in each lab; Cases 1–5 in README §3.4; Latihan 7; the full 3-step recording in `rakaman-e2e.md`. |

---

## 🌉 Bridge to Day 2 (last 5 minutes)

Leave the HTML report with ~67% errors, or the View Results Tree with two red 401s, on screen.

> *"Today we learned to generate load, validate responses, and record. But our recording failed — not because JMeter is broken, but because the portal gives every session a **new** token and csrf, and the recording keeps the **old** ones. First thing tomorrow morning we do **correlation**: capture `token` and `csrf` from the login response with a **JSON Extractor**, reuse them as `${token}` and `${csrf}` — and watch Error % drop from ~67% to 0%. Then we run real load in non-GUI mode, and read the report like a performance engineer."*

Preparation for participants (also in the README ➡️):
- Make sure `jmeter -v` and `node --version` work.
- Save your own recorded plan (`rakaman-saya.jmx`).
- Bring your Throughput / Average / 95% Line values from Latihan 2 and 5.

---

## 🔁 Day 2 opening: Day 1 revision (15 minutes)

For this cohort (Day 1 on 21 Sep 2026 → Day 2 on 5 Oct 2026 — a two-week gap), start Day 2 with a quick revision:

| Minutes | Activity |
|-------|----------|
| 0–5 | Participants answer the **Day quiz — Day 1 self-assessment** (5 questions) in the LMS. |
| 5–10 | Discuss the questions most often answered wrongly (see the LMS statistics). Repeat the three messages: target ethics, scope by position, percentiles not averages. |
| 10–15 | Everyone starts the SUT and runs `04-rakaman-mentah.jmx` once — sees 200 / 401 / 401 — and goes straight into correlation. |

Also check for participants who have not yet ticked the ✅ Checkpoints for Latihan 0–3 in the LMS — they may need installation help before Day 2's S1 begins.

---

## 📋 End-of-day check (trainer)

- [ ] Record the number of participants who saw the 401 from replaying a recording (target ≥ 90%)
- [ ] Note the 3 most common points of confusion → open Day 2 by correcting them (5 minutes)
- [ ] Make sure every machine can run `node sut/server.js` and `jmeter -v` — Day 2 depends on it
- [ ] Make sure **no** participant leaves the `ApacheJMeterTemporaryRootCA` certificate trusted in their browser/OS, and that the Firefox proxy has been restored
- [ ] Restore `hari-1/data/kenderaan.csv` on any machine that still has the `ABC0000` row
