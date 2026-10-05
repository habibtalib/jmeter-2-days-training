# Day 2 (Hari 2) screenshots: manifest

All images are real captures taken 2026-10-05 from JMeter 5.6.3 runs against the localhost mock SUT (`sut/server.js`). No mock-ups.

## How they were produced

| Run | Command (plan copies run from a scratch dir; mock on a local port) | Result |
|---|---|---|
| `rep05` | `05-transaksi-penuh.jmx` (10 users, 2 loops), mock 40–180 ms | 80 samples, 0 % error |
| `rep07` | `07-beban-puncak-cukai.jmx -Jpengguna=50 -Jrampup=10 -Jtempoh=60` (default SLA 2000 ms) | 2 438 samples, 0.25 % error (synthetic 500s) |
| `rep07sla` | same plus `-Jsla_ms=150` | 2 455 samples, 5.78 % error (Duration Assertion breaches + 500s) |
| `rep07slow` | `-Jpengguna=200 -Jrampup=40 -Jtempoh=75` against a slow mock (`LATENCY_MIN=300 LATENCY_MAX=900`) | 6 813 samples, 0.28 % error |

Dashboards use `-Jjmeter.reportgenerator.overall_granularity=2000` (2 s points). Captured with Playwright at a 1440 px viewport, 2x scale, then downscaled to 1600 px max width or less.

Session key: **S1** record/playback · **S2** replayable script (correlation, Transaction Controller) · **S3** HTML dashboard reports & terms · **S4** test planning (SLA/NFR, load model) · **Lab N** = matching lab.

## Files

