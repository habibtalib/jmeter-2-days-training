# Performance Test Plan Template

[⬅️ Day 2 README](../README.md) · [🧪 Day 2 Lab](./lab.md) · [📝 Test Report Template](./templat-laporan-ujian.md)

> **How to use:** Copy this file (e.g. `pelan-ujian-<team>.md`) and fill in every section. The **Filled-in example (eJPJ)** column shows one complete answer for the Portal eJPJ (mock) — replace it with your own system. Sections marked ✍️ are where you write.
>
> ⚠️ **All example figures are TRAINING ASSUMPTIONS**, not official JPJ statistics. The target system in this course is **only** `http://localhost:3000` (the mock in `sut/`). A plan for a real system is **not valid** without written authorisation (section 12).

---

## 0. Document information

| Field | Filled-in example (eJPJ) | ✍️ Yours |
|-------|---------------------|---------|
| Title | Performance Test Plan — Road Tax Renewal (Price Increase Day) | |
| System | Portal eJPJ (mock), course repo `sut/server.js` version | |
| Plan version / date | v0.1 · 5 Oct 2026 | |
| Prepared by | Pair A (course participants) | |
| Reviewed / approved by | Trainer (for the exercise) · *real system: system owner + head of infrastructure* | |
| Status | Draft | |

---

## 1. Background & objectives

**Background (example):** On the last day before the road tax price increase, portal traffic is expected to surge several times above a normal day. Management wants to know whether the **road tax renewal** flow stays within acceptable response times at peak load, and where its capacity limit is.

**Business questions that must be answered:**

| # | Question | Filled-in example (eJPJ) | ✍️ Yours |
|---|--------|---------------------|---------|
| Q1 | Can the system handle the **expected** peak load? | Can 10 renewals/second be sustained for 30 minutes within the NFRs? | |
| Q2 | Where is the **capacity limit** (knee point)? | At how many transactions/second does p95 exceed 2000 ms or Error % exceed 1%? | |
| Q3 | How does the system respond to a sudden **spike**? | Recovers in < 5 minutes after a 2× spike with no persistent errors? | |
| Q4 | Is performance **stable** over a long period? | No p95 degradation > 20% and no memory leak over 4 hours | |

---

## 2. Scope

| | Filled-in example (eJPJ) | ✍️ Yours |
|-|---------------------|---------|
| **In scope** | Login → vehicle list → road tax quote → pay road tax (APIs `POST /api/log-masuk`, `GET /api/kenderaan`, `GET /api/kenderaan/:no/cukai`, `POST /api/kenderaan/:no/bayar-cukai`) | |
| **Out of scope** | Checking & paying summonses (phase 2), third-party payment gateway (FPX/card — replaced with a stub), static assets/CDN, mobile app | |
| **Assumptions** | The real payment gateway is not tested; the test database is sized equivalent to production | |

---

## 3. Non-functional requirements (NFR) / SLA

> Write **measurable** NFRs: *transaction + load + metric (percentile) + threshold + duration*. Avoid "the system must be fast".

| ID | NFR (filled-in example) | JMeter metric / source | Threshold | ✍️ Yours |
|----|--------------------|------------------------|--------|---------|
| NFR-01 | **Pembaharuan Cukai Jalan** (road tax renewal) transaction at **10 transactions/s** for 30 minutes | `95th pct` of the transaction row (Statistics / `pct2ResTime`) | ≤ **2000 ms** | |
| NFR-02 | Transaction error rate at peak load | `Error %` of the transaction row | < **1%** | |
| NFR-03 | Sustained transaction throughput | `Transactions/s` of the transaction row | ≥ **10 /s** | |
| NFR-04 | Login at peak load | `95th pct` of `1. POST /api/log-masuk` | ≤ **1000 ms** | |
| NFR-05 | Overall user satisfaction | APDEX (T = 500 ms, F = 1500 ms — JMeter defaults) | ≥ **0.90** | |
| NFR-06 | Application server resources | Average CPU (server monitoring tool) | < **75%** | |

**SLA vs SLO vs NFR (for this document):** NFR = the requirement we test; SLO = the operations team's internal target; SLA = the contractual promise to users/clients (usually looser than the SLO).

---

## 4. Workload model

### 4.1 Business volume → target rate

| Input | Filled-in example (eJPJ) — assumption | ✍️ Yours |
|-------|-------------------------------|---------|
| Peak-hour volume | 36,000 renewals between 10.00 and 11.00 | |
| Target rate **X** (transactions/s) | 36,000 ÷ 3,600 s = **10 transactions/s** | |
| HTTP requests per transaction | 4 (login, list, quote, pay) | |
| Request rate (hits/s) | 10 × 4 = **40 requests/s** | |
| Expected transaction response time **R** | ≈ 2 s (same as the NFR-01 limit — a conservative estimate) | |
| Think time across the journey **Z** | 58 s (read the list 15 s + check the quote 20 s + fill in payment 23 s) | |

