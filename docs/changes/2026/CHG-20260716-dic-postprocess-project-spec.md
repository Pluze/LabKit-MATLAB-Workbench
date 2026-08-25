# DIC Postprocess adopts one product and project declaration

```labkit-change
id: CHG-20260716-dic-postprocess-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_DICPostprocess_app | 1.4.1 -> 1.4.2
```

## Why

DIC Postprocess split static product metadata across `definition.m`, `requirements.m`, and `version.m`, while its version-1 durable schema occupied three generic `+appLifecycle` files. None of those separations represented a separate scientific capability or independently evolving contract.

### Accepted choice

Make `definition.m` the product declaration and `projectSpec.m` the only durable-schema entry. Keep `createSession.m` separate because it restores file-backed strain, image, mask, and prepared overlay caches that must not be serialized into the project.

## What changed

- Moved command metadata, version, update date, and facade requirements into the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved transient reconstruction to one explicitly named package-root entry.
- Removed the two metadata files and generic lifecycle package.
- Replaced the stale GUI-free manual example with an executable call matching the real input structure, complete parameter contract, and three outputs.
- Kept all calculation, parameter, action, presentation, and export behavior unchanged.

## Impact

Ncorr loading, overlay preparation, statistics, save/load, and exports behave unchanged. Maintainers can now find the complete product contract in one file and the complete durable schema in one adjacent file.

## Compatibility and limits

The command, project ID, payload version, fields, defaults, validation rules, and source records are unchanged. Existing DIC Postprocess projects require no migration.

### Remaining limits

The action file remains a meaningful workflow boundary because it coordinates input selection, calculation, export, diagnostics, and dialogs. Its naming and possible smaller capability boundaries will be compared across the DIC family instead of changed in isolation.
