---
id: B-21
title: "Build with both native targets, now that staging can tell them apart"
status: wip
priority: P2
size: S
stage: m1-ships-twice
epic: feature-item-round-trip
---

# B-21 — The AC B-15 could not meet

[sborka#80](https://github.com/youndie/sborka/issues/80) is fixed and published in `0.4.0.82`:
`stageNativeImage` stages one binary per native target, and `NativeImageReference` takes the staged
path so a generated Dockerfile names the architecture it was built for.

B-15 closed on the thing it was for — an arm64 suite running on arm64 hardware — and left one
criterion unmet: `./gradlew build -Pkeel.linuxArm64=true` failed in staging, because two release
binaries were renamed to one name in one directory. This is that criterion.

- **What has to be checked beyond a green build.** The staged layout changes shape when a second
  target appears, and keel's `Dockerfile` has a `COPY` line reading `build/native-image/keel`. If the
  layout is now `<konanTarget>/keel` whenever there are two, that `COPY` breaks the moment a clone
  turns `keel.linuxArm64` on — which is a worse failure than the one being fixed, because it happens
  at image build time rather than at configuration.
- The rejected alternative is leaving the third target unbuildable and keeping the note. It costs
  nothing today and it means the first clone to want arm64 finds a repository that documents the
  problem instead of one that solved it.

- AC: `./gradlew build -Pkeel.linuxArm64=true` is green.
- AC: the image still builds **with the property off**, and what happens to that `COPY` with the
  property on is either verified or written down.
- Anchors: `gradle/libs.versions.toml`, `Dockerfile`, `server/build.gradle.kts`
