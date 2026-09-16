---
id: B-09
title: "The webhook relay is built from keel, and every non-domain line the agent added is a defect"
status: open
priority: P0
size: L
stage: m4-consumer
blocked_by: [B-07, B-08]
---

# B-09 — The first consumer, with somebody counting

The webhook relay is built *from* keel through the `native-service-bootstrap` skill, by the agent,
with a human counting. The measure is not "did it work": it is **every line the agent had to add
that is neither domain nor template renaming**, and each of those is a defect with a destination.

| the line was | it goes to |
|---|---|
| a build flag, a linker option, a CI step | sborka |
| lifecycle, probes, config, shutdown | kore |
| a procedure the agent had to work out | the skill |

- **The decision and its reason.** Nothing goes to keel except renaming. If keel accumulates fixes it
  is turning back into konekt, which is the thing it was extracted from. The routing table is how a
  template stays a template under pressure from a real service.
- The count is kept by a person who is not the agent doing the work. An agent grading its own output
  against "was this line necessary" is the shape of measurement that always passes.
- **The number is recorded whatever it is**, including zero and including twenty. kore's first
  adoption found seven defects in two days that 184 tests and an end-to-end oracle had not; that is
  the honest expectation here too.
- Kill criterion, from the brief: if acceptance 6 — 500 lines of Kotlin, 100 of Gradle — cannot be
  met after this consumer, the starter idea is wrong for this stack and the honest deliverable is
  the skill alone, generating from konekt's pieces. **Write that down and stop.**

- AC: the relay runs, and the tally is in this item: lines added, split by destination, with a link
  to each issue filed.
- AC: keel's own diff during the exercise is renaming only, or the exception is argued here.
- Anchors: `docs/services/keel-server.md`, `CLAUDE.md`,
  `kotlin-skills/plugins/kotlin-fullstack/skills/native-service-bootstrap/SKILL.md`
