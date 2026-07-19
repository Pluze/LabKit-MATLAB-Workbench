# Runtime uses one source contract for launch, migration, and layout

```labkit-change
schema: 2
id: LK-20260717-retired-runtime-compatibility
date: 2026-07-17
sequence: 126
type: refactor
compatibility: breaking
component: `labkit.ui` | `7.4.7 -> 7.5.0`
scope: Runtime launch contract
scope: Project payload migration
scope: Semantic layout validation
```

## Context

UI Runtime had already introduced one-definition App launch, one
version-aware `Project.Migrate` callback, and presenter-owned managed
interactions. Transitional branches still accepted separate requirements and
version factories, ordered `Project.Migrations` cells, and a `toolPanel`
layout kind whose public constructor no longer existed. No public or accepted
private App used those branches; framework tests and stale guidance were their
only remaining consumers.

## Decision and rationale

Keep one writable source contract for each capability. `launch` receives one
definition factory and reads product metadata and requirements from that
definition. Runtime calls the App's single `Migrate(project,fromVersion)`
callback for each missing payload step. Layout sections contain supported
semantic controls, while presenter interaction specs own axes tools.

This removes source-level compatibility that could hide an incomplete App
migration. Read-only support for current saved project envelopes, declared
legacy MAT imports, and older supported payload versions remains intact.

## Changes

- Removed requirements/version factory dispatch from `runtime.launch` and
  added a direct diagnostic for the retired call form.
- Rejected `Project.Migrations` and removed its project-reader fallback.
- Removed `toolPanel` validation, sizing, building, diagnostics, and current
  manual guidance.
- Converted Runtime tests to complete single definitions and added regression
  checks for both retired contracts.

## User and developer impact

Current Apps and their project files behave the same. App developers have one
place to review identity, version, requirements, layout, and optional runtime
capabilities. Source code still using a three-factory launch or
`Project.Migrations` now fails immediately with migration guidance instead of
silently taking a legacy path.

## Compatibility and migration

This is a source-contract cleanup within UI 7. Call
`labkit.ui.runtime.launch(@app.definition,varargin{:})`, move product metadata
and `Requirements` into `definition.m`, and replace migration callback cells
with one callback that switches on `fromVersion`. No saved-data rewrite is
required.

## Validation

Focused Runtime GUI tests cover single-definition launch, rejection of the
retired launch form, ordered project migration and atomic load, rejection of
`Project.Migrations`, managed interactions, and startup progress. Contract
tests cover App layout structure and public surface drift.

## Evidence

- [Runtime and lifecycle](../../../../framework/guides/runtime.md)
- [App development](../../../../development/build-apps/app-development.md)
- [Public API reference](../../../../reference/README.md)

## Known limitations and follow-up

Historical records retain their original descriptions of the transitional
APIs. They document how the architecture evolved and are not current usage
guidance.
