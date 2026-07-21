# Profiling and validation speedups

```labkit-change
id: LK-20260702-profiling-and-validation-speedups
date: 2026-07-02
sequence: 30
type: ci
compatibility: compatible
component: `labkit_launcher` | `1.2.0 -> 1.2.1`
component: `labkit_launcher` | `1.2.1 -> 1.2.2`
component: `labkit.ui` | `3.4.0 -> 3.4.1`
component: `labkit.ui` | `3.4.1 -> 3.4.2`
component: `labkit_BatchImageCrop_app` | `1.6.0 -> 1.6.1`
component: `labkit_ECGPrint_app` | `1.3.0 -> 1.3.1`
scope: Profiling and validation speedups
```

## Context

Startup and file-selection complaints could not be resolved reliably from wall
clock impressions alone. At the same time, focused changes paid avoidable test
discovery cost, GUI tests waited longer than the behavior required, and Batch
Crop read every selected image before the user requested a preview or export.

## Decision and rationale

Add a profiler that records launcher, startup, callback, and close costs with
source attribution. Use its evidence to remove repeated UI updates and eager
image reads. Route changed-file validation to the smallest owning suites and
bound GUI waits without weakening their behavioral assertions.

## Changes

- `labkit_launcher` `1.2.0 -> 1.2.2`
- `labkit.ui` `3.4.0 -> 3.4.2`
- `labkit_BatchImageCrop_app` `1.6.0 -> 1.6.1`
- `labkit_ECGPrint_app` `1.3.0 -> 1.3.1`

- Added LabKit profiling and build-managed test routing to the launcher.
- Reduced GUI profiling overhead and deferred Batch Crop image reads until
  preview/export.
- Compressed validation runtime with bounded GUI waits.

## User and data impact

Maintainers could launch a profiled target and receive a summarized report
instead of interpreting MATLAB's raw profile table. Selecting many Batch Crop
files returned sooner because images were decoded only for the current preview
or final export. Routine validation also completed with less discovery and wait
overhead.

## Compatibility and migration

Profiling and test routing were maintainer tools. Batch Crop kept its task and
export schemas; selected images were simply decoded later in the workflow.

## Validation

The profiling tool received a dedicated unit suite. Later commits added
launcher profiler coverage, deferred-read tests, debug-trace mirroring checks,
routing guardrails, and bounded GUI-wait tests. Commit `25912c54` records
successful `buildtool changed`, integration validation, and remote MATLAB
tests.

## Evidence

- Main commits `c07dfc0a`, `74025fee`, `eadcca82`, `25912c54`, and `fcfc36d8`.

## Known limitations and follow-up

These changes reduced measured work but did not eliminate the white window
shown before all startup setup completed. The following startup pass changed
when windows were painted and when scroll navigation was installed.
