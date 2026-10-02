# The gates. Taken from docs-bootstrap's templates/Makefile, next to .github/workflows/check.yaml
# taken from templates/workflow-check.yaml; CI runs exactly these targets.
#
#   make check    the documentation gate and the reports - exactly what CI's check job runs
#   make build    the code gate - exactly what CI's build job runs
#   make fix      regenerate the backlog index, append missing coverage-map lines
#
# `check` reads the documents - python, seconds, no JDK. `build` compiles and tests - a toolchain and
# minutes. Separate, because a contributor editing a document should not need the second, and one
# target that needed both would be one nobody ran.
#
# ONE VERSION OF THE CHECKS, WRITTEN DOWN ONCE: the `uses: youndie/docs-bootstrap@<ref>` line in
# .github/workflows/check.yaml. CI runs the checks at that ref because the runner resolves the line.
# This file reads the same line and fetches the same ref into .docs-bootstrap/, a directory that
# ignores itself, so `make check` here runs what CI runs - the same scripts, the same guard, the same
# flags. Renovate bumps the line, and the next `make check` fetches what CI already moved to.
#
# WHY THE SCRIPTS ARE NOT COPIED IN. A copied check runs, but at the version of the day it was copied,
# and a fix upstream never arrives: across one portfolio 18 copies of backlog_index.py were found in
# three versions, eleven of them without the guard that makes `--check` fail when the backlog has
# gone missing - a guard that existed upstream the whole time. A clone of this template used to
# inherit such a copy; it now inherits the pin, and Renovate moves it.
#
# WHY THE VERSION IS NOT ALSO WRITTEN HERE. A version pinned in the workflow and again in this file is
# two pins, and two pins drift: one is bumped, the other is found months later, and "green here, red
# there" comes back with nobody able to say which side is right. So this file holds none; if the
# workflow names two different refs, it refuses to choose.
#
# WHAT LIVES HERE is what is this repository's own: where the tree is, how the backlog is kept, the
# code gate, and the reports being non-blocking. How the documents are checked - including the guard
# that fails the gate when docs/ or the backlog is not there, which this file used to hand-write - is
# in check.mk at the pinned version, and changes arrive with a bump instead of with a re-copy.
#
# OVERRIDES. `DOCS_BOOTSTRAP=<dir>` runs the checks from a directory instead of the pinned ref: a
# clone of docs-bootstrap you are changing, or - offline, or without GitHub Actions - a committed
# copy of its check.mk, scripts/ and .claude-plugin/. That last one is the copy route again, with its
# drift; it is the fallback, not the default.

DOCS ?= docs
BACKLOG ?= backlog.md
# How the backlog is kept (docs-bootstrap SKILL.md, step 7): one file per item in $(DOCS)/backlog/
# and the generated index in $(BACKLOG). A clone starts with one seed item, so the guard holds there
# too: the day that item is deleted rather than closed, the gate goes red.
BACKLOG_FORM ?= files
# WHERE THE SIBLING REPOSITORIES ARE, for the two reports that resolve code anchors.
#
# `..` is right for this portfolio, where the checkouts sit side by side, and for CI, where the parent
# holds one directory. It is WRONG for a clone anywhere else, and a template gets cloned anywhere
# else: cloned to `/work`, `..` is `/`, and the report walks the entire filesystem - 25 seconds and
# then OOM-killed on an 8 GB machine. Found by B-08, doing exactly that.
#
# A clone that does not sit beside kore and sborka sets `REPOS=.` and gets a report about its own
# paths, with the anchors that name other repositories listed as not found - which is the truth for a
# machine that does not have them.
REPOS ?= ..
PY ?= python3
GRADLE ?= ./gradlew
# CI passes `--no-daemon`; a laptop wants the daemon. The flags are the only difference between the
# two, which is the point.
GRADLEFLAGS ?=

# Where the pin is, and what it names.
DOCS_BOOTSTRAP_PIN ?= .github/workflows/check.yaml
DOCS_BOOTSTRAP_REPO ?= youndie/docs-bootstrap
DOCS_BOOTSTRAP_CACHE ?= .docs-bootstrap
# The revision of templates/Makefile this file follows. check.mk says so when a newer docs-bootstrap
# expects a newer one.
DOCS_BOOTSTRAP_SHIM := 1

.DEFAULT_GOAL := help
.PHONY: help check gate report fix build

help:
	@echo "make check   - the documentation gate and the reports: exactly what CI's check job runs"
	@echo "make gate    - the blocking half alone"
	@echo "make report  - non-blocking: BDD coverage, code anchors"
	@echo "make build   - the code gate: blocking, exactly what CI's build job runs"
	@echo "make fix     - regenerate the backlog index, fill in missing coverage-map lines"

check: gate report

