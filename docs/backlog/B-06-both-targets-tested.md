---
id: B-06
title: "CI proves a suite ran on each target, rather than proving the build was green"
status: open
priority: P0
size: S
stage: m1-ships-twice
epic: feature-item-round-trip
blocked_by: [B-01]
---

# B-06 — A green build that visited nothing is the failure mode here

The brief's red list includes "a check that passes on one target and is skipped on the other", and
that is not hypothetical. In kore, a green `build` on one host meant `linuxArm64Test` **did not
exist** — Kotlin/Native has no `linux_arm64` host, so the plugin never creates the task — while
`macosArm64Test` was *disabled*. One word, "SKIPPED", stood for two different states for weeks.

- **The decision and its reason.** CI's build job ends by printing every test result file with its
  counts and failing when there are none. A suite that ran zero tests exits zero, so the only
  evidence that a target was tested is a result file with a number in it.
- For the target this host cannot run, linking and running are separable: CI links the test binary on
  x86-64 and **executes** it on an arm64 runner, which is what kore does since its own B-49.
- The rejected alternative is trusting `BUILD SUCCESSFUL` through a pipe. It has been wrong in this
  portfolio before; a result file and an artefact timestamp have not.
- Not covered: mutation testing. `sborka.mutation` exists and is deliberately not wired into `check`.

- AC: the build job fails when a target's result file is missing or reports zero tests, and the
  failure names the target.
- AC: `keel-server` §8's thirteenth quirk is verified as written — a local green build on one host is
  demonstrated not to cover the other.
- Anchors: `.github/workflows/check.yaml`, `Makefile`,
  `kore/CLAUDE.md`
