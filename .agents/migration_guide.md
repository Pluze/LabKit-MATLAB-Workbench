# Agent Migration Guide

This is the agent-facing migration ledger for LabKit app-runner migrations and
debt burn-down. It combines the former runner migration maps and future design
handbook into one operational source for agents.

Human-facing architecture and behavior contracts remain in `docs/`. This guide
owns migration procedure, current debt status, target direction, and tactical
runner maps. It is long-lived while migration debt exists, but it should shrink
as debt is resolved rather than become a second architecture manual.

Lifecycle contract:

- Update this guide when migration debt is added, reduced, retired, or
  re-prioritized.
- Keep current facts aligned with `docs/architecture.md`,
  `docs/testing.md`, `tests/integration/project/ProjectDebtGuardrailTest.m`,
  and `tests/integration/project/ProjectDocumentationGuardrailTest.m`.
- Do not copy agent execution procedure into human docs. Human docs may point
  here when maintainers need the active migration roadmap.
- When no active migration debt remains, replace the active roadmap with a
  concise completed-baseline note or remove the roadmap section.
- Use `labkit-migration-planner` for migration audits, recent-history reviews,
  debt scans, and updates to this guide.

## North Star

LabKit should stay:

```text
small stable foundation + focused apps + explicit compatibility contracts
```

Apps are first-class products. `+labkit` is a small foundation with UI, DTA,
and biosignal facades. App-specific workflow logic belongs under the owning
app tree, preferably in app-owned packages once the app grows beyond a small
single-file entry point.

## Current Debt Snapshot

Current facts:

- Oversized app entry points: none.
- Oversized app runners over 500 lines: CIC and CSC only.
- App `private/` debt: `apps/dic/private/`, currently remaining DIC
  Postprocess helper debt only. Initial `dic_postprocess.view` helpers have
  moved into an app-owned package.
- Completed app package migrations: ECG Print and DIC Preprocess.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
- Private helper contract debt remains in parts of `+labkit`.

Executable sources of truth:

- `ProjectDebtGuardrailTest.expectedOversizedRunnerDebtFiles`
- `ProjectDebtGuardrailTest.expectedAppPrivateDebtFiles`
- `ProjectDocumentationGuardrailTest.expectedPrivateContractDebtFiles`
- `ProjectStructureGuardrailTest` package and startup path checks

When debt shrinks, update the code, tests, and this guide in the same change.
Do not keep stale debt entries as documentation.

## Health Signals

Use recent git history and current debt facts to decide whether migration work
is helping:

- Healthy: refactors remove legacy surfaces, preserve public app behavior, add
  direct tests for extracted behavior, keep CI green, and reduce this guide.
- Risky: refactors mostly move files, split tiny helpers without reducing
  runner complexity, add guardrails for unstable internals, or expand
  governance faster than debt shrinks.
- Stop condition: once a runner mostly owns callbacks, axes side effects,
  alerts, and refresh ordering, do not keep extracting unless a new
  deterministic view-model or export contract appears.
- Management signal: a red CI run must lead to a focused fix before more
  migration work; repeated red pushes mean the migration batch is too large.

## Migration Standard

A healthy runner owns orchestration only:

- launch and debug wiring
- GUI shell construction
- app state coordination
- callback registration
- alerts and user-facing log wording
- refresh ordering

A runner should not own deterministic calculations, export table schemas,
parser/import option normalization, result summary construction, axis-value
generation, or local copies of behavior that already exists in an app-owned
package.

Every extraction from a runner must satisfy all of these:

- the real GUI path calls the extracted helper
- the helper has a direct unit test when it is not pure UI construction
- the public app launch command and app behavior stay unchanged
- app-specific workflow logic stays under the owning app tree
- no new `private` runner, `*Workflow.m`, or string-dispatch layer is created

Moving a large runner into another large helper is not progress. Progress means
directly testable behavior leaves the runner and the real GUI path calls that
behavior.

## App-Owned Package Target

