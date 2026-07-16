# DIC Preprocess replaces its generic state bucket

```labkit-change
schema: 2
id: LK-20260716-dic-preprocess-state-capabilities
date: 2026-07-16
sequence: 85
type: refactor
compatibility: compatible
component: `labkit_DICPreprocess_app` | `1.5.2 -> 1.5.3`
scope: DIC
scope: App ownership
```

## Context

The generic `+appState` package mixed three unrelated concepts: durable
align/crop undo history, mask editing and undo, and a predicate over transient
source-image cache state. The name exposed storage mechanics without helping a
maintainer find the behavior they needed.

## Decision and rationale

Group these operations by the capability that owns their invariants.
`editHistory` owns align/crop snapshots and reset behavior, `maskEditing` owns
mask canvas composition and undo snapshots, and `sourceFiles` owns the loaded
image-pair predicate. None is promoted to LabKit because the project fields,
undo limits, image semantics, and operation order are specific to DIC
Preprocess.

## Changes

- Moved four edit-history operations into `+editHistory`.
- Moved five mask composition/history operations into `+maskEditing`.
- Moved the image-pair readiness predicate into `+sourceFiles`.
- Updated actions, presenters, preview requests, and direct state tests to use
  the capability paths.
- Removed the generic `+appState` package without adding an adapter.

## User and developer impact

All controls, calculations, undo limits, project fields, masks, alignment/crop
history, and viewport behavior are unchanged. Code navigation now starts from
the user capability rather than an undifferentiated state bucket.

## Compatibility and migration

This is an app-internal ownership change. Project payloads and public GUI-free
scientific APIs are unchanged, so saved projects require no migration.

## Validation

State tests cover history trimming, reset/restore behavior, mask composition,
and image-pair readiness through the new capability paths. The full DIC
Preprocess unit and hidden GUI workflows verify the unchanged callers.

## Evidence

- [DIC Preprocess](../../../../apps/dic/dic-preprocess/README.md)
- [Architecture](../../../../development/architecture.md)

## Known limitations and follow-up

`definitionActions.m` remains a large but cohesive workflow coordinator. Its
callbacks will be compared with other interaction-heavy image Apps before any
further extraction; file length alone is not a reason to create another
technical package.
