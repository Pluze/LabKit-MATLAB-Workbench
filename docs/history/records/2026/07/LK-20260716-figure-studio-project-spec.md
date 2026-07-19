# Figure Studio consolidates its project schema

```labkit-change
schema: 2
id: LK-20260716-figure-studio-project-spec
date: 2026-07-16
sequence: 82
type: refactor
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.2.2 -> 0.2.3`
scope: LabKit Core
scope: Project lifecycle
```

## Context

Figure Studio's version-1 project creation and validation lived in separate
files under a generic `+appLifecycle` package. The package name described a
framework phase rather than the durable capability those functions owned.

## Decision and rationale

Consolidate the complete durable schema behind `projectSpec.m`. Keep
`createSession.m` separate at the App package root because it performs a
different job: rebuilding transient selection and decoded plot cache from a
validated project.

## Changes

- Added one project declaration with local create and validate functions.
- Moved session reconstruction to one explicitly named package-root entry.
- Removed the three-file generic `+appLifecycle` package.
- Left meaningful startup, action, presentation, source, style, and export
  capabilities unchanged.

## User and developer impact

Figure loading, axes handoff, styling, project save/load, session restoration,
and exports behave unchanged. A maintainer can now understand the entire
durable schema in one file.

## Compatibility and migration

The App command, project ID, payload version, fields, validation, and source
record format are unchanged. Existing Figure Studio projects need no migration.

## Validation

The existing unit and hidden GUI suites cover FIG reading, source style,
project round-trip, axes handoff, canvas resizing, quick export, and data
package export through the consolidated project declaration.

## Evidence

- [Figure Studio](../../../../apps/labkit-core/figure-studio/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

The startup hook still owns axes handoff and resize-resource installation. It
will be evaluated with other App startup hooks before any shared mount/action
capability is introduced.