Use this shape for nontrivial app migrations:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/+ui/
apps/<family>/<app_slug>/+<app_slug>/+state/
apps/<family>/<app_slug>/+<app_slug>/+ops/
apps/<family>/<app_slug>/+<app_slug>/+view/
apps/<family>/<app_slug>/+<app_slug>/+export/
apps/<family>/<app_slug>/+<app_slug>/+io/
```

Create only the component packages the app actually needs.

| Package | Owns |
| --- | --- |
| `+ui` | App-specific control construction and layout assembly. |
| `+state` | Default state/result structs and state normalization. |
| `+ops` | Deterministic calculations, transforms, and analysis kernels. |
| `+view` | Summary rows, display tables, plot-data preparation, labels. |
| `+export` | CSV/image export table builders and output contracts. |
| `+io` | App-local file option normalization and workflow-specific readers. |

Keep `+labkit` growth conservative. A helper may move into `+labkit` only when
it is domain-neutral, app-state-free, directly testable, useful to multiple
real apps or a whole workflow family, and clearer as a public facade than as
app-local code.

## Current Oversized Runner Inventory

| Runner | Family | Current status | First useful reduction |
| --- | --- | --- | --- |
| `apps/electrochem/cic/+cic/+ui/runApp.m` | electrochem | App-owned package owns CIC computation, table/export helpers, current-file summary text, and plot request preparation. Runner still owns axes drawing and annotation side effects. | Stop shrinking unless a future deterministic view-model appears; otherwise move to the next oversized runner. |
| `apps/electrochem/csc/+csc/+ui/runApp.m` | electrochem | App-owned `+ops` and small `+view` helpers exist, including trim overlay, comparison readout, and plot request preparation. Runner still owns callback orchestration and axes drawing. | Keep shrinking only if another deterministic view-model appears; otherwise move to the next oversized runner. |

When an oversized runner drops below the debt threshold, remove its `##`
file-heading map from this section and update the debt snapshot and roadmap.

## `apps/electrochem/cic/+cic/+ui/runApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| Window preset application and UI callback sequencing | runner callbacks | runner |
| DTA file/folder dialogs and session mutation | runner callbacks plus `labkit.dta` facade | runner, later app `+io` only if normalization grows |
| CIC computation | `cic.ops.computeCIC` | already extracted |
| Batch table data | `cic.view.buildBatchTableData` | already extracted |
| CSV export | `cic.export.writeResultsCSV` | already extracted |
| Current-file summary strings and mode selection | `cic.view.buildCurrentSummary` | already extracted |
| Runner-facing CIC display unit normalization | `cic.view.displayUnit` | already extracted |
| Axis data selection and title/label decisions | `cic.view.plotRequest` | already extracted |
| Axes drawing, shading, limits, markers, annotations, and grid | runner plus existing `cic.view` axes annotation helpers | runner |
| UI-only axes reset, swap, refresh ordering | runner | runner |

### Next Extraction Target

CIC now has the obvious deterministic view helpers extracted. Stop shrinking
the CIC runner unless a future change exposes another directly testable
view-model that is not axes or callback choreography.

Do not move `plotOneAxis` wholesale. It still mixes axes drawing, marker
creation, window shading, title/label assignment, and checkbox-driven UI
effects.

### Direct Test Target

Direct electrochem unit tests now cover current summary strings, display unit
scaling, selected CIC mode behavior, plot request preparation, batch table
formatting, compute behavior, and export contracts. Future CIC runner edits
should add direct tests only when new deterministic behavior is extracted.

## `apps/electrochem/csc/+csc/+ui/runApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| DTA file/folder dialogs and session mutation | runner callbacks plus `labkit.dta` facade | runner |
| CV/CT CSC computation | `csc.ops.computeCSC` | already extracted |
| Curve dropdown population and default X/Y selection | runner `updateDropdowns` plus `csc.view.defaultPlotSelections` | default selection already extracted; dropdown population stays runner |
| Charge/CSC display formatting | `csc.view.formatChargeAndCSC` | already extracted |
| Comparison readout and status text | `csc.view.comparisonReadout` | already extracted |
| Trim overlay preparation | `csc.view.trimOverlayData` | already extracted |
| Trim overlay cleanup and plotting | runner local `clearTrim`, `drawTrimOverlay` axes logic | runner |
| Top/bottom plot-data, label, and log preparation | `csc.view.plotRequest` | already extracted |
| Top/bottom axes drawing | runner with `labkit.ui.view.draw` | runner |
| Reload, clear, current item selection | runner | runner |

