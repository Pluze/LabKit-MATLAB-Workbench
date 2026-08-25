# Canonical role-based source collections

```labkit-change
id: CHG-20260716-canonical-role-based-sources
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_RHSPreview_app | 1.4.0 -> 1.4.1
component: labkit_NerveResponseAnalysis_app | 1.4.0 -> 1.4.1
```

## Why

RHS Preview and Nerve Response Analysis stored external files in separate app-specific fields such as `rhsSource`, `filterSources`, and `protocolSource`. The records already carried explicit roles, but Runtime V2 could only discover the canonical `project.inputs.sources` collection during portable save/load and missing-file relinking.

### Accepted choice

Store every external dependency in one canonical collection and select records by their app-owned role. The framework remains domain-neutral, while each app continues to distinguish preview recordings, filter recordings, filter JSON, and optional protocols without duplicating persistence mechanics.

## What changed

- Advanced both project payload schemas from version 1 to version 2.
- Added ordered migrations that combine the former role-specific fields without changing source record contents or order.
- Added app-local role selection and replacement operations used consistently by lifecycle creation, actions, presenters, exports, and validation.
- Kept at most one primary recording/protocol per relevant app while allowing RHS Preview to retain an ordered collection of filter recordings.

## Impact

Project reopen, result provenance, and future missing-file recovery can now see all selected dependencies. Preview, filtering, event detection, CAP metrics, and output formats are unchanged.

## Compatibility and limits

Existing version 1 payloads remain readable and preserve every source record. The old fields are removed only from the migrated in-memory project; saving writes the version 2 canonical collection.

### Remaining limits

This change makes every source discoverable but does not yet rebase relative paths at the final project save destination. That framework serialization change is tracked as the next persistence batch.
