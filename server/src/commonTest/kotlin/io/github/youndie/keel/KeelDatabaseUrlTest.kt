package io.github.youndie.keel

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The URL the service opens its database with.
 *
 * **This test exists because the line it covers was wrong and everything still looked fine.** The URL
 * was built from a broken string template, so the service opened a database named after the
 * expression rather than the path in it: every request answered correctly, `GET` returned what `POST`
 * had written, and the data was gone after a restart with no file ever created on disk.
 *
 * Nothing in the store suite could see it. That suite builds its own URL, so it tests the store
 * against a database it opened correctly — writing and reading the same wrong way is exactly the
 * shape of test that passes on a diverged format. Only starting the binary twice found this, and the
 * two assertions below are what stand in for doing that on every build.
 */
class KeelDatabaseUrlTest {
    @Test
    fun `the url carries the path it was given`() {
        val url = keelDatabaseUrl("/var/lib/keel/keel.db")

        assertEquals("sqlite:///var/lib/keel/keel.db?mode=rwc", url)
        assertTrue("/var/lib/keel/keel.db" in url, "the path did not reach the url")
    }

    /**
     * `mode=rwc` is not decoration: without it the Rust driver does not create a missing file, while
     * Xerial's JDBC does — so a service that omits it works on the JVM and starts empty on the target
     * that ships.
     */
    @Test
    fun `the url asks for the file to be created`() {
        assertTrue(keelDatabaseUrl("/tmp/x.db").endsWith("?mode=rwc"))
    }

    /** A template that did not interpolate is the specific failure, so it is the specific assertion. */
    @Test
    fun `the url never contains an uninterpolated expression`() {
        val url = keelDatabaseUrl("/tmp/x.db")

        assertTrue("\$" !in url, "the url still carries a template expression: $url")
        assertTrue("settings" !in url, "the url names the variable instead of its value: $url")
    }
}
