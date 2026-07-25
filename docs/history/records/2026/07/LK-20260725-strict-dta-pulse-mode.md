# DTA rejects unknown pulse modes

```labkit-change
id: LK-20260725-strict-dta-pulse-mode
date: 2026-07-25
sequence: 164
type: fix
compatibility: compatible
component: `labkit.dta` | `3.0.0 -> 3.0.1`
scope: DTA pulse detection
```

## Context

The public pulse detector documented an explicit failure for unsupported mode
text, but its private normalizer silently selected metadata-first behavior.
An invalid scientific option could therefore produce a plausible successful
result from a different detection policy.

## Decision and rationale

Unknown modes now return the canonical failed pulse and an explanatory
message. Defaults apply only when the caller omits the option, not when it
supplies an unrecognized value.

## Changes

- Distinguished omitted modes from invalid modes.
- Removed the silent fallback to metadata-first detection.
- Added a regression specification using valid pulse data and an invalid mode.

## User and data impact

Supported mode labels and aliases are unchanged. Invalid modes no longer run a
different scientific branch, making configuration errors visible to callers.

## Compatibility and migration

No saved data or supported caller changes are required.

## Validation

The focused DTA facade and pulse contract passed, including metadata,
current-based fallback, metadata-only failure, and invalid-mode failure.

## Evidence

- [DTA Library](../../../../libraries/dta/README.md)

## Known limitations and follow-up

No known silent mode fallback remains in pulse detection.
