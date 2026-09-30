# CLAUDE.md — {{name}}

**What this service is has not been written yet.** [B-01](docs/backlog/B-01-say-what-this-service-is.md)
writes it, here and in the README. Until then this paragraph is the only claim about the service in
this file, and it is true. Everything below is structure and rules, and none of it describes what the
service does.

The code was started from [a template for a Kotlin server that ships twice](https://github.com/youndie/keel):
one source, a JVM distribution and a Kotlin/Native binary, both runnable, both tested, one image. The
template's research, measurements and backlog stay at that address. They describe the template, not
this service, and none of it was copied here.

## How to start a session

1. **The research**, once B-01 has written it: `docs/research/`. Until then, the template's
   [research](https://github.com/youndie/keel/blob/main/docs/research/research-architecture.md) is why
   the wiring looks the way it does.
2. [backlog.md](backlog.md): the goal, the stages, the index. Items are one file each in
   `docs/backlog/`. The index between the markers is generated, so edit the item and run
   `python3 scripts/backlog_index.py`.
3. The layer document the task belongs to. The map is [docs/README.md](docs/README.md), and a new
   document starts from `docs/templates/`.
4. The skills, when the task is building rather than documenting: `native-service-bootstrap` for the
   skeleton, `ktor-server-feature` for a route, `kmp-testing` for the suites, `backlog-item` for an
   item. The repository is read **before** the skill.

## Where a line goes

The build and the lifecycle are not this repository's own. A line that is neither this service's
domain nor its name is a defect somewhere else, and it has a destination:

| the line was | it goes to |
|---|---|
| a build flag, a linker option, a CI step | [sborka](https://github.com/youndie/sborka) |
| lifecycle, probes, config, shutdown | [kore](https://github.com/youndie/kore) |
| a procedure that had to be worked out | the `native-service-bootstrap` skill |

The workaround stays local, and carries a comment naming the issue so the next person deletes it
instead of inheriting it.

## The two rules

- **`main` describes what exists.** A document says what is built, and what is absent says so where a
  reader meets it. A new document is `draft` in its pull request and `active` once somebody has checked
  it against the code.
- **What was verified is separated from what was assumed, explicitly.** A verified fact carries a file,
  a coordinate or a URL with the date it was read. Everything else says "decision" or "hypothesis", and
  a hypothesis names the item that settles it.

## Rules that are cheap to follow and expensive to discover

Most of these are kore's and sborka's, restated because a session here will not have their
repositories open.

- **Never put shutdown work in `ApplicationStopping`.** On Kotlin/Native it runs *before* the drain
  and on the JVM *after* it, from identical source. Anything outbound (a pool, a producer, a client) is
  registered with `runUntilSignal` after `drain(...)`: `consumer(...)` for something that has to flush
  first, `pool(...)` for a pool.
- **Never call `addShutdownHook`.** One global slot on Native, last registration wins, and the
  callback runs on the signal stack.
- **Start the server with `server.startForKore()`, never `start()`.** On the JVM `start()` adds Ktor's
  own shutdown hook, the JVM runs it beside kore's, and it closes the listener at the signal — a
  readiness probe then gets a refused connection instead of a `503` (kore#90). On Kotlin/Native it also
  installs kore's signal handler around `start`, so no signal meets Ktor's own (kore#98).
- **Never install a signal handler written in Kotlin.** A `staticCFunction` is a bridge that
  initialises the runtime on whichever thread receives the signal; a worker receiving it in its first
  instructions dies. kore's handler is C on Linux (kore#100) — read its flag, do not add another.
- **One `DrainGate`, handed to both `installShutdownRefusal` and `EngineDrain`.** The refusal opens at
  the drain, never at the announce, which goes on serving while the news travels; two instances
  compile and never refuse (kore#94).
- **`runUntilSignal` goes after `server.startForKore()`**, because its default `watch` argument
  installs the handler at the moment of the call. Print the transcript **inside** `onFinished`: on
  the JVM the line after the call never runs.
- **Check the port before the engine binds it, with the engine's own `reuseAddress`.** CIO binds in a
  coroutine of its own after `start` returns, so a busy port is `SIGABRT` on Kotlin/Native;
  `configuration.requireListenable(PORT, reuseAddress = …)` makes it a one-line refusal. And set
  `reuseAddress = true` on the engine: the JVM gets `SO_REUSEADDR` from NIO, the native build does
  not, and without it cannot restart over its own TIME_WAIT (https://github.com/youndie/keel/issues/49).
- **`nativeService { }` goes above the `kotlin { }` block**, or the build fails with "property
  entryPoint has no value available" and names neither the ordering nor the place.
- **Two sibling modules applying different Kotlin plugins need the root build to declare both with
  `apply false`.** Otherwise the Kotlin plugin's shared build service exists under two classloaders
  and the build fails naming two of them and nothing else. That is why the root `build.gradle.kts`
  exists.
- **Exactly one sqlx4k driver.** Two do not link (`duplicate symbol: std::panicking::EMPTY_PANIC`),
  and it is a link error, not a resolution error. A service with **no** database removes the driver
  and keeps the shutdown slot the pool was in:
  [every place it lives](https://github.com/youndie/keel/blob/main/docs/services/keel-server.md#9-a-service-without-a-database).
- **`ENTRYPOINT` in exec form, always.** Shell form makes `/bin/sh -c` PID 1, which does not forward
  `SIGTERM`; the run then looks like an instant clean shutdown.
- **Never assert an exit code across the two targets.** A clean `SIGTERM` exits `0` on Native and
  `143` on the JVM. Assert the process ended itself and was not `SIGKILL`ed (`137`).
- **A chart points readiness at `/health/ready`.** `/health` is an alias for **liveness**, and a
  readiness probe there cannot fail while the process is alive.
- **Read a result file, not a log line.** A test-result XML and an artefact's timestamp are
  evidence; `BUILD SUCCESSFUL` through a pipe is not. A suite that ran zero tests exits zero.
- **A green build on one host says nothing about arm64.** Kotlin/Native has no `linux_arm64` host, so
  `linuxArm64Test` is never created: it does not appear as skipped, it does not appear at all. CI
  cross-links the test binary and runs it on an arm64 runner. Turning `{{name}}.linuxArm64` on also
  moves the staged binary; `nativeImageTar` still builds the `linux_x64` one, and an arm64 image is not something it builds.
- **A number that was not measured says so**, and names the item that will measure it.
- **Do not fork a toolkit.** A gap goes upstream as an issue.

## Where things build

```bash
./gradlew build          # both targets, both suites; the code gate, and CI's build job runs it
make check               # the documentation gate; CI's check job runs exactly this
```

A Mac cannot link an ELF: a klib cross-compiles and an executable does not, so the native half of
`build` really runs on Linux.

## Documentation

Format: [docs-bootstrap](https://github.com/youndie/docs-bootstrap). Documents in English, code in
English.

```bash
pip install pyyaml
make check      # the gate; CI runs exactly it
make report     # the two non-blocking reports
```

## Commits

English, Conventional Commits, no tool signature: `feat(server): …`, `docs(research): …`, `ci: …`.
Branch names the same way.