# Blocking: the backlog index, the cross-references and the coverage map, after the guard that refuses
# an absent docs/ or an empty backlog. `status: draft` as an error is not here - it is
# branch-specific, and CI runs it on pushes to the default branch (`make docs-on-main`, B-10).
gate: docs-gate

# Non-blocking, on purpose - AND THE `-` IS WHAT MAKES THAT TRUE.
#
# `bdd_report` counts scenarios; a percentage is meaningless while most scenarios are target
# behaviour. `code_anchors` cannot tell a path quoted AS OBSOLETE from a live one, and what rots lives
# in other people's repositories. Neither is a gate.
#
# They are nevertheless *run* by `check`, so a report that fails would fail the gate - and B-08 found
# it the way such things are found: a fresh clone at `/work` made `code_anchors` scan `/`, the kernel
# killed it, and `make check` went red on a repository whose documentation was entirely consistent.
# check.mk runs the two without a `-`, so the target is run as a sub-make and the `-` is put on that:
# the reports still print, and what they print is still read by a person.
report:
	-@$(MAKE) --no-print-directory docs-report

fix: docs-fix

# The code gate, and CI's `build` job runs exactly this. One `build` for every target the project
# declares - which today is `jvm` and `linuxX64`; `linuxArm64` is behind `keel.linuxArm64`, and CI
# cross-links its test binary and runs it on an arm64 runner (B-15).
#
# What a green run here does NOT cover is in CLAUDE.md rather than assumed: a Mac cannot link an ELF,
# so the native half of this only really runs on Linux.
build:
	$(GRADLE) build $(GRADLEFLAGS)

# -- where the checks come from. Nothing below is meant to be edited. ------------------------------

ifndef DOCS_BOOTSTRAP
DOCS_BOOTSTRAP_REF := $(sort $(shell sed -n -E 's|^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*"?$(DOCS_BOOTSTRAP_REPO)@([^"[:space:]]+).*|\2|p' $(DOCS_BOOTSTRAP_PIN) 2>/dev/null))
ifeq ($(words $(DOCS_BOOTSTRAP_REF)),0)
$(error no `uses: $(DOCS_BOOTSTRAP_REPO)@<ref>` in $(DOCS_BOOTSTRAP_PIN). That line is the version of the checks, for CI and for this file alike - copy templates/workflow-check.yaml, or run with DOCS_BOOTSTRAP=<a local copy>)
endif
ifneq ($(words $(DOCS_BOOTSTRAP_REF)),1)
$(error $(DOCS_BOOTSTRAP_PIN) pins $(DOCS_BOOTSTRAP_REPO) at more than one ref: $(DOCS_BOOTSTRAP_REF). One version of the checks, one ref - make every uses: line name the same one)
endif
DOCS_BOOTSTRAP := $(DOCS_BOOTSTRAP_CACHE)/$(DOCS_BOOTSTRAP_REF)
else ifeq ($(wildcard $(DOCS_BOOTSTRAP)/check.mk),)
$(error DOCS_BOOTSTRAP=$(DOCS_BOOTSTRAP) holds no check.mk)
endif

include $(DOCS_BOOTSTRAP)/check.mk

# The fetch. A tarball of the ref rather than a clone: a tag, a branch and a commit SHA (what
# Renovate writes when it pins digests) are all one URL, and no history is needed. Unpacked next to
# its final place and moved in only once complete, so an interrupted fetch never leaves a directory
# that looks like a version. GNU make 3.81 - the one macOS ships - announces the missing file
# ("check.mk: No such file or directory") just before fetching it; that line is not the error.
$(DOCS_BOOTSTRAP_CACHE)/%/check.mk:
	@echo "docs-bootstrap: fetching $(DOCS_BOOTSTRAP_REPO)@$* - the ref $(DOCS_BOOTSTRAP_PIN) pins"
	@rm -rf "$(@D).part" && mkdir -p "$(@D).part"
	@curl -fsSL --retry 2 -o "$(@D).part/src.tar.gz" "https://codeload.github.com/$(DOCS_BOOTSTRAP_REPO)/tar.gz/$*" || { rm -rf "$(@D).part"; echo "could not fetch $(DOCS_BOOTSTRAP_REPO)@$* - offline, or a ref that does not exist? DOCS_BOOTSTRAP=<dir> runs a local copy instead" >&2; exit 1; }
	@tar -xzf "$(@D).part/src.tar.gz" -C "$(@D).part" --strip-components=1 && rm -f "$(@D).part/src.tar.gz"
	@test -f "$(@D).part/check.mk" || { echo "$(DOCS_BOOTSTRAP_REPO)@$* has no check.mk - versions before 0.3.0 cannot be pinned this way" >&2; rm -rf "$(@D).part"; exit 1; }
	@rm -rf "$(@D)" && mv "$(@D).part" "$(@D)"
	@echo '*' > "$(DOCS_BOOTSTRAP_CACHE)/.gitignore"
