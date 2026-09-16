---
id: B-01
title: "The repository builds both targets with the conventions applied and nothing of its own"
status: open
priority: P0
size: M
stage: m0-shape
epic: feature-item-round-trip
---

# B-01 — The repository builds both targets, on borrowed conventions

There is no repository yet. What this item produces is the skeleton every later item stands on:
`settings.gradle.kts` applying `io.github.youndie.sborka.settings`, `:server` applying
`sborka.kmp` + `sborka.lint` + `sborka.native-service`, `jvm()` and `linuxX64()` declared with
`linuxArm64()` behind `keel.linuxArm64`, and one route answering.

- **The decision and its reason.** Every convention comes from sborka and every lifecycle call from
  kore, so keel's build files set names and apply plugins and nothing else. The test for any line
  added here is the brief's: *did konekt or katcher need this?* — and if the answer is yes but the
  line is a build flag, it belongs in sborka, not in this file.
- **`nativeService { }` goes above the `kotlin { }` block.** The convention configures
  `binaries.executable` from inside `targets.withType(...).configureEach`, which fires the moment
  `linuxX64()` declares one; a block further down is a value set after it was read, and the build
  fails with "property entryPoint has no value available", naming neither the ordering nor the place.
- The rejected alternative is a build file that declares `binaries.executable` itself. It works, and
  it is two blocks configuring one container, with the winner decided per repository — which is
  exactly what the convention exists to stop.
- This item does **not** cover the store (`B-02`), the JVM distribution (`B-03`) or the image
  (`B-04`). One route returning a constant is enough to prove the toolchain.

- AC: `./gradlew build` produces a JVM artefact and a `linuxX64` executable; `sborka.binaryBudget`
  is set in `gradle.properties` and razves is applied, so the budget is enforced rather than
  declared; `stageNativeImage` writes `server/build/native-image/keel` and logs what the binary
  asks the loader for.
- AC: the Gradle line count across the repository is recorded in the commit message. Acceptance 6's
  budget is 100 lines and this is the first reading of it.
- Anchors: `settings.gradle.kts`, `gradle.properties`, `server/build.gradle.kts`,
  `sborka/build-logic/conventions/src/main/kotlin/io/github/youndie/sborka/native-service.gradle.kts`
