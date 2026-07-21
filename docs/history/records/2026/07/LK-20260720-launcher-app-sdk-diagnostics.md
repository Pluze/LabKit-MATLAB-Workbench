# Launcher adopts the App SDK diagnostic launch contract

```labkit-change
id: LK-20260720-launcher-app-sdk-diagnostics
date: 2026-07-20
sequence: 139
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.5.2 -> 1.6.0`
scope: LabKit Core
scope: App Framework
```

## Context

The Launcher still passed the retired `RequestAdapter` startup seam after Apps
had moved to `labkit.app.Definition`. Normal launch therefore failed before the
selected App could create its window. Removing that argument restored startup,
but temporarily also removed the user's diagnostic launch path.

## Decision and rationale

Treat the App entrypoint and `Definition.launch` as the only Launcher-to-App
runtime boundary. A normal launch uses the SDK defaults. A debug launch passes
one typed `labkit.app.diagnostic.Options` value that requests verbose persisted
events and the App-owned anonymous synthetic sample.

The Launcher continues to read catalog metadata from the single app-owned
`definition.m` source without executing the SDK. This preserves its recovery
role when an installed framework is incomplete or damaged.

## Changes

- Replaced retired runtime-adapter injection with direct App SDK entrypoint
  calls for normal launch and profiling.
- Restored **Open Debug** using verbose typed diagnostics and each App's
  `BuildDebugSample` contract.
- Added one isolated session folder per debug launch under
  `artifacts/diagnostics/launcher/`, with the event stream, manifests, and
  anonymous fixture artifacts.
- Kept Launcher UI state in a Launcher-owned view record instead of the retired
  framework registry name.
- Updated Definition metadata discovery for current name-value syntax while
  retaining the older literal form for repair-oriented catalog compatibility.
- Excluded hidden class-folder implementation methods from public API and
  generated-documentation discovery.

## User and data impact

Existing normal launch, profiling, packaging, update, and documentation actions
keep their public behavior. Debug launch now creates explicit diagnostic
artifacts and opens the App with its synthetic scenario; it no longer invokes
the retired string-mode or request-adapter contracts.


## Compatibility and migration

No additional migration applies beyond the compatibility information in the preceding impact section.

## Validation

- Focused Launcher GUI, catalog, progress, profiling, and documentation
  contracts.
- App SDK diagnostic integration through DIC Preprocess, including
  `events.jsonl` and `sample-pack.json` evidence.
- Documentation source synchronization and public API discovery guardrails.

## Evidence

The validation details above are the supporting evidence for this record.

## Known limitations and follow-up

Developer-led interactive validation should confirm the visible debug launch,
the selected App's synthetic state, and the usefulness of the generated
diagnostic bundle on the deployment MATLAB version.
