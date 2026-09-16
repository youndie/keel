---
id: B-03
title: "installDist runs with a verified AOT cache, and the split it costs is one module"
status: open
priority: P0
size: M
stage: m1-ships-twice
epic: feature-item-round-trip
blocked_by: [B-01]
---

# B-03 — The JVM half is shipped, not only tested

The parity finding behind keel is that every service in the portfolio had `jvm()` and none had a
runnable JVM. This item is where that stops being true: `:server-jvm` applies `application` and
zavarnik, `installDist` produces a distribution whose start script carries a trained AOT cache, and
`aotVerify` runs on `check`.

- **The decision and its reason.** [research-architecture](../research/research-architecture.md) D5:
  zavarnik refuses a project without the `application` plugin, and `application` does not apply to a
  multiplatform module. The split is the only arrangement that keeps `installDist`, a trained cache
  and one copy of the code.
- The alternative that looks cheapest — kore's hand-assembled fat jar — is ruled out by zavarnik's
  own requirements: the cache trains through the start script over the `lib/*.jar` layout, and a
  single jar is not that layout. Dropping zavarnik is the other alternative, and it is the **right**
  one if this item pushes the repository over acceptance 6's Gradle budget. Hiding the module is not
  on the list.
- `:server-jvm` holds one `main` and no logic. A starter whose logic lives in a JVM-only module has
  quietly stopped shipping twice.
- Watch for: a wildcard on the start script's classpath is refused at `installDist` by design — the
  JVM records the classpath string and expands `lib/*` in whatever order the filesystem answers, and
  two container runtimes answered differently, which is how a cache was silently refused in a
  cluster.

- AC: `./gradlew :server-jvm:installDist` produces a distribution that starts and answers
  `/health/ready`; `aotVerify` is green as part of `check` and names the percentage of application
  classes served from the cache.
- AC: the Gradle line count after this item is recorded. If it is over 100, the follow-up is an item
  to remove zavarnik, not a raised budget.
- Anchors: `server-jvm/build.gradle.kts`, `server-jvm/src/main/kotlin/.../Main.kt`,
  `zavarnik/zavarnik-gradle-plugin/src/functionalTest/kotlin/io/github/youndie/zavarnik/ConfigurationChecksFunctionalTest.kt`
