package io.github.youndie.keel

import io.github.youndie.kore.config.ConfigKey
import io.github.youndie.kore.config.ConfigPair
import io.github.youndie.kore.config.ConfigSchema

/**
 * What this service is configured as, under the prefix `KEEL`.
 *
 * Four keys, and each one is a different **shape** rather than a different setting — a clone deletes
 * the ones it does not need and has an example of every kind left:
 *
 * - [DB_PATH] is **required**. A service that invents where its data lives starts happily and serves
 *   wrong data, which is worse than not starting. Refusing at startup is the whole feature.
 * - [PORT] and [WORK_MS] have **defaults**, so a deployment does not repeat a value it has no
 *   opinion about — and `--print-config` still prints `DEFAULT` beside them, so nobody has to guess
 *   which happened.
 * - [TRACY_KEY] is a **secret**, masked wherever the configuration is rendered. A property of the
 *   declaration rather than a list of names somebody keeps in sync with the schema: a list is a
 *   second schema, and the day it disagrees with the first is the day a secret is printed.
 * - [TRACY_ENDPOINT] and [TRACY_KEY] are a **pair** — both or neither. One without the other is a
 *   deployment that believes it is observed and is not.
 *
 * The schema also refuses a variable under this prefix that it does not declare, naming the declared
 * one it is probably a misspelling of. On macOS native that check reports that it *could not run*
 * rather than "nothing found": the environment cannot be enumerated there, and a deployment reads
 * "nothing found" as evidence.
 */
object KeelConfig {
    val PORT: ConfigKey<Int> = ConfigKey.int("PORT", default = 8080)

    /** The one key with no sensible default. */
    val DB_PATH: ConfigKey<String> = ConfigKey.required("DB_PATH")

    /** Half of the observability pair. Unset means "not observed", which is a decision. */
    val TRACY_ENDPOINT: ConfigKey<String?> = ConfigKey.optional("TRACY_ENDPOINT")

    /** The other half, and a secret. */
    val TRACY_KEY: ConfigKey<String?> = ConfigKey.optional("TRACY_KEY", secret = true)

    val SCHEMA: ConfigSchema =
        ConfigSchema(
            prefix = "KEEL",
            keys = listOf(PORT, DB_PATH, TRACY_ENDPOINT, TRACY_KEY),
            pairs = listOf(ConfigPair(TRACY_ENDPOINT.name, TRACY_KEY.name)),
        )
}

/**
 * The resolved configuration in the shape the rest of the service uses.
 *
 * A small class rather than passing `Configuration` around, so a value nothing reads shows up as an
 * unused property here instead of hiding behind an indexing call that may never be made.
 */
class KeelSettings(
    val port: Int,
    val dbPath: String,
    val observed: Boolean,
) {
    /** One line for `docker logs`, naming what was configured and masking what must not be printed. */
    fun describe(): String = "configured: port=$port db=$dbPath observability=${if (observed) "on" else "off"}"
}
