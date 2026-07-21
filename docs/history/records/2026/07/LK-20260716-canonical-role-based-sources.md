# Canonical role-based source collections

```labkit-change
id: LK-20260716-canonical-role-based-sources
date: 2026-07-16
sequence: 73
type: refactor
compatibility: compatible
component: `labkit_RHSPreview_app` | `1.4.0 -> 1.4.1`
component: `labkit_NerveResponseAnalysis_app` | `1.4.0 -> 1.4.1`
scope: project payload schema
scope: source roles and relinking
```

## Context

RHS Preview and Nerve Response Analysis stored external files in separate
app-specific fields such as `rhsSource`, `filterSources`, and
`protocolSource`. The records already carried explicit roles, but Runtime V2
could only discover the canonical `project.inputs.sources` collection during
portable save/load and missing-file relinking.

## Decision and rationale

Store every external dependency in one canonical collection and select records
by their app-owned role. The framework remains domain-neutral, while each app
continues to distinguish preview recordings, filter recordings, filter JSON,
and optional protocols without duplicating persistence mechanics.

## Changes

- Advanced both project payload schemas from version 1 to version 2.
- Added ordered migrations that combine the former role-specific fields without
  changing source record contents or order.
- Added app-local role selection and replacement operations used consistently
  by lifecycle creation, actions, presenters, exports, and validation.
- Kept at most one primary recording/protocol per relevant app while allowing
  RHS Preview to retain an ordered collection of filter recordings.

## User and data impact

Project reopen, result provenance, and future missing-file recovery can now see
all selected dependencies. Preview, filtering, event detection, CAP metrics,
and output formats are unchanged.

## Compatibility and migration

Existing version 1 payloads remain readable and preserve every source record.
The old fields are removed only from the migrated in-memory project; saving
writes the version 2 canonical collection.

## Validation

Focused unit tests verify role-preserving migrations and project versions.
Focused GUI workflows verify RHS indexing, multiple filter-file management,
project save/reopen, filter analysis, export, and transient cache rebuilding.

## Evidence

- [RHS Preview](../../../../apps/neurophysiology/rhs-preview/README.md)
  documents its three source roles.
- [Nerve Response Analysis](../../../../apps/neurophysiology/nerve-response-analysis/README.md)
  documents filter/protocol restoration and relinking.
- [App Framework](../../../../framework/README.md) defines the canonical
  project source collection.

## Known limitations and follow-up

This change makes every source discoverable but does not yet rebase relative
paths at the final project save destination. That framework serialization
change is tracked as the next persistence batch.
