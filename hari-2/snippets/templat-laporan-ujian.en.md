# Performance Test Report Template (Test Report & Findings)

[⬅️ Day 2 README](../README.md) · [🧪 Day 2 Lab](./lab.md) · [📋 Test Plan Template](./templat-pelan-ujian.md)

> **How to use:** Copy this file (e.g. `laporan-<run-id>.md`). Section **A** is the blank ✍️ template; section **B** is an example already filled in with **real figures** from runs of plan `07-beban-puncak-cukai.jmx` against the `localhost:3000` mock (JMeter 5.6.3). Your run's figures will differ slightly — the mock latency is random (40–180 ms) and ~1% of payments deliberately fail (500).
>
> **Golden rule:** every finding must have **evidence** (a number + the dashboard section), its **impact** on users/the business, and a **recommendation**. The report's readers are management — start with the verdict, not with graphs.

---

## A. Blank template

### A1. Executive summary ✍️

| | |
|-|-|
| **Overall verdict** | PASS / FAIL / CONDITIONAL PASS |
| **One sentence** | *"At \_\_\_ users (\_\_\_ transactions/s), the \_\_\_ transaction achieved p95 \_\_\_ ms and Error % \_\_\_ — \_\_\_ the NFR."* |
| **3 key points** | 1. … 2. … 3. … |
| **Recommended actions** | … |

### A2. Run context ✍️

| Field | Value |
|-------|-------|
| Run ID / date & time | |
| System & version | |
| Environment (SUT, load generator) | |
| JMeter plan & JMeter version | |
| Exact command | `jmeter -n -t … -J… -l … -e -o …` |
| Load model (users, ramp-up, duration, think time) | |
| Test type (baseline / load / stress / spike / soak) | |
| Evidence files (`.jtl`, HTML report folder) | |

### A3. Results against the NFRs ✍️

| NFR | Target | Actual | Source (dashboard section) | Status |
|-----|---------|---------|-----------------------------|--------|
| | | | | ✅ / ❌ |

### A4. Key statistics (copy from Statistics) ✍️

| Label | #Samples | FAIL | Error % | Average | Median | 90th pct | 95th pct | 99th pct | Max | Transactions/s |
|-------|---------:|-----:|--------:|--------:|-------:|---------:|---------:|---------:|----:|---------------:|
| *(transaction row)* | | | | | | | | | | |
| *(each step)* | | | | | | | | | | |
| **Total** | | | | | | | | | | |

### A5. Findings ✍️

Repeat this block for each finding (target: 3 findings).

| Field | Content |
|-------|-----|
| **ID & title** | D1 — … |
| **Severity** | Critical / High / Medium / Low / Informational |
| **Evidence** | Figures + dashboard section (e.g. *Statistics → 95th pct*, *Charts → Over Time → Response Times Over Time*) |
| **Impact** | What it means for users / the business |
| **Probable cause** | Hypothesis — state it if not yet confirmed with server metrics |
| **Recommendation** | Next action + who |

### A6. Comparison with the baseline ✍️

| Metric | Baseline | This run | Change | Comment |
|--------|---------:|-----------:|----------:|-------|
| Transaction p95 (ms) | | | | |
| Transactions/s | | | | |
| Error % | | | | |

### A7. Limitations, assumptions & next steps ✍️

- …

### A8. Site comparison (for distributed / multi-site tests) ✍️

Agents: … (site → host:port) · Load per agent: … users × … loops · Total users = … × … agents = …

| Site | Label | Samples | Error % | Average ms | p90 ms | p95 ms | TPS | NFR (✅/❌) |
|--------|-------|-------:|--------:|----------:|-------:|-------:|----:|:----------:|
| | (transaction) | | | | | | | |
| | TOTAL (HTTP samples) | | | | | | | |
| | (transaction) | | | | | | | |
| | TOTAL (HTTP samples) | | | | | | | |
| Combined | Total | | | | | | | — |

Site findings: (1) … (2) …

---

## B. Filled-in example — Road Tax Price Increase Day (eJPJ mock)

