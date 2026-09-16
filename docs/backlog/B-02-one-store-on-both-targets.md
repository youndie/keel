---
id: B-02
title: "One ItemStore implementation compiles and passes its contract suite on both targets"
status: wip
priority: P0
size: M
stage: m1-ships-twice
epic: feature-item-round-trip
blocked_by: [B-01]
---

# B-02 — One store, both targets, or the fallback

[research-architecture](../research/research-architecture.md) D1 decided that keel writes **one**
`ItemStore` over `sqlx4k-sqlite` rather than the two implementations the brief priced in, because the
library already publishes the split: the Rust driver on native and `org.xerial:sqlite-jdbc` on the
JVM. That was read out of the `.module` metadata and the JVM jar's class listing, not out of a
compiled `commonMain` — §1.6 says so and calls it a hypothesis. This item settles it.

- **The decision and its reason.** If the common surface typechecks against both variants, keel keeps
  one implementation and the port exists only so the route's tests can run against an in-memory
  store. If it does not, the fallback is the brief's original shape — sqlx4k on native, JDBC on the
  JVM behind the same port — and §1.6 is amended **at the point of divergence**, keeping the reason
  the first reading was wrong.
- The alternative of writing two implementations up front is worse for a starter specifically: a
  clone copies whatever keel does, and two implementations that drift is the defect the template
  would be teaching.
- **Exactly one driver.** Two sqlx4k drivers in one Kotlin/Native binary do not link —
  `duplicate symbol: std::panicking::EMPTY_PANIC` — and it is a link error, not a resolution error.
  The build file carries that comment whichever way this item goes.
- Not covered: migrations beyond the single `CREATE TABLE`, and connection-pool tuning.

- AC: `jvmTest` and `linuxX64Test` both run `ItemStoreContractTest` against a real SQLite file and
  **both report a non-zero test count**, read from the result file rather than from `BUILD
  SUCCESSFUL`.
- AC: whichever way it goes, research §1.6 says so in writing, with the compiler's message if it
  failed.
- Anchors: `server/src/commonMain/kotlin/.../item/ItemStore.kt`,
  `server/src/commonTest/kotlin/.../item/ItemStoreContractTest.kt`,
  `chronik/chronik-sqlx4k-sqlite/build.gradle.kts`
