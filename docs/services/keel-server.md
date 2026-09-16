---
id: keel-server
title: keel :server — the template service
type: service
repo_url: https://github.com/youndie/keel
module: ":server and :server-jvm — see section 3"
tech_stack: [Kotlin Multiplatform, Ktor CIO, sqlx4k-sqlite, kore, sborka, Docker]
owner: unassigned
status: draft
depends_on:
  - kore
  - sborka
  - razves
  - zavarnik
  - sqlx4k-sqlite
publishes:
  - "ghcr.io/youndie/keel (the template's own image; a clone renames it)"
---

# keel `:server`

**The skeleton is built; most of this document is not.** Since B-01 `:server` produces a JVM jar and
a `linuxX64` executable, `GET /items` answers a constant, kore is wired and the size gate runs. The
store, `:server-jvm`, the `Dockerfile`, `k6/` and every test are still descriptions —
[backlog.md](../../backlog.md) is the order they arrive in, and the paths in §2a are a mixture of real
files and places code will live, which is why `code_anchors.py` still reports some of them rotten.

What *is* verified rather than merely built is
[research-architecture](../research/research-architecture.md) §1: everything keel depends on was read
in a published artefact or a portfolio repository on 2026-09-16, and §1.3 and §1.4 gained a
confirmation from B-01's first build.

## 1. Responsibility

One Kotlin Multiplatform module that is a **complete, runnable server on two targets** and carries no
domain: one entity `Item { id, name }`, one route group, one storage port, three probes, `/version`,
an ordered shutdown, an image, and a measurement harness. A clone renames it and starts writing
features.

What it deliberately does **not** do:

- **no client.** kompot and Compose belong to a second template. Mixing them is how konekt reached
  300 pages;
- **no second entity.** A starter whose example grows features stops being a starter. `Item` stays
  `{ id, name }`;
- **no build logic of its own.** Every convention is sborka's; keel's build files apply conventions
  and set names. A flag that appears in keel's `build.gradle.kts` is a flag sborka forgot, and it is
  filed there rather than fixed here (§3, the routing table);
- **no lifecycle code.** `announce → drain → release → exit`, the three probes and the typed
  configuration are kore's. keel shows them wired and adds nothing;
- **no documentation of the stack.** How kore or sborka work is documented where they live. This tree
  is keel's own service and nothing else.

## 2. API contracts

* **Routes:** [endpoint-items](../api/endpoint-items.md) — the complete reference, keel's own route
  group and everything kore mounts.
* **Contracts:** `server/src/commonMain/kotlin/.../item/Item.kt`, a `@Serializable` data class.
  Fields are not copied into any document; the path is.
* **Auth tiers:** there are none. keel ships no authentication, and that is a non-goal rather than an
  omission — a starter that ships a half-authentication is a starter whose first consumer inherits
  it. The `ktor-server-feature` skill is where a real one comes from.

## 2a. Code anchors

| File | What is there |
|---|---|
| `server/build.gradle.kts` | targets, the two sborka conventions, `nativeService { }` **before** the target block |
| `server/src/commonMain/kotlin/.../KeelMain.kt` | everything both entry points do: `--print-config`, the build line, the configuration read, then start |
| `server/src/commonMain/kotlin/.../Wiring.kt` | `embeddedServer(CIO)`, `installKoreProbes`, `installKoreVersion`, `runUntilSignal` with the four registrations |
| `server/src/commonMain/kotlin/.../KeelConfig.kt` | the four `ConfigKey`s and the `ConfigSchema` |
| `server/src/commonMain/kotlin/.../item/ItemStore.kt` | the port, and the `sqlx4k-sqlite` implementation behind it |
| `server/src/commonMain/kotlin/.../item/ItemRoutes.kt` | `GET`/`POST /items` |
| `server/src/jvmMain/kotlin/.../Main.kt`, `server/src/linuxX64Main/kotlin/.../Main.kt` | four lines each; the only thing that differs between the two builds |
| `server-jvm/build.gradle.kts` | `application` + zavarnik, and the reason it exists (§3) |
| `Dockerfile` | two stages, `STATIC=1` behind a build arg |
| `k6/items.js` | the scenario both binaries are driven with |
| `.github/workflows/check.yaml` | the documentation gate and the build gate |

## 3. How it is built

**The module split, and why there are two.** `:server` is the multiplatform module and holds every
line of Kotlin that matters. `:server-jvm` is `kotlin("jvm")`, applies `application` and zavarnik, and
contains one `main` that calls into `:server`'s JVM target. It exists because zavarnik refuses a
project without the `application` plugin, and `application` does not apply to a multiplatform module —
the full argument and the two alternatives that were rejected are
[research-architecture](../research/research-architecture.md) D5. A reader who finds this split
surprising is reading it in the right order: it is the one structural concession in the repository,
and if acceptance 6's Gradle budget breaks, the honest fix is dropping zavarnik rather than hiding
the module.

