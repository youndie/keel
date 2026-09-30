# {{name}}

**What this service is has not been written yet.** [B-01](docs/backlog/B-01-say-what-this-service-is.md)
writes it.

Started from [a template for a Kotlin server that ships twice](https://github.com/youndie/keel): one
source, a JVM distribution and a Kotlin/Native binary, one image. What it came with is an example
route over SQLite, three probes, `/version` and an ordered shutdown. Whatever of that is still here
is the template's until B-01 says otherwise.

```bash
./gradlew :distribution:run                     # the JVM half; runs on a fresh clone, no config
./gradlew :distribution:run --args="--print-config"   # every {{PREFIX}}_* variable and where its value came from
./gradlew :server:linkReleaseExecutableLinuxX64 # the native binary; Linux only
./gradlew build                                 # both targets, both suites
./gradlew :server:nativeImageTar               # the image, no Docker needed: server/build/native-image-oci/{{name}}.tar
```

## Resolving the dependencies

**kore, sborka and razves are not on Maven Central yet.** Until they are, `settings.gradle.kts`
carries the portfolio's repository:

```kotlin
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
        maven("https://reposilite.kotlin.website/snapshots") {
            content { includeGroupByRegex("io\\.github\\.youndie.*") }
        }
    }
}
```

Filtered, and the filter is about failure isolation rather than speed: an unfiltered repository takes
part in resolving *every* dependency, so the day that host is unreachable Gradle disables it and
fails artefacts it never served, naming the victim rather than the cause.

## Documentation

Format: [docs-bootstrap](https://github.com/youndie/docs-bootstrap). Start at
[docs/README.md](docs/README.md); a session starts with [CLAUDE.md](CLAUDE.md).

```bash
pip install pyyaml
make check
```
