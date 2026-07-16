# Minimal App definitions

```labkit-change
schema: 2
id: LK-20260716-minimal-app-definition
date: 2026-07-16
sequence: 76
type: feat
compatibility: additive
component: `labkit.ui` | `7.0.0 -> 7.1.0`
scope: App authoring
scope: Runtime V2 definition defaults
```

## Context

Runtime V2 already normalized missing project and session buckets, but every
definition still had to provide project create/validate callbacks, at least one
action, and a presenter. A static App therefore needed lifecycle files and
placeholder functions that owned no behavior.

## Decision and rationale

Make lifecycle components proportional to product behavior. Every App still
declares a stable ID, title, and semantic layout. The framework supplies empty
canonical state and no-op dynamic behavior until the App opts into durable
data, transient cache, actions, or presentation.

## Changes

- Made `Project`, `Actions`, and `Present` optional in
  `labkit.ui.runtime.define`; `CreateSession` was already optional.
- Added a framework-owned version-1 empty project specification and empty
  presenter model.
- Allowed an empty action registry when no layout event or startup phase
  references an action.
- Added a GUI contract test that launches a definition containing only `Id`,
  `Title`, and `Layout` and verifies both canonical state roots.
- Rewrote App-development entry guidance around capability tiers instead of a
  fixed list of placeholder files.

## User and developer impact

Existing Apps behave unchanged. A new static App does not need
`createProject.m`, `createSession.m`, `validateProject.m`,
`definitionActions.m`, or a presenter. Those components are introduced only
when the App gains corresponding behavior.

## Compatibility and migration

The change is additive within UI 7. Existing complete definitions remain
valid. Saved project and source schemas do not change.

## Validation

The minimal-definition GUI test exercises real launch, canonical project and
session creation, layout construction, empty presentation, and readiness.
Definition validation and public documentation guardrails cover both minimal
and full definitions.

## Evidence

- [App Framework](../../../../framework/README.md) introduces the minimal
  definition.
- [Runtime and Lifecycle](../../../../framework/runtime.md) lists required and
  optional definition components.
- [App Development](../../../../development/app-development.md) maps files to
  capabilities instead of treating them as universal boilerplate.

## Known limitations and follow-up

Apps that own a project schema still use explicit project specification. The
next lifecycle cleanup consolidates each App's project factory, validator, and
ordered migration steps behind one `projectSpec.m` entry point rather than
scattered version-step files.