**The two allocators, one floor below the other.** `sborka.native-service` sets
`fixedBlockPageSize=16` on the binary; the image sets `MALLOC_ARENA_MAX=2`. Kotlin/Native's allocator
keeps a page per size class *per thread* and a thread holds its pages for as long as it lives, so
resident memory follows the thread count rather than the live heap — which is why a service dies at a
limit its heap is nowhere near. Neither number is keel's to change without a measurement, and the
pair is dangerous in one specific combination: with `-Xallocator=std`, `MALLOC_ARENA_MAX=2` took a
peak from 39.3 MB to 413.7 MB and 10 survivals out of 10 to 7. Both lines carry that beside them.

**Where the binary lands.** `stageNativeImage` puts the release `.kexe` at
`server/build/native-image/<baseName>` whatever the target was declared as, and writes a
`<baseName>.needed.txt`
next to it naming what the binary asks the loader for. The `Dockerfile` copies from that path and
nothing else; the whole point of the convention is that a `COPY` line survives being moved between
repositories.

**The order things run in at startup**, and it is a claim about what a service owes an operator:
`--print-config` answers before anything else including the build line, because it is asked *because*
the process will not start; the configuration is read once before anything serves; a refusal prints
the message and nothing else, because a stack trace buries the two lines that say which variable and
why.

**The order things run in at shutdown** is kore's and is the product:
`announce` (readiness false, then a wait long enough to matter) → `drain` (accept stops, in-flight
finishes, new arrivals get 503) → `release` (the store, then telemetry, each with its own deadline)
→ `exit`. keel registers, and registers nothing in `ApplicationStopping` — §8, first quirk.

**Where a defect goes**, which is the rule that keeps keel from becoming konekt:

| the line was | it goes to |
|---|---|
| a build flag, a linker option, a CI step | sborka |
| lifecycle, probes, config, shutdown | kore |
| a procedure the agent had to work out | the `native-service-bootstrap` skill |

Nothing goes to keel except renaming.

## 4. Dependencies

| Kind | Name | What for |
|---|---|---|
| Library | `io.github.youndie:kore-core`, `kore-ktor` | the shutdown sequence, the probes, the typed config, `/version`. `0.1.4` on the portfolio's repository |
| Gradle | `io.github.youndie.sborka.native-service`, `.kmp`, `.lint`, `.settings` | the binary's name and staging, `fixedBlockPageSize`, `--as-needed`, ktlint. `0.4.0.79` |
| Gradle | `io.github.youndie.razves` | the size budget `sborka.binaryBudget` is enforced by; the convention fails configuration if the property is set and this is absent |
| Gradle | `io.github.youndie.zavarnik` | the AOT cache for the JVM distribution, and `aotVerify` on `check` |
| Database | `io.github.smyrgeorge:sqlx4k-sqlite:1.13.1` | the one store, on both targets — Rust driver on native, `org.xerial:sqlite-jdbc` on the JVM |
| Tool | k6 | the load scenario for the parity smoke and `:server:measure` |
| Optional | `io.github.youndie.chronik:chronik-core` | a durable timer; commented out, `linuxX64` only |

**Only sqlx4k-sqlite is on Maven Central.** kore, sborka and razves resolve from
`https://reposilite.kotlin.website/snapshots`, and until they reach Central a clone needs that
repository configured — which is acceptance 1's precondition and the README's first block.

## 5. Infrastructure and deploy

* **Image:** built from the repository root, two stages. Runtime `gcr.io/distroless/cc-debian13` by
  default; `--build-arg STATIC=1` selects the `scratch` variant.
* **Probes:** `GET /health/startup`, `GET /health/ready`, `GET /health/live`. A chart must point
  readiness at `/health/ready` and **not** at `/health`, which is an alias for liveness — see §8.
* **Version:** `GET /version`, `key: value` per line, read by deploy checks rather than by people.
* **`ENTRYPOINT` in exec form, always.** Shell form makes `/bin/sh -c` PID 1 and it does not forward
  `SIGTERM`, so the process never sees the signal and the run looks like an instant clean shutdown.
* **No chart.** keel ships no Helm; the chart is a decision about a cluster keel does not have. The
  `native-service-bootstrap` skill carries one.

## 6. Local setup

```bash
./gradlew :server-jvm:run                       # the JVM half, on the development machine
./gradlew :server:linkReleaseExecutableLinuxX64 # the native binary; Linux only
docker build -t keel .                          # distroless/cc
docker build --build-arg STATIC=1 -t keel:static .
```

