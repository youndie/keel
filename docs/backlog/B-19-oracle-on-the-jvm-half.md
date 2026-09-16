---
id: B-19
title: "Assert the JVM half's shutdown, once the oracle can reach a distribution"
status: wip
priority: P2
size: S
stage: m1-ships-twice
epic: feature-item-round-trip
---

# B-19 — The half the oracle cannot see

B-07 closed on the native image, which is what deploys. The JVM distribution's shutdown is **observed**
correct — exit `143`, kore's full transcript, in B-03's smoke — and asserted by nothing.

- **Why this is not a formality.** kore exists because `EmbeddedServer.stop` runs its steps in the
  **opposite order** on JVM and Kotlin/Native, from identical source. The JVM half is precisely where
  a shutdown defect can live that a green native run cannot see. keel registers nothing in
  `ApplicationStopping`, which is the wiring that trips over it, so there is reason to expect it is
  fine — and reason to expect is not a check.
- **Blocked on [kore#85](https://github.com/youndie/kore/issues/85)**, which asks whether the oracle
  should drive a distribution as well as an image. keel deliberately ships no JVM image: a test-only
  artefact in a template is inherited by every clone.
- **If kore says no**, this item closes as `dropped` rather than lingering, and B-07's iteration 3
  becomes the record of what keel chose not to cover. That is a legitimate outcome, not a failure.
- The rejected alternative is keel containerising its distribution for the test. It is the option that
  needs nobody's permission and it is the one that costs a clone the most.

- AC: the oracle runs against the JVM distribution with a non-zero in-flight count, and the findings
  match the native run's — or the difference is explained.
- AC: the feature's `kill -TERM` scenario loses its "not yet run against the JVM half" qualifier.
- Anchors: `distribution/build.gradle.kts`, `docs/backlog/B-07-shutdown-oracle.md`
