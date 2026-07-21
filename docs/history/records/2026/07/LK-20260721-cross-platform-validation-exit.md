# Cross-platform validation exits cleanly after settled plot fitting

```labkit-change
id: LK-20260721-cross-platform-validation-exit
date: 2026-07-21
sequence: 151
type: fix
compatibility: compatible
component: `labkit.app` | `1.2.2 -> 1.2.3`
scope: App Framework
scope: Continuous Integration
```

## Context

Windows headless validation completed every test and report but retained a
progress heartbeat resource until the GitHub Actions step timed out. Hosted
macOS GUI validation also measured equal-scale plot limits before native layout
had settled, producing a platform-specific false failure.

## Decision and rationale

Make lifecycle ownership explicit at the test-runner boundary and measure
equal-data-unit limits only after MATLAB has applied pending native layout.
This keeps CI diagnostics available while ensuring successful validation exits
promptly, without changing the App SDK surface or EIS workflow meaning.

## Changes

- Explicitly release each progress plugin and its heartbeat timer when a test
  runner returns, including nested focused runs.
- Verify focused runs leave no tagged heartbeat timer behind.
- Settle native layout before equal-data-unit fitting and assert EIS scaling
  from the post-action axes allocation.

## User and data impact

Users receive the same transient equal-scale EIS view, now calculated against
the displayed axes allocation. Projects, source records, results, and exports
are unchanged.

## Compatibility and migration

The patch release is compatible with all 1.x App SDK requirements. No project
or result migration is required.

## Validation

- Focused nested-runner coverage verifies heartbeat cleanup after return.
- Focused EIS GUI coverage verifies independent fitting and equal-scale limits.
- GitHub Actions will re-run the complete platform matrices after delivery.

## Evidence

The timed-out Windows job reported all 468 headless tests and `** Finished
headless` more than twenty minutes before the action timeout. The macOS GUI
artifact consistently identified the pre-layout equal-scale pixel assertion.

## Known limitations and follow-up

The Windows hosted runner remains the final verification environment for
process teardown. Manual visual assessment of plot layout remains outside
hidden-GUI automation.