Nothing else has to be running: the store is SQLite in a file, and `KEEL_DB_PATH` defaults to one
under the working directory.

**Both binaries cannot be built on a Mac.** A klib cross-compiles and an executable does not — a Mac
cannot produce an ELF. On a mutagen-synced checkout the Gradle commands run on the Linux box
(`~/.claude/bin/wsl-run ./gradlew …`); `make check` stays local.

## 7. Configuration

Four keys, declared in `server/src/commonMain/kotlin/.../KeelConfig.kt` under the prefix `KEEL`. The
list is not copied here — `--print-config` prints every value with its origin, and a copy in this
document would be the second schema that disagrees with the first.

```bash
./gradlew :server-jvm:run --args="--print-config"
```

What the shape is for: one key is **required** with no sensible default (a service that invents where
its data lives starts happily and serves wrong data), two have defaults so a deployment does not
repeat them, and the fourth is half of an optional **pair** — both set or neither, because one
without the other is a deployment that believes it is observed and is not.

## 8. Quirks

Fourteen, and the first five are not keel's: they are the platform divergences every Kotlin/Native
Ktor service inherits, verified by kore against the artefacts rather than against documentation
([research-architecture](../research/research-architecture.md) §1.2). They are here because a keel
reader will not have kore's research open, and each one looks like a bug in the service.

1. **`ApplicationStopping` runs after the drain on the JVM and before it on Kotlin/Native**, from
   identical source, with nothing saying so. Every Ktor example tells you to close your pool there.
   keel closes nothing there; the store is a release-stage participant.
2. **`ApplicationStopPreparing` fires after the socket has stopped accepting** on CIO, so it cannot
   flip readiness — which is the one thing its name suggests.
3. **The Kotlin/Native shutdown hook is a single global slot**, last registration wins, and the
   callback runs on the POSIX signal-handler stack. Never call `addShutdownHook`; kore installs a
   handler that writes a flag and nothing else.
4. **`Connection: close` on a response does not close a CIO connection** — the engine reads keep-alive
   from the *request's* header. kore promises the header and not the socket, and so does keel.
5. **Enumerating the environment is `__environ` on Linux and does not exist on macOS native**, so the
   unknown-variable check is a declared capability rather than a universal one. A capability that is
   absent on a target says so; it never reports "nothing found" where the check could not run.

And keel's own:

6. **A clean `SIGTERM` exits `0` on Kotlin/Native and `143` on the JVM.** Both are right. Never assert
   a specific exit code across the two; assert the process ended itself and was not `SIGKILL`ed
   (`137`). The parity normaliser has this as its first entry.
7. **`/health` is liveness, not readiness.** It is an alias kore mounts because every chart in the
   portfolio already names it, and a chart pointing readiness there gets a probe that cannot fail
   while the process is alive — which is the failure the three probes exist to stop.
8. **`runUntilSignal`'s default `watch` argument installs a signal handler when the call is made**, so
   the call belongs *after* `server.start(wait = false)`. Installed earlier, it catches a signal whose
   sequence has nothing to drain. Nothing at the call site shows this.
9. **The shutdown transcript is printed inside `onFinished`, not after the call.** On the JVM,
   `runUntilSignal` returning means the shutdown hook has returned and the process is already on its
   way out; the line after the call never runs. kore shipped this defect in its own example and a
   consumer found it.
10. **Two sqlx4k drivers in one native binary do not link.** Not a resolution failure — a link failure
    naming a Rust symbol, `duplicate symbol: std::panicking::EMPTY_PANIC`. keel takes exactly one
    driver; a clone adding Postgres **replaces** SQLite rather than adding to it.
11. **The chronik timer block is `linuxX64` only.** Turning it on together with `keel.linuxArm64=true`
    fails at resolution with "no matching variant", which names an attribute and not the decision
    that caused it.
12. **`writeNativeDockerfile` refuses to overwrite.** keel's `Dockerfile` is committed, so the task
    will always refuse here; it is for a clone that deleted the file, and the refusal is deliberate —
    the runtime image is where certificates, shared libraries and a base image's glibc are decided.
13. **A green `build` on one host does not mean both targets were tested.** Kotlin/Native has no
    `linux_arm64` host, so `linuxArm64Test` is never *created* — it does not appear as skipped, it does
    not appear at all. CI links there and executes the test binary on an arm64 runner; a local green
    build proves nothing about it. **Today it is worse than that:** there is no test anywhere, so
    `./gradlew build` is green having run zero of them. B-06.
14. **A Gradle task that writes into the repository must not be run through the replica.** The mutagen
    session is a one-way replica, so `./gradlew updateEditorconfig` on the Linux box wrote
    `.editorconfig` there and the next sync deleted it. Generated files arrive on the Mac or not at
    all.
