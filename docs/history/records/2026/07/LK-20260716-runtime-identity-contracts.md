# Validated runtime identity contracts

```labkit-change
schema: 2
id: LK-20260716-runtime-identity-contracts
date: 2026-07-16
sequence: 65
type: fix
compatibility: compatible
component: `labkit.ui` | `6.0.0 -> 6.0.1`
scope: runtime definitions
scope: layouts and presentations
scope: projects and result manifests
```

## Context

Runtime ids connect app definitions, layout controls, actions, axes,
interactions, durable source records, result outputs, and managed resources.
Several registries previously accepted duplicate ids or dangling references
until a callback ran. Recovery directory names also used MATLAB identifier
normalization, which is not an injective mapping and could make two distinct
app ids share storage.

## Decision and rationale

Keep semantic ids developer-owned, but validate each namespace at the earliest
transaction boundary. App ids now have one documented portable syntax and a
collision-free filesystem encoding. References from layouts, presentations,
and interactions must resolve before the runtime changes visible handles or
managed resources.

Same-scope resource replacement remains intentional: a resource id is an
idempotent ownership slot, while resources that must coexist use distinct ids.

## Changes

- Rejected invalid app ids, duplicate preview-axis ids, duplicate durable
  source ids, and duplicate result-output ids.
- Rejected layout, interaction, and presentation references to unknown
  actions, controls, targets, axes, or renderers before committing UI changes.
- Encoded app recovery storage with the exact app id while retaining read-only
  discovery of recovery files written under the earlier normalized folder.
- Added a repository contract test requiring literal public app ids to be
  globally unique.

## User and data impact

Valid current apps and saved projects behave as before. Configuration mistakes
now fail with a specific runtime error instead of overwriting another object or
appearing later as a broken callback. Existing recovery files remain
discoverable and new recovery files cannot collide through name normalization.

## Compatibility and migration

This patch is compatible for documented definitions. A private app with an
invalid app id, duplicate semantic ids, or a dangling reference must correct
that declaration. Its app id should otherwise remain unchanged because the id
is part of saved-project and recovery compatibility.

## Validation

Focused unit, contract, and hidden-GUI runtime tests cover invalid definitions,
duplicate namespaces, dangling references, result manifests, and recovery
storage behavior.

## Evidence

- `labkit.ui.runtime.define` documents the public identity and resource rules.
- Runtime validation rejects invalid identity graphs before commit.
- The app identity contract scans every public app definition.

## Known limitations and follow-up

Identity validation protects one runtime and the public app catalog. External
private-app catalogs remain responsible for running the same contract test in
their own workspace.