### 4.2 Little's Law — number of concurrent users

```
N = X × (R + Z)
N = pengguna serentak · X = throughput (transaksi/s) · R = masa respons (s) · Z = think time (s)
```

| | Filled-in example (eJPJ) | ✍️ Yours |
|-|---------------------|---------|
| N (virtual users / threads) | 10 × (2 + 58) = **600 concurrent users** | |
| Sanity check | 600 users × 1 journey every 60 s = 10 journeys/s ✔ | |

> **Check against the course lab (verified):** plan `07` has think time ≈ 4 s per iteration (Uniform Random Timer 0.5–1.5 s × 4 samplers) and R ≈ 0.45 s. A run with 50 users (ramp 10 s, 60 s) gives **10.46 transactions/s** → 10.46 × (0.45 + 4.0) ≈ **46** users — matching the average active threads (~46, because of the 10 s ramp-up).

### 4.3 Rate control (pacing)

| Option | Filled-in example (eJPJ) | ✍️ Yours |
|---------|---------------------|---------|
| Approach | **Closed model**: 600 threads + realistic think time | |
| Rate limiter | **Constant Throughput Timer** as a child of `1. POST /api/log-masuk`: Target throughput **600** (samples/minute), *Calculate Throughput based on* = **all active threads in current thread group (shared)** → maximum 10 iterations/s | |
| Alternative | **Precise Throughput Timer**: Target throughput 10, Throughput period 1 s, Test duration 1800 s | |

> ⚠️ A throughput timer counts **the samples it affects**. If it is placed directly under a Transaction Controller with 4 samplers, the target is counted per sampler (not per transaction). Place it as a **child of one sampler** (e.g. login) to control the transaction rate.

---

## 5. Transaction mix & scripts

| User journey | % of load | Rate (at 10 trans/s total) | JMeter script | Script status | ✍️ Yours |
|---------------------|--------:|--------------------------------|--------------|--------------|---------|
| Road tax renewal (login → list → quote → pay) | 70% | 7 /s | `07-beban-puncak-cukai.jmx` | Verified (0 functional errors at 1 user) | |
| Check only (login → list → quote, no payment) | 30% | 3 /s | Copy of `07` + **Throughput Controller** (Percent Executions 70) wrapping the payment step | To be built | |

**Key JMeter elements in the script:** `token` + `csrf` correlation (JSON Extractor), CSV `pengguna.csv`, Transaction Controller, Uniform Random Timer, Response Assertion `BERJAYA`, Duration Assertion `${__P(sla_ms,2000)}`, properties `-Jpengguna/-Jrampup/-Jtempoh`.

---

## 6. Test data

| Item | Filled-in example (eJPJ) | ✍️ Yours |
|---------|---------------------|---------|
| Source | `hari-2/data/pengguna.csv` (3 synthetic users), `kenderaan.csv` | |
| Volume required | Real system: ≥ 600 unique test accounts (one per virtual user) so there is no "false caching" | |
| Dynamic data | `token`, `csrf` — correlated at run time (not stored in the CSV) | |
| Re-provisioning | Payments change the data → reset the test database before every run | |
| Personal data | **Prohibited** — synthetic/masked data only | |

---

## 7. Test environment

| Component | Filled-in example (eJPJ) | Difference from production | ✍️ Yours |
|----------|---------------------|-------------------------|---------|
| SUT | Node.js mock `localhost:3000` (simulated latency 40–180 ms, `ERROR_RATE` 1%) | No database, no real capacity limits | |
| Load generator | Participant's laptop, JMeter 5.6.3, non-GUI | Same machine as the SUT → competes for CPU | |
| Network | Loopback | No Internet latency | |
| Frozen version | Course repo commit | — | |

> Results are only valid for the environment tested. State the differences from production and their impact on interpretation.

---

## 8. Test types & run schedule

| # | Type | Purpose | Configuration (real system — example) | Lab configuration (mock) | ✍️ Yours |
|---|-------|--------|---------------------------------------|---------------------------|---------|
| 1 | **Smoke / shakeout** | Scripts & environment work | 1–5 users, 5 min | `05-transaksi-penuh.jmx` (10 × 2 loops) | |
| 2 | **Baseline** | Reference at low load — compare every other run against it | 60 users (~1 trans/s), 15 min | `07` `-Jpengguna=5 -Jrampup=5 -Jtempoh=60` | |
| 3 | **Load** (expected peak) | Answer Q1 | 600 users, ramp 10 min, hold 30 min | `07` `-Jpengguna=50 -Jrampup=10 -Jtempoh=60` | |
| 4 | **Stress** (stepped) | Answer Q2 — find the knee point | 600 → 900 → 1200 (150%, 200%), 15 min per step | `07` `-Jpengguna=50/100/150` | |
| 5 | **Spike** | Answer Q3 | 100 → 1200 within 1 min, hold 5 min, back to 100 | Short ramp-up: `-Jpengguna=150 -Jrampup=1` | |
| 6 | **Soak / endurance** | Answer Q4 | 420 users (70%), 4–8 hours | `-Jtempoh=1800` (30 min, demo only) | |

