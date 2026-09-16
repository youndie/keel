---
id: B-13
title: "The first measurement on the stand: readiness, RSS at ready, p95 at a fixed rate"
status: open
priority: P1
size: M
stage: m3-measured
epic: feature-item-round-trip
blocked_by: [B-04, B-05]
---

# B-13 — A service without a number is not created

The brief's own first backlog item. `:server:measure` drives `k6/items.js` at a fixed rate and
records three things per target: time to `/health/ready`, RSS at ready, and p95 at that rate.

- **The decision and its reason.** `:server:measure` **refuses** to write into `docs/research/`
  unless `--stand` names two hosts; a local run prints and exits with "not a measurement" in its
  first line. Local numbers are how the last post shipped a wrong table, and a refusal is the only
  mechanism that survives somebody being in a hurry.
- **Read the peak from the cgroup, not from the process.** `memory.peak`, with the kill count from
  `memory.events`' `oom_kill` — not `/proc/<pid>/status`'s `VmHWM`, which counts the mapped pages of
  a ten-megabyte binary and reported 9 600 kB for a container the kernel was holding under an 8 MiB
  limit. A peak larger than the limit means the metric is wrong, not the limit.
- **A measurement is a comparison.** Sample against control, alternating, median of several runs, the
  first run after a restart discarded explicitly. And a positive control: the same image under a
  deliberately small limit must be killed, or the harness cannot detect a failure at all.
- The two-host shape — subject and generator on separate machines over a private link — is the one the
  container-limit study used, so "the stand" is a thing that exists rather than an aspiration.
- Not covered: tuning anything. This item produces numbers, and a number that suggests a change
  produces a different item.

- AC: `docs/research/measurements-<date>/` exists, written by a `--stand` run, carrying the raw k6
  output as well as the summary — a conclusion without its rows is not re-checkable.
- AC: a local run of the same task prints, refuses to write, and says why in one line.
- Anchors: `k6/items.js`, `server/build.gradle.kts`,
  `kotlin-skills/plugins/kotlin-fullstack/skills/native-service-bootstrap/references/memory-under-a-limit.md`
