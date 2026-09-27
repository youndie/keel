package io.github.youndie.keel.item

import io.github.youndie.keel.keelModule
import io.github.youndie.kore.health.LivenessGate
import io.github.youndie.kore.health.ReadinessGate
import io.github.youndie.kore.health.StartupGate
import io.github.youndie.kore.lifecycle.DrainGate
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.ApplicationTestBuilder
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals

/**
 * The module answers, on both targets, from one source.
 *
 * These go through `keelModule` rather than through a route function, because what is worth
 * guarding is the assembly: the order things are installed in is what decides whether the shutdown
 * refusal can see the first request after the announce, and a test of `itemRoutes()` alone would
 * pass with that interceptor missing entirely.
 */
class ItemRoutesTest {
    @Test
    fun `GET items answers with the seeded item`() =
        testApplication {
            keel()

            val response = client.get("/items")

            assertEquals(HttpStatusCode.OK, response.status)
            assertEquals(
                """[{"id":"keel","name":"the first member laid down"}]""",
                response.bodyAsText(),
                "the route renders a body, which is the half a status code cannot show — every rendered " +
                    "byte on Kotlin/Native goes through glibc iconv",
            )
        }

    /**
     * keel's startup probe says "started" immediately, and that is correct rather than broken.
     *
     * A `StartupGate` with no named gates is started from birth — `started = gates.isEmpty()` — so
     * keel, which names none, answers `200` from the moment the module is installed. This test was
     * written asserting the opposite and failed on both targets, which is the useful kind of wrong:
     * the probe is only worth having once a service names what it is waiting for, and a clone that
     * adds migrations without adding a gate has a startup probe that lies.
     *
     * Both halves are asserted so that the day somebody gives keel a real gate, the second one is
     * already here describing what they should expect.
     */
    @Test
    fun `startup with no named gates is started immediately`() =
        testApplication {
            keel()

            val response = client.get("/health/startup")

            assertEquals(HttpStatusCode.OK, response.status)
            assertContains(response.bodyAsText(), "started")
        }

    /**
     * A named gate is a real latch: `503` until it completes, and never `503` again afterwards.
     *
     * The `503` body names what is outstanding, because a probe that only says "not yet" sends the
     * reader to the logs of a process that has not started writing any.
     */
    @Test
    fun `a named startup gate holds the probe at 503 until it completes`() =
        testApplication {
            val startup = StartupGate(gates = setOf("migrations"))
            keel(startup = startup, store = InMemoryItemStore())

            val waiting = client.get("/health/startup")
            assertEquals(HttpStatusCode.ServiceUnavailable, waiting.status)
            assertContains(waiting.bodyAsText(), "migrations", message = "the 503 must name what is outstanding")

            startup.completed("migrations")

            assertEquals(HttpStatusCode.OK, client.get("/health/startup").status)
        }

    /**
     * `/health` is liveness, and this test exists because a chart will point readiness at it.
     *
     * The alias answers `200` while the process is merely alive — which is exactly the probe that
     * cannot fail, and exactly what three separate probes exist to replace. If this test ever goes
     * red because `/health` started tracking readiness, that is not a regression in kore: it is a
     * deployment somewhere reading `/health` as readiness that has just started working by accident.
     */
    @Test
    fun `health is an alias for liveness and not for readiness`() =
        testApplication {
            keel()

            val health = client.get("/health")
            val live = client.get("/health/live")

            assertEquals(HttpStatusCode.OK, health.status)
            assertEquals(live.status, health.status, "/health must answer whatever /health/live answers")
            assertEquals(live.bodyAsText(), health.bodyAsText())
        }

    /**
     * The refusal opens at the drain, not at the announce — the wiring is what decides it.
     *
     * keel gated it on readiness until kore B-61, so every request inside the five-second announce was
     * a `503`, and the oracle's A5 failed on every run. Reverting to that predicate fails the first
     * assertion; handing `EngineDrain` a different `DrainGate` from the one the refusal reads fails
     * nothing here and never refuses at all, which is the second half's reason to exist.
     */
    @Test
    fun `the announce still serves and the drain refuses`() =
        testApplication {
            val readiness = ReadinessGate()
            val draining = DrainGate()
            keel(readiness = readiness, draining = draining)

            readiness.beginShutdown()
            assertEquals(HttpStatusCode.OK, client.get("/items").status, "a request inside the announce is served")

            draining.beginDrain()
            val refused = client.get("/items")
            assertEquals(HttpStatusCode.ServiceUnavailable, refused.status, "refused once the drain opens")
            assertEquals("close", refused.headers["Connection"])
            assertEquals(HttpStatusCode.OK, client.get("/health/live").status, "liveness is never refused")
        }

    /** The build identity the Gradle plugin compiled in is served, rather than read at runtime. */
    @Test
    fun `version names the build`() =
        testApplication {
            keel()

            val response = client.get("/version")

            assertEquals(HttpStatusCode.OK, response.status)
            assertContains(response.bodyAsText(), "version", message = "the body is key: value lines a shell can grep")
        }

    /** The whole module, as `startKeel` assembles it, with every gate a test does not name left fresh. */
    private fun ApplicationTestBuilder.keel(
        startup: StartupGate = StartupGate(),
        readiness: ReadinessGate = ReadinessGate(),
        draining: DrainGate = DrainGate(),
        store: ItemStore = InMemoryItemStore(SEED),
    ) = application { keelModule(startup, readiness, LivenessGate(), draining, store) }

    private companion object {
        /**
         * The fixture the route used to carry as a constant.
         *
         * It moved here when a store went behind the route: a seed compiled into the service is
         * a thing a clone deletes and forgets, and a seed in the test is one the test owns.
         */
        val SEED = listOf(Item(id = "keel", name = "the first member laid down"))
    }
}
