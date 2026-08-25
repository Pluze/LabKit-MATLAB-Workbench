# Clean-room cross-platform CI

```labkit-change
id: CHG-20260717-clean-room-cross-platform-ci
date: 2026-07-17
type: ci
compatibility: compatible
component: repository
```

## Why

The previous MATLAB workflow combined ordinary CI, scheduled reports, release validation, and raw tag creation. Its optional Base MATLAB job also mixed static source checks with installed-product dependency analysis, even though that analysis can only report products present on the runner. The design made it difficult to tell which evidence was required and did not exercise every candidate outside the developer's operating system.

### Accepted choice

Make a Toolbox-free MATLAB installation the baseline for all required CI behavior. Let one CI workflow run complete headless and hidden-GUI tasks on Linux, macOS, and Windows. Keep coverage as an explicit local report. Release creation remains a developer-initiated process after manual App validation, requires a successful main-push CI run for the exact commit, and stops at a draft for final human review.

This directly tests the promised runtime instead of trying to infer the same fact from a runner with optional products installed.

## What changed

- Replaced the monolithic MATLAB workflow with one ordinary/reusable CI workflow and one manual release workflow.
- Made cross-platform Base MATLAB headless and hidden-GUI validation mandatory for pull requests and main pushes, and required exact same-commit CI evidence before release.
- Removed the installed-product dependency-analysis task and all CI Toolbox installation.
- Kept static known-Toolbox call detection and representative shadowed-helper workflows inside the ordinary headless suite.
- Kept coverage out of CI because it has no failure threshold and repeats the non-GUI tests; maintainers can still request the local report explicitly.
- Replaced raw Git-ref creation with a validated annotated tag, tag-blob launcher staging, remote asset verification, and a draft GitHub Release.

## Impact

No App runtime, calculation, project, or saved-data behavior changes. CI may now expose operating-system, path, case-sensitivity, layout, or missing- dependency failures that a configured development machine did not reveal.

## Compatibility and limits

Maintainers should use `Continuous Integration` for required checks, `buildtool coverage` for an on-demand local report, and the manual `Release` workflow only after interactive App validation. The retired `buildtool baseMatlab` task has no compatibility alias because clean Base MATLAB execution is now the environment of every required build task rather than a separate partial check.

### Remaining limits

Hidden GUI tests cannot drive native dialogs or judge visual and pointer quality. Developer-led manual App testing therefore remains mandatory before starting a release. CI also detects only Toolbox calls reached by tests or covered by the maintained static-call set; temporary product use still needs its declared fallback, idempotency, and parity evidence.
