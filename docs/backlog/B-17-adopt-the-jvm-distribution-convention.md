---
id: B-17
title: "Adopt sborka's jvm-distribution convention once it exists"
status: open
priority: P3
size: XS
stage: m1-ships-twice
---

# B-17 — Twelve lines that belong in sborka

`distribution/build.gradle.kts` is twelve lines of build logic, and only three of them are keel's:
the main class, the project it depends on and the workload. The rest is what *any* Kotlin/Native
service in this portfolio needs to ship a JVM half, which is the definition of something belonging in
a convention rather than in a repository.

Proposed as [sborka#78](https://github.com/youndie/sborka/issues/78), with the three traps it would
carry that cost keel a red build each: the root build's `apply false` for two sibling Kotlin plugins,
the module name that must not be `:distribution`, and the JDK 25 floor.

- **The decision and its reason.** B-03 chose to fit the module inside the budget rather than wait for
  the convention, because the budget question and the convention question are separable and only one
  of them blocked five items. This is the other half, and it is `P3` because nothing is broken — the
  file works, it is just in the wrong repository.
- Not covered: writing the convention. That is sborka's work, in sborka's backlog.

- AC: `distribution/build.gradle.kts` applies `io.github.youndie.sborka.jvm-distribution` and is down
  to its three keel-specific lines; `./gradlew build` and `aotVerify` stay green.
- AC: the build-logic count in `backlog.md` is re-measured and the new number recorded.
- Anchors: `distribution/build.gradle.kts`, `build.gradle.kts`, `settings.gradle.kts`
