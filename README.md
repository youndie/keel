# keel

**A template repository for a Kotlin server that ships twice.** Clone, rename, `./gradlew run`, and
there is a service: one route, one table, three probes, a `/version`, two targets both runnable, one
image, every check green on day one.

*keel* — the first member laid down; everything else is built on it.

> **Status: nothing is built.** This repository is documentation first. There is a docs tree, a
> backlog of thirteen items and a gate that runs; there is no `settings.gradle.kts`, no `:server` and
> no `Dockerfile` yet. [backlog.md](backlog.md) is the order they arrive in, and
> [docs/research/research-architecture.md](docs/research/research-architecture.md) is what was
> checked before any of it was written.
>
> **No number in this README is measured yet.** The figures below are the acceptance thresholds
> declared in the brief before the first commit — they are targets, and each says which item replaces
> it with a measurement and the date it was taken. A starter that publishes an unmeasured number is
> the first thing its reader will check against their own clock.

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
| one store | `ItemStore` over `sqlx4k-sqlite`: the Rust driver on native, `sqlite-jdbc` on the JVM, one implementation |
| kore | `installKoreProbes`, `installKoreVersion`, `runUntilSignal` with `announce → drain → release` |
| sborka | `fixedBlockPageSize=16`, `--as-needed`, ktlint, a size budget, the staged binary path |
| zavarnik | a Leyden AOT cache for the JVM distribution, `aotVerify` on `check` |
| `Dockerfile` | two stages; `gcr.io/distroless/cc-debian13` by default, `scratch` behind `--build-arg STATIC=1` |
| `k6/` | one scenario, used for the parity smoke and for `:server:measure` |
| `docs/` | this tree, passing `make check` on day one |

## The numbers, and what they are

| | target | measured |
|---|---|---|
| clone → `/health/ready` on both targets, cold machine, including the toolchain fetch | under 1 h | not yet — [B-08](docs/backlog/B-08-clone-to-ready.md) |
| image, `distroless/cc` | under 25 MB | not yet — [B-04](docs/backlog/B-04-image-and-size-budget.md) |
| image, `STATIC=1` | under 12 MB | not yet — [B-04](docs/backlog/B-04-image-and-size-budget.md) |
| Kotlin in `:server` | under 500 lines | not yet — [B-01](docs/backlog/B-01-repository-skeleton.md) |
| Gradle across the repository | under 100 lines | not yet — [B-01](docs/backlog/B-01-repository-skeleton.md) |

Going over either line budget is the signal that something belongs in sborka or kore instead, and it
is filed there rather than fixed here.

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
