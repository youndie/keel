# keel

**A template repository for a Kotlin server that ships twice.** Clone, rename, `./gradlew run`, and
there is a service: one route, one table, three probes, a `/version`, two targets both runnable, one
image, every check green on day one.

*keel* — the first member laid down; everything else is built on it.

> **Status: the skeleton builds and is tested; that is all.** `./gradlew build` produces a JVM jar
> and a `linuxX64` executable, `GET`/`POST /items` go through a real SQLite database that survives a
> restart, kore is wired, the size gate runs, and **22 tests run on each of the two targets from one
> source** — CI names both suites and fails if either goes missing. The image builds, serves and
> stops cleanly at **14 MB**. There is no JVM distribution: B-03 is a `question`, because the split it
> needs does not fit acceptance 6's line budget. [backlog.md](backlog.md) is the order the rest
> arrives in.
>
> **Most numbers here are still targets, and each says so.** They are the acceptance thresholds
> declared in the brief before the first commit; the table below names the item that replaces each
> with a measurement and the date it was taken. A starter that publishes an unmeasured number is the
> first thing its reader will check against their own clock.

## What it is

keel is [konekt](https://github.com/youndie/konekt) with the domain removed: the wiring a new service
needs, and nothing the last one happened to have. It is not a library and publishes nothing. It is
not a framework — [kore](https://github.com/youndie/kore) owns the lifecycle,
[sborka](https://github.com/youndie/sborka) owns the build, and keel only shows them wired.

The test for every file in it: *did konekt or katcher need this?* If not, it is not in keel.

| | |
|---|---|
| `:server` | one KMP module, `jvm()` + `linuxX64` (+ `linuxArm64` behind a property) |
| `:server-jvm` | ten lines, so the JVM half can have `application` and an AOT cache — [why](docs/research/research-architecture.md) |
| one route | `GET`/`POST /items`, JSON via kotlinx.serialization |
| one store | `ItemStore` over `sqlx4k-sqlite`: the Rust driver on native, `sqlite-jdbc` on the JVM, **one** implementation |
| kore | `installKoreProbes`, `installKoreVersion`, `runUntilSignal` with `announce → drain → release` |
| sborka | `fixedBlockPageSize=16`, `--as-needed`, ktlint, a size budget, the staged binary path |
| zavarnik | a Leyden AOT cache for the JVM distribution, `aotVerify` on `check` |
| `Dockerfile` | two stages; `gcr.io/distroless/cc-debian13`, the binary and nothing beside it |
| `k6/` | one scenario, used for the parity smoke and for `:server:measure` |
| `docs/` | this tree, passing `make check` on day one |

## The numbers, and what they are

| | target | measured |
|---|---|---|
| clone → `/health/ready` on both targets, cold machine, including the toolchain fetch | under 1 h | not yet — [B-08](docs/backlog/B-08-clone-to-ready.md) |
| image, `distroless/cc` | under 25 MB | **13 972 497 bytes**, 2026-09-16 — `docker image inspect`, `linux/amd64` |
| image, `STATIC=1` | under 12 MB | not built — [B-16](docs/backlog/B-16-static-image.md) asks whether a template should ship that recipe at all |
| Kotlin in `server/` | under 500 lines | **140** code lines (275 as written), 2026-09-16 |
| Gradle across the repository | under 100 lines | **91** code lines (225 as written), 2026-09-16 |
| the `linuxX64` release binary | — | **9 227 448 bytes**, declaring 7 shared libraries, 2026-09-16 (4 983 240 before the SQLite driver) |

The image figure names its method because it had to: `docker images` reports **55.4MB** for the same
image, counting every platform of the base manifest in the containerd store. `docker save | wc -c`
confirms the smaller number. A budget checked with the wrong command fails at random.

**Code lines**, meaning blank lines and comments dropped, and both numbers are reported so the choice
stays visible — the reasoning in this portfolio lives beside the line it explains, and on the four
Gradle files that is 60 % of them. A comment cannot make a build do the wrong thing; a line of Gradle
can, and that is what the budget is for.

Going over either line budget is the signal that something belongs in sborka or kore instead, and it
is filed there rather than fixed here. Gradle is at 91 of 100 with **one** module, before B-03 adds
`:server-jvm` — that pressure is the brief working as intended, not a problem to solve by raising the
number.

## Resolving the dependencies

**kore, sborka and razves are not on Maven Central.** Until they are, a clone needs the portfolio's
repository in `settings.gradle.kts`:

```kotlin
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
        maven("https://reposilite.kotlin.website/snapshots") {
            content { includeGroupByRegex("io\\.github\\.youndie.*") }
        }
    }
}
```

Filtered, and the filter is about failure isolation rather than speed: an unfiltered repository takes
part in resolving *every* dependency, so the day that host is unreachable Gradle disables it and
fails artefacts it never served — naming the victim rather than the cause.

Central is expected around **2026-10**; the "stranger test" — the same clone with no portfolio
repository configured at all — waits for it and is deliberately not in the box. `sqlx4k-sqlite` is on
Central already.

## Documentation

Format: [docs-bootstrap](https://github.com/youndie/docs-bootstrap). Start at
[docs/README.md](docs/README.md); a session starts with [CLAUDE.md](CLAUDE.md).

```bash
pip install pyyaml
make check
```

## Licence

MIT.
