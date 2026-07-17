# Project restore distinguishes missing sources from damaged sources

```labkit-change
schema: 2
id: LK-20260717-strict-project-session-restore
date: 2026-07-17
sequence: 125
type: fix
compatibility: compatible
component: `labkit.ui` | `7.4.6 -> 7.4.7`
component: `labkit_FigureStudio_app` | `0.2.8 -> 0.2.9`
component: `labkit_FLIRThermal_app` | `1.4.6 -> 1.4.7`
component: `labkit_FocusStack_app` | `1.5.5 -> 1.5.6`
component: `labkit_ImageMatch_app` | `1.6.6 -> 1.6.7`
component: `labkit_ImageEnhance_app` | `1.6.6 -> 1.6.7`
component: `labkit_NerveResponseAnalysis_app` | `1.4.6 -> 1.4.7`
scope: Runtime project restore
scope: App session reconstruction
```

## Context

Runtime already resolved missing required source paths and offered interactive
relinking before it rebuilt an App session. Several session factories then
caught every decoder exception and returned an empty cache. A file that still
existed but was damaged, unsupported, or exposed a programming error could
therefore look like an unresolved source or an empty project.

## Decision and rationale

Keep path resolution and cancellation in Runtime, and make reconstruction of
an existing source strict. A session factory may accept an explicitly absent
optional source, but it must not reinterpret an exception from an existing
file. Runtime wraps reconstruction failures with `inputs.sources` IDs, roles,
and filenames, records the exception in diagnostics, and preserves the prior
state and presentation.

## Changes

- Removed broad exception recovery from Figure Studio, Focus Stack, Image
  Match, Image Enhance, FLIR Thermal, and Nerve Response Analysis session
  reconstruction.
- Made FLIR restore use strict thermal decoding while retaining skip-and-report
  behavior for interactive batch import.
- Added Runtime diagnostic context and a field-specific
  `ProjectSessionRestoreFailed` error without replacing the decoder cause.
- Added atomic corrupt-source, diagnostic-delivery, cross-App factory, and
  no-broad-catch regression coverage.

## User and developer impact

Missing required files still open the relink workflow, and cancelling it leaves
the current project untouched. Existing corrupt or unsupported files now stop
the load with the relevant project source identities and filenames instead of
showing an empty preview. The prior document remains usable.

App developers can leave ordinary decoder failures uncaught in
`createSession.m`; Runtime owns the user-visible load failure and diagnostic
record.

## Compatibility and migration

No saved-project migration is required. Project envelopes and source-reference
formats are unchanged. This change only corrects failure handling while
reconstructing transient state.

## Validation

Focused validation covers successful project round trips, missing-source
relink, cancellation rollback, existing corrupt source rollback, diagnostic
delivery, all affected session factories, and the repository guardrail that
forbids broad catches in `createSession.m`.

## Evidence

- [Runtime and lifecycle](../../../../framework/runtime.md#session-actions-presentation-and-renderers)
- [Figure Studio](../../../../apps/labkit-core/figure-studio/README.md)
- [FLIR Thermal](../../../../apps/image-measurement/flir-thermal/README.md)
- [Focus Stack](../../../../apps/image-measurement/focus-stack/README.md)
- [Image Match](../../../../apps/image-measurement/image-match/README.md)
- [Image Enhance](../../../../apps/image-measurement/image-enhance/README.md)
- [Nerve Response Analysis](../../../../apps/neurophysiology/nerve-response-analysis/README.md)

## Known limitations and follow-up

Automated hidden GUI tests verify state rollback and semantic error delivery;
they do not replace manual review of native dialog wording or damaged
third-party file variants.
