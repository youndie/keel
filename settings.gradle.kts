rootProject.name = "keel"

pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()

        // WRITTEN OUT BY HAND, AND IT HAS TO BE. `pluginManagement` is evaluated before any settings
        // plugin is applied — including sborka's, which is fetched through it — so the repositories
        // that plugin brings arrive too late to resolve a plugin.
        //
        // FILTERED, and the filter is about failure isolation rather than speed: an unfiltered
        // repository takes part in resolving EVERY dependency, so the day this host is unreachable
        // Gradle disables it and fails artefacts it never served, naming the victim rather than the
        // cause. That has cost this portfolio a debugging session already.
        //
        // This block is what acceptance 1 of the brief means by "with the portfolio's repository
        // configured", and it goes away when kore, sborka and razves reach Maven Central.
        maven("https://reposilite.kotlin.website/snapshots") {
            name = "wip-snapshots"
            content { includeGroupByRegex("io\\.github\\.youndie.*") }
        }
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"

    // Repositories with content filters, the shared `wip` catalog and the `.editorconfig` check.
    // Every convention this repository uses comes from here: a flag in keel's own build files is a
    // flag sborka forgot, and it is filed there rather than added here.
    id("io.github.youndie.sborka.settings") version "0.4.0.79"
}

// THE ONE MODULE. `:server-jvm` — ten lines, `application` and zavarnik — arrives with B-03, because
// zavarnik refuses a project without the `application` plugin and `application` does not apply to a
// multiplatform module. docs/research/research-architecture.md D5.
include(":server")
