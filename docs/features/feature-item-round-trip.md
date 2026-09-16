---
id: feature-item-round-trip
title: One item, stored and returned, on both targets
type: feature
status: draft
owner: unassigned
involved_services:
  - keel-server
client_entries: []
api:
  - endpoint-items
tags: [template, parity]
---

# One item, stored and returned, on both targets

## 1. Overview

keel's only feature, and it is not about items. `POST /items` then `GET /items` is the shortest path
that touches every mechanism a new service needs working on day one: JSON in and out, a store that is
a real database on both targets, a route that survives a shutdown mid-request, and a binary that
answers the same way whether it was compiled to a JVM class file or to an ELF. The entity is
`Item { id, name }` and it stays that way — a starter whose example grows features stops being a
starter.

`client_entries: []` is the answer rather than an omission: keel has no client, by the brief's first
non-goal. A client template is a separate repository.

The scenarios below **are** the acceptance criteria of the template. Six of them restate the brief's
declared acceptance in a form a test can hold, and none carries an `**Automated:**` line yet, because
no code exists — that absence is the honest signal and `bdd_report.py` counts every one of them as
manual.

## 2. Business rules

* An item has exactly two fields. Adding a third is the brief's red list: "a second entity" and a
  growing example are the same failure at different sizes.
* The store is reached through `ItemStore`, always. The route never touches a driver, so the route's
  tests run against an in-memory implementation and say nothing about SQLite.
* **Exactly one sqlx4k driver is on the classpath.** Adding a second is a link failure on native, not
  a resolution failure — a clone that wants Postgres replaces SQLite rather than adding to it.
* A request in flight when `SIGTERM` arrives is finished, not dropped. A request arriving after the
  announce gets `503` and `Connection: close`.
