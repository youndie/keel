---
id: B-22
title: "The kotlin.website page: a Kotlin server that ships twice, in an hour"
status: open
priority: P1
size: M
stage: m4-consumer
---

# B-22 — The deliverable that was never an item

The brief lists three deliverables. Two are done — the template repository, flagged as one, with the
measured numbers in its README; and `native-service-bootstrap` pointing here with an eval suite beside
it. The third is a page on kotlin.website, *"A Kotlin server that ships twice, in an hour"*, and it
**was never entered into this backlog at all**.

That is the finding, and it is worth more than the page: twenty-one items were written from the
brief's contents table, its acceptance list and its decisions, and the deliverables section was read
past. A backlog derived from a document can inherit the document's shape and still miss a section of
it, and nothing here would have noticed — every gate is about internal consistency, and a missing
deliverable is consistent with everything.

- **What the page is, per the brief.** The numbers and the clone line, and **nothing about how kore or
  sborka work inside**. That restriction is the whole editorial problem: most of what was learned here
  is about those two, and none of it belongs on this page.
- **The numbers it has to carry**, all measured and dated in this repository: 3 min 48 s from clone to
  both halves answering `/health/ready` on a machine that has never seen the portfolio; 13 972 497
  bytes of image; p95 1.86 ms at a delivered 499.95 req/s on two hosts; 23 tests on each of three
  targets; the first consumer's six lines that were neither domain nor renaming.
- **What it must not do is claim the stranger test.** A clone still needs the portfolio's Maven
  repository configured, because kore, sborka and razves are not on Maven Central. A page that says
  "clone and run" without that line is wrong for everybody outside this portfolio, which is most
  readers.
- Not covered: moving those three to Central. That is not keel's work and the README already carries
  the reposilite block.

- AC: the page exists on kotlin.website, carrying the clone line and the measured numbers with the
  dates they were taken.
- AC: it says what a reader needs before cloning — the repository block — rather than discovering it.
- AC: it explains none of kore's or sborka's internals.
- Anchors: `README.md`, `docs/research/measurements-2026-09-16.md`, `backlog.md`
