package io.github.youndie.keel.item

import io.ktor.server.application.Application
import io.ktor.server.response.respond
import io.ktor.server.routing.get
import io.ktor.server.routing.routing

/**
 * `GET /items` — a constant, until B-02 puts a store behind it.
 *
 * Constant and not empty, deliberately: the value of this route today is that it **renders**, and a
 * response with no body crosses no charset. Every rendered byte on Kotlin/Native goes through glibc
 * `iconv`, which is `dlopen`ed, and an image that cannot do that answers a status code perfectly well
 * — which is how a `401` from a static image was once read as a pass.
 *
 * `POST /items` arrives with the store in B-02. One route returning a constant is what B-01 needs: it
 * proves Ktor CIO links and serves on both targets, which is the toolchain risk this item exists to
 * retire.
 */
fun Application.itemRoutes() {
    routing {
        get("/items") { call.respond(SEED) }
    }
}

private val SEED = listOf(Item(id = "keel", name = "the first member laid down"))
