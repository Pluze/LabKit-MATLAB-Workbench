---
name: labkit-test-planner
description: "Use for LabKit validation planning, running tests, pre-commit checks, MATLAB source/test/fixture changes, or deciding which build task to run. Trigger on validate, test plan, before commit, CI, GUI check, parser regression, fixture, or sample hygiene work."
---

# LabKit Test Planner

## Goal

Choose visible, source-aligned validation without overstating coverage.

## Required Read Order

Start with a quick pass:

1. `AGENTS.md`
2. nearest scoped `AGENTS.md`
3. touched source, tests, and fixture files

Read `docs/testing.md` only when exact build-task names, CI scope, fixture
policy, GUI/non-GUI pairing, or validation-routing changes are needed. When
another skill already read shared AGENTS context, do not reread it.

## Task Routing

Use the smallest source-aligned validation set that covers the touched
boundary. `docs/testing.md` owns the stable build-task names, CI scope, and
command examples. Keep the public build-task set small: improve changed-file
planner routing, representative selectors, printed plan reasons, or focused
runner selectors before adding a new public task.

Use the fast changed-file build task for tight local iteration when git state
is available, and the conservative changed-file build task before handoff.
These tasks inspect the current diff and print why each selected scope is
being run. Use
`runLabKitTests("Suites", ...)` for component, app-family, or focused GUI
diagnosis after a scope is known. For local GUI edits that only touch one app,
prefer the app-level GUI folder, for example a `Suites` value such as
`gui/apps/image_measurement/batch_crop` with `IncludeGui=true` and
`GuiMode="hidden"`.

For broad validation, prefer public buildfile tasks and let the buildfile own
whether a large selected test set should run serially or through internal
worker shards. Use runner-level shard arguments only when developing or
debugging the runner itself; every shard must have a distinct `RunName` and the
combined shards must cover the same selected suite. On GitHub Actions, keep the
public CI entry as `buildtool headless` and let the buildfile choose serial
execution unless independent child MATLAB licensing has been proven.

For a dirty worktree, route through the changed-file validation planner before
manually choosing tests. The focused planner maps the current diff to the
affected plan; do not skip that planning step and hand-pick broad or low-level
suites just because the likely answer seems obvious. If release validation or
an explicit user request requires broader gates, run them after the focused
plan or state why a completed broader gate fully covers the affected plan
instead of rerunning narrower tests for ceremony.

After a planned run fails, do not rerun the planner just to discover the same
scope again. Fix the root cause and rerun the narrowest failed suite or test
directly, for example `runLabKitTests("Suites", "project")` after a project
guardrail failure. Escalate back to the changed-file, headless, or GUI build
task only when the fix touches additional areas, changes validation routing,
or the user explicitly asks for a broader/release gate.

```text
project                    startup, architecture, package surface, sample-data hygiene
labkit_framework/dta       DTA parser, facade, session, item, pulse behavior
labkit_framework/image     image file IO, RGB normalization, resizing, mean filtering, basic enhancement primitives
labkit_framework/biosignal biosignal import, processing, ECG peaks, segments, measurements
labkit_framework/ui        reusable UI helpers; include GUI coverage for layout/callback/shell/debug/tool checks
apps/electrochem           electrochem app-owned calculations, exports, layout
apps/dic                   DIC app layout
apps/image_measurement     image measurement calculations, exports, layout
apps/wearable              wearable app layout
gui/apps                   app GUI launch, layout, callback wiring, and workflow checks
gui/apps/<family>/<app_slug>
                           one app GUI layout, callback wiring, and workflow checks
gui/project/launcher       launcher discovery and layout checks
gui/labkit_framework/ui    reusable UI GUI, workflow, and gesture checks
```

Pair reusable changes with downstream apps when the app-facing contract could
be affected. Use the default non-GUI build task for broad non-GUI changes, the
labkit/app GUI build tasks for broad GUI structural routing, and runner suite
selectors for narrower local diagnosis.

In Codex sandbox sessions, run MATLAB validation commands and GitHub CI
inspection commands with escalated sandbox permissions on the first attempt.
MATLAB build tasks need the host runtime, and `gh`/GitHub API checks need
network plus the host keyring; probing in the restricted sandbox first only
adds a known false failure.

When local GUI validation is needed, account for focus stealing. MATLAB GUI
tests open real figures on macOS and can interrupt the user's typing. Prefer
the focused GUI target, CI, or another noninteractive display for broad GUI
validation; only start full local GUI validation when the user asked for it,
release validation requires it, or the user is not actively using the keyboard.

## GUI Claims

- Default non-GUI tests do not validate interactive GUI workflow behavior.
- Automated GUI tests include `Structural` launch/layout/callback checks and
  `Workflow` hidden synthetic app flows.
- Debug GUI checks validate trace plumbing and callback instrumentation, not full user interaction quality.
- Interactive file selection, drawing, visual inspection, scientific validity,
  and full workflow feel require manual user validation.
- Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Handoff Requirements

Report:

- MATLAB availability
- automated tests run and pass/fail result
- GUI/manual validation status
- unverified behavior
- why any relevant task was not run
