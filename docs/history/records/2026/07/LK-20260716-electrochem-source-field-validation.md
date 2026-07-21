# Electrochemistry source-field validation boundary

```labkit-change
id: LK-20260716-electrochem-source-field-validation
date: 2026-07-16
sequence: 118
type: fix
compatibility: compatible
component: `labkit_ChronoOverlay_app` | `1.4.5 -> 1.4.6`
component: `labkit_CIC_app` | `1.4.5 -> 1.4.6`
component: `labkit_CSC_app` | `1.4.5 -> 1.4.6`
component: `labkit_EIS_app` | `1.4.5 -> 1.4.6`
component: `labkit_VTResistance_app` | `1.4.5 -> 1.4.6`
scope: electrochemistry project schemas
scope: malformed project rejection
```

## Context

Runtime owns the format of a portable source record but intentionally allows a
project whose `inputs` bucket has no `sources` field. Static and embedded-data
Apps may not use external sources. The first electrochemistry validator
reduction correctly removed record-format duplication but also stopped
declaring that these five file-backed Apps require a source collection.

## Decision and rationale

Keep field presence with the App schema and record shape with Runtime. This is
the narrow ownership split: the App decides whether sources are required;
Runtime decides what every supplied source record means.

## Changes

- Restored the `inputs.sources` presence requirement in all five
  electrochemistry project validators.
- Added a GUI-free unit contract that accepts each default project and rejects
  the same project after its App-required source collection is removed.
- Kept canonical bucket and source-record field validation out of the Apps.

## User and data impact

Valid projects are unchanged. A malformed electrochemistry project missing its
entire source collection is rejected by the App validator before session
reconstruction instead of failing later while decoded data are rebuilt.

## Compatibility and migration

No saved format changed and no migration is required. Every project created or
saved by these Apps already contains `inputs.sources`.

## Validation

The focused project-spec test covers all five accepted defaults and all five
missing-source rejection cases. The Runtime project and electrochemistry GUI
tests continue to cover canonical record validation and working file flows.

## Evidence

- [Runtime and Lifecycle](../../../../framework/guides/runtime.md) separates
  framework-owned record shape from App-owned fields and roles.
- The [Electrochemistry App manuals](../../../../apps/electrochemistry/README.md)
  identify the required App source collection.

## Known limitations and follow-up

The same distinction must be applied explicitly while reducing validators in
other App families; a generic source format does not imply that every App has
the same required source fields or roles.
