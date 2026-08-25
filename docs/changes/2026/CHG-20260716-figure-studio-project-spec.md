# Figure Studio consolidates its project schema

```labkit-change
id: CHG-20260716-figure-studio-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FigureStudio_app | 0.2.2 -> 0.2.3
```

## Why

Figure Studio's version-1 project creation and validation lived in separate files under a generic `+appLifecycle` package. The package name described a framework phase rather than the durable capability those functions owned.

### Accepted choice

Consolidate the complete durable schema behind `projectSpec.m`. Keep `createSession.m` separate at the App package root because it performs a different job: rebuilding transient selection and decoded plot cache from a validated project.

## What changed

- Added one project declaration with local create and validate functions.
- Moved session reconstruction to one explicitly named package-root entry.
- Removed the three-file generic `+appLifecycle` package.
- Left meaningful startup, action, presentation, source, style, and export capabilities unchanged.

## Impact

Figure loading, axes handoff, styling, project save/load, session restoration, and exports behave unchanged. A maintainer can now understand the entire durable schema in one file.

## Compatibility and limits

The App command, project ID, payload version, fields, validation, and source record format are unchanged. Existing Figure Studio projects need no migration.

### Remaining limits

The startup hook still owns axes handoff and resize-resource installation. It will be evaluated with other App startup hooks before any shared mount/action capability is introduced.
