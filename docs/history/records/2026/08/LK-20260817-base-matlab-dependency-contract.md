# Base MATLAB dependency and facade requirement enforcement

```labkit-change
id: LK-20260817-base-matlab-dependency-contract
date: 2026-08-17
sequence: 179
type: fix
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.7.2 -> 1.7.3`
scope: Base MATLAB runtime dependency boundary
scope: App facade requirement completeness and launch enforcement
scope: Video Marker image facade declaration
```

## Context

The repository documented optional MathWorks Toolbox debt even though clean CI
and offline deployment already assumed Base MATLAB. App definitions also
declared facade versions without the normal launch path enforcing them. Video
Marker called `labkit.image` tracking primitives but declared only the App SDK.

## Decision and rationale

Make Base MATLAB plus repository code the only production runtime boundary.
Treat an optional Toolbox need as an architecture decision instead of accepted
temporary debt. Enforce every App's declared LabKit facade ranges immediately
before native Runtime creation, and check that statically visible facade calls
have matching declarations.

## Changes

- The root and App governance contracts, architecture guide, and getting
  started guide now state the Base MATLAB-only boundary.
- Obsolete Toolbox-debt registry and ledger language were removed. A focused
  repository guard prevents the retired Parallel Computing Toolbox gateways
  from returning while clean CI remains the executable general boundary.
- `Definition.launch` asserts declared facade compatibility before creating a
  native figure. Public-App conformance scans App source for undeclared facade
  calls.
- Video Marker now declares its `labkit.image` 4.x dependency.
- Two unreferenced private App plot helpers were removed; no public plotting
  surface changed.

## User and data impact

Users need only a supported Base MATLAB installation. An incompatible LabKit
facade now fails before an App window is constructed instead of surfacing later
as a missing or mismatched call. Projects, exports, calculations, and Video
Marker tracking behavior are unchanged.

## Compatibility and migration

This is compatible within the existing App SDK and Video Marker contracts.
Video Marker projects require no migration. Private Apps must declare every
LabKit facade they call; an omitted declaration is now a conformance failure.

## Validation

Focused App SDK coverage verifies pre-window requirement enforcement. Public
App definition conformance checks declared versions and call completeness.
Repository policy scans production source for the retired Parallel Computing
Toolbox entry points, while the platform matrix runs without optional
Toolboxes.

## Evidence

All 88 public-App conformance identities passed, including facade-call
completeness and Video Marker's corrected declaration. Ten Mark-10 facade and
three acquisition identities passed without Parallel Computing Toolbox. The
focused pre-window launch assertion and retired-PCT source guard passed. The
repository Skill validator accepted all 11 Skill contracts after the boundary
skill gained its Base MATLAB dependency procedure.

## Known limitations and follow-up

MATLAB's static product report currently misclassifies the App layout `Step`
property as Control System Toolbox usage, so it is not used as a merge gate.
Clean Base MATLAB execution and focused retired-symbol guards remain the
authoritative evidence unless MathWorks provides a precise product trace.
