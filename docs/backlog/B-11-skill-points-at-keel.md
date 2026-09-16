---
id: B-11
title: "native-service-bootstrap names keel as its reference project in Step 0"
status: open
priority: P1
size: S
stage: m4-consumer
blocked_by: [B-09]
---

# B-11 — The skill's Step 0 currently points at two production services

`native-service-bootstrap` is already the tenth skill in kotlin-skills — the brief's "move it there"
deliverable is done, verified in
[research-architecture](../research/research-architecture.md) §1.11. What is not done is keel being
its reference project: Step 0 today says *"copy a living service, not the template in this file"* and
names metrik and katcher.

- **The decision and its reason.** That instruction was right when the alternative was a template
  inside a markdown file, which rots the moment a convention moves. It is the wrong instruction once
  a repository exists whose CI proves it still builds: metrik and katcher carry a domain, and an
  agent copying one starts by deleting things it does not understand.
- What changes is one step, not the skill. The skill's own split — "this file describes and measures;
  the convention compels" — stays exactly as it is, and keel is a third category: *the thing that is
  already wired*.
- **After [B-09](B-09-first-consumer.md), not before.** Pointing a skill at a template nobody has
  built a service from is how a recommendation gets made on the strength of an intention.
- The alternative of leaving Step 0 alone and mentioning keel further down is worse in the one way
  that matters: an agent reads Step 0 and acts on it.

- AC: Step 0 names keel, with the clone line and what to rename; the two services stay named as
  *where the idioms are newer*, which is a different question.
- AC: the skill's paragraph about keel carries the measured numbers from
  [B-08](B-08-clone-to-ready.md), not estimates.
- Anchors: `kotlin-skills/plugins/kotlin-fullstack/skills/native-service-bootstrap/SKILL.md`,
  `kotlin-skills/plugins/kotlin-fullstack/skills/native-service-bootstrap/references/`
