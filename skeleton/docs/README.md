# docs — {{name}}

The documentation of this service, layered in the [docs-bootstrap](https://github.com/youndie/docs-bootstrap)
format; links run top to bottom. **Nothing has been written into the layers yet**:
[B-01](backlog/B-01-say-what-this-service-is.md) starts with the research. A new document starts from
[templates/](templates/).

| Layer | Directory | Answers |
|---|---|---|
| Research | `research/` | *why* it is built this way; what was verified and against what |
| Feature | `features/` | *what* the service does, and the scenarios that are its acceptance |
| API | `api/` | every route, its status codes, and what is deliberately not promised |
| Service | `services/` | the modules, how they are built, the quirks inherited from the platform |

**Backlog** — [backlog.md](../backlog.md): the goal, the stages and the index; the items themselves
are one file each in [`backlog/`](backlog/).

## Coverage map

The list below is **checked** against the files on disk: a document missing here, or an entry with no
file behind it, fails `coverage_map.py`. It is empty because the layers are.
