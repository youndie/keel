---
id: B-14
title: "Take sborka 0.4.0.80 and delete the configuration-cache workaround"
status: wip
priority: P1
size: S
stage: m0-shape
---

# B-14 — Delete the workaround, now that the thing it worked around is gone

B-01 set `org.gradle.configuration-cache=false` with
[sborka#76](https://github.com/youndie/sborka/issues/76) named in the comment, because
`stageNativeImage` could not be serialised. The issue is fixed and `0.4.0.80` is published, so the
line comes out — which is the half of "a workaround carries a comment naming the issue" that
normally never happens.

- **The decision and its reason.** The comment exists so the next reader deletes the line instead of
  inheriting it. A template makes that worse than usual: every clone would carry a slower build and a
  paragraph about a bug that no longer exists, and none of them would know to look.
- **"Closed" and "fixed" are different claims, and only the second is checkable.** The issue being
  closed is not evidence; the version keel resolves behaving correctly is. So this item is settled by
  a build, not by a changelog.
- **The fix is larger than serialisation and that is why this needs a real check.** `stageNativeImage`
  now stages from the link tasks' outputs instead of scanning `build/bin`, and sborka's own comment
  names the trap: a copy spec resolves its sources while the cache entry is written, so after a
  `clean` the stored entry can report `NO-SOURCE` on every later run with the binary sitting there. A
  task that quietly stages nothing is worse than the failure it replaces.
- Not covered: bumping anything else. One dependency, one reason.

- AC: `org.gradle.configuration-cache=true`, `./gradlew build` green **twice** — once storing the
  entry and once reusing it — with `server/build/native-image/keel` present after each, because the
  second run is the one that would show `NO-SOURCE`.
- AC: the workaround comment is gone from `gradle.properties` and quirk 14 is gone from
  `keel-server.md`, deleted **after** the verification rather than on the strength of the fix.
- Anchors: `gradle.properties`, `gradle/libs.versions.toml`,
  `sborka/build-logic/conventions/src/main/kotlin/io/github/youndie/sborka/native-service.gradle.kts`
