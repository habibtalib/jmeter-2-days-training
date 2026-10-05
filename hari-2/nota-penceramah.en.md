# Trainer Notes — Day 2: Record & Playback, Performance Reports & Test Planning

[📖 Day 2 README](./README.md) · [🧪 Lab](./snippets/lab.md) · [📋 Test Plan Template](./snippets/templat-pelan-ujian.md) · [📝 Test Report Template](./snippets/templat-laporan-ujian.md) · [🗂️ Test plans](./test-plans/) · [⬅️ Day 1 README](../hari-1/README.md)

> **Core messages for today:**
> 1. **"A recording is a starting point, not a finished product."** The recorder copies what it sees — including tokens that will expire.
> 2. **"Green ≠ correct."** A playback that passes without restarting the SUT, or a 200 without an assertion, is a false pass.
> 3. **"The report is your product."** Every dashboard number must be explainable with the correct terminology.
> 4. **"Percentiles, baseline, NFRs — in that order."** Averages lie; a single run without a baseline means nothing; NFRs are agreed **before** the test.
> 5. **"User counts are calculated, not guessed."** N = X × (R + Z).
> 6. **"Only targets authorised in writing."** Our client is JPJ — participants must leave with this reflex.

## Presenter summary

| Item | Value |
|---------|-------|
| Client | JPJ — Road Transport Department Malaysia. The scenarios (road tax, summonses, registration numbers) are their world; invite them to relate to real systems **verbally**, not by testing real systems. |
| Date & context | Day 2: **Monday, 5 Oct 2026**. Day 1 was taught on **21 Sep** — two weeks ago. Recap is 10 minutes only; broken installations are caught in S1. |
| Focus (organiser's request) | **Record & playback to produce reports**, **explaining reports & terminology**, and **how to plan tests**. Correlation is taught as a tool to make recordings replayable — not as a stand-alone topic. Advanced logic controllers, JSR223, CI, distributed, Grafana = ⭐ brief overview. |
| Ratio | S1 ~40% demo/explanation · S2 ~35% · S3 ~55% (dashboard & terminology) · S4 ~45% · the rest is lab |
| Materials | Two-pane projector: Terminal A (SUT log) + JMeter GUI / browser (dashboard). Whiteboard: 4-step user journey, 401/403 table, APDEX formula, Little's Law. |
| Key moments | (1) S1: playback without restart = **all green** → restart → 200/401/200/401; (2) S1: only token correlated → **403**; (3) S2: Aggregate Report 80 + 20, transaction ≈ 440 ms despite 1–3 s think time; (4) S3: Over Time graph with 1 point → regenerate with `-g` at 5 s granularity; (5) S3: SLA 150 ms → Error % 1% → 22% with no change to the system; (6) S4: Little's Law predicts 46 users from the report; (7) S3 §3.9: combined average 363 ms hides PENANG p95 ≈ 890 ms |
| Required outputs by end of day | ≥ 85% of participants: Exercise 3 (replayable plan) + Exercise 4 (dashboard worksheet) + Exercise 6 (plan with N calculation) + Day quiz submitted |
| Progress in pelatih.my | JMeter runs on participants' laptops — the LMS cannot see it. The last item of each ✅ Checkpoint is ticked when **Quiz S1–S4** is passed; "Complete the Day 2 self-assessment" is ticked by the **Day quiz**. Remind participants to submit the quiz at the end of each session. |

### Real figures for reference (verified with JMeter 5.6.3 on the mock, 4 Oct 2026)

| Run | Figures |
|--------|-------|
| `04-rakaman-mentah.jmx` (playback) | 3 samples, Err 2 (66.67%); Errors: `401/Unauthorized` 2 · 100% · 66.67% |
| `05-transaksi-penuh.jmx` (10 × 2) | 80 HTTP samples + 20 transactions; 0% errors; transaction Avg ≈ 442 ms, p95 ≈ 561 ms; APDEX transaction 0.875, Total 0.975 |
| `07` R1 (`-Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000`) | Total 2432 samples, 41.29/s, Err 0.25% (6 × 500); transaction 598, **10.46/s**, Avg 446, p95 **583**, Err **1.00%**; APDEX Total 0.971, transaction 0.862 |
| `07` R2 (same, `-Jsla_ms=150`) | Total Err 5.37%; transaction Err **21.75%**, p95 572; bayar-cukai 19–26%; APDEX transaction 0.717; ~30 distinct `The operation lasted too long…` rows in Errors |
| `07` R3 (slow mock on port 3001, 500–1500 ms) | Total 22.78/s; transaction **5.78/s**, Avg 3954, p95 **4969**; APDEX Total 0.401 |
| Little's Law | R1: 10.46 × (0.446 + 4.0) ≈ 46.5 · R3: 5.78 × (3.954 + 4.0) ≈ 46.0 · average active threads ≈ 45.8 (10 s ramp-up) |
| Constant Throughput Timer 300/min (shared, current TG) as a child of login | login 5.39/s ≈ 323/min |
| `09` distributed (`run-berbilang-lokasi.sh`, 10 × 3 per agent, 2 agents) | Combined 240 HTTP samples, 0% errors, Avg 363, p95 873, 6.90/s; transaction KL Avg 476 / p95 640; PENANG Avg 2430 / p95 3000; step p95 KL 175–180, PENANG 886–896; Active Threads: 2 series (`127.0.0.1:1099-…`, `127.0.0.1:1100-…`) |

> Participants' figures will differ slightly (random mock latency 40–180 ms, `ERROR_RATE` 1%). Emphasise the **pattern**, not the exact values.

---

## ✅ Pre-class checklist (the night before / 8.15 am)

- [ ] **Java + JMeter 5.6** on the demo machine: `java -version` (≥ 8; 17 recommended) and `jmeter --version` → 5.6.x.
- [ ] **Start the SUT:** `node sut/server.js` → `Portal eJPJ (TIRUAN) berjalan di http://localhost:3000`. Test <http://localhost:3000/api/health>.
- [ ] **Recorder port 8888 free:** `lsof -iTCP:8888 -sTCP:LISTEN -n -P` (no output) / Windows `netstat -ano | findstr :8888`. Close Burp/Fiddler/other proxies.
- [ ] **curl through the proxy:** open `hari-1/test-plans/rakam-template.jmx` → Start the recorder → `curl -s -x http://localhost:8888 http://localhost:3000/api/health` → one sampler appears in the Recording Controller. Stop. Do not save changes to the template.
- [ ] **Windows participants:** Git Bash installed (the curl blocks in README §1.4 are bash). Without Git Bash → use `04-rakaman-mentah.jmx` as the recording (catch-up plan).
- [ ] **Browser proxy:** only if you want to show browser recording (Firefox → Manual proxy `localhost:8888`, clear *No proxy for*). The SUT has no web forms, so the main demo uses curl. **The CA certificate is only for HTTPS** — the SUT is `http://`, so it is not needed.
- [ ] **Backup reports:** run R1, R2 (and R3) once on the demo machine into `hasil/` (instructions in README §3.7) — if a live run fails, open the backup report.
  ```bash
  mkdir -p hasil
  jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
    -l hasil/r07-sla2000.jtl -e -o hasil/laporan07-sla2000 -Jjmeter.reportgenerator.overall_granularity=5000
  ```
- [ ] **No Internet needed** — the SUT, plans, data and reports are all local.
- [ ] Print / share `templat-pelan-ujian.md` and `templat-laporan-ujian.md` (or make sure participants can open them).
- [ ] ⚠️ **Check the target of every plan you will open:** HTTP Request Defaults → `localhost` / `3000` / `http`. Make this an ethics lesson.
- [ ] Confirm the **Evaluation form** link in the pelatih.my menu opens at **2.00 pm**.
- [ ] Pair list + identify 2–3 participants who fell behind on Day 1 (pair them with strong participants).

> ⚠️ **Room risk:** every participant runs their **own** SUT on `localhost:3000` and their **own** recorder on `localhost:8888`. Do not let anyone point curl/proxy/plans at a colleague's IP without consent — that is also "someone else's system". The `07` run with 50 users × 60 s is light for an ordinary laptop; do not raise it to the 300 × 300 s default in class.

---

## S1 · 9.00 – 10.30 am · Record & Playback (90 min)

| Time | Min | Activity | Notes |
|------|------:|----------|------|
| 9.00–9.05 | 5 | Welcome back. Day agenda (README schedule): *"Today we do a performance engineer's job, from recording all the way to report and plan."* pelatih.my progress = one quiz per session. | Say it directly: reports & planning are the afternoon focus. |
| 9.05–9.15 | 10 | **Day 1 recap** (§1.1): everyone runs `node sut/server.js`; open `04-rakaman-mentah.jmx` → **check HTTP Request Defaults together** → Start → 1 green, 2 red. Table of 4 quick questions. | This is also an installation check — broken JMeter/Java/Node is caught **now**. |
| 9.15–9.25 | 10 | **§1.2 Plan first** — whiteboard: 4 steps, names `T01…T04`, circle the dynamic data. Ask: *"One click on 'Pay' in the real portal — how many requests?"* | The "one action = one transaction" concept. |
| 9.25–9.40 | 15 | 🎬 **Demo §1.3–1.5**: Save As `latihan-01-rakaman.jmx`; HTTP Request Defaults; Grouping → *Put each group in a new transaction controller*; Excludes (+ analytics); Constant Timer `${T}`; Start; *Recorder: Transactions Control* dialog (type `T01_LogMasuk`); run the curl blocks with `sleep 6`; Stop. Expand the tree: name `/api/log-masuk-1`, Header Manager with hard-coded `Authorization: Bearer …`, literal `csrf` in the body, timer ≈ 6000 ms. | Show `lsof … :8888`. Stress: *"The recorder stores the Bearer token as fixed text; Cookies are dropped — cookie-based apps need a Cookie Manager."* |
| 9.40–10.00 | 20 | **Exercise 1** (pairs). | Walk around: issue #1 forgot Start / forgot `-x $P` → no samplers; issue #2 everything in one group (did not wait 5 s). Fast pairs → ⭐ format string. |
| 10.00–10.10 | 10 | 🎬 **Playback demo** (key moment #1): Start **without** restarting → all green. *"Ready for 300 users?"* Let them answer. Restart SUT → Start → 200/401/200/401. VRT: Sampler result → Request → Response data. Then correlate `token` only → **403** (key moment #2). | *"401 = who you are; 403 = is this request legitimate."* Ask why `T03` is green (no token needed) → the need for assertions. |
| 10.10–10.25 | 15 | **Exercise 2.** | If a participant's recording failed → use `04-rakaman-mentah.jmx` (catch-up plan). |
| 10.25–10.30 | 5 | Checkpoint + **Quiz S1**. | Bridge: *"After the break we fix this recording until 10, 50, 300 users can replay it."* |

**Short script (playback):**
> *"Imagine you record a video of yourself entering the bank with yesterday's access card. Today you show that video to the guard — the door does not open, because yesterday's card has been cancelled. That is recording playback. But if the bank forgot to cancel yesterday's card, the door opens — and you think your video 'worked'. That is a false pass."*

**Questions to ask:**
- "Why do we wait 6 seconds between steps?" (`proxy.pause` 5 s → new group)
- "What does `${T}` record?" (the real time gap between requests)
- "Why is everything green before the restart?" (the recording session is still alive in the mock's memory)
- "In the real JPJ system, what other dynamic values are there?" (session cookie, view-state, payment nonce, FPX transaction ID — **discuss only**)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "The recorder will handle the token" | The recorder copies literal values; correlation is our job (S2) |
| "All green = the script is correct" | False pass: the recording session is still valid; 200 without an assertion |
| "Just record with a normal browser" | The browser must be pointed at proxy 8888; this SUT is an API → curl |
| "You need a CA certificate to record" | Only for HTTPS |
| "401 and 403 are the same" | 401 = token (identity); 403 = csrf (request legitimacy) |

**✅ Before moving on to S2:** ≥ 80% of pairs have a 4-step recording (their own or `04-rakaman-mentah`) and can explain 401 vs 403.

---

## 10.30 – 10.45 am · Break

Leave the SUT running. Trainer: check who has no recording → give them `04-rakaman-mentah.jmx` (Save As into `hari-2/test-plans/`) for S2.

---

## S2 · 10.45 am – 1.00 pm · Making the Recording Replayable (135 min)

| Time | Min | Activity | Notes |
|------|------:|----------|------|
| 10.45–10.55 | 10 | §2.1 10-item checklist (show it on the recording on screen) + §2.2 parameterisation vs correlation. | Analogy: *"The CSV is your IC; the token is the counter queue number — only the counter knows it."* |
| 10.55–11.15 | 20 | 🎬 **Live build** §2.3–2.5: JSON Extractor `token;csrf` + default `TOKEN_TAK_JUMPA` → `Bearer ${token}` / `${csrf}` → CSV `pengguna.csv` → vehicle extractor `$.kenderaan[0]…` → path `${no_pendaftaran}`. Show the JSON Path Tester + Debug Sampler. | Type slowly. Stress extractor scope (child of the sampler) and the `.jmx` location (relative CSV path). |
| 11.15–11.25 | 10 | 🎬 §2.6–2.8: sampler names, Transaction Controller (Generate parent sample — show both), delete the `${T}` timer, Uniform Random Timer, Response Assertion, If Controller. | Ask: *"A timer under a TC with 4 samplers — how many pauses?"* (4) |
| 11.25–12.20 | 55 | **Exercise 3.** Functional test 1 × 1 first, then 10 × 2. | Common issues: CSV not found (plan not in `hari-2/test-plans/`), extractor not a child, 6 s recorded timer still present (run "hangs"). At 12.00: stuck pairs → open `05` and compare element by element. |
| 12.20–12.35 | 15 | 🎬 Run `05` (10 × 2): Summary vs Aggregate — every column (§2.9). 80 + 20; transaction ≈ 440 ms despite think time. | **Key moment #3.** *"Transaction time = system time; think time affects throughput, not response time."* — bridge to Little's Law. |
| 12.35–12.50 | 15 | ⭐ Brief §2.10: `08` ForEach (Match `-1`, *Add "_" before number ?* → 0 iterations without errors) + JSR223 (Cache, `vars.get`). **Or** catch-up time for Exercise 3. | Choose based on class progress — Exercise 3 matters more. |
| 12.50–1.00 | 10 | Checkpoint + **Quiz S2**. | Bridge: *"After lunch we stop looking at the GUI and start reading reports the way management reads them."* |

**Questions to ask:**
- "Why is the extractor default `TOKEN_TAK_JUMPA`, not empty?" (the failure becomes visible in the Request tab)
- "300 threads log in — how many tokens?" (300; `vars` is per thread)
- "Why an If Controller before paying?" (avoids bogus payments that pollute Error %)
- "Why one row per vehicle in the Aggregate Report?" (dynamic label `${no_pendaftaran}`)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "Put the extractor anywhere in the Thread Group" | Scope follows position — child of the login sampler |
| "Keep the recorded `${T}` timer — it is realistic" | It is **your** think time, identical for every thread → users move in lockstep; use a random timer |
| "Transactions should include think time" | Usually not — we measure system time |
| "Aggregate & Summary Report are the same" | Aggregate has Median & 90/95/99% Line; Summary has Std. Dev. & Avg. Bytes |

**✅ Before moving on to S3:** ≥ 80% have a plan that produces a `Pembaharuan Cukai Jalan` transaction row with Error % ≈ 0 (their own or `05`).

---

## 1.00 – 2.00 pm · Lunch

Remind them: **do not close Terminal A**. Trainer: open the R1/R2/R3 backup reports in browser tabs. **The course evaluation form opens at 2.00 pm** — mention it once at the start of S3, and again at the close.

---

## S3 · 2.00 – 3.30 pm · Reports & Terminology (90 min)

| Time | Min | Activity | Notes |
|------|------:|----------|------|
| 2.00–2.05 | 5 | Energiser: *"Who has ever been asked to 'make a report' from screenshots?"* Announce that the evaluation form is open. | |
| 2.05–2.13 | 8 | 🎬 §3.1: `mkdir -p hasil` → `jmeter -n -t …05… -l … -e -o …` → open `index.html`. Then `-g` into a new folder with `overall_granularity=5000`. Show the `folder is not empty` error. Anatomy of a `.jtl` (open it in an editor). | If `mkdir` is forgotten: `parent folder is not writable` error — show it as a lesson. |
| 2.13–2.25 | 12 | 🎬 **Dashboard tour** (§3.2–3.3, **shortened**) using the R1 backup report: Test and Report information → APDEX (formula on the board; failed = Frustrated) → Statistics (Total ≠ transaction) → Errors/Top 5 → **3 graphs only**: Active Threads, Response Times Over Time, Total TPS (+ Codes/s for R2). Other graphs = reference README §3.3 / Exercise 4. | **Key moment #4.** Show the 60 s granularity report (1 point) vs 5 s. One question per graph. |
| 2.25–2.38 | 13 | **Exercise 4** — worksheet (fast pairs complete all 14 rows; others at least 8). | Fast pairs → compare `statistics.json` with the table. |
| 2.38–2.45 | 7 | §3.5 glossary (pick 6: response time / latency, throughput / TPS, percentile vs average, APDEX, saturation) + §3.6 pattern table. "Averages lie" example on the board. | The glossary is a reference — do not read every row. |
| 2.45–2.48 | 3 | 🎬 §3.7: launch R1 & R2 (60 s each) — explain the Duration Assertion while waiting. | Participants start Exercise 5 at the same time. |
| 2.48–3.05 | 17 | **Exercise 5** — runs + comparison table + **2** findings in class (3rd finding as homework). Show the section B example in `templat-laporan-ujian.md`. | **Key moment #5:** R2 — Error % 1% → 22% with no change to the system. *"The only thing that changed is the definition of 'fast enough'."* |
| 3.05–3.12 | 7 | 🎬 **§3.9 Multi-site report** — demo `./run-berbilang-lokasi.sh` (script below). | **Key moment #7:** combined average 363 ms looks "OK" — PENANG p95 ≈ 890 ms fails. |
| 3.12–3.25 | 13 | **Exercise 8** — run the script, open the 3 reports, fill in the comparison sheet, 2 site findings. | Slow participants: use the trainer's report (screen share) and fill in the sheet only. Make sure the Terminal A SUT is stopped first (port 3000). |
| 3.25–3.30 | 5 | Checkpoint + **Quiz S3**. | |

**Short script (percentiles):**
> *"If 100 citizens renew their road tax and the average is 300 ms, we know nothing about the slowest citizens. A p95 of 583 ms means: 95 people finished within 0.6 seconds, 5 people took longer. A good NFR protects those 5 people."*

**🎬 Demo script §3.9 (7 minutes) — multi-site report:**

Before class: run `cd hari-2/run && ./run-berbilang-lokasi.sh` once to warm up the JVM and keep a backup report. During the demo: **stop the Terminal A SUT** (the script uses ports 3000/3001/1099/1100/4001/4002).

1. *(1 min)* Whiteboard: controller + 2 agents (KL 1099, PENANG 1100). *"JPJ places load generators in several states — one test, two sites. The agents generate the load; the controller only collects."*
2. *(2 min)* `./run-berbilang-lokasi.sh` (≈ 45 s). While it runs, show in the script: `-Jsite=KL` on the agent (local) vs `-Gpengguna=10` on the controller (all agents) → **10 × 2 = 20 users**. Point out `summary +` arriving in bursts: *"sample sender StrippedBatch — samples are sent back in batches."*
3. *(2 min)* `laporan/gabungan`: Statistics — `[KL]` & `[PENANG]` rows; Active Threads Over Time — **two series** `127.0.0.1:1099-…` and `127.0.0.1:1100-…` (proof that both agents ran). Total: average 363 ms.
4. *(2 min)* Comparison table on the console + `laporan/PENANG`: transaction KL 476 ms vs PENANG 2430 ms; step p95 180 vs 890 ms; 0% errors on both.

**Key message:** *"One test, many sites → one combined report for load & throughput, but NFR decisions must be made **per site**. A combined average hides the failing site. Label samples with the site (`[${__P(site)}]`) so you can break them down later."*

**Expected question — *"Why are PENANG's times higher?"***
> In the demo: because we deliberately gave the PENANG mock 300–900 ms latency (`LATENCY_MIN/MAX`) to imitate a distant network path; the KL mock has 40–180 ms. The application and load are the same (10 users per agent), with 0% errors on both → the difference is **latency**, not server capacity. In the real world, the response time measured by an agent = network (RTT, DNS, TLS, WAN/ISP path) **+** server. If all agents target the **same** server and only one site is slow → suspect that site's network/path (compare `Connect` and `Latency` in the JTL; traceroute). If all sites slow down together as load increases → suspect the server. Also check the agent itself (CPU maxed out, clock out of sync) before drawing conclusions.

**Questions to ask:**
- "Why is the transaction APDEX 0.86 when every step is 1.0?" (a 4-step transaction ≈ 450 ms is judged against the same T = 500 ms)
- "Why does Codes per Second show only 200 even though 22% of R2 failed?" (Duration Assertion; the HTTP code is still 200)
- "Throughput flattens even as users increase — what does that mean?" (saturation / knee point)
- "The 1% errors also happen at 5 users — load-related or not?" (baseline!)

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "The Statistics Total includes transactions" | Total = HTTP samples only; transaction rows are separate |
| "APDEX ignores errors" | In JMeter, a failed sample = Frustrated |
| "Latency = response time" | Latency = up to the first byte (including connect); response time = up to the last byte |
| "Hits/s = TPS" | 1 renewal transaction = 4 hits |
| "The Over Time graph is broken — only one point" | Default granularity is 60 s; regenerate with `overall_granularity` |
| "Max is the SLA" | Max = one sample; the SLA is on a percentile |

**✅ Before moving on to S4:** ≥ 85% have opened their own dashboard and filled in the worksheet; ≥ 60% have at least one written finding.

**⏱️ PerfMon + chatbot add-on (§3.10–3.11, Lab 9) — ~22 minutes.** The JPJ participants asked for this topic (their real reports have CPU from an agent + a chatbot system). Take the time from existing blocks:

| Original time | Change | Saved | Used for |
|---------------|--------|------:|----------|
| 3.05–3.12 §3.9 demo + 3.12–3.25 Lab 8 | §3.9 demo only (5 min); Lab 8 → homework / ⭐ | 15 | 🎬 PerfMon demo (8 min) + Lab 9 steps 5–8 with the trainer's report (7 min) |
| 2.38–2.45 glossary | Pick 4 terms, not 6 | 2 | §3.11 chatbot p95/p99 (whiteboard "1 in 100 questions") |
| 2.48–3.05 Lab 5 | 2nd finding becomes homework | 5 | Quiz S3 questions 6–7 + p95/p99 NFR |

**Night-before prep:** (1) install jpgc-perfmon, jpgc-cmd, jpgc-graphs-basic in the trainer's JMeter; (2) unzip ServerAgent-2.2.3; (3) run `./run-chatbot-perfmon.sh` once and keep the `hasil/<time>/` folder as a **backup report** (the run takes ~3.5 min — do not wait for it in class if you are late); (4) Apple Silicon Mac: the agent must use an x86_64 Java (README §3.10 "Limits & platform issues").

**Short script (chatbot p99):**
> *"The JPJ chatbot receives 10 questions per second. p95 1.7 s — OK. But p99 6 s means 6 people every minute wait more than 6 seconds, and many will press 'send' again. The 1.07 s average hides all of that."*
---

## 3.30 – 3.45 pm · Break

Trainer: write the formula `N = X × (R + Z)` and the R1 figures (10.46/s, 0.446 s, 4 s) on the board — ready for S4. Check how many have filled in the evaluation form.

---

## S4 · 3.45 – 5.00 pm · Planning Performance Tests (75 min)

| Time | Min | Activity | Notes |
|------|------:|----------|------|
| 3.45–3.55 | 10 | §4.1 lifecycle (diagram) + §4.2 NFRs: rewrite "the portal must be fast" together with the class into a SMART NFR. | Link each phase to what they did today. |
| 3.55–4.10 | 15 | §4.3 **Little's Law**: eJPJ example (36,000/hour → 10/s → 600 users). Then **check against R1**: 10.46 × 4.45 ≈ 46 ≈ active threads. R3: same N, R up → X down. Pacing: Constant Throughput Timer (samples/**minute**, child of the first sampler) & Precise Throughput Timer. | **Key moment #6.** *"Little's Law lets you sanity-check someone else's report in 30 seconds."* |
| 4.10–4.18 | 8 | §4.4–4.7: transaction mix, baseline → load → stress → spike → soak, entry/exit/suspension criteria, monitoring, risks, **written authorisation**. | Ask JPJ: *"Who in your organisation signs the authorisation for a load test?"* |
| 4.18–4.38 | 20 | **Exercise 6** — fill in the plan template (pairs). | Make sure every pair has an N calculation with correct units (seconds). |
| 4.38–4.50 | 12 | **Exercise 7** — mini presentations, 3–4 pairs × 3 minutes. | Pick volunteers; if time is short, 2 pairs. One "How do you know…?" question per pair. |
| 4.50–4.53 | 3 | ⭐ Brief §4.9: CI (`jmeter -n` exits 0 even on failure → `statistics.json` gate), distributed (already demoed in §3.9 — just recap: each worker = the whole Thread Group, `-G`), Grafana (live vs after the fact). | Concepts only — no demo. |
| 4.53–5.00 | 7 | **Closing** (see below). | **Do not** cut the closing + evaluation form. |

**Closing — script (7 minutes):**
1. **2-day summary** — table §4.10. *"On Day 1 you learned to generate load. On Day 2 you learned to generate the **right** load, read what it tells you, and plan it so the results can be trusted."*
2. **Course evaluation form:** *"The course evaluation form opened at 2.00 pm; complete it before we finish."* In pelatih.my → **Evaluation form** menu. Give 3 minutes in class — do not leave it for "later".
3. **Quiz S4 + Day quiz — Day 2 self-assessment**: submit now; it completes the lab checkpoints and the "Complete the Day 2 self-assessment" item.
4. **Certificates:** certificates of participation are issued by the organiser once attendance and the evaluation form are confirmed — do not promise dates you do not control.
5. **Final ethics message:** *"This repo, this SUT, these templates — take them home. But before JMeter is pointed at a real JPJ system: written authorisation, staging, a time window, and the infrastructure team monitoring alongside you."*

**Questions to ask:**
- "Volume 18,000/hour, R = 2 s, Z = 28 s — how many users?" (150)
- "Constant Throughput Timer 10 — why is the throughput far lower?" (the unit is samples/minute)
- "Why the baseline first?" (to separate load effects from pre-existing issues)
- "What is one thing you will change in how your team reports performance after this course?"

**Common misconceptions:**

| Misconception | Correction |
|-------------|------------|
| "Number of users = number of registered users" | **Concurrent** users = X × (R + Z) |
| "More threads = more throughput, forever" | Throughput is limited by capacity; after saturation, response time rises |
| "A pacing timer can speed things up" | Timers only slow things down; if N < X × (R + Z), add threads |
| "A small test against a public system is fine" | Size is irrelevant — written authorisation is mandatory |
| "Distributed splits threads among workers" | Every worker runs the **whole** Thread Group |

**✅ End-of-day criteria:** ≥ 85% submit the Day quiz; the evaluation form is completed by everyone; every pair has a plan with an N calculation; at least 2 mini presentations.

---

## 🎬 Demo scripts

### Recording demo (S1, ~15 minutes)
1. Open `hari-1/test-plans/rakam-template.jmx` → **Save As** `hari-2/test-plans/latihan-01-rakaman.jmx`.
2. Add HTTP Request Defaults (`localhost`/`3000`) under the Thread Group. Recorder: Grouping → *Put each group in a new transaction controller*; add `.*google-analytics.*` to Excludes; add a Constant Timer `${T}` under the recorder.
3. Start → show `lsof -iTCP:8888 -sTCP:LISTEN -n -P`. In *Recorder: Transactions Control*, type `T01_LogMasuk` → run the T01 block (README §1.4). Repeat T02–T04 with their own names, waiting > 5 s.
4. Stop. Expand the tree. Show: Header Manager `T02` → `Authorization: Bearer <uuid>` (fixed text); `T04` body → fixed `csrf`; Constant Timer → real numbers.
5. If recording fails on screen (proxy/port): switch immediately to `04-rakaman-mentah.jmx` — *"this is the result of the same recording."*

### Playback demo (S1, ~10 minutes)
1. Start without restarting → all green. Ask the class: ready for load?
2. Terminal A: Ctrl+C → `node sut/server.js`. Clear All → Start → 200 / 401 / 200 / 401.
3. VRT `T02` → Request (old token) vs `T01` Response data (new token).
4. JSON Extractor `token` only + `Bearer ${token}` → Start → `T02` 200, `T04` **403** `Token CSRF tidak sah — sila log masuk semula`.

### Plan `05-transaksi-penuh.jmx` (S2, ~5 minutes)
1. Show `Pembaharuan Cukai Jalan` → `Jika ada kenderaan` → `3. GET …/${no_pendaftaran}/cukai` → `4. POST …/bayar-cukai` (`"amaun": ${amaun}`), Uniform Random Timer under the TC.
2. Start (10 × 2). Aggregate Report: 80 HTTP samples + 20 transactions; 3 vehicle labels (`WXY1234`, `JQK7788`, `BMT3030` — the first vehicle of each CSV user).
3. If 1 error 500 appears: *"The SUT's `ERROR_RATE` of 1% — on purpose. The dashboard will show it this afternoon."*

### First dashboard (S3, ~10 minutes)
```bash
mkdir -p hasil
jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx -l hasil/r05.jtl -e -o hasil/laporan05
jmeter -g hasil/r05.jtl -o hasil/laporan05-5s -Jjmeter.reportgenerator.overall_granularity=5000
jmeter -g hasil/r05.jtl -o hasil/laporan05-5s      # ralat: folder is not empty (sengaja)
```

### Plan `07` — SLA (S3, ~5 minutes + run)
1. R1 & R2 (README §3.7, ≈ 1 minute each). While waiting: show the Duration Assertion `${__P(sla_ms,2000)}` in the GUI.
2. R2 → Errors: ~30 rows of `The operation lasted too long: It took 1xx milliseconds…` — *"this table groups by text; add them up."* Codes Per Second → only `200` (+ a few `500`). Transactions Per Second → `-failure` series.
3. ⭐ R3 (slow mock, port 3001) if time allows: `PORT=3001 LATENCY_MIN=500 LATENCY_MAX=1500 node sut/server.js` + `-Jport=3001` — throughput drops ~45%. Stop the 3001 mock afterwards.

### PerfMon + chatbot (S3, ~8 minutes + 3.5-minute run)
1. Whiteboard: JMeter machine ↔ server (ServerAgent port 4444). *"JMeter measures response time; CPU comes from an agent on the server — a separate `perfmon.jtl` file."*
2. Terminal: `./startAgent.sh --udp-port 0 --tcp-port 4444` → `telnet localhost 4444` → `test` → `Yep`. Show plan `10b` in the GUI: PerfMon Metrics Collector (CPU, Memory `usedperc`, Filename).
3. `cd hari-2/run && ./run-chatbot-perfmon.sh` (or open the backup report). While it runs: §3.11 — *"p95 vs p99, the average lies"*; show `summary` rising every 30 s.
4. Open `active-threads.png`, `cpu-perfmon.png`, `response-times-over-time.png` side by side: in our run CPU ≥ 80% from ~31 users, p95 1027 → 3567 ms in the same window, throughput flat at ~14 /s.
5. Dashboard → Statistics: p95 1665 vs **p99 6076 ms**; Response Time Percentiles (vertical tail after p95); **trap:** *Percentiles Over Time* = successful only — Max never passes ~3 s.
6. **Ctrl+C ServerAgent.** *"This agent has no password and can run commands (`exec`) — test env only, firewall, stop it after the test."*

**Expected question — *"Why is Memory at 94% for the whole test?"*** That is whole-laptop memory (macOS counts cache), flat from the start — not a leak. Take an idle baseline first; what matters is the **change** under load.

**Expected question — *"Our servers are Windows/Linux — is it the same?"*** Yes: `startAgent.bat`/`startAgent.sh` on the test server, open port 4444 only to the JMeter machine's IP. More modern alternatives: node_exporter/Prometheus or Telegraf/InfluxDB + Grafana.

### Little's Law (S4, ~5 minutes on the board)
```
R1:  X = 10.46 trans/s   R = 0.446 s   Z ≈ 4 × 1.0 s = 4.0 s
     N = 10.46 × 4.446 ≈ 46.5   (purata thread aktif ≈ 45.8: 10 s ramp-up + 50 s × 50)
R3:  X = 5.78            R = 3.954 s   Z = 4.0 s
     N = 5.78 × 7.954 ≈ 46.0    → N sama, R naik, X turun
```

---

## 🧯 Catch-up plan

| Situation | Action |
|---------|----------|
| JMeter/Java/Node broken on a participant's laptop (caught during the recap) | Pair them with a colleague immediately; fix it during the 10.30 break. Do not stop the class. |
| **Recording fails** (proxy, port 8888, no Git Bash, curl not going through the proxy) | Use `hari-1/test-plans/04-rakaman-mentah.jmx` (Save As into `hari-2/test-plans/`) as the recording — Exercises 2 & 3 run the same. For Exercises 4–5 use `05-transaksi-penuh.jmx` / `07`. |
| Port 8888 in use | Change the recorder port (e.g. 8889) and `P=http://localhost:8889` |
| More than 20 minutes behind on Exercise 3 | Open `05-transaksi-penuh.jmx`, run it, and **explain** each element to the pair. Building it themselves becomes homework. |
| The `07` run is too heavy for a laptop | `-Jpengguna=25`; or open the trainer's backup reports (share the `hasil/` folder via USB drive/class network). The patterns are still visible. |
| Class running late going into S3 | The dashboard tour stays in full (organiser's focus). Exercise 4: rows 1–9 only. Exercise 5: R1 & R2 + **two** findings. |
| Class running late going into S4 | Exercise 6: section 3 (NFRs) + Appendix A (Little's Law) + 12 (authorisation) only. Exercise 7: 2 pairs. Skip ⭐ §4.9. **Do not** cut the closing + evaluation form. |
| Fast / experienced participants | ⭐ recorder format string (Lab 1), Regex/Boundary + `08` ForEach (Lab 3), R3 + APDEX thresholds + stress (Lab 5), CI SLA gate (Lab 7), help other pairs. |

## 📋 End-of-day check (trainer)

- [ ] Record the number of participants who submitted the Day quiz (target ≥ 85%)
- [ ] Confirm the course evaluation form was completed by all participants (pelatih.my **Evaluation form** menu)
- [ ] Collect (photos of) the 2–3 best test plans & findings for the follow-up e-mail (with participants' permission)
- [ ] Stop the SUT (and the port 3001 mock if used); delete `hasil/` on the demo machine
- [ ] Send the organiser the attendance list for certificates
- [ ] Report any material issues found so the repo is fixed before the next class