### Next Extraction Target

CSC now has the obvious deterministic view helpers extracted. Stop shrinking
the CSC runner unless a future change exposes another directly testable
view-model that is not GUI callback choreography.

Do not move `plotTop`, `plotBottom`, or `refreshCompare` as one block. These
callbacks still mix axes drawing, UI handle updates, trim drawing, status
labels, and logging.

### Direct Test Target

Direct electrochem unit tests now cover CSC formatting, default selections,
trim overlay data, comparison readout, and plot request preparation. Future CSC
runner edits should extend those tests only when new deterministic behavior is
extracted.

## Completed Migration Baselines

### Wearable ECG Print

Current status: complete. ECG Print lives under
`apps/wearable/ecg_print/`, keeps the public command
`labkit_ECGPrint_app`, and uses `apps/wearable/ecg_print/+ecg_print/...` for
directly tested app-owned helpers.

Current responsibilities:

- `+io`: import options and file-header preview.
- `+ops`: peak method mapping.
- `+view`: import status, summary rows, waveform/template plot requests.
- `+export`: analysis table construction.
- `+ui`: app-specific control construction and runner orchestration.

Preserve these invariants:

- no direct `apps/wearable/+ecg_print` package
- no wearable private runner
- direct wearable unit tests call non-UI `ecg_print` package helpers

### DIC Preprocess

Current status: complete. DIC Preprocess lives under
`apps/dic/dic_preprocess/`, keeps the public command
`labkit_DICPreprocess_app`, and uses
`apps/dic/dic_preprocess/+dic_preprocess/...` for directly tested app-owned
helpers. Its `+ui/runApp.m` runner is below the 500-line debt threshold.

Current responsibilities:

| Class | Destination |
| --- | --- |
| Image geometry, registration support, false-color preview, and masks | `+ops/` |
| Preview and display data | `+view/` |
| Export builders | `+export/` |
| File/path defaults | `+io/` |
| Default state structs | `+state/` |
| GUI control construction | `+ui/` |
| Callback-only coordination | runner |

Preserve these invariants:

- `apps/dic/private/runDICPreprocessApp.m` stays removed
- DIC Preprocess package helpers keep direct unit coverage
- interactive point selection, crop dragging, mask drawing, and visual output
  review remain manual GUI checks unless a focused noninteractive tool test is
  added

## Active Roadmap

### Phase 0: Keep Governance Current

Goal: keep exact debt inventories trustworthy.

Actions:

- Remove debt inventory entries that no longer match current facts.
- Split broad guardrail files only when new unrelated checks are needed.
- Keep `docs/testing.md` as the only human-facing command matrix.
- Keep this guide as the only agent-facing migration roadmap.

Exit criteria:

- Oversized-runner inventory matches actual oversized runners.
- App `private/` debt inventory matches actual helper files.
- No human doc duplicates agent execution procedures.

### Phase 1: Finish CIC And CSC Runner Normalization

Goal: make oversized electrochem runners orchestration-only where further
deterministic view-models still exist.

Actions:

- Do not move axes/callback blocks wholesale.
- Extract only behavior that can be directly tested and called by the GUI path.
- Extend focused electrochem unit tests only when new deterministic behavior is
  extracted.

Exit criteria:

- No runner keeps a local copy of a package helper.
- New deterministic behavior enters package helpers first.
- CIC and CSC either fall below the 500-line threshold or keep documented maps
  because remaining code is axes/callback choreography.

### Phase 2: Migrate DIC Postprocess Private Helpers

Goal: remove the remaining app `private/` debt without damaging Ncorr strain
overlay behavior, ROI summaries, colorbar exports, or optical enhancement
controls.