> The data below comes from three real runs of plan `07` (50 users, ramp-up 10 s, 60 s) carried out while preparing the materials: **R1** SLA 2000 ms (normal mock), **R2** SLA 150 ms (normal mock), **R3** SLA 2000 ms with a "slow" mock (`LATENCY_MIN=500 LATENCY_MAX=1500`).

### B1. Executive summary

| | |
|-|-|
| **Overall verdict** | **CONDITIONAL PASS** (R1) |
| **One sentence** | *"At 50 users (10.46 transactions/s), the `Pembaharuan Cukai Jalan (Puncak)` transaction achieved p95 **583 ms** (target ≤ 2000 ms) but Error % of **1.00%** sits exactly on the NFR limit of < 1% — all errors are HTTP 500 on the payment step."* |
| **3 key points** | 1. Response times are well within the NFR (p95 583 ms ≈ 29% of the limit). 2. 500 errors on `bayar-cukai` (~1%) — not load-dependent, must be investigated. 3. If the server becomes 3× slower (R3), throughput drops 45% and p95 breaches the NFR. |
| **Recommended actions** | Investigate the cause of the 500s on `bayar-cukai` before the full load test; repeat the Load run after the fix; run a Stress test to find the knee point. |

### B2. Run context (R1)

| Field | Value |
|-------|-------|
| Run ID | R1 — 4 Oct 2026, 8.0x pm |
| System | Portal eJPJ (mock), `sut/server.js` (latency 40–180 ms, `ERROR_RATE` 0.01) |
| Environment | SUT + JMeter on the same laptop (macOS), loopback |
| Plan & JMeter | `hari-2/test-plans/07-beban-puncak-cukai.jmx`, JMeter 5.6.3, non-GUI |
| Command | `jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 -l r07a.jtl -e -o rep07a` |
| Load model | 50 threads, ramp-up 10 s, 60 s, Loop *Infinite*; think time Uniform Random 0.5–1.5 s × 4 samplers ≈ 4 s/iteration |
| Test type | Load (lab scale) |

### B3. Results against the NFRs (R1)

| NFR | Target | Actual | Source | Status |
|-----|---------|---------|--------|--------|
| Transaction p95 | ≤ 2000 ms | **583 ms** | Statistics → `Pembaharuan Cukai Jalan (Puncak)` row → 95th pct | ✅ |
| Transaction Error % | < 1% | **1.00%** (6 / 598) | Statistics → Error % | ❌ (exactly on the limit) |
| Transaction throughput | ≥ 10 /s | **10.46 /s** | Statistics → Transactions/s | ✅ |
| Login p95 | ≤ 1000 ms | **173 ms** | Statistics → `1. POST /api/log-masuk` | ✅ |
| Overall APDEX | ≥ 0.90 | **0.971** | APDEX → Total | ✅ |

### B4. Key statistics (R1, taken from the dashboard)

| Label | #Samples | FAIL | Error % | Average | Median | 90th pct | 95th pct | 99th pct | Max | Transactions/s |
|-------|---------:|-----:|--------:|--------:|-------:|---------:|---------:|---------:|----:|---------------:|
| Pembaharuan Cukai Jalan (Puncak) | 598 | 6 | 1.00% | 446 | 446 | 554 | 583 | 644 | 693 | 10.46 |
| 1. POST /api/log-masuk | 630 | 0 | 0.00% | 110 | 107 | 166 | 173 | 180 | 181 | 10.70 |
| 2. GET /api/kenderaan | 614 | 0 | 0.00% | 113 | 114 | 168 | 174 | 180 | 189 | 10.60 |
| 4. POST /api/kenderaan/BMT3030/bayar-cukai | 196 | 3 | 1.53% | 109 | 107 | 165 | 176 | 182 | 182 | 3.58 |
| 4. POST /api/kenderaan/JQK7788/bayar-cukai | 196 | 3 | 1.53% | 113 | 113 | 168 | 173 | 181 | 182 | 3.54 |
| **Total** | 2432 | 6 | 0.25% | 112 | 112 | 168 | 175 | 180 | 189 | 41.29 |

