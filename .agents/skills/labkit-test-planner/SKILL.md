---
name: labkit-test-planner
description: "Use for LabKit validation planning, running tests, pre-commit checks, MATLAB source/test/fixture changes, or deciding which suite to run. Trigger on validate, test plan, before commit, CI, GUI check, parser regression, fixture, or sample hygiene work."
---

# LabKit Test Planner

## Goal

Choose visible, source-aligned validation without overstating coverage.

## Required Read Order

1. `AGENTS.md`
2. nearest scoped `AGENTS.md`
3. `docs/testing.md`
4. touched source, tests, and fixture files

## Suite Routing

Use the smallest set that covers the touched boundary:

```text
project                    startup, architecture, package surface, sample-data hygiene
labkit/dta                 DTA parser, facade, session, item, pulse behavior
labkit/biosignal           biosignal import, processing, ECG peaks, segments, measurements
labkit/ui                  reusable UI helpers; add --gui for layout/callback/shell/debug checks
apps/electrochem           electrochem app-owned calculations, exports, layout
apps/dic                   DIC app layout; usually --gui
apps/image_measurement     image measurement calculations, exports, layout
apps/wearable              wearable app layout; usually --gui
apps/smoke                 cross-app noninteractive launch checks
```

Pair reusable changes with downstream apps when the app-facing contract could be affected:

```bash
scripts/run_matlab_tests.sh --suite labkit/dta --suite apps/electrochem
scripts/run_matlab_tests.sh --suite labkit/biosignal --suite apps/wearable
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
```

Use the default non-GUI suite for broad changes:

```bash
scripts/run_matlab_tests.sh
```

On Windows, use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project
```

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
- why any relevant suite was not run
