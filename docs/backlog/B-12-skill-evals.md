---
id: B-12
title: "An eval suite for native-service-bootstrap with checkable expectations"
status: open
priority: P2
size: M
stage: m4-consumer
blocked_by: [B-11]
---

# B-12 — "Create service X", and something that can say whether it worked

The brief asks for `evals/evals.json` beside the skill, with "create service X" and checkable
expectations. There is none: the plugin directory holds `skills/` and nothing else
([research-architecture](../research/research-architecture.md) §1.11).

- **The decision and its reason.** An expectation is checkable or it is decoration. "The service
  starts" is not checkable by a grader; "`/health/ready` answers `200` and `/health/startup` answered
  `503` before it" is. The suite is written against facts of the same kind as the BDD scenarios in
  [feature-item-round-trip](../features/feature-item-round-trip.md) §5.
- The first cases come from [B-09](B-09-first-consumer.md)'s tally: whatever the agent had to work
  out for itself is what the eval should catch next time. Writing cases before that run would be
  guessing at which steps are hard.
- The rejected alternative is a smoke test that builds the service and checks the exit code. It
  passes when the agent produces a service with one probe answering `200` for all three questions,
  which is the exact failure kore exists to stop.
- Not covered: evals for the other nine skills.

- AC: `evals/evals.json` exists beside the skill, each case naming an observable — a route, a status,
  a file that must exist, a line that must not.
- AC: at least three cases are drawn from defects the first consumer actually hit.
- Anchors: `kotlin-skills/plugins/kotlin-fullstack/skills/native-service-bootstrap/SKILL.md`,
  `docs/features/feature-item-round-trip.md`
