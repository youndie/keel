---
id: B-04
title: "Two images from one Dockerfile, both measured against a budget declared first"
status: wip
priority: P0
size: M
stage: m2-image
epic: feature-item-round-trip
blocked_by: [B-01]
---

# B-04 — The image, and the number beside it

sborka's `writeNativeDockerfile` produces the reference two-stage file; keel commits it, fills the
two holes, and adds the `STATIC=1` variant behind a build arg. The budgets were declared in the
brief before any commit — under 25 MB on `distroless/cc`, under 12 MB with `STATIC=1` — and this item
is where they meet a real image.

- **The decision and its reason.** `gcr.io/distroless/cc-debian13` is the default and `scratch` is a
  flag ([research-architecture](../research/research-architecture.md) D3). `distroless/base` is not
  a candidate at all: Kotlin/Native's exception handling imports thirteen `_Unwind_*` symbols from
  `libgcc_s`, which `base` does not carry, and the failure is at exec.
- **No `COPY` line other than the binary.** An earlier generation of these Dockerfiles dragged
  `libcrypt.so.1` out of the builder and carried a rule that the builder's glibc must be no newer
  than the runtime's. `sborka.kmp` links with `--as-needed`, the declaration goes away, and so does
  the rule. If the image ever fails with `cannot open shared object file`, the answer is that the
  convention did not apply — not another `COPY`.
- **`MALLOC_ARENA_MAX=2` carries its counter-example, not just its value.** It was measured on a
  different service; with `-Xallocator=std` the same line took a peak from 39.3 MB to 413.7 MB and
  survivals from 10/10 to 7/10. The comment says re-measure, and says what a positive control is.
- The `STATIC=1` stage copies five paths **out of the build stage** — `/etc/ld.so.cache`, the loader,
  `libc.so.6`, the whole `gconv` directory and `zoneinfo`. Not from the host and not from another
  image of the same version: `dlopen` from a static binary needs the same glibc *build* as the
  `libc.a` it was linked against.
- A budget that is missed gets a new number **and a line saying what it bought**. A quiet edit is how
  a budget stops being one.

- AC: both images build from the committed `Dockerfile`; both answer `/health/ready`; the static one
  additionally passes the rendered-page smoke of [B-05](B-05-parity-smoke.md)'s harness, because a
  status code is not evidence there.
- AC: both sizes are recorded in the README with the date, against the declared budgets.
- Anchors: `Dockerfile`, `server/build.gradle.kts`,
  `sborka/build-logic/conventions/src/main/kotlin/io/github/youndie/sborka/internal/NativeImageReference.kt`,
  `sborka/docs/research/research-static-binary.md`
