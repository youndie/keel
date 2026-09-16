# keel — backlog

## The goal

A GitHub template repository for a Kotlin server that ships twice. Clone, rename, `./gradlew run`,
and there is a service: one route, one table, three probes, a `/version`, two targets both runnable,
one image, every check green on day one. It is konekt with the domain removed — the wiring a new
service needs, and nothing the last one happened to have.

The test for every file in it is the brief's: *did konekt or katcher need this?* If not, it is not in
keel.

## The reality check

**The service runs; the packaging does not exist.** Since B-01 there is a `:server` module producing
a JVM jar and a `linuxX64` executable, the kore wiring and the size gate; since B-06 a CI job that
compiles the code and a report step that fails when a **named** target's suite goes missing; since
B-02 two routes over a real SQLite database that survives a restart, and 22 tests on each target from
one source; since B-04 an image that builds, serves a rendered page and stops cleanly at 14 MB; since
B-03 a JVM distribution whose AOT cache is verified on every `check`.

**A service has been built from keel, and the template needed no change to carry it.** The first
consumer — a webhook relay — cost 249 lines of renaming, 178 lines of its own domain, and **six lines
that were neither**: two dependency declarations for an HTTP client. Every infrastructure file is
byte-identical to the template. The caveat is in [B-09](docs/backlog/B-09-first-consumer.md) and it
matters: the relay forwards over `http` only, because `ktor-client-cio` has no TLS on Kotlin/Native,
and fixing that would touch the `Dockerfile` — filed as
[kotlin-skills#5](https://github.com/youndie/kotlin-skills/issues/5). The count was also kept by the
agent that did the work, which is the measurement this item warns about.

**keel ships twice in the sense the brief meant it.** What is left is the measuring: parity
(B-05), clone-to-ready (B-08) and the stand (B-13). **Acceptance 3 is verified on both halves.** kore's oracle asserts seven things from the client's
record against the native image (B-07) and, since kore#85 gave it `--command`, against the JVM
distribution too (B-19): 32 of 32 requests in flight at the signal all completed on each, every
refusal carrying `Connection: close`, exit `0` native and `143` JVM. **The asymmetry that made this
worth two items is closed** — `EmbeddedServer.stop` runs its steps in the opposite order on the two
platforms, so the JVM half was where a defect could hide from a green native run.
**B-16 is answered and B-18 is `dropped`**: keel ships on `distroless/cc-debian13` and the `scratch`
recipe stays written down rather than shipped. That is now a decision without an expiry — it carried
KT-89362 as one until the owner closed the question on 2026-09-16, on the ground that 4.5 MB off an
image 44 % under budget was never a trade a ticket could swing. `linuxArm64` is covered by nobody (B-15).

Every document outside `docs/research/` is still `status: draft`, because each of them describes more
than exists. The research is `active`: the reading it records happened on 2026-09-16 against artefacts
and repositories that exist.

This section was wrong within one iteration of being written — it said "nothing is built" — and that
is the failure mode to watch for: a sentence about the state of a repository has no way to go red.
The items below and the build do. Prefer them.

Three things about this backlog that are not obvious from the items:

* **Two of the brief's four open decisions came out differently from what it assumed.** D1 — the
  store — needs one implementation, not two, because `sqlx4k-sqlite` publishes a JVM variant that is
  JDBC underneath. D3's ticket was the wrong ticket: KTOR-9891 is fixed and ships in Ktor 3.6.0, and
  it has nothing to do with charsets. Both are in
  [research-architecture](docs/research/research-architecture.md) §2 with what settled them.
* **One decision is new and contradicts the brief's contents table.** zavarnik refuses a project
  without the `application` plugin, and `application` does not apply to a multiplatform module — so
  "one KMP module" and "`aotVerify` on `check`" cannot both be literal. D5 splits off a ten-line
  `:distribution`, and names dropping zavarnik as the right answer if that split breaks acceptance 6's
  Gradle budget.
* **[B-09](docs/backlog/B-09-first-consumer.md) can end the project, and that is deliberate.** If the
  first consumer cannot be built from keel inside the line budgets, the brief's own kill criterion
  applies: the starter idea is wrong for this stack, the honest deliverable is the skill alone, and
  the instruction is to write that down and stop.

## Stages

| Stage | Name | What closes it |
|---|---|---|
| `m0-shape` | Shape | a repository that builds both targets on borrowed conventions, with nothing of its own in its build files |
| `m1-ships-twice` | Ships twice | one store on both targets, a JVM distribution with a verified cache, the oracle green, and evidence that a suite actually ran on each target |
| `m2-image` | The image | two images from one `Dockerfile`, both against budgets declared before the first build |
| `m3-measured` | Measured | parity against a normaliser written first, the clone-to-ready time, and the first stand measurement |
| `m4-consumer` | The first consumer | the webhook relay built from keel with the defects counted and routed, the skill pointed here, the draft gate on |

A milestone closes as a whole and gets a line here saying what came out beyond the plan, and which
research hypothesis was confirmed or refuted.

**Two of the five are closed. The other three are each held open by one item blocked in another
repository** — `m1-ships-twice` by B-15, B-17 and B-19, `m2-image` by B-18, `m4-consumer` by B-12 —
which is worth naming because it is not the same as work remaining here.

### Shape closed — 2026-09-16

**The premise holds: keel's build files apply conventions and set names, and nothing else.** B-01 put
`:server` on `sborka.native-service`, `sborka.kmp`, `sborka.lint` and razves without a single flag of
its own, and B-14 removed the one line that was not — a workaround, after the thing it worked around
was fixed.

*Beyond the plan:* **the conventions had never been run with the configuration cache on.**
`stageNativeImage` could not be serialised, and keel was the first build anywhere to meet it — sborka's
own stand applies the convention without the cache, and the three services that run with the cache
hand-write their native builds. Filed as [sborka#76](https://github.com/youndie/sborka/issues/76),
fixed the same day, and the workaround deleted with the comment that made it findable. The round trip
took one working day and it is the clearest evidence so far that the routing table works.

*Confirmed:* research §1.3's claim that `--as-needed` drops three of the ten `NEEDED` entries — read
off `keel.needed.txt` as **seven**, the first time that prediction has been checked on a binary
outside sborka.

*Refuted:* the unstated assumption that a convention working on its own stand works in a consumer.
The second consumer is where a convention's edges are, and keel was the second consumer of three
different ones.

*Also out of it:* acceptance 6 had no definition. Counting every Gradle line or only build logic
differed by 2.5x, and the question could not be deferred — B-03 could not fit until it was answered.

### Measured closed — 2026-09-16

**Every number the brief declared is now measured or explicitly refused, and the refusals are the
better half.**

| | declared | measured |
|---|---|---|
| clone → ready, cold machine | under 1 h | **3 min 48 s**, the build 82 % of it |
| parity between the targets | no diff after the normaliser | no diff, with a control on the record count |
| p95 at a fixed rate | — | **1.86 ms** at a delivered 499.95 req/s, on two hosts |

*Beyond the plan:* **three of the four defects these items found were in the measuring, not in keel.**
A parity comparison that diffed two empty files and passed. A normaliser that named `/version` fields
which do not exist, so it normalised nothing while looking correct. A `handleSummary` that threw on a
metric this k6 does not publish, so a run that had worked reported nothing at all — twice, in two
different items, both times because that function runs in a context the rest of the script does not.

*And one that was in keel:* `GET /items` has no limit. At 500 req/s it achieved 29.8 iterations a
second, dropped 4 692 and moved 151 MB in ten seconds, every figure describing a response body growing
by 500 rows a second. Quirk 18, and a denial of service any clone would inherit.

*Confirmed:* research open question 1 — the hour holds, and the guess that the toolchain download
dominates was right at 82 %.

*Refuted, by me:* B-13 iteration 1 recorded that the stand hardware "is not available to this loop".
`bench-a` and `bench-b` were in `~/.ssh/config` the whole time. The claim was written without
checking, and it is the one entry in this backlog that was wrong for no reason other than not
looking.

## What the numbers are, and where they come from

The acceptance thresholds are the brief's, declared before the first commit — an hour to ready, 25 MB
on `distroless/cc`, 12 MB with `STATIC=1`, 500 lines of Kotlin, 100 of Gradle.

**The two line budgets needed a definition and did not have one**, which B-01 found by being the first
thing to measure them. Counted as written, the Gradle files are 225 lines; counted as code — blank
lines and comments dropped — they are 91. The difference is not slack, it is this portfolio's house
style: the reasoning lives beside the line it explains, and on these four files that is 60 % of them.

**The measure is code lines of build logic**, and both halves of that were decided by being measured
against.

*Code lines* — blank lines and comments dropped — because a comment cannot make a build do the wrong
thing and a line of Gradle can. Both numbers are reported at every reading so the choice stays
visible rather than becoming a way to pass.

*Build logic* — which excludes `gradle/libs.versions.toml` — was **decided in B-03**, and the
reasoning is the budget's own stated purpose. Acceptance 6 says going over "is the signal that
something belongs in sborka or kore instead". A pinned version cannot belong in sborka: keel pins
kore, sqlx4k and razves deliberately, each with a comment saying why that number and not the newest.
Counting them measured something the rule was never about, and it was about to force the removal of a
feature to make room for a dependency list.

The honest cost of the decision, since it was taken by the thing being measured: **it is a criterion
edited in the middle of the work it was constraining.** What makes it defensible rather than
convenient is that it was taken with the alternative written down and rejected on its merits — the
options and their measured costs are in [B-03](docs/backlog/B-03-jvm-half-ships.md) — and that the
number itself did not move. Four of sborka's shared catalog versions could genuinely come from its
`wip` catalog, and doing that is a separate item rather than an argument for counting them here.

Measured on `feat/b-01-repository-skeleton`, 2026-09-16:

| | code | as written | budget |
|---|---|---|---|
| Gradle — build logic, catalog excluded (B-03) | **95** | — | 100 |
| Kotlin under `server/`, main only | **211** | 407 | 500 |
| Kotlin under `server/`, tests included | 541 | 1002 | — |

**87 of 100 with the distribution module in**, counting build logic. The paragraph below is how that
number came to mean what it means; the history that produced it is worth keeping, because the
alternative was removing a feature to make room for a dependency list.

**98 of 100, and B-03 needed 17 more.** The nine lines of headroom B-01 recorded went on the SQLite
driver, okio and the razves workaround. B-03 measured the smallest honest `:distribution` at 12 code
lines plus an include plus four catalog entries — **115 of 100** — and there is no smaller correct
version of that file.

B-03 was a **`question`** for exactly that reason, with four options and their measured costs in the
item. The prescribed answer — dropping zavarnik — turned out not to close the gap on its own:
`application` is what `installDist` needs, so the module stays either way. **The owner took options 3
and 4**: count build logic rather than every Gradle line, and propose the module's shape to sborka
([#78](https://github.com/youndie/sborka/issues/78), adopted here by B-17). That is the acceptance
criterion doing what a criterion declared before the first commit is for — forcing a decision instead
of being quietly adjusted.

**A second measure is worth recording while this is open.** The Kotlin budget reads 211 lines counting
only `commonMain`/`jvmMain`/`nativeMain`, and 541 counting the test sources with it. The brief says
"Kotlin in `:server` under 500", which does not say which. Main-only is the reading that matches the
budget's purpose — a test suite is not something that "belongs in sborka or kore instead" — and both
numbers are reported so the choice stays visible.

Measured, not estimated, on the same build: the `linuxX64` release binary is **4 983 240 bytes**, and
it declares **seven** shared libraries rather than the ten a Kotlin/Native binary names by default —
`--as-needed` dropped `libresolv`, `libutil` and `libcrypt`, which is the whole argument for the image
carrying the binary and nothing else.

A budget that is missed gets a new number **and a line saying what it bought**. A quiet edit is how a
budget stops being one.

## Index

<!-- BEGIN INDEX - generated by scripts/backlog_index.py, do not edit by hand -->

## Open (3)

| Task | | Priority | Size | Blocked by |
|---|---|---|---|---|
| [B-12](docs/backlog/B-12-skill-evals.md) `[ ]` | An eval suite for native-service-bootstrap with checkable expectations | P2 | M | B-11 |
| [B-19](docs/backlog/B-19-oracle-on-the-jvm-half.md) `[~]` | Assert the JVM half's shutdown, once the oracle can reach a distribution | P2 | S | - |
| [B-17](docs/backlog/B-17-adopt-the-jvm-distribution-convention.md) `[ ]` | Adopt sborka's jvm-distribution convention once it exists | P3 | XS | - |

## Closed (16)

**Shape**

- [B-01](docs/backlog/B-01-repository-skeleton.md) `[x]` - The repository builds both targets with the conventions applied and nothing of its own
- [B-14](docs/backlog/B-14-configuration-cache-back-on.md) `[x]` - Take sborka 0.4.0.80 and delete the configuration-cache workaround

**Ships twice**

- [B-02](docs/backlog/B-02-one-store-on-both-targets.md) `[x]` - One ItemStore implementation compiles and passes its contract suite on both targets
- [B-03](docs/backlog/B-03-jvm-half-ships.md) `[x]` - installDist runs with a verified AOT cache, and the split it costs is one module
- [B-06](docs/backlog/B-06-both-targets-tested.md) `[x]` - CI proves a suite ran on each target, rather than proving the build was green
- [B-07](docs/backlog/B-07-shutdown-oracle.md) `[x]` - kore's oracle runs against keel's binary, on both targets
- [B-15](docs/backlog/B-15-arm64-suite-runs.md) `[x]` - Run the linuxArm64 suite on an arm64 runner, once razves can register its tasks

**The image**

- [B-04](docs/backlog/B-04-image-and-size-budget.md) `[x]` - Two images from one Dockerfile, both measured against a budget declared first
- [B-16](docs/backlog/B-16-static-image.md) `[x]` - Should the template ship the scratch recipe at all?
- [B-18](docs/backlog/B-18-scratch-when-static-is-static.md) `[-]` - Ship the scratch image once -static needs no property overrides

**Measured**

- [B-05](docs/backlog/B-05-parity-smoke.md) `[x]` - The parity normaliser is written before the first parity run
- [B-08](docs/backlog/B-08-clone-to-ready.md) `[x]` - Clone to /health/ready on a machine that has never seen the portfolio, timed
- [B-13](docs/backlog/B-13-first-measurement-on-the-stand.md) `[x]` - The first measurement on the stand: readiness, RSS at ready, p95 at a fixed rate

**The first consumer**

- [B-09](docs/backlog/B-09-first-consumer.md) `[x]` - The webhook relay is built from keel, and every non-domain line the agent added is a defect
- [B-10](docs/backlog/B-10-draft-gate.md) `[x]` - Turn docs_check.py --on-main on once the tree describes code that exists
- [B-11](docs/backlog/B-11-skill-points-at-keel.md) `[x]` - native-service-bootstrap names keel as its reference project in Step 0

<!-- END INDEX -->
