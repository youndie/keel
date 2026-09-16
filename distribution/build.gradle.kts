// The JVM half, as a distribution that ships rather than a target that only compiles.
//
// It exists because `application` and zavarnik are `kotlinJvm`-only and do not apply to a
// multiplatform module — research D5. It holds one `main` and no logic: a starter whose logic lived
// in a JVM-only module would have quietly stopped shipping twice.
//
// THE MODULE IS `:distribution` AND NOT `:server-jvm`, WHICH EVERY DOCUMENT CALLED IT UNTIL IT WAS
// BUILT. `:server`'s JVM artefact is already `server-jvm-0.1.0.jar` — Kotlin names it that — so a
// module of that name produces a duplicate in `lib/` and `installDist` refuses. The name also reads
// better: this module is a distribution, not a target.
//
// THESE TWELVE LINES ARE THE ONES ACCEPTANCE 6 ARGUED ABOUT, and the argument is worth knowing when
// you edit them. Counting the version catalog as build logic, this module put the repository at 115
// against a budget of 100; counting build logic alone it is 81. B-03 has the four options and why
// this one. The follow-up is B-17: every native service in this portfolio that wants a shipped JVM
// half needs this same file, which is the definition of something belonging in sborka.

plugins {
    alias(libs.plugins.kotlinJvm)
    application
    alias(libs.plugins.zavarnik)
}

kotlin { jvmToolchain(25) }

dependencies { implementation(project(":server")) }

application { mainClass = "io.github.youndie.keel.jvm.MainKt" }

// THE CACHE IS TRAINED AGAINST THE ROUTE THAT MATTERS, not against the probe.
//
// A workload of `/health/ready` would train the cache on a handler that touches nothing; `/items`
// goes through serialization, the store and the driver, which is where the class loading is.
//
// The training run inherits the build's environment and cannot be given one of its own
// (youndie/zavarnik#13), so this only works because `KEEL_DB_PATH` has a default. A service that
// requires it cannot be trained by `check` at all today.
zavarnik {
    training {
        readyWhen.url("http://127.0.0.1:8080/health/ready")
        workload { get("http://127.0.0.1:8080/items") }
    }
}
