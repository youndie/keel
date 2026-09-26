---
id: B-01
title: "Say what this service is, and replace the example it was started with"
status: open
priority: P0
size: M
stage: s0-named
---

# B-01 — Say what this service is

The repository was renamed from a template and carries the template's example: an item store over
SQLite, `GET`/`POST /items`, and the tests for both. The documentation carries nothing yet. The two
sentences in `CLAUDE.md` and `README.md` that say so are placeholders, and this item is what replaces
them.

- **The decision and its reason.** Write down what the service is before building it, because every
  document after this one cites it. A research document that separates what was read from what is
  assumed costs an afternoon; a backlog derived from nothing costs the first wrong week.
- **The example domain goes in this item, not later.** `Item`, its routes and its store are an
  example, and an example left in place becomes the first feature by accident. Replace it, or remove
  the database entirely: the template lists
  [every place it lives](https://github.com/youndie/keel/blob/main/docs/services/keel-server.md#9-a-service-without-a-database),
  including the four module tests that must move rather than be deleted.
- Not in this item: the service's features beyond the first. They are items of their own, entered
  here once the research names them.

- AC: `docs/research/research-architecture.md` exists, from `docs/templates/`, and says what the
  service is, what was verified and what was assumed.
- AC: the first paragraphs of `CLAUDE.md` and `README.md` describe this service and no longer say
  that nothing has been written.
- AC: the example domain is replaced or removed, and `./gradlew build` is green on both targets.
- AC: the backlog has the next items, entered from the research.
- Anchors: `CLAUDE.md`, `README.md`, `docs/research/`, `server/src/commonMain/`.
