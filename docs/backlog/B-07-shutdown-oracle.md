---
id: B-07
title: "kore's oracle runs against keel's binary, on both targets"
status: open
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
