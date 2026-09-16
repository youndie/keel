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

## Note added 2026-09-16, after B-01 merged

**There is no build job in CI at all**, so today a pull request that does not compile is green. B-01
closed against its own acceptance — a build that runs on the Linux box — and left CI alone; the
workflow's comment claimed the job had arrived with it, and that has been corrected.

This item was sized against "prove a suite ran on each target". It now also carries "run the build in
CI in the first place", which is the cheaper half and the one everything else waits on. **It became
more urgent the moment the loop started merging its own pull requests on green CI** (`CLAUDE.md`, the
loop section): green currently means the documentation gate passed and says nothing about the Kotlin.
`renovate.json` declines `automerge-harness` for exactly this reason, and that preset can be added in
the same change that closes this item.
