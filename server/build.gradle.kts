// The whole service: one route, the kore wiring, two entry points. Everything that ships is here.
//
// What is deliberately NOT here: the `application` plugin and the AOT cache. They cannot apply to a
// multiplatform module, so they live in `:distribution`:
// https://github.com/youndie/keel/blob/main/docs/backlog/B-03-jvm-half-ships.md

plugins {
    alias(wip.plugins.kotlinMultiplatform)
    alias(wip.plugins.kotlinSerialization)
    alias(libs.plugins.sborkaKmp)
    alias(libs.plugins.sborkaLint)
    alias(libs.plugins.sborkaNativeService)
    alias(libs.plugins.koreBuild)

    // APPLIED BY THE REPOSITORY, NOT BY SBORKA. `sborka.native-service` configures the gate and
    // refuses the build when `sborka.binaryBudget` is set and this line is missing — a budget
    // nothing checks is a build that passes forever.
    alias(libs.plugins.razves)
}

// BEFORE THE TARGETS, AND IT HAS TO BE. The convention configures `binaries.executable` from inside
// `targets.withType(...).configureEach`, which fires the moment `linuxX64()` declares one — so an
// entry point set after that line is set after it was read, and the build fails with "property
// entryPoint has no value available", naming neither the ordering nor this block.
nativeService {
    entryPoint = "io.github.youndie.keel.main"
    baseName = "keel"
}

// THE IMAGE, AND NO DOCKERFILE. `./gradlew :server:nativeImageTar` pulls this base by digest with no
// Docker daemon, checks that its loader can load the binary — and refuses to write the image if not —
// then writes `server/build/native-image-oci/keel.tar`. sborka's B-33/B-34, on the owner's decision:
// https://github.com/youndie/sborka/blob/main/docs/research/research-native-image.md
//
// What the check cannot see stays a decision for whoever changes this line: CA certificates and
// glibc's gconv modules, which this base carries and no ELF entry names (service document §3).
nativeImage {
    base = "gcr.io/distroless/cc-debian13@sha256:4594d59540d1948417f6ca2829ddd9294493a7c68b7528f4dd459de7f203a750"
    ports = listOf(8080)
}

// THE BUDGET WATCHES WHAT SHIPS, AND THIS IS A WORKAROUND WITH AN ADDRESS: youndie/razves#4.
//
// razves applies `binarySize.budget` to every executable, and the debug binary is 3.1x the release
// one — 28,580,560 against 9,227,448 on this commit, because the Rust driver and the unstripped
// Kotlin arrive together. Holding both to one number means choosing: a ceiling debug fits under is
// one the shipped binary could triple beneath without the build noticing.
//
// So the release check keeps the real 25 MiB and the debug one is off. `stageNativeImage` stages the
// release binary and the image carries that; nothing deploys the debug one.
//
// This is the only line in this repository's build files that is not "apply a convention and set a
// name", and it is here on the terms CLAUDE.md sets for a workaround: local, and carrying the issue
// so the next person deletes it instead of inheriting it.
tasks.matching { it.name == "sizeBudgetCheckDebugExecutable" }.configureEach { enabled = false }

// THE MEASUREMENT, AND THE LOGIC IS NOT HERE. `k6/measure.sh` holds it, because a measurement is a
// procedure somebody reads and edits rather than a Gradle task, and because build logic is on a
// budget this repository's acceptance actually counts.
tasks.register<Exec>("measure") {
    group = "verification"
    description = "Time to ready, RSS at ready, p95. Refuses to write without --stand naming two hosts"
    dependsOn("stageNativeImage")
    // From the repository root, because that is where `k6/` is and where every path the script
    // prints should be read from. An Exec task defaults to its own project's directory.
    workingDir = rootProject.projectDir
    commandLine("k6/measure.sh")
    args(providers.gradleProperty("measureArgs").orNull?.split(" ") ?: emptyList<String>())
}

kotlin {
    // Development and tests, and a distribution that actually ships (`:distribution`). The parity
    // finding behind keel is that every service in this portfolio had this line and none had a
    // runnable JVM.
    jvm()

    // The target that ships. `--as-needed`, `fixedBlockPageSize=16` and the staged binary path all
    // arrive from the two conventions above; none of them is a line in this file, which is the
    // arrangement the whole repository exists to demonstrate.
    linuxX64()

    // Off by default — see `keel.linuxArm64` in gradle.properties.
    if (providers.gradleProperty("keel.linuxArm64").orNull.toBoolean()) linuxArm64()

    sourceSets {
        commonMain.dependencies {
            implementation(libs.kore.core)
            implementation(libs.kore.ktor)
            implementation(libs.ktor.server.core)
            implementation(libs.ktor.server.cio)
            implementation(libs.ktor.server.content.negotiation)
            implementation(libs.ktor.serialization.json)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.sqlx4k.sqlite)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.ktor.server.test.host)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.okio)
        }
    }
}
