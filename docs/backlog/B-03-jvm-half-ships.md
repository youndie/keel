---
id: B-03
title: "installDist runs with a verified AOT cache, and the split it costs is one module"
status: question
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

---

## Iteration 1 — 2026-09-16: this is a question, and it is the owner's

**The split does not fit, and no way of writing it does.** B-01 predicted this with nine lines of
headroom; B-02 spent seven of them on the driver, okio and the razves workaround, so the budget stood
at **98 of 100** before this item started.

Measured, not estimated — the smallest honest `:server-jvm` was written, counted, and deleted again:

| | code lines |
|---|---|
| the four existing Gradle files | 98 |
| `server-jvm/build.gradle.kts` (plugins, toolchain, dependency, mainClass, zavarnik block) | 12 |
| the `include(":server-jvm")` in settings | 1 |
| catalog entries for `kotlinJvm` and `zavarnik` (2 versions, 2 plugin ids) | 4 |
| **total** | **115** |

The build file has no fat in it: eleven of its twelve lines are a plugin, a toolchain, a dependency, a
main class or a zavarnik setting. There is no smaller correct version.

### What the brief says to do, and why it is not obviously right

Acceptance 6's rule is "over either is the signal that something belongs in sborka or kore instead",
and both B-01 and this item wrote down the prescribed answer in advance: **drop zavarnik rather than
raise the number.** Having measured it, that answer does not actually close the gap:

| Option | Gradle lines | What it costs |
|---|---|---|
| **1. Drop zavarnik, keep the distribution** | ~108 | still over by 8. `application` is what `installDist` needs, so the module stays; only the cache goes. The brief's prescribed answer does not, by itself, work |
| **2. Drop the JVM distribution entirely** | 98 | under budget, and keel stops shipping twice in any sense a reader would recognise — the JVM target becomes a test fixture. It contradicts the repository's first sentence |
| **3. Move the shape into sborka** as a `jvm-service` convention | ~105 | still over by 5, and it is the option the routing table actually points at: every native service in this portfolio that wants a shipped JVM half needs the same ten lines |
| **4. Change what the budget counts** | 68 today, ~85 with the split | excludes `gradle/libs.versions.toml`, on the argument that a version catalog is data rather than build logic and a pinned version cannot "belong in sborka". Weakened by the fact that some of those pins genuinely could come from sborka's shared `wip` catalog |

### Why the loop stops here

Each option changes what keel *is*, not how it is built: option 2 retires a claim in the README's
first paragraph, option 3 is work in another repository, option 4 rewrites an acceptance criterion
that was deliberately declared before the first commit — and a criterion edited by the thing it was
measuring is not a criterion.

**The brief's own kill criterion is adjacent and should be said out loud:** *"Acceptance 6 cannot be
met after the first consumer → the starter idea is wrong for this stack and the honest deliverable is
the skill alone."* That is about the first consumer rather than about this item, and 3 and 4 are both
live, so this is not that moment. It is close enough to name.

**A recommendation, since one is owed:** 3 and 4 together. The convention is where those ten lines
belong by the portfolio's own rule, and the catalog is not build logic that could move anywhere. Both
are defensible alone; neither is mine to take.

The measured `server-jvm/build.gradle.kts`, for whoever decides:

```kotlin
plugins {
    alias(libs.plugins.kotlinJvm)
    application
    alias(libs.plugins.zavarnik)
}
kotlin { jvmToolchain(25) }
dependencies { implementation(project(":server")) }
application { mainClass = "io.github.youndie.keel.jvm.MainKt" }
zavarnik {
    readinessUrl = "http://127.0.0.1:8080/health/ready"
    workload { get("/items") }
}
```
