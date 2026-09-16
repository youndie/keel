// The scenario both binaries are driven with — for the parity smoke (B-05) and, at a fixed rate, for
// the stand measurement (B-13).
//
// It is one file for both on purpose: a parity run and a measurement that drove different traffic
// would be answering questions about different services.

import http from 'k6/http';
import { check } from 'k6';
import { normalise } from './normalise.js';

const BASE = __ENV.KEEL_BASE || 'http://127.0.0.1:8080';
const TARGET = __ENV.KEEL_TARGET || 'unknown';

export const options = {
  scenarios: {
    items: {
      executor: __ENV.KEEL_RATE ? 'constant-arrival-rate' : 'shared-iterations',
      ...(__ENV.KEEL_RATE
        ? {
            rate: Number(__ENV.KEEL_RATE),
            timeUnit: '1s',
            duration: __ENV.KEEL_DURATION || '30s',
            preAllocatedVUs: 20,
          }
        : __ENV.KEEL_RECORD === '1'
          ? { vus: 1, iterations: 1 }
          : { vus: 4, iterations: 40 }),
    },
  },
  thresholds: { checks: ['rate==1.0'] },
};

// THE RECORDED RESPONSES ARE PRINTED, NOT COLLECTED, AND THAT IS NOT A STYLE CHOICE.
//
// The obvious shape — a module-level array pushed to from the default function and written out in
// `handleSummary` — compiles, runs, and produces an EMPTY array. k6 runs `handleSummary` in its own
// context; each VU gets its own module instance and none of them is the one the summary sees.
//
// It fails silently and in the worst possible direction: the parity comparison then diffs two empty
// files and reports no difference. That happened here, and it is why the run below asserts a
// non-zero record count before believing a clean diff.
//
// So a recording run prints one `PARITY <json>` line per call and the caller collects them.
const RECORD = __ENV.KEEL_RECORD === '1';

function record(call, response) {
  if (RECORD) console.log(`PARITY ${JSON.stringify({ call, ...normalise(response) })}`);
}

export default function () {
  // A deterministic id per iteration: the two runs have to produce the same rows, and a random id
  // would make every comparison fail for a reason that is not parity.
  //
  // The RECORDING run needs its own namespace, and finding that out cost a run. Sharing one with the
  // load pass meant the recorded `POST` hit a row the load pass had already inserted, so what got
  // compared was the primary-key violation rather than the success path — and the two drivers word
  // that differently on purpose (see below), so the comparison failed on a difference that is not a
  // defect.
  const id = RECORD ? `record-${__VU}-${__ITER}` : `parity-${__VU}-${__ITER}`;

  const created = http.post(`${BASE}/items`, JSON.stringify({ id, name: `item ${id}` }), {
    headers: { 'Content-Type': 'application/json' },
  });
  check(created, { 'POST /items is 201': (r) => r.status === 201 });

  const listed = http.get(`${BASE}/items`);
  check(listed, { 'GET /items is 200': (r) => r.status === 200 });

  const version = http.get(`${BASE}/version`);
  check(version, { 'GET /version is 200': (r) => r.status === 200 });

  const ready = http.get(`${BASE}/health/ready`);
  check(ready, { 'ready is 200': (r) => r.status === 200 });

  // `GET /items` is deliberately not recorded: it grows as the run proceeds, so its body depends on
  // how the VUs interleaved rather than on the platform, and a comparison of it would fail for a
  // reason that is not parity. A recording run is one VU and one iteration, so the three below are
  // the same three calls on both targets.
  record('POST /items', created);
  record('GET /version', version);
  record('GET /health/ready', ready);
}

// INTO `build/`, AND NOT INTO A DIRECTORY BESIDE THIS FILE.
//
// `build/` is gitignored, which is the obvious half. The half that cost a run: this repository is
// developed against a one-way mutagen replica, and the watcher deletes anything on the Linux box that
// does not exist on the Mac — so a summary written to `k6/out/` appears and is removed between the
// run and the next command, which looks exactly like k6 failing to write it. `build/` is on the
// session's ignore list, so what is written there survives.
export function handleSummary(data) {
  return {
    [`build/k6/${TARGET}-checks.json`]: JSON.stringify(data.metrics.checks, null, 2),
    stdout: `${TARGET}: ${data.metrics.checks.values.passes} checks passed, ${data.metrics.checks.values.fails} failed\n`,
  };
}