* Both targets answer identically, except for what the parity normaliser declares (the exit code, the
  `Server` and `Date` headers, and `/version`'s build time). The normaliser is written **before** the
  first parity run, so that it cannot become a list of whatever happened to differ.
* A number that was not measured says so. The README carries the image sizes and the clone-to-ready
  time with the date they were taken; every other figure is a hypothesis and is labelled one.

## 3. Flow

```
POST /items ──▶ ItemRoutes ──▶ ItemStore ──▶ sqlx4k-sqlite ──▶ SQLite file
                                                 │
                            native: the Rust driver · JVM: org.xerial:sqlite-jdbc
GET  /items ──▶ ItemRoutes ──▶ ItemStore ──▶ … ──▶ [Item, …] as JSON

SIGTERM ─▶ kore: announce (readiness 503) ─▶ drain (in-flight finishes)
                                    ─▶ release (the store closes) ─▶ exit
```

There are no cross-service calls and no auth tiers, because there is one service and no
authentication (see [endpoint-items](../api/endpoint-items.md)).

## 4. Code anchors

| Service | Code |
|---|---|
| keel-server | `server/src/commonMain/kotlin/.../item/` — the whole feature: `Item`, `ItemStore`, `ItemRoutes` |
| keel-server | `server/src/commonMain/kotlin/.../Wiring.kt` — where the routes, the probes and the shutdown registrations meet |
| keel-server | `server/src/commonTest/kotlin/.../item/ItemRoutesTest.kt` — the route against an in-memory `ItemStore` |
| keel-server | `server/src/commonTest/kotlin/.../item/ItemStoreContractTest.kt` — the same suite run against SQLite on both targets |
| keel-server | `k6/items.js` — the scenario both binaries are driven with, for parity and for `:server:measure` |
| kore | `kore/samples/service/src/commonMain/kotlin/io/github/youndie/kore/sample/KoreWiring.kt` — the wiring keel's is derived from |

## 5. Scenarios (BDD / test cases)

All **target** behaviour. A scenario gains an `**Automated:**` line when its test exists; until then
the check is manual and is meant to look that way.

### Scenario: an item survives the round trip, on both targets

* **Given:** a freshly started keel binary with an empty store
* **When:** `POST /items` with `{"id":"a","name":"first"}` and then `GET /items`
* **Then:** the `POST` answers `201` with the stored item and the `GET` answers `200` with an array
  containing exactly it
* **And:** the same two calls against the other target produce byte-identical bodies

### Scenario: the store is the same code on both targets

* **Given:** the `ItemStore` contract suite
* **When:** it is run as `jvmTest` and as `linuxX64Test`
* **Then:** both run the same scenarios against a real SQLite file, and **both report a non-zero
  count** — a suite that ran nothing exits zero and must not pass
* **And:** if the common surface does not typecheck against both sqlx4k variants, this scenario is
  what says so, and [B-02](../backlog/B-02-one-store-on-both-targets.md) takes the fallback

### Scenario: `kill -TERM` under load finishes every in-flight request

* **Given:** the binary under k6 load with requests in flight
* **When:** the container receives `SIGTERM`
* **Then:** every request in flight at the signal receives its response
* **And:** requests arriving after the announce receive `503` with `Connection: close`
* **And:** the process ends itself — `0` on native, `143` on the JVM — and is not `SIGKILL`ed (`137`)
* **And:** the run is **inconclusive**, not green, if fewer than the declared floor of requests were
  in flight at the signal

### Scenario: readiness goes false before the drain starts

* **Given:** a running binary answering `200` on `/health/ready`
* **When:** `SIGTERM` arrives
* **Then:** `/health/ready` answers `503` while the socket is still accepting, and only then does the
  drain begin
* **And:** nothing is closed in `ApplicationStopping`, which runs on the wrong side of the drain on
  one of the two platforms

### Scenario: a missing required variable stops the process instead of a route

* **Given:** an environment with the required configuration key unset
* **When:** the binary starts
* **Then:** it refuses to start, printing every problem it found rather than the first one
* **And:** `--print-config` answers the same verdict **without** starting the process, because it is
  asked precisely when the process will not start

### Scenario: a misspelled variable is named rather than ignored

* **Given:** `KEEL_WORK_MSEC` set where the schema declares `KEEL_WORK_MS`
* **When:** the binary starts on a Linux target
* **Then:** it refuses, naming the declared variable the unknown one is probably a misspelling of
* **And:** on macOS native the check reports that it **could not run**, never "nothing found" — the
  environment cannot be enumerated there

### Scenario: the image starts with the binary and nothing beside it

* **Given:** the image built from the committed `Dockerfile` with no `COPY` line other than the binary
* **When:** the container is started
* **Then:** it answers `/health/ready` — no `cannot open shared object file`, no library dragged from
  the builder stage
* **And:** the image is under the declared budget for its base (see
  [B-04](../backlog/B-04-image-and-size-budget.md))

### Scenario: the static image serves a rendered page, not a status code

* **Given:** the image built with `--build-arg STATIC=1`
* **When:** `POST /items` and then `GET /items` are called against it
* **Then:** the JSON body comes back correct — **not** merely a `2xx`
* **And:** no `Failed to open iconv for charset UTF-8 with error code 22` appears in the log

This scenario is worded the way it is because a `401` from a static image was once read as a pass: a
`401` is produced before any text crosses a charset, and every rendered byte goes through glibc
`iconv`, which is `dlopen`ed.

### Scenario: parity — the same k6 scenario, no diff after the normaliser

* **Given:** the JVM distribution and the native binary, both serving
* **When:** `k6/items.js` runs against each
* **Then:** the recorded responses are identical after the declared normaliser, and the normaliser is
  the file that existed before the run

### Scenario: the clone builds on a machine that has never seen the portfolio

* **Given:** a clone of the template with the portfolio's Maven repository configured and no other
  local state
* **When:** both targets are built, `check` is run, the image is built
* **Then:** all three succeed and `/health/ready` answers on both binaries
* **And:** the wall time — including the Kotlin/Native toolchain fetch — is recorded in the README
  with the date it was taken, whatever it turns out to be

### Scenario: the template stays a template

* **Given:** the repository at any commit
* **When:** the line counts are taken
* **Then:** Kotlin under `server/` is under 500 lines and Gradle across the repository is under 100
* **And:** going over either is treated as the signal that something belongs in sborka or kore, and
  the finding is filed there rather than fixed here

## 6. Out of scope

* Authentication, a chart, a client, a second entity, a second route group.
* Migrations beyond the one statement that creates the table. A migration framework is a decision a
  real service makes.
* Metrics and tracing: `kore-observability` is a commented block, because it is portfolio-only and a
  clone outside the portfolio cannot resolve it.
* The "stranger test" — a clone with **no** portfolio repository configured — which waits for kore and
  sborka to reach Maven Central and is not keel's work.

## 7. Quirks

The platform divergences that make these scenarios read strangely are in
[keel-server](../services/keel-server.md) §8, all thirteen of them. The three that bear directly on
the scenarios above:

* **Exit codes differ between the targets on a *correct* shutdown** — `0` and `143`. The scenario
  asserts "not `137`" for that reason.
* **`Connection: close` does not close the socket** on CIO; it is a header promise. A scenario that
  asserted the socket closed would fail against correct behaviour.
* **A suite that ran zero tests exits zero**, and on one host `linuxArm64Test` is never created at
  all. "Both report a non-zero count" is in the second scenario because of that, not as pedantry.
