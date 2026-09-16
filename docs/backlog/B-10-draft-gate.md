---
id: B-10
title: "Turn docs_check.py --on-main on once the tree describes code that exists"
status: open
priority: P2
size: XS
stage: m4-consumer
blocked_by: [B-07]
---

# B-10 — The draft gate is off with an address, not relaxed

Every document outside `research/` is `status: draft`, because the code does not exist. On `main` a
draft is a defect — it means intent was documented as fact — and `docs_check.py --on-main` is the
mechanical half of that rule. It is **off**, and this item is its address.

- **The decision and its reason.** A docs-first template repository has nothing that exists yet. The
  two honest ways to hold the invariant are to keep the whole tree in an open pull request until the
  code lands, or to say in one place that the tree is intent and name the item that turns the gate
  on. kore took the second and it worked: the flag became a line in CI rather than a relaxed rule.
- What is not acceptable is a tree of `active` documents describing code nobody has written, which is
  the failure mode this whole format exists to prevent.
- **Flipping the field is not the work.** When a feature is built, its document becomes `active` *and
  is re-read against the code* — the status is the last edit, not the first.
- Not covered: the research documents, which stay `active` throughout. Research legitimately predates
  the code, and `research-architecture` describes reading that actually happened.

- AC: `docs_check.py --on-main` runs in CI on pushes to the default branch and is green, because every
  layer document has been re-read against the code it describes.
- Anchors: `.github/workflows/check.yaml`, `Makefile`, `scripts/docs_check.py`
