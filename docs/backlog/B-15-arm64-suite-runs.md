---
id: B-15
title: "Run the linuxArm64 suite on an arm64 runner, once razves can register its tasks"
status: wip
priority: P2
size: S
stage: m1-ships-twice
epic: feature-item-round-trip
---

# B-15 — The third target is built by nobody and tested by nobody

B-06 gave CI a build job that names `jvmTest` and `linuxX64Test` and fails when either is missing.
`linuxArm64` is not in that list, because it is off by default (`keel.linuxArm64`) — and because
turning it on does not currently build at all.

- **Blocked by [youndie/razves#3](https://github.com/youndie/razves/issues/3).** With two native
  targets razves registers `sizeReportDebugExecutable` twice — its task names carry the build type
  and not the target — and the build fails at configuration with "Cannot add task
  'sizeReportDebugExecutable' as a task with that name already exists". So `-Pkeel.linuxArm64=true`
  cannot be built while `sborka.binaryBudget` is set, which is every build of this repository.
- **The decision and its reason.** The shape is kore's, and it is not the obvious one: the x86-64 job
  **cross-links** the test binary and an `ubuntu-24.04-arm` runner **executes** it. Kotlin/Native has
  no `linux_arm64` host, so `linuxArm64Test` is never created — it does not appear as skipped, it
  does not appear at all — but linking and running are separable even where the plugin will not do
  it for you.
- The rejected alternative is building everything on an arm64 runner. It works and it doubles the
  Kotlin/Native toolchain downloads, for a target that is off by default.
- Not covered: making `linuxArm64` a default target. That is a decision about what keel ships, not
  about what CI checks, and nothing deploys there yet.

- AC: a `linux-arm64-suite` job executes the cross-linked binary on `ubuntu-24.04-arm`, fails if no
  binary was produced, and fails if the binaries ran zero tests.
- AC: `-Pkeel.linuxArm64=true ./gradlew build` is green, which is what razves#3 has to land for.
- Anchors: `.github/workflows/check.yaml`, `server/build.gradle.kts`, `gradle.properties`
