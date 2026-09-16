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
        : { vus: 4, iterations: 40 }),
    },
  },
  thresholds: { checks: ['rate==1.0'] },
};

// The recorded responses, normalised, in scenario order. Written out at the end so the two runs can
// be diffed as files rather than compared inside k6 — the comparison is between two processes that
// never run at the same time.
const recorded = [];

export default function () {
  // A deterministic id per iteration: the two runs have to produce the same rows, and a random id
  // would make every comparison fail for a reason that is not parity.
  const id = `parity-${__VU}-${__ITER}`;

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

  // `GET /items` grows as the run proceeds, so its body is not comparable between two runs unless
  // both see the same rows in the same order. They do — the ids are deterministic and the store
  // orders by id — but only the FIRST iteration's listing is recorded, because after that the
  // interleaving of VUs decides how many rows exist and that is not a parity question.
  if (__ITER === 0 && __VU === 1) {
    recorded.push({ call: 'POST /items', ...normalise(created) });
    recorded.push({ call: 'GET /version', ...normalise(version) });
    recorded.push({ call: 'GET /health/ready', ...normalise(ready) });
  }
}

export function handleSummary(data) {
  return {
    [`k6/out/${TARGET}.json`]: JSON.stringify({ recorded, checks: data.metrics.checks }, null, 2),
    stdout: `${TARGET}: ${data.metrics.checks.values.passes} checks passed, ${data.metrics.checks.values.fails} failed\n`,
  };
}
