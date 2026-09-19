# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **course material repository** for a 2-day Apache JMeter performance-testing training course. Lecture notes are in **Bahasa Melayu**; technical terms (Thread Group, ramp-up, throughput, percentile, correlation, assertion, Transaction Controller, non-GUI, CI/CD) stay in **English**. The course project is load-testing a **Portal eJPJ (tiruan)** — a local mock of Malaysia's Road Transport Department (JPJ) online services (login, vehicle lookup, road-tax payment, summons).

**Ethics is a first-class constraint here.** JMeter is a load-generation tool; pointing it at a real production/public system without written authorization is effectively a DoS attack and illegal. Every test plan targets `http://localhost:3000` — the bundled mock in `sut/`. All data is synthetic (not real JPJ data). Keep this framing in any edits.

## Repository Structure

- `sut/server.js` — the System Under Test: a **zero-dependency** Node.js (`http` module) mock API. Run with `node server.js` (no `npm install`). Env vars `PORT`, `LATENCY_MIN`/`LATENCY_MAX`, `ERROR_RATE` tune its behavior for demos.
- `hari-{1,2}/README.md` — full step-by-step lecture notes for each day (Bahasa Melayu).
- `hari-{1,2}/test-plans/*.jmx` — reference JMeter test plans (JMeter 5.6 format, XML). These are the "solution" artifacts the READMEs teach you to build in the GUI.
- `hari-{1,2}/data/*.csv` — CSV Data Set inputs + data dictionaries.
- `hari-2/snippets/jsr223-groovy.groovy` — Groovy scripting examples.
- `hari-2/run/run-nogui.{sh,bat}` — non-GUI load run + HTML dashboard generator.
- `hari-{1,2}/snippets/lab.md` — per-day exercises.
- `slides/jmeter-training.html` — reveal.js deck, vendored under `slides/vendor/reveal/` (works from `file://`).

This layout mirrors the sibling `nodejs-2-days-training` and `powerbi-2-days-training` training repos (per-day folders, `snippets/` labs, vendored reveal.js deck).

## Course Progression

1. **Hari 1** — Install Java/JMeter, run the SUT, Test Plan anatomy & scope-by-position, Thread Group (threads/ramp-up/loop), HTTP Request Defaults + Header Manager, Listeners (View Results Tree / Summary / Aggregate), Response + Duration Assertions, Timers (think time), CSV Data Set parameterization, recording with the HTTP(S) Test Script Recorder (motivates Day 2 correlation).
2. **Hari 2** — Correlation (JSON/Regex/Boundary Extractor for `token` + `csrf`), Logic Controllers (Transaction, If), JSR223 Groovy + JMeter functions (`__Random`/`__UUID`/`__P`), non-GUI runs + HTML dashboard, reading throughput/percentile/error%/APDEX + SLA/NFR, brief distributed testing / CI-CD / Grafana.

## SUT Contract (keep test plans in sync with this)

Base: `http://localhost:3000`. Endpoints:
- `POST /api/log-masuk` — body `{no_kp, kata_laluan}` → `{token, csrf, nama}`. **token** and **csrf** are the dynamic values correlated on Day 2.
- `GET /api/kenderaan?no_kp=` — needs `Authorization: Bearer <token>` → `{kenderaan:[{no_pendaftaran, model, tarikh_luput_cukai, amaun_cukai}]}`.
- `GET /api/kenderaan/:no/cukai` → `{amaun, tempoh_bulan}` (404 if vehicle unknown).
- `POST /api/kenderaan/:no/bayar-cukai` — needs token + body `{csrf, tempoh_bulan, amaun}`; wrong/missing csrf → 403; ~1% synthetic 500.
- `GET /api/saman?no_kp=` → `{saman:[...]}`.
- `POST /api/saman/:id/bayar` — needs token + `{csrf}`.

Synthetic users: `800101015500` (WXY1234, VAB88), `900202025600` (JQK7788), `850303035700` (BMT3030, PKL909). Any non-empty password is accepted.

## Verifying Test Plans

All `.jmx` are valid JMeter 5.6 XML and have been run non-GUI against the live mock (0 errors). To re-verify:

```bash
node sut/server.js &                      # start SUT
jmeter -n -t hari-1/test-plans/03-csv-berparameter.jmx -l /tmp/r.jtl
jmeter -n -t hari-2/test-plans/05-transaksi-penuh.jmx -l /tmp/r5.jtl
jmeter -n -t hari-2/test-plans/07-beban-puncak-cukai.jmx -Jpengguna=10 -Jrampup=2 -Jtempoh=8 -l /tmp/r7.jtl
```

`07-beban-puncak-cukai.jmx` is the "price-hike-day" peak-load renew scenario: it pays road tax using the amount from the quote endpoint (`GET /cukai`) and gates each transaction with a **Duration Assertion** (SLA), tunable via `-Jsla_ms` (default 2000). Lower `-Jsla_ms` to demonstrate SLA breaches surfacing as Error %.

CSV `filename` paths in the `.jmx` are **relative to the `.jmx` file** (`../data/...`), so run from any cwd but keep the folder layout intact.

For a full load run with the HTML dashboard, use the wrapper (it points at `06-ujian-beban-nogui.jmx`):

```bash
cd hari-2/run
./run-nogui.sh                        # default: 50 users, ramp 30s, 120s
PENGGUNA=200 RAMPUP=60 TEMPOH=300 ./run-nogui.sh
# report: hari-2/run/hasil/<timestamp>/laporan/index.html
```

Plan `06` reads its load model from JMeter properties, so it's tunable without editing the `.jmx`: `-Jpengguna` / `-Jrampup` / `-Jtempoh` / `-Jhost` / `-Jport` (defaults via `__P(...,<default>)`). The wrapper maps the `PENGGUNA`/`RAMPUP`/`TEMPOH`/`HOST`/`PORT` env vars onto those `-J` flags. Plan `07` adds `-Jsla_ms` on top of these.

⚠️ **`hari-1/test-plans/04-rakaman-mentah.jmx` is intentionally broken — do not "fix" it.** It's the raw output of the HTTP(S) Test Script Recorder with a hardcoded/expired `token` + `csrf`. On replay, login returns 200 but `/api/kenderaan` and `bayar-cukai` return **401**, and the `BERJAYA` assertion fails — that failure is the teaching point (it motivates Day 2 correlation; the corrected version is `hari-2/test-plans/04-korelasi-log-masuk.jmx`). Its embedded `ProxyControl` (HTTP(S) Test Script Recorder) is a GUI-only, non-test element and stays `enabled="false"` so non-GUI runs ignore it.

## Language & Conventions

- **Lecture text, UI labels, comments in the mock:** Bahasa Melayu (e.g. "log masuk", "sebut harga", "beban", "think time").
- **JMeter element names & technical terms:** English (Thread Group, Response Assertion, Transaction Controller, etc.).
- **Domain nouns / variables:** BM snake_case (`no_kp`, `no_pendaftaran`, `amaun`, `tarikh_luput_cukai`), matching the CSV headers and JSON fields.
