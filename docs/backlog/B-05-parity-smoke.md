---
id: B-05
title: "The parity normaliser is written before the first parity run"
status: wip
priority: P1
size: S/M
stage: m3-measured
epic: feature-item-round-trip
blocked_by: [B-02, B-03]
---

# B-05 — Parity, against a normaliser that existed first

Acceptance 4 of the brief: the same k6 scenario against the JVM and the native binaries produces no
diff after the declared normaliser. The order is the whole item — the normaliser is committed
**before** the first run.

- **The decision and its reason.** A normaliser written after a red run is a list of whatever
  differed, and it absorbs the next real divergence without anybody noticing. Written first, it is a
  statement about what the two platforms are allowed to disagree on.
- What it declares, from [research-architecture](../research/research-architecture.md) D6: the exit
  code (`0` native, `143` JVM — both correct), the `Server` header, `Date`, and `/version`'s build
  time. Everything else is a diff and fails.
- The rejected alternative is comparing latencies. That is a measurement, not a parity check, and it
  belongs to [B-13](B-13-first-measurement-on-the-stand.md).
- Not covered: sborka's `sborka.parity` convention, which asks the *platform* (hostname resolution,
  connect, environment) rather than the application. It is worth applying later and is a different
  question.

- AC: `k6/items.js` runs against both binaries; the recorded responses are identical after the
  normaliser; the normaliser file's commit predates the first run's.
- AC: the harness asserts a **rendered body**, not a status code — the check the static image needs.
- Anchors: `k6/items.js`, `k6/normalise.js`, `.github/workflows/check.yaml`,
  `sborka/docs/research/research-parity.md`
