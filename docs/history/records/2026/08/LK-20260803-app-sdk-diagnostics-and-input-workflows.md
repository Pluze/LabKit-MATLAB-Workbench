# App SDK improves diagnostics, artifacts, and input workflows

```labkit-change
id: LK-20260803-app-sdk-diagnostics-and-input-workflows
date: 2026-08-03
sequence: 168
type: feat
compatibility: compatible
component: `labkit.app` | `2.1.0 -> 2.2.0`
scope: Session Log detail levels
scope: Automatic diagnostic export
scope: Automatic utility artifacts
scope: File-list validation and failure alerts
scope: Point-only paired-anchor interaction
scope: Multi-row plot composition guidance
```

## Context

The standard Session Log combined a severity selector with a second audience
view, presented an unexplained Default choice, and exposed a pause-follow
control that did not improve diagnosis. TRACE normally contained no more useful
detail than DEBUG because capture was off and Runtime emitted few trace stages.
Diagnostic ZIP export also asked for a destination before every attempt, while
screenshot and project-state saves required manual naming and destination
selection. Successful diagnostic export used MATLAB's default error icon.
File collections lacked a shared content predicate and native error-alert
fallback, and the paired-anchor interaction could inherit a connecting path
that implied meaning the App did not own. These were separate development
checkpoints but one pending App SDK transition from the mainline baseline.

## Decision and rationale

Use one three-level display contract while keeping capture cost independent of
the selected view. Retain DEBUG and higher during ordinary operation, enable
TRACE automatically after the first error, and keep an explicit capture toggle
inside the owning log window. Give TRACE distinct transaction and presentation
stage records. Treat the repository artifacts area as the first destination
for diagnostics, screenshots, and project state, generate App-specific names,
and ask for another location only after automatic output fails. Retain full
diagnostic details in memory, the viewer, and the local journal. Apply privacy
filtering only after the user explicitly chooses redacted export; complete
export retains those events and additionally includes current App state.
Complete the same SDK transition with a domain-neutral file-list predicate,
aggregate rejection notice, native file-action failure alert, and an explicit
point-only paired-anchor mode. Apps continue to own file-type meaning, alert
wording they handle directly, and scientific interaction semantics.

## Changes

- The viewer now offers Full TRACE, DEBUG, and User levels, defaults to Full
  TRACE, follows new records continuously, and removes the duplicate View and
  pause-follow controls.
- Each viewer title names its owning App, and manual TRACE capture lives in the
  viewer instead of the App Tools menu.
- Selecting an event in the viewer highlights its complete row while retaining
  the same structured-detail inspection behavior.
- ERROR and CRITICAL records enable TRACE capture for later activity; trace
  records now distinguish state update, validation, presentation, native
  commit, and rollback cleanup stages.
- Diagnostic export generates a unique App-specific filename beneath
  `artifacts/diagnostics/`; its text fallback uses the same base name, and a
  prefilled save dialog appears only when automatic output fails.
- Each diagnostic export prompts for redacted or complete-sensitive content;
  complete export preserves full events and adds the current project/session
  state as `app-state.mat`. ZIP fallback inherits the chosen privacy mode.
- Screenshot and project-state saves now generate App-specific names beneath
  `artifacts/screenshots/` and `artifacts/states/`, with chooser fallback only
  when automatic output fails.
- Successful utility exports use an information icon rather than MATLAB's
  default error icon.
- File lists can apply a caller-owned predicate to newly proposed paths,
  preserve accepted sources, and report aggregate kept/rejected counts without
  retaining rejected filenames or paths.
- Native file-panel actions surface otherwise-unhandled validation or parsing
  failures in an error alert after transactional rollback.
- Paired-anchor interactions force point rendering without a connecting path.
- Public plot-area help and the Runtime guide document how vertically arranged
  workspace-page content composes paired plot rows, including fixed-width
  scale or histogram columns, without App-owned native containers.

## User and data impact

Users can distinguish concurrent App logs, select a meaningful amount of detail
with one control, and export diagnostics without choosing a path. Redacted
diagnostics are filtered only when that export is selected. The local journal,
Session Log, complete export, and complete fallback may contain projects,
inputs, results, paths, filenames, exception locations, and decoded images;
external source files and screenshots remain excluded from bundles.
Apps can accept mixed batch selections without losing compatible inputs, and
unhandled source failures are visible instead of remaining callback output.
App authors can discover the existing multi-row plot composition pattern from
both the function help and the framework guide.

## Compatibility and migration

The App SDK change is compatible with existing version-2 App requirements and
does not change callback logging syntax, canonical event fields, projects, or
results. Existing App definitions require no migration. The removed Tools-menu
TRACE item was a Runtime utility, not an App-facing API; the same manual ability
is available in the Session Log window.

## Validation

Focused headless specifications cover three-level projection, automatic trace
activation, distinct trace stages, generated ZIP and fallback names, redacted
default export, full-detail retention, explicit state-inclusive export, and
privacy-mode-preserving fallback. Hidden-GUI specifications cover App-specific
titles, the single level selector, viewer-local TRACE control, continuous
follow, full-row event selection, complete event inspection, exports from both
entry points, and automatic screenshot/project-state artifacts. App SDK source
evidence also covers file-predicate masks, aggregate notices, preserved source
alignment, native failure alerts, and point-only paired anchors.

## Evidence

- `labkittest.run(File="+labkit/+app/+internal/SessionLogProjection.m")`
- `labkittest.run(File="+labkit/+app/+internal/SessionLogViewer.m")`
- `labkittest.run(File="+labkit/+app/+internal/SessionDiagnosticBundle.m")`
- Five focused logging/journal specifications passed 62 headless identities;
  the Session Log viewer specification passed 4 hidden-GUI identities.
- App SDK and cross-App file-entry focused specifications passed 64 identities.
- DIC hidden-GUI evidence covered point-only paired anchors and mask activation.
- Authored-link validation passed; full deterministic documentation rendering
  remains part of final PR validation.

## Known limitations and follow-up

TRACE cannot reconstruct stages that occurred before capture was enabled. A
process termination before Runtime records a terminal event still leaves only
the last successfully retained boundary. Native visual density and dialog feel
remain manual review boundaries.
