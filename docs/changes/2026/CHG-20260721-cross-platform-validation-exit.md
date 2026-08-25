# Cross-platform validation exits cleanly after settled plot fitting

```labkit-change
id: CHG-20260721-cross-platform-validation-exit
date: 2026-07-21
type: fix
compatibility: compatible
component: labkit.app | 1.2.2 -> 1.2.3
```

## Why

Windows headless validation completed every test and report but retained a progress heartbeat resource until the GitHub Actions step timed out. Hosted macOS GUI validation also measured equal-scale plot limits before native layout had settled, producing a platform-specific false failure.

### Accepted choice

Make lifecycle ownership explicit at the test-runner boundary and measure equal-data-unit limits only after MATLAB has applied pending native layout. This keeps CI diagnostics available while ensuring successful validation exits promptly, without changing the App SDK surface or EIS workflow meaning.

## What changed

- Explicitly release each progress plugin and its heartbeat timer when a test runner returns, including nested focused runs.
- Verify focused runs leave no tagged heartbeat timer behind.
- Settle native layout before equal-data-unit fitting and assert EIS scaling from the post-action axes allocation.

## Impact

Users receive the same transient equal-scale EIS view, now calculated against the displayed axes allocation. Projects, source records, results, and exports are unchanged.

## Compatibility and limits

The patch release is compatible with all 1.x App SDK requirements. No project or result migration is required.

### Remaining limits

The Windows hosted runner remains the final verification environment for process teardown. Manual visual assessment of plot layout remains outside hidden-GUI automation.