> Reading notes: (1) **Total** counts HTTP samples only (2432) — the transaction row is not included. (2) Steps 3 & 4 split into one row per vehicle because the sampler names contain `${no_pendaftaran}`. (3) 630 logins but 598 transactions: iterations still in progress when the 60 s duration ended produce no transaction sample.

### B5. Findings

**D1 — Transaction response time well within the NFR at lab-scale peak load**

| Field | Content |
|-------|-----|
| Severity | Informational (positive) |
| Evidence | R1: transaction p95 **583 ms**, p99 644 ms, Max 693 ms (*Statistics*). Regenerated at 5 s granularity: *Response Time Percentiles Over Time* (successful HTTP samples) — 95th percentile flat at 172–181 ms in every interval; *Response Times Over Time* transaction row 430–470 ms throughout the steady phase. Transaction APDEX 0.862 (a 4-step transaction ≈ 450 ms sometimes exceeds T = 500 ms — Tolerating, not Frustrated). |
| Impact | 95% of users complete a renewal (excluding think time) in < 0.6 s. |
| Cause | Mock latency 40–180 ms × 4 steps ≈ 440 ms on average — matching the Average of 446 ms. |
| Recommendation | Set per-transaction APDEX thresholds (`jmeter.reportgenerator.apdex_per_transaction`) so a 4-step transaction's APDEX is not judged against the same T = 500 ms as a single request. |

**D2 — ~1% of payments fail with HTTP 500, independent of load**

| Field | Content |
|-------|-----|
| Severity | **High** — causes the Error % NFR to fail (1.00% ≮ 1%) |
| Evidence | *Errors*: `500/Internal Server Error` = 6 (100% of errors, 0.25% of all samples). *Top 5 Errors by sampler*: 3 on `…/BMT3030/bayar-cukai`, 3 on `…/JQK7788/bayar-cukai`. *Codes Per Second* (5 s granularity): the `500` series appears in 5 of 12 intervals (0.2–0.4 /s), scattered — not clustered at peak load. |
| Impact | ~1 in 100 citizens has to repeat the payment — risk of double charges/complaints on the peak day. |
| Cause | The mock has `ERROR_RATE=0.01` (synthetic errors). In a real system: check the server logs at the timestamps of the failed samples (`timeStamp` in the `.jtl`). |
| Recommendation | Application team to investigate the 500s on `bayar-cukai`; repeat R1 after the fix. Compare with a 5-user baseline to prove it is not caused by load. |

**D3 — An overly strict NFR changes the verdict without any change to the system**

| Field | Content |
|-------|-----|
| Severity | Medium (process issue) |
| Evidence | R2 (`-Jsla_ms=150`, same system): transaction Error % **21.75%** (132 / 607), payment step 19–26%, Total 5.37%; transaction APDEX drops 0.862 → 0.717. *Errors* is full of rows like `The operation lasted too long: It took 1xx milliseconds, but should not have lasted longer than 150 milliseconds.` — one row per ms value, so add them all up. |
| Impact | Without agreed NFRs, a "pass/fail" verdict can be manipulated by changing the threshold. |
| Cause | Payment step p90 ≈ 165–171 ms; a 150 ms threshold cuts into the tail of the distribution. |
| Recommendation | Freeze the NFRs (with the system owner) **before** the run; state the `-Jsla_ms` value in every report. |

**D4 (optional) — When the server slows down, throughput drops even with the same users**

| Field | Content |
|-------|-----|
| Severity | High (capacity risk) |
| Evidence | R3 (mock 500–1500 ms, 50 users): transaction **5.78 /s** (R1: 10.46 /s, −45%), transaction p95 **4969 ms** (> 2000 ms ❌), APDEX Total 0.40. Little's Law: 5.78 × (3.95 + 4.0) ≈ 46 users — same user load, response time up → throughput down. |
| Impact | If the database/downstream services slow down on the peak day, the portal completes only about half as many renewals per hour. |
| Cause | Closed model: each thread waits for the response before its next iteration. |
| Recommendation | Monitor downstream service response times; run a Stress test to find the real knee point with server metrics. |

