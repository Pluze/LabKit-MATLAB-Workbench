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
command examples. Build tasks are broad discovery-driven entry points; use
`runLabKitTests("Suites", ...)` for component or app-family iteration. For
local GUI edits that only touch one app, prefer the app-level GUI
folder or `runLabKitTests("AffectedAppsOnly", true)`.

```text
project                    startup, architecture, package surface, sample-data hygiene
labkit/dta                 DTA parser, facade, session, item, pulse behavior
labkit/biosignal           biosignal import, processing, ECG peaks, segments, measurements
labkit/ui                  reusable UI helpers; include GUI coverage for layout/callback/shell/debug checks
apps/electrochem           electrochem app-owned calculations, exports, layout
apps/dic                   DIC app layout
apps/image_measurement     image measurement calculations, exports, layout
apps/wearable              wearable app layout
gui/apps                   app GUI launch, layout, and callback wiring checks
gui/apps/<family>/<app_slug>
                           one app GUI layout and callback wiring checks
gui/labkit/launcher        launcher discovery and layout checks
```

Pair reusable changes with downstream apps when the app-facing contract could
be affected. Use the default non-GUI build task for broad non-GUI changes, the
labkit/app GUI build tasks for broad GUI structural routing, and runner suite
selectors for narrower local diagnosis.

## GUI Claims

- Default non-GUI tests do not validate interactive GUI workflow behavior.
- Automated GUI tests are structural launch/layout/callback checks.
- Debug GUI checks validate trace plumbing and callback instrumentation, not full user interaction quality.
- Interactive file selection, drawing, visual inspection, and full workflow feel require manual user validation.
- Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Handoff Requirements

Report:

- MATLAB availability
- automated tests run and pass/fail result
- GUI/manual validation status
- unverified behavior
- why any relevant task was not run
