# App manuals become reader-oriented and focused tests gain one wrapper

```labkit-change
id: LK-20260720-reader-oriented-app-manuals-and-test-wrapper
date: 2026-07-20
sequence: 142
type: docs
compatibility: compatible
scope: App documentation
scope: Documentation validation
scope: Agent testing workflow
scope: Agent skill maintenance
```

## Context

Concrete App manuals repeated shared hover-help and runtime architecture
contracts. The repetition displaced workflow and scientific content, became
stale when the framework changed, and made every App page appear more
implementation-oriented than user-oriented. Focused test execution also
required agents to repeatedly assemble low-level runner arguments; omitting
GUI inclusion could produce a zero-match selection that looked like a test
problem.

## Decision and rationale

Keep shared behavior in the App catalog and framework manual. Concrete App
pages describe only their inputs, workflow, App-specific interactions,
scientific semantics, outputs, recovery, programmatic surface, and
limitations. Protect that boundary with a documentation guardrail.

Provide one platform-independent MATLAB wrapper with explicit operations for
listing a file's canonical test names, running an exact file, running a
canonical class or method within its owning file, and running a suite. Keep
broad final gates on the existing `buildtool` interface.

Treat recurring reasoning, command construction, discovery, and retry cost as
skill-maintenance signals. Improvements must describe durable concepts and
semantic operations rather than one product version, App, transient failure,
or current repository snapshot.

## Changes

- Removed repeated hover-help and Framework Compatibility boilerplate from all
  tracked App manuals.
- Rewrote project-state passages around user-visible persistence, recovery,
  source relinking, and recalculation rather than internal factories,
  callbacks, and schema implementation.
- Clarified the App-manual authoring contract and added a guardrail against
  reintroducing shared framework boilerplate.
- Added `runLabKitTestTarget.m` to the test-planner skill with automatic
  repository discovery, GUI inference for exact files and GUI suites, hidden
  figures, focused artifacts, and fail-on-zero-match behavior.
- Made exact canonical selectors resolve their unique owning test file, while
  retaining an explicit file constraint for ambiguous ownership.
- Made local parallel build tasks retain structured shard state while relaying
  concise human-readable heartbeats, clear stale transient status at worker
  startup, and print only failing worker logs instead of remaining silent and
  then dumping every shard log.
- Moved child-process orchestration out of `buildfile.m` into a MATLAB/Java
  runner shared by local macOS, Linux, and Windows, removing generated POSIX
  scripts and adding an independent ETA to each shard summary. Hosted CI
  remains single-process pending explicit concurrent-license evidence.
- Partitioned broad local workers by unique test-class owner file so each
  worker discovers only its assigned files instead of repeating full-tree
  discovery.
- Batched App path registration while keeping every setup call sensitive to
  newly added App entrypoints, added quiet discovery probes, and removed one
  unreferenced GUI assertion helper.
- Updated the skill to list canonical names before exact method reruns and to
  distinguish selection failures from passing evidence.
- Added a root agent rule to improve skills and scripts when reusable
  automation can remove recurring inference or retry cost.

## User and data impact

App behavior, calculations, saved data, and exports are unchanged. Existing
manual content about scientific meaning and recovery remains available with
less implementation noise. The wrapper is an agent convenience over the
official test runner and does not add another CI or public build interface.


## Compatibility and migration

No additional migration applies beyond the compatibility information in the preceding impact section.

## Validation

- Documentation guardrails scan every concrete App manual for shared
  boilerplate.
- Documentation rendering and byte-for-byte site comparison cover all edited
  pages and this record.
- The wrapper lists and runs canonical GUI methods through the official
  runner, demonstrating automatic hidden-GUI selection.
- Test-runner profiling measured fresh full discovery before and after the path
  change at 5.83 and 4.82 seconds; path setup fell from 1.27 to 0.32 seconds.
  The retained rescan avoids a stale-cache failure when an App is added during
  a MATLAB session.
- Build contracts prove file partitions are disjoint, cover every selected
  test, accept deeply nested owning files, and preserve explicit failures for
  missing or ambiguous owners.

## Evidence

The validation details above are the supporting evidence for this record.

## Known limitations and follow-up

Continue reviewing App manuals when user-visible behavior changes; structural
guardrails prevent known boilerplate but cannot judge scientific clarity.
