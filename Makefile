# One gate, and CI runs exactly these targets.
#
# A local check set that differs from the CI one turns "green here, red there" into the normal state
# of affairs, and then neither is read. So: whatever is not behind one of these targets is not a
# gate, and whatever is runs the same way in both places.
#
# `check` reads the documents — python, seconds, no JDK. `build` compiles and tests — a toolchain and
# minutes. Separate, because a contributor editing a document should not need the second, and one
# target that needed both would be one nobody ran.
#
# `build` does nothing yet: there is no Gradle build in this repository until B-01 closes. It is here
# already so that CI's job and a contributor's command are one string in one place from the first
# commit rather than from the commit that adds the build.
#
# Every script defaults to `docs` in the working directory, so the variables below exist to be
# overridden rather than because anything needs them.

DOCS ?= docs
BACKLOG ?= backlog.md
REPOS ?= ..
PY ?= python3
GRADLE ?= ./gradlew
# CI passes `--no-daemon`; a laptop wants the daemon. The flags are the only difference between the
# two, which is the point.
GRADLEFLAGS ?=

.PHONY: check gate report fix build help

help:
	@echo "make check   - the documentation gate: blocking, exactly what CI's check job runs"
	@echo "make build   - the code gate: blocking, exactly what CI's build job runs (nothing yet, B-01)"
	@echo "make report  - non-blocking reports: BDD coverage, code anchors"
	@echo "make fix     - regenerate the backlog index, fill in missing coverage-map lines"

check: gate report

# Blocking. Any of these failing means the documentation is internally inconsistent, which is a
# defect in the documentation rather than a matter of opinion.
#
# NOT here: `docs_check.py --on-main`, which makes `status: draft` an error on the default branch. It
# is off with an address — B-10 — rather than relaxed, and it is branch-specific in any case: a draft
# is legal in a pull request, where it means "this branch will make it true".
gate:
	$(PY) scripts/backlog_index.py --check --docs $(DOCS) --backlog $(BACKLOG)
	$(PY) scripts/docs_check.py --docs $(DOCS) --backlog $(BACKLOG)
	$(PY) scripts/coverage_map.py --check --docs $(DOCS)

# Non-blocking, on purpose.
#
# `bdd_report` counts scenarios; a percentage is meaningless while every scenario is target
# behaviour. `code_anchors` reports most of this tree rotten today, and correctly — the paths are
# where the code will live. The count going down is how the template arriving looks from here. It is
# not a gate even when it reaches zero: a path quoted AS OBSOLETE is indistinguishable by machine
# from a live one, and what rots lives in other people's repositories.
report:
	$(PY) scripts/bdd_report.py --docs $(DOCS) --repos $(REPOS)
	$(PY) scripts/code_anchors.py --docs $(DOCS) --repos $(REPOS)

# The code gate. One `build` for every target the project declares. Until B-01 there is no wrapper,
# so this says so rather than failing with "no such file".
build:
	@test -x $(GRADLE) || { echo "no Gradle build yet - see B-01 in backlog.md"; exit 0; }
	$(GRADLE) build $(GRADLEFLAGS)

fix:
	$(PY) scripts/backlog_index.py --docs $(DOCS) --backlog $(BACKLOG)
	$(PY) scripts/coverage_map.py --fix --docs $(DOCS)
