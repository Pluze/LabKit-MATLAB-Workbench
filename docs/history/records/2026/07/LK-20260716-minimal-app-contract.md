# Minimal App contract and current authoring manuals

```labkit-change
schema: 2
id: LK-20260716-minimal-app-contract
date: 2026-07-16
sequence: 115
type: docs
compatibility: clarification
component: `LabKit project` | documentation
scope: App authoring
scope: Runtime V2 contract guardrails
```

## Context

Runtime V2 already supplied default project, session, action, presenter, and
startup capabilities, but the complete-App tutorial and several current
manuals still taught the retired split metadata and generic lifecycle package
shape. The App structure guardrail also prohibited those files only when an App
already owned `projectSpec.m`, leaving static Apps unprotected.

## Decision and rationale

Make progressive capability the documented and tested authoring contract. A
static App consists of a thin entrypoint, one definition, and one data-only
layout. Actions, presentation, durable project state, transient reconstruction,
and startup are added independently only when the product needs them.

## Changes

- Rewrote the complete-App tutorial around the three-file starting point and
  one `projectSpec.m` create/validate/migrate entry.
- Updated architecture, framework, private-App, library, testing, release, and
  history manuals plus scoped App rules and the App-builder skill to use
  definition-owned metadata and progressive optional capabilities.
- Added a hidden-GUI launch test whose definition omits every optional Runtime
  V2 component.
- Corrected the tutorial's numeric field declaration after the real launch
  test exposed its implicit text-control mismatch.
- Made the App package guardrail reject retired metadata, lifecycle, state,
  startup, and per-version migration files for every App shape.

## User and developer impact

App behavior and scientific results do not change. A developer can begin with
three source files and add each larger architectural concept only when a real
workflow requires it. Public and private App documentation now teach the same
contract.

## Compatibility and migration

This change documents and protects the already migrated Runtime V2 structure.
It does not alter saved project payloads or remove the temporary low-level
legacy project-migration reader used by framework tests.

## Validation

Focused contract and GUI tests cover both the forbidden retired structures and
an actual launch from the minimal definition. A documentation contract checks
the tutorial, scoped App rules, and App-builder skill together. Documentation
consistency checks and a regenerated site validate navigation and history
metadata.

## Evidence

- [Build a Complete App](../../../../development/build-apps/complete-app.md) gives the
  progressive file-by-file tutorial.
- [Architecture](../../../../development/build-apps/architecture.md) defines the current
  package shape and ownership boundaries.
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md) specifies every
  optional component and callback.

## Known limitations and follow-up

The minimal contract proves framework defaults, not that every complex App has
already reached its lowest maintainable complexity. App-by-App workflow and
framework-boundary audits continue separately.
