# Runtime-owned project shape validation

```labkit-change
id: CHG-20260716-runtime-owned-project-shape-validation
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit.ui | 7.4.4 -> 7.4.5
component: labkit_ChronoOverlay_app | 1.4.4 -> 1.4.5
component: labkit_CIC_app | 1.4.4 -> 1.4.5
component: labkit_CSC_app | 1.4.4 -> 1.4.5
component: labkit_EIS_app | 1.4.4 -> 1.4.5
component: labkit_VTResistance_app | 1.4.4 -> 1.4.5
```

## Why

Runtime already validated canonical project buckets and portable source records after actions committed. During project restore, however, the App validator ran before that framework validation. Every persistent App consequently repeated the same bucket and source-record checks so malformed loaded projects would fail safely.

### Accepted choice

Validate framework-owned project structure before invoking App-owned project validation on both initial state and project restore. App validators should describe only their own schema and scientific rules. This gives canonical shape and source records one owner while retaining strict validation at the load boundary.

## What changed

- Added one private Runtime project-shape validator shared by restore and semantic state validation.
- Runtime now rejects a malformed loaded payload before its App validator can inspect domain fields.
- Removed 67 net lines of repeated canonical bucket and source-record checks from the five electrochemistry `projectSpec.m` files.
- Kept each App's legal choices, numeric bounds, result fields, and other domain-specific validation unchanged.

## Impact

Valid projects and scientific results are unchanged. Malformed projects now receive the framework's consistent invalid-state error for canonical structure failures instead of an App-specific bucket or source error. No payload migration is required.

## Compatibility and limits

The accepted project schema is unchanged. This is a validation-ownership change, not a data-format change, and current or older supported project versions continue through the same migration callbacks.

### Remaining limits

Other App families still repeat some canonical structure checks. They will move to the same boundary only after their role and cross-field constraints are separated from the generic checks and covered by focused tests.
