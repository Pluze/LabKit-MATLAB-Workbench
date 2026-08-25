# Focus Stack adopts the compact App contract

```labkit-change
id: CHG-20260716-focus-stack-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FocusStack_app | 1.5.1 -> 1.5.2
```

## Why

Focus Stack split static metadata across `requirements.m` and `version.m`, spread a version-1 project over a generic lifecycle package, grouped three calculation concepts under `+appState`, and ran a startup callback only to fill an output path and emit an App-specific debug line. It also duplicated the portable-reference path loop in session, actions, and presentation.

### Accepted choice

Use the compact Runtime V2 contract: one product definition, one durable project specification, and one explicit session factory. Put calculation result shape, presets, and run fingerprinting beside the computation. Resolve output folders only when file registration or export actually needs them.

## What changed

- Consolidated command metadata, version, requirements, and optional capabilities in `definition.m`.
- Consolidated project creation and validation in `projectSpec.m`.
- Moved transient image reconstruction to root `createSession.m`.
- Moved three `+appState` helpers into their owning `+analysisRun` capability.
- Removed the metadata files, generic lifecycle/state packages, and redundant App startup callback.
- Replaced all direct portable-reference reads with the Runtime path accessor.

## Impact

Focus loading, registration, fusion, previews, duplicate-run detection, project reopen, and exports keep the same scientific behavior. A new App no longer mutates its durable output folder during startup. After inputs are selected, output defaults remain source-adjacent as before.

The App package loses six structural files and one generic package while its real workflow capabilities become easier to locate.

## Compatibility and limits

The durable payload remains version 1 with identical fields, defaults, and validation. Existing projects require no migration. The removed startup debug line is replaced by the Runtime's standard debug-startup message.

### Remaining limits

The remaining Image Measurement Apps still use the older structural packages and will be reviewed individually rather than copied from this App blindly.
