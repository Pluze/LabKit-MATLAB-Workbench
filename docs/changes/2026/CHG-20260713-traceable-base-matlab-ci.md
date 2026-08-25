# Traceable and base-MATLAB CI validation

```labkit-change
id: CHG-20260713-traceable-base-matlab-ci
date: 2026-07-13
type: ci
compatibility: compatible
component: repository
```

## Why

CI failures and stalls could end without enough information to identify the active test, and ordinary success on a toolbox-rich development machine did not prove that base-MATLAB users could run representative workflows.

### Accepted choice

Make the existing official runner publish progress and active-test state, and add a distinct compatibility gate that combines static calls, product ownership, and toolbox-shadowed behavior.

## What changed

- Added per-test progress, heartbeat, active-test, timeout-summary, and artifact publication behavior to CI.
- Added `buildtool baseMatlab` and representative toolbox-shadow workflows.
- Improved changed-file routing to target direct consumers while retaining explicit owners such as the launcher GUI suite.
- Corrected result aggregation so assumption-filtered tests remain visible as skipped without being misreported as shard failures.

## Impact

Base-MATLAB compatibility is now an explicit supported path, and failed or stalled CI runs provide enough state to identify the last active test. Runtime scientific outputs are not changed by this record.

## Compatibility and limits

Existing build tasks remain available. Maintainers can add `baseMatlab` to local validation without installing or uninstalling toolboxes.

### Remaining limits

Shadow tests cover known dependency risks and cannot simulate every licensed toolbox combination; MATLAB product-ownership analysis remains the broad check.