### B6. Comparison with the baseline

| Metric | Baseline (R1, normal mock) | R3 (slow mock) | Change | Comment |
|--------|--------------------------:|-------------------:|----------:|-------|
| Transaction p95 (ms) | 583 | 4969 | +752% | Breaches NFR-01 |
| Transactions/s | 10.46 | 5.78 | −45% | Same users (50) |
| Transaction Error % | 1.00% | 0.90% | ≈ same | Synthetic errors, not load |
| APDEX Total | 0.971 | 0.401 | −0.57 | Most samples > 500 ms |

### B7. Limitations & next steps

- The SUT is a mock with no database and no real capacity limits — the results demonstrate the **method**, not the real eJPJ capacity.
- The SUT and JMeter share one laptop; no server metrics were collected.
- A 60 s run is too short for a soak; Over Time graphs at the default 60 s granularity have only 1–2 points — regenerate with `-Jjmeter.reportgenerator.overall_granularity=5000`.
- Next: stepped Stress (50 → 100 → 150 users) + Spike, with CPU monitoring.

### B8. Site comparison — filled-in example (plan `09`, distributed test)

> A real run of `hari-2/run/run-berbilang-lokasi.sh` (JMeter 5.6.3, one machine, localhost only): agent **KL** `127.0.0.1:1099` → mock on port 3000 (40–180 ms); agent **PENANG** `127.0.0.1:1100` → mock on port 3001 (300–900 ms, imitating a distant network). Load per agent: 10 users × 3 loops, ramp-up 5 s → **20 users** in total. Figures taken from `laporan/<LOKASI>/statistics.json`.

| Site | Label | Samples | Error % | Average ms | p90 ms | p95 ms | TPS | NFR p95 ≤ 800 ms/step |
|--------|-------|-------:|--------:|----------:|-------:|-------:|----:|:------------------------:|
| KL | Pembaharuan Cukai Jalan (transaction) | 30 | 0.00 | 476 | 598 | 640 | 1.30 | — |
| KL | TOTAL (HTTP samples) | 120 | 0.00 | 119 | 170 | 178 | 4.04 | ✅ |
| PENANG | Pembaharuan Cukai Jalan (transaction) | 30 | 0.00 | 2430 | 2915 | 3000 | 1.06 | — |
| PENANG | TOTAL (HTTP samples) | 120 | 0.00 | 607 | 873 | 892 | 3.51 | ❌ |
| Combined | Total (`laporan/gabungan`) | 240 | 0.00 | 363 | 790 | 873 | 6.90 | — (hides the difference) |

| Finding L1 | |
|---|---|
| Severity | High |
| Evidence | PENANG transaction average **2430 ms** (p95 3000 ms) vs KL **476 ms** (p95 640 ms) — ~5× slower; each PENANG HTTP step 570–670 ms vs KL 110–130 ms; 0% errors at both sites (*Statistics*, per-site reports). |
| Impact | Citizens accessing from the PENANG area wait ~2.4 s per renewal compared with ~0.5 s in KL. |
| Cause | Latency on the path to the site (network), not an application failure — same application, 0% errors. |
| Recommendation | Check the PENANG network/WAN path (traceroute, RTT) and consider a CDN/regional entry point before tuning the servers. |

| Finding L2 | |
|---|---|
| Severity | Medium (reporting risk) |
| Evidence | The combined average of **363 ms** looks good, but with an NFR of p95 ≤ 800 ms per step: KL p95 175–180 ms ✅, PENANG p95 886–896 ms ❌. |
| Impact | A report that quotes only the combined figures would pass a system that fails for one site. |
| Cause | A combined average/percentile mixes the distributions of two different populations. |
| Recommendation | Report NFR results **per site** (`[LOKASI]` label + per-site reports); use combined figures only for total load/throughput. |
