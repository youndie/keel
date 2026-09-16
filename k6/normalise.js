// WHAT THE TWO TARGETS ARE ALLOWED TO DISAGREE ABOUT.
//
// Committed BEFORE the first parity run, and that ordering is the whole item. A normaliser written
// after a red run is a list of whatever happened to differ, and it absorbs the next real divergence
// without anybody noticing. Written first, it is a statement about what the two platforms may
// legitimately differ on — and anything it does not name is a diff that fails.
//
// Adding an entry here is a decision, not a fix. Each one below carries why it is legitimate; an
// entry that cannot be given such a line is a bug being normalised away.

/** Headers dropped from the comparison entirely. */
export const IGNORED_HEADERS = [
  // The engine's own banner. Both targets run Ktor CIO, but the header carries a version string that
  // a bump changes on one side of a comparison before the other.
  'server',
  // Wall-clock. Two processes started seconds apart cannot agree, and nothing about the service
  // depends on it.
  'date',
  // A body-length header is not dropped — see below. This list is only for values that cannot match.
];

/**
 * `/version` is a contract, so it is compared — except the two fields that are facts about the build
 * rather than about the service.
 *
 * `built_at` differs because the two binaries are linked at different moments. `commit` is the same
 * in CI and differs locally, where only one half may have been rebuilt; keeping it would make the
 * parity run fail for a reason that is not parity.
 */
export const VERSION_VOLATILE_FIELDS = ['built_at', 'commit', 'release'];

/**
 * The exit code is NOT normalised here, because nothing in an HTTP response carries it — it is named
 * so the next reader does not go looking.
 *
 * A clean `SIGTERM` exits `0` on Kotlin/Native and `143` on the JVM. **Both are correct**, and a
 * parity check that compared them would fail against two correct shutdowns. Whatever asserts the
 * shutdown asserts "the process ended itself and was not SIGKILLed (137)", never a specific code.
 */
export const EXIT_CODES_DIFFER_LEGITIMATELY = { native: 0, jvm: 143 };

/** A response reduced to what the two targets must agree on, byte for byte. */
export function normalise(response) {
  const headers = {};
  for (const [name, value] of Object.entries(response.headers)) {
    const key = name.toLowerCase();
    if (IGNORED_HEADERS.includes(key)) continue;
    headers[key] = value;
  }
  return { status: response.status, headers, body: normaliseBody(response) };
}

function normaliseBody(response) {
  const body = response.body === null ? '' : String(response.body);
  // `/version` is `key: value` per line. Drop the volatile lines and keep the rest, so a renamed or
  // missing field still fails the comparison.
  if (body.includes('version:') && body.includes('\n')) {
    return body
      .split('\n')
      .filter((line) => !VERSION_VOLATILE_FIELDS.some((field) => line.startsWith(field + ':')))
      .join('\n');
  }
  return body;
}
