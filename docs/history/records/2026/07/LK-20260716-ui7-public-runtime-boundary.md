# UI 7 public runtime boundary

```labkit-change
id: LK-20260716-ui7-public-runtime-boundary
date: 2026-07-16
sequence: 75
type: refactor
compatibility: breaking
component: `labkit.ui` | `6.0.5 -> 7.0.0`
component: `labkit_DICPostprocess_app` | `1.4.0 -> 1.4.1`
component: `labkit_DICPreprocess_app` | `1.5.0 -> 1.5.1`
component: `labkit_ChronoOverlay_app` | `1.4.0 -> 1.4.1`
component: `labkit_CIC_app` | `1.4.0 -> 1.4.1`
component: `labkit_CSC_app` | `1.4.0 -> 1.4.1`
component: `labkit_EIS_app` | `1.4.0 -> 1.4.1`
component: `labkit_VTResistance_app` | `1.4.0 -> 1.4.1`
component: `labkit_GaitAnalysis_app` | `2.0.1 -> 2.0.2`
component: `labkit_BatchImageCrop_app` | `1.7.0 -> 1.7.1`
component: `labkit_CurvatureMeasurement_app` | `1.4.1 -> 1.4.2`
component: `labkit_FLIRThermal_app` | `1.4.0 -> 1.4.1`
component: `labkit_FocusStack_app` | `1.5.0 -> 1.5.1`
component: `labkit_ImageEnhance_app` | `1.6.0 -> 1.6.1`
component: `labkit_ImageMatch_app` | `1.6.0 -> 1.6.1`
component: `labkit_VideoMarker_app` | `1.5.0 -> 1.5.1`
component: `labkit_FigureStudio_app` | `0.2.0 -> 0.2.1`
component: `labkit_NerveResponseAnalysis_app` | `1.4.1 -> 1.4.2`
component: `labkit_ResponseReviewStats_app` | `1.4.1 -> 1.4.2`
component: `labkit_RHSPreview_app` | `1.4.1 -> 1.4.2`
component: `labkit_ECGPrint_app` | `1.4.1 -> 1.4.2`
scope: public API ownership
scope: Runtime V2 busy and persistence mechanics
```

## Context

The UI 6 runtime exposed three implementation-level helpers alongside its App
lifecycle: direct busy-state execution and the creation and resolution of
portable file-reference structs. Production Apps did not need those entry
points. Semantic callbacks already owned busy transactions, while injected
project services and the save/load boundary owned source references.

Keeping the helpers public created two competing ways to perform the same
framework-owned work. It also made tests exercise a direct busy mode that no
production App used.

## Decision and rationale

UI 7 keeps lifecycle and semantic construction public while moving callback
transactions and reference serialization into the runtime implementation.
`labkit.ui.runtime.create` remains public: it has a distinct supported purpose
for callers that already own a complete declarative layout and need only the
workbench shell, without project lifecycle or action orchestration.

## Changes

- Removed `labkit.ui.runtime.runBusy` from the public facade. Layout actions and
  other semantic callbacks now reach one private transaction helper.
- Removed `createPortableFileReference` and
  `resolvePortableFileReference` from the public facade. Runtime save, load,
  recovery, and relink code continue to use those algorithms privately.
- Removed the unused direct-busy behavior that froze callbacks and graphics hit
  testing. Semantic transactions preserve callback-owned interaction changes.
- Updated all tracked Apps to declare the UI 7 compatibility range without
  changing their domain behavior or project payload versions.
- Replaced tests that fabricated references through a public helper with
  project-level save/move/load coverage or explicit legacy fixtures.

## User and data impact

App users see no workflow or saved-data change. App developers initiate work
through semantic actions and create source records through
`services.project.sourceRecord`; the runtime owns the corresponding busy and
serialization mechanics. Code that called the three removed UI 6 functions
must move to those lifecycle contracts before adopting UI 7.

## Compatibility and migration

The change is a deliberate public API break and therefore increments the UI
facade major version. Every tracked App now requires `labkit.ui >=7 <8`. Runtime
V2 project envelopes, App payload versions, and portable-reference field names
are unchanged, so saved projects require no data migration.

## Validation

Validation covers the exact UI package surface, semantic busy transactions,
Runtime V2 project save/move/load and relink behavior, affected App migrations,
App requirement/version consistency, generated API removal, and documentation
history contracts.

## Evidence

- [UI Framework](../../../../framework/README.md) maps the supported public
  packages and runtime entry points.
- [Runtime and Data Model](../../../../framework/guides/runtime.md) explains semantic
  transactions, injected services, and portable source behavior.

## Known limitations and follow-up

This boundary change does not redesign the lower-level declarative workbench
builder. `labkit.ui.runtime.create` remains supported and will be judged by its
own layout-only contract rather than by production App call count.