| File | Size (px) | Shows | Fits | Caption (EN) | Kapsyen (BM) |
|---|---|---|---|---|---|
| `h2-10-dashboard-info-apdex.png` | 1600×1382 | Dashboard top: Test and Report information, APDEX table (T=500 ms, F=1.5 s; Total 0.972), Requests Summary pie | S3, Lab dashboard | The first screen of the HTML dashboard: run info, APDEX per label and pass/fail split. | Skrin pertama dashboard HTML: maklumat larian, APDEX setiap label dan pecahan lulus/gagal. |
| `h2-11-requests-summary-pie.png` | 1128×560 | Requests Summary pie: PASS 99.75 % / FAIL 0.25 % | S3 | Requests Summary: share of passed and failed samples. | Requests Summary: peratus sampel lulus dan gagal. |
| `h2-12-statistics-table.png` | 1600×1009 | Full Statistics table for the peak run (samples, FAIL, Error %, avg/min/max/median, p90/p95/p99, Transactions/s, KB/s) | S3, S4 | The Statistics table: read p90/p95/p99 and Error % first, then throughput. | Jadual Statistics: baca p90/p95/p99 dan Error % dahulu, kemudian throughput. |
| `h2-13-errors-table.png` | 1600×1077 | Errors table from the SLA-breach run (`-Jsla_ms=150`), cropped to the top rows. Each Duration Assertion message includes the exact ms, so the same failure splits into many rows. A `500/Internal Server Error` row also appears. | S3, S4, Lab SLA | Errors table: SLA breaches from the Duration Assertion appear as errors. One row per message, so similar failures split up. | Jadual Errors: pelanggaran SLA oleh Duration Assertion dikira sebagai ralat. Satu baris bagi setiap mesej, jadi ralat yang sama terpecah. |
| `h2-14-apdex-sla-breach.png` | 1257×1600 | APDEX table of the SLA-breach run (lower scores on the bayar-cukai labels) | S3, S4 | APDEX drops for the labels that fail the SLA. | Skor APDEX jatuh bagi label yang gagal SLA. |
| `h2-15-response-times-over-time.png` | 1600×795 | Response Times Over Time, per label + Transaction Controller "Pembaharuan Cukai Jalan (Puncak)" (~450 ms) above individual requests (~110 ms) | S3, S2 | Response Times Over Time: the transaction line sits above its individual requests. | Response Times Over Time: garis transaksi berada di atas permintaan individu. |
| `h2-16-active-threads-over-time.png` | 1600×726 | Active Threads Over Time: ramp-up 0→50 in 10 s, hold, ramp-down | S3, S4 | Active Threads Over Time: check that the load model (ramp-up, hold) really ran. | Active Threads Over Time: sahkan model beban (ramp-up, tahan) benar-benar berlaku. |
| `h2-17-transactions-per-second.png` | 1300×674 | Transactions Per Second per label (success/failure series) | S3 | Transactions Per Second for each label. | Transactions Per Second bagi setiap label. |
| `h2-18-response-time-percentiles.png` | 1600×795 | Response Time Percentiles curve (0–100th) per label | S3, S4 | Percentile curve: read p90/p95 off the x-axis. The transaction tail rises near p99. | Lengkung persentil: baca p90/p95 pada paksi-x. Ekor transaksi naik berhampiran p99. |
| `h2-19-response-time-distribution.png` | 1600×795 | Response Time Distribution histogram (bucketed counts) | S3 | Response Time Distribution: how many samples fall in each time bucket. | Response Time Distribution: bilangan sampel dalam setiap julat masa. |
| `h2-20-latencies-over-time.png` | 1600×795 | Latencies Over Time (time to first byte) per label | S3 | Latencies Over Time: time to the first byte, compared with full response time. | Latencies Over Time: masa ke bait pertama, berbanding masa respons penuh. |
| `h2-21-slow-response-times-over-time.png` | 1600×795 | Response Times Over Time on the slow mock (300–900 ms per request; transaction ~2.4 s) | S3, S4 | Same chart, slower server: every line shifts up, and the transaction takes ~2.4 s. | Carta sama, pelayan lebih perlahan: semua garis naik, transaksi ~2.4 s. |
| `h2-22-slow-total-tps.png` | 1600×726 | Total Transactions Per Second on the slow run: rises with ramp-up to ~150–160/s then plateaus | S3, S4 | Total TPS climbs with ramp-up, then levels off when the user count stops growing. | Jumlah TPS naik semasa ramp-up, kemudian mendatar apabila bilangan pengguna berhenti bertambah. |
| `h2-23-slow-time-vs-threads.png` | 1300×702 | Time Vs Threads (1→200 active threads) on the slow run: response time stays flat | S3, S4 (saturation discussion) | Time vs Threads: a flat line means the server is not saturated yet. A real bottleneck shows a rising curve. | Time vs Threads: garis mendatar bermaksud pelayan belum tepu. Kesesakan sebenar menunjukkan lengkung yang naik. |
| `h2-24-transaction-statistics-05.png` | 1600×926 | Statistics for plan 05: four requests + Transaction Controller row "Pembaharuan Cukai Jalan" (avg 449 ms = the sum of the steps; think time excluded) | S2, S3, Lab 05 | The Transaction Controller adds one business-level row: the time of the whole renewal. | Transaction Controller menambah satu baris tahap perniagaan: masa keseluruhan pembaharuan. |
| `h2-25-top5-errors-by-sampler.png` | 1600×702 | Top 5 Errors by sampler (SLA-breach run): only the 3 `bayar-cukai` POSTs fail (43–52 errors each) | S3, S4, Lab SLA | Top 5 Errors by sampler: shows which request breaks the SLA. | Top 5 Errors by sampler: menunjukkan permintaan mana yang melanggar SLA. |
| `h2-26-statistics-sla-breach.png` | 1600×1036 | Statistics of the SLA-breach run: Total 5.78 % error, bayar-cukai 21–26 %, transaction 23.47 % | S3, S4 | A tighter SLA (150 ms) turns slow responses into Error %, with no code change. | SLA lebih ketat (150 ms) menukar respons perlahan menjadi Error %, tanpa ubah kod. |
| `h2-27-gui-json-extractor-05.png` | 1600×389 | JMeter GUI, plan 05: tree with Transaction Controller + JSON Extractor "Ekstrak token + csrf" selected (`token;csrf`, `$.token;$.csrf`, defaults `TOKEN_TAK_JUMPA;CSRF_TAK_JUMPA`) | S2, Lab correlation | JSON Extractor captures token and csrf from the login response. | JSON Extractor menangkap token dan csrf daripada respons log masuk. |
| `h2-28-gui-transaction-controller-05.png` | 1600×389 | JMeter GUI, plan 05: Transaction Controller "Pembaharuan Cukai Jalan" selected; options "Generate parent sample" / "Include duration of timer…" both unchecked | S2 | The Transaction Controller groups the renewal steps into one measurable transaction. | Transaction Controller menghimpunkan langkah pembaharuan menjadi satu transaksi yang boleh diukur. |
| `h2-29-gui-recorder-settings.png` | 1600×827 | JMeter GUI, `hari-1/test-plans/rakam-template.jmx`: HTTP(S) Test Script Recorder (port 8888, Target Controller = Recording Controller, grouping "Add separators between groups", naming scheme Prefix) | S1, Lab recording | HTTP(S) Test Script Recorder: proxy port 8888, recorded requests go to the Recording Controller. | HTTP(S) Test Script Recorder: proksi port 8888, permintaan dirakam ke dalam Recording Controller. |

## Notes / caveats

- **GUI tree highlight:** in `h2-27`/`h2-28` the tree shows more than one highlighted row (HTTP Request Defaults stays highlighted). The automation selected nodes through macOS accessibility, which adds to the selection instead of replacing it. The right-hand panel always shows the intended element. Retake by hand if a clean single highlight matters.
- **Saturation:** the mock adds a random delay per request with no queueing, so it does not saturate. `h2-21`–`h2-23` show "slower server, more users", not a real knee. Present `h2-23` as the "healthy / not saturated" reference.
- **Not captured:** Aggregate Report after a GUI run, and the Recorder's "Requests Filtering" tab. GUI control through accessibility was intermittent because the window was on a background Space, and keystroke automation was avoided.
- The plans' default port 3000 shows in the GUI shots (`localhost:3000`). The dashboard runs used scratch copies on other local ports. No course `.jmx` was modified.
