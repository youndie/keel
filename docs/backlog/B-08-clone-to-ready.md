---
id: B-08
title: "Clone to /health/ready on a machine that has never seen the portfolio, timed"
status: open
priority: P1
size: S/M
stage: m3-measured
epic: feature-item-round-trip
blocked_by: [B-04]
---

# B-08 — The hour, measured rather than claimed

Acceptance 1 of the brief declares an hour of wall time, including the toolchain fetch, from a clone
to a service answering `/health/ready` on both targets. Nothing has been timed. This item produces
the number and puts it in the README with the date it was taken.

- **The decision and its reason.** The figure goes in the README **whatever it turns out to be**. A
  README that promises an hour and delivers two is worse than one that says two: the first thing a
  reader of a starter does is compare the claim with their own clock.
- The hypothesis is that the time is dominated by two downloads — roughly a gigabyte of Kotlin/Native
  toolchain, and the `gradle:9.7.1-jdk25-noble` builder image — and that the `~/.konan` cache mount
  keeps the second image build off the network. If the hypothesis is wrong, what actually dominates
  is the interesting finding.
- **A machine that has never seen the portfolio** means empty `~/.gradle`, empty `~/.konan`, no
  Docker layer cache. A warm machine measures the cache.
- Not covered: the "stranger test", a clone with **no** portfolio repository configured. That waits
  for kore and sborka on Maven Central and is not keel's work; until then the README carries the
  reposilite block with the date it is expected to go.

- AC: a transcript with timestamps for each phase — toolchain fetch, `build`, `check`, image build,
  first `200` from each binary — and one line in the README.
- AC: if the hour is missed, the README says the measured number and the item records which phase ate
  it, so the next reader knows what to attack.
- Anchors: `README.md`, `Dockerfile`, `.github/workflows/check.yaml`
