# Framework public APIs become an explicit last resort

```labkit-change
id: CHG-20260720-public-api-escalation-order
date: 2026-07-20
type: docs
compatibility: compatible
component: repository
```

## Why

A convenient framework helper can appear attractive for one App-specific need, but every public name becomes a long-lived compatibility and documentation commitment. Conversely, forcing unrelated behavior into an existing API can turn a focused contract into an ambiguous option bucket.

### Accepted choice

Use a consistent escalation order for new App behavior: keep it App-local, extend an existing focused API when the addition is natural, add private framework/runtime capability when shared implementation does not require an App-authored contract, and add a new public API only for stable use by multiple Apps or when the nearest existing API would otherwise lose a clear single purpose.

This makes a new public API the final solution without prohibiting one when a genuine reusable boundary has emerged.

## What changed

- Added the escalation order to the root, framework, and App agent contracts.
- Updated the App builder and boundary guard skills to require evidence for multiple consumers or an anti-bucket clarity need before introducing a new public name.
- Updated the documentation maintainer skill to distinguish documentation of an existing focused extension from review of a genuinely new public surface.

## Impact

Runtime behavior, public signatures, App calculations, projects, and exports are unchanged. The rule affects future design choices and review evidence.

## Compatibility and limits

No additional migration applies beyond the compatibility information in the preceding impact section.

### Remaining limits

When a proposed public API crosses the stated threshold, record its consumers, ownership rationale, alternatives considered, and compatibility contract in the component history.