**Standard run command (non-GUI):**

```bash
jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx \
  -Jpengguna=50 -Jrampup=10 -Jtempoh=60 -Jsla_ms=2000 \
  -l hasil/<id-larian>.jtl -e -o hasil/<id-larian>-laporan
```

---

## 9. Entry, exit & suspension criteria

| Type | Filled-in example (eJPJ) | ✍️ Yours |
|-------|---------------------|---------|
| **Entry** | Scripts pass smoke (0 functional errors); data prepared; environment frozen; monitoring active; **written authorisation signed**; NOC/SOC notified | |
| **Exit** | All planned runs complete; results analysed against the NFRs; report delivered; no open blocking issues | |
| **Suspend** | Error % > 10% for 2 min; load generator CPU > 80%; system owner's request; impact on other systems | |
| **Resume** | Cause identified & fixed; test manager's approval | |
| **Pass/fail** | PASS if NFR-01 to NFR-04 are met in the Load run; NFR-05/06 are reported as observations | |

---

## 10. Monitoring

| Layer | Metrics | Tool (example) | Owner | ✍️ Yours |
|---------|--------|---------------|---------|---------|
| Load generator | CPU, memory, network | Activity Monitor / Task Manager / `top` | Tester | |
| Client (JMeter) | Response time, throughput, Error %, active threads | `.jtl` + HTML dashboard; (optional) Backend Listener → InfluxDB/Grafana | Tester | |
| Application server | CPU, memory, threads/connections, error logs | APM / the organisation's monitoring tool | Application team | |
| Database | Slow queries, locks, connections | DBA tools | DBA | |

> Without server metrics, the report can only say *"what"* happened, not *"why"*.

---

## 11. Risks & mitigation

| Risk | Impact | Mitigation (example) | ✍️ Yours |
|--------|-------|-------------------|---------|
| Test environment smaller than production | Results cannot be extrapolated directly | State the ratio; test scaling in steps | |
| Load generator becomes the bottleneck | Figures measure JMeter, not the SUT | Non-GUI, no View Results Tree, monitor CPU < 80%, distribute if needed | |
| Test data runs out / repeats | False caching, data errors | Large enough CSV, reset the data | |
| Test affects other systems (shared network) | Service disruption | Agreed time window, a "STOP" contact person | |
| Third-party payment gateway | Charges / blocking | Use a stub; never target third parties | |

---

## 12. Authorisation & ethics

| Item | Filled-in example (eJPJ) | ✍️ Yours |
|---------|---------------------|---------|
| Authorised target | `http://localhost:3000` only (training) | |
| Written authorisation from | *Real system:* the system owner **and** the head of infrastructure/security | |
| Scope covered by the authorisation | Host/URL, endpoints, maximum load, time window (e.g. Saturday 10.00 pm – 2.00 am) | |
| Parties notified | NOC/SOC, application team, DBA | |
| Stop procedure | Tester presses Stop / `shutdown.sh`; contact person: ✍️ | |

> ⚠️ Without written authorisation, a load test against someone else's system is a denial-of-service (DoS) attack — even if the load is "small".

---

## 13. Roles & responsibilities

| Role | Responsibilities | ✍️ Name |
|---------|---------------|---------|
| Test manager / test lead | Plan, approval, pass/fail decision | |
| Performance test engineer | Scripts, data, runs, analysis, report | |
| System owner | Authorisation, NFRs, priorities | |
| Infrastructure / DBA | Environment, server monitoring | |

---

## 14. Deliverables

- This plan (approved)
- `.jmx` scripts + CSV data (under version control)
- Raw `.jtl` files + HTML dashboard report for every run
- **Test report** — use [`templat-laporan-ujian.md`](./templat-laporan-ujian.md)

---

## Appendix A — Little's Law worksheet (fill in during Exercise 6)

| Step | Formula | Your value |
|---------|---------|------------|
| 1. Peak-hour volume | V (transactions/hour) | |
| 2. Target rate | X = V ÷ 3600 | |
| 3. Expected transaction response time | R (s) | |
| 4. Think time across the journey | Z (s) | |
| 5. Concurrent users | N = X × (R + Z) | |
| 6. HTTP request rate | X × (number of requests per transaction) | |
| 7. Pacing (if threads < N) | Constant Throughput Timer = X × 60 samples/minute | |
