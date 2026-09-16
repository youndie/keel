---
id: B-07
title: "kore's oracle runs against keel's binary, on both targets"
status: wip
priority: P0
size: M
stage: m1-ships-twice
epic: feature-item-round-trip
blocked_by: [B-02, B-03, B-04]
---

# B-07 — Somebody else's oracle, pointed at this binary

Acceptance 3 of the brief: `kill -TERM` under load finishes every in-flight request, on both targets.
kore already has the harness — a load driver that signals a real container and asserts **from the
client's record**, never from the server's log. This item points it at keel.

- **The decision and its reason.** keel writes no oracle of its own. The assertions belong to kore,
  which is the thing being proved correct; a second copy here would be a second specification, and
  the day the two disagree is the day neither is read. What keel supplies is a binary and a
  compose file.
- **The oracle asserts from the client's record.** A log line is written by the code under test, and
  an oracle that reads one can be satisfied by a comment.
- **A run that visited nothing is a failure, not a pass.** The harness counts requests in flight at
  the signal and reports *inconclusive* below a floor.
- Never assert an exit code across the two targets — `0` on native, `143` on the JVM, both correct.
  Assert the process ended itself and was not `SIGKILL`ed (`137`).
- If this run finds a defect in the shutdown, the defect goes to **kore**. keel's first consumer is
  the second real consumer kore has had, and the first found seven defects in two days.

- AC: the oracle run is green on both targets with a non-zero in-flight count, and its transcript is
  attached to the item.
- AC: any finding is filed in kore's backlog with a link from here, not fixed in keel.
- Anchors: `deploy/compose.oracle.yaml`, `Dockerfile`,
  `kore/samples/oracle/src/main/kotlin/io/github/youndie/kore/oracle/Oracle.kt`

---

## Iteration 1 — 2026-09-16: blocked on kore, with the ordering observed

**The oracle cannot be pointed at keel.** `samples/oracle` hardcodes the path it drives —
`client.get("/work?ms=$workMillis")` in `Run.kt:119` — and `/work` is `samples/service`'s route.
`Options` takes `--image`, `--work`, `--connections`, `--grace`, `--read-timeout`, `--pre-drain` and
`--subject-args`, and no path. Pointed at keel's image the in-flight count is zero, nothing spans the
signal, and the run is correctly **inconclusive** — which says nothing about keel.

Filed as **[kore#81](https://github.com/youndie/kore/issues/81)** per the routing table. keel adds no
`/work` endpoint: an on-demand sleep shipped in a template is inherited by every clone, and writing a
harness here is the second copy of the specification this item exists to refuse.

### What was observed anyway, and what it is worth

The in-flight guarantee is not the only thing acceptance 3 claims. The **ordering** can be seen from
the client's record using keel's own routes, and it was, against the image:

| t (s) | `/health/ready` | `/items` |
|---|---|---|
| before the signal | `200` | `200` |
| 0.0 — immediately after `SIGTERM` | `503` | `503` |
| 0.5 … 4.6 | `503` | `503` |
| **5.1** | connection refused | connection refused |
| exit | | **`0`** |

Against the transcript the binary printed:

```
SIGNAL COMPLETED in 898ns
ANNOUNCE COMPLETED in 5.000092518s
DRAIN COMPLETED in 1.050051ms
RELEASE_CONSUMERS COMPLETED in 406ns
RELEASE_POOLS COMPLETED in 2.623227ms
RELEASE_TELEMETRY COMPLETED in 291ns
EXIT COMPLETED in 52ns
```

So: readiness goes false **while the socket is still accepting**, new arrivals get `503` for the whole
five-second announce — `installShutdownRefusal` doing its job — the socket stops accepting only after
it, the store closes after that, and the process ends itself with `0`. That is the specified order,
and the announce window is kore's five-second default rather than an accident.

**This is an observation, not an assertion.** Nothing here runs on a build, nothing spans the signal,
and a single run on one machine is not the property. The item stays `wip`.

### What is still unproven

*Every request in flight at the signal receives its response* — the actual claim. It needs a route
that takes longer than the signal-to-drain gap, which is what kore#81 is about. Until then acceptance
3 is **unverified rather than failing**, and the distinction is the reason this entry exists.