Current status: active remaining app-private debt. The only allowed app
`private/` directory is `apps/dic/private/`, and its files belong to DIC
Postprocess.

Target shape:

```text
apps/dic/dic_postprocess/labkit_DICPostprocess_app.m
apps/dic/dic_postprocess/+dic_postprocess/+ui/
apps/dic/dic_postprocess/+dic_postprocess/+state/
apps/dic/dic_postprocess/+dic_postprocess/+ops/
apps/dic/dic_postprocess/+dic_postprocess/+view/
apps/dic/dic_postprocess/+dic_postprocess/+export/
apps/dic/dic_postprocess/+dic_postprocess/+io/
```

Recommended extraction order:

1. Ncorr MAT loading and app-local normalization into `+io`.
2. Strain mask, valid-mask, RGB conversion, and enhancement operations into
   `+ops`.
3. Summary table rows, colorbar-level table rows, path tags, and display text
   into `+view`.
4. Overlay and colorbar output writers into `+export`.
5. Default state/result structs into `+state` when repeated state construction
   exists.
6. App-specific control construction into `+ui`.
7. Public entrypoint relocation only after behavior helpers and direct tests
   exist.

Exit criteria:

- `apps/dic/private/` disappears or contains only narrowly justified helpers
  shared by multiple DIC apps with documented contracts.
- DIC Postprocess keeps the public command `labkit_DICPostprocess_app`.
- Direct DIC unit tests cover non-UI `dic_postprocess` package helpers.
- GUI structural tests cover launch and layout; full visual strain review
  remains manual.

### Phase 3: Complete Private Contract Hygiene

Goal: make private implementation readable enough for future refactors.

Actions:

- Finish top-of-file implementation contracts for remaining `+labkit` private
  helpers.
- Keep contracts concise: expected caller, input/output shape, side effects,
  assumptions.
- Remove stale comments that describe old app boundaries.

Exit criteria:

- No private helper contract debt inventory remains.
- New private helpers without contracts fail project guardrails.

### Phase 4: Modernize Guardrails

Goal: prevent the governance layer from becoming another large runner.

Actions:

- Split guardrails by concern when files become broad.
- Convert exact debt lists into structured inventory helpers when lists are
  still needed.
- Keep exact file-list assertions only for stable public surfaces and temporary
  debt inventories.

Exit criteria:

- A guardrail failure points to one concern.
- Debt dashboards are easy to update when debt shrinks.
- Adding a new app does not require editing unrelated project guardrails.

## Validation For Migration Work

Use `docs/testing.md` for exact commands. Default routing:

| Change | Minimum validation |
| --- | --- |
| Debt inventory, app path, package boundary, or this guide | `testProject` |
| Electrochem app-owned calculations/export/view helpers | `testAppsElectrochem`; add `testAppsElectrochemGui` for layout/wiring |
| DIC app-owned helpers or DIC migration | `testAppsDicGui` plus `testProject` |
| Wearable app-owned helpers or migration regression | `testAppsWearableGui` plus `testProject` |
| Reusable UI boundary | `testLabkitUiGui`; add affected app-family GUI tasks |

Automated GUI tests are structural. Interactive file selection, drawing,
visual inspection, and full workflow feel remain manual GUI validation.

After any push intended to complete work, inspect CI. If required CI fails,
read the failing logs, fix the underlying issue, rerun relevant local checks,
push again, and repeat until CI passes or a real infrastructure/access blocker
is reported.

## Anti-Patterns

Do not:

- move a large runner into a large helper and call it refactoring
- create public `+labkit/+analysis`, `+io`, `+data`, or `+util` surfaces for
  convenience
- put experiment-specific result schemas into reusable UI helpers
- freeze evolving app-owned package internals with exact file-list guardrails
- treat GUI structural tests as full workflow validation
- add source-string tests to prove app business behavior
- add a generic launcher that hides separate app entry points
- convert struct models to classes just to look more formal
- keep a debt exception after the reason for the exception is gone
