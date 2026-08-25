# Base MATLAB dependency and facade requirement enforcement

```labkit-change
id: CHG-20260817-base-matlab-dependency-contract
date: 2026-08-17
type: fix
compatibility: compatible
component: labkit_VideoMarker_app | 1.7.2 -> 1.7.3
```

## Why

The repository documented optional MathWorks Toolbox debt even though clean CI and offline deployment already assumed Base MATLAB. App definitions also declared facade versions without the normal launch path enforcing them. Video Marker called `labkit.image` tracking primitives but declared only the App SDK.

### Accepted choice

Make Base MATLAB plus repository code the only production runtime boundary. Treat an optional Toolbox need as an architecture decision instead of accepted temporary debt. Enforce every App's declared LabKit facade ranges immediately before native Runtime creation, and check that statically visible facade calls have matching declarations.

## What changed

- The root and App governance contracts, architecture guide, and getting started guide now state the Base MATLAB-only boundary.
- Obsolete Toolbox-debt registry and ledger language were removed. A focused repository guard prevents pool and cluster APIs owned by Parallel Computing Toolbox from entering production while preserving MATLAB's explicit single-worker `backgroundPool` path. Clean CI remains the executable general boundary.
- `Definition.launch` asserts declared facade compatibility before creating a native figure. Public-App conformance scans App source for undeclared facade calls.
- Video Marker now declares its `labkit.image` 4.x dependency.
- Two unreferenced private App plot helpers were removed; no public plotting surface changed.

## Impact

Users need only a supported Base MATLAB installation. An incompatible LabKit facade now fails before an App window is constructed instead of surfacing later as a missing or mismatched call. Projects, exports, calculations, and Video Marker tracking behavior are unchanged.

## Compatibility and limits

This is compatible within the existing App SDK and Video Marker contracts. Video Marker projects require no migration. Private Apps must declare every LabKit facade they call; an omitted declaration is now a conformance failure.

### Remaining limits

MATLAB's static product report currently misclassifies the App layout `Step` property as Control System Toolbox usage and conservatively reports Parallel Computing Toolbox for MATLAB's no-license `backgroundPool` APIs. It is therefore not used as a merge gate. Clean Base MATLAB execution, direct symbol-contract review, and focused Toolbox-only source guards remain the authoritative evidence unless MathWorks provides a more precise product trace.
