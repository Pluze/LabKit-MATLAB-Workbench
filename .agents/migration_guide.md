# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or general
roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns active migration debt facts, reopen
triggers, and executable migration routes.

## How To Use This File

Use this file only for active migration debt, runner complexity, helper
structure, app-owned package cleanup, framework hook extraction, or an
explicitly requested executable migration route.

Before executing or adding a route:

1. Verify current facts with source scans; snapshots drift.
2. Preserve app-first ownership: workflow stays in apps, reusable mechanics
   move to `+labkit` only after the boundary test is clear.
3. Prefer behavior-backed refactors. A smaller file is not progress unless
   responsibilities become clearer and the real GUI/app path uses the helper.
4. Update this file only when migration debt is added, reduced, retired, or
   reprioritized.

When a route completes, shrink this file. Completed work should become source,
tests, docs, or guardrails, not permanent roadmap prose.

## Current Debt Snapshot

Last audited: 2026-07-14.

Active migration debt:

```text
ui-runtime-v2: active
app-project-and-result-contracts: active
```

Current facts from the architecture audit:

- Package-root app `run.m` orchestration and `+ui/runApp.m` lifecycle adapters
  are retired.
- Fourteen public apps now use Runtime V2: `chrono_overlay`, `cic`, `csc`, `eis`,
  `vt_resistance`, `dic_postprocess`, `batch_crop`, `dic_preprocess`, and
  `video_marker`, plus `rhs_preview`, `nerve_response_analysis`, and
  `response_review_stats`, `ecg_print`, and `gait_analysis`. Six public apps and
  the nested private app still use the v1 definition path.
- The five pilots use canonical project/session state, native presenters,
  registered renderers, managed interactions/resources, standard project
  persistence, and result manifests where they export files.
- Video Marker legacy projects and v1 runtime snapshots are read-only import
  formats on the V2 path. New V2 writes use `labkitProject`.
- Closure-owned state, direct control mutation, app-owned interaction/runtime
  plumbing, and no-op render paths remain migration debt only in the unmigrated
  fleet.
- `docs/ui-runtime-redesign.md` remains the target architecture. `docs/ui.md`,
  `docs/apps.md`, and `docs/architecture.md` describe contracts as they land.

## Goal Prompt: Migrate All Apps To UI Runtime V2

### Objective

Implement the target architecture in `docs/ui-runtime-redesign.md`, migrate
every public app, and retire the superseded public UI surface. Continue by
phase until all completion criteria are met or a real blocker below is reached.

The result must reduce app-author complexity and improve behavior, not merely
rename packages or move callback code into new wrappers.

### Required Read Set

Before executing this route, read:

1. `AGENTS.md`
2. the nearest scoped `AGENTS.md` for every touched source/test path
3. `docs/ui-runtime-redesign.md` completely
4. current `docs/ui.md`, `docs/apps.md`, and `docs/architecture.md` sections
   affected by the current phase
5. `docs/testing.md` only when selecting validation

Use `labkit-boundary-guard` for every proposed public API addition and
`labkit-test-planner` for validation routing. Do not add another migration
roadmap or agent handbook.

### Operating Principles

- Preserve scientific behavior, accepted inputs, formulas, defaults, plot
  meaning, workflow wording, result columns, and existing output filenames
  unless the user explicitly approves a behavior/format change.
- Framework owns mechanics; apps own domain decisions.
- Maintain one semantic state root: `state.project` plus `state.session`.
- Persist an explicit project allowlist. Never serialize a whole runtime and
  then blacklist handles one field at a time.
- Use a queued event transaction. Never solve ordering by adding another
  `updating`, `refreshing`, or `activeAxes` flag in an app.
- Use a single figure interaction hub. Apps must not restore figure callbacks.
- Keep `saveState/loadState` as the stable public persistence facade. Separate
  codec/migration, storage policy, and dialogs internally.
- Replace loaded project state after migration; do not shallow/deep merge an
  old payload with current defaults.
- Keep layout constructors readable. API reduction targets control, runtime
  utility, plot-mechanics, interaction-runtime, and debug exposure rather than
  collapsing layout into a string router.
- Do not introduce MATLAB classes, third-party runtimes, code generation, a
  global event bus, or new package naming churn.
- Do not create app-specific branches under `+labkit`.
- Work in small coherent commits. Defer broad version/changelog/test closure
  until the stable pre-PR phase as requested, but never omit that closure.

### Target Runtime Contract

All migrated definitions declare:

```text
Id
Title
Project: Version, Create, Validate, ordered Migrations, optional legacy import
CreateSession (optional)
Layout
Actions
Present
Renderers (optional)
Start (optional)
```

All migrated handlers use:

```matlab
state = handler(state, event, services)
```

All migrated state uses:

```text
state.project.inputs
state.project.parameters
state.project.annotations
state.project.results
state.project.extensions
state.session.selection
state.session.workflow
state.session.view
state.session.cache
```

No other state root fields are allowed. Project and session contain plain
serializable MATLAB data only. Runtime resources live in the framework
resource registry.

### Phase 0: Freeze And Baseline

Deliverables:

- Verify the audit metrics and all 20 public app definitions dynamically.
- Record public UI API calls by app and classify each API as target core,
  advanced compatibility, internalize, or remove.
- Record each app's current state fields, resource-like fields, project/import
  formats, exports, and GUI tests.
- Add no new public UI function during this phase.
- Treat `docs/ui-runtime-redesign.md` as the design source and this section as
  the only execution state.

Exit condition: inventories match current source, and any discrepancy is
resolved in the design/route before framework implementation begins.

```text
phase: 0/freeze-and-baseline
status: complete
completed contracts: 20 v1 definitions inventoried; 69-function UI surface and app call patterns reverified; state/resource/project/result/test inventories matched the 2026-07-14 design audit
migrated apps: none
compatibility retained: all production apps remain on v1
tests: source audit only; no executable behavior changed in phase 0
next phase: runtime kernel
blocker:
```

### Phase 1: Runtime Kernel

Implement a v2 path alongside v1 definitions so apps can migrate one at a time.

Required work:

- Add `runtime.launch` and keep old entrypoint behavior compatible.
- Add one non-recursive FIFO event queue per figure.
- Make nested `services.dispatch` enqueue instead of invoke immediately.
- Add canonical project/session state construction and validation.
- Add `Present` reconciliation and semantic layout bindings.
- Suppress user semantic callbacks during programmatic presentation commits.
- Add renderer registration so apps pass plot models, not UI registry handles.
- Add a scoped resource registry with idempotent cleanup.
- Infer utility availability from definition capabilities.
- Keep v1 `InitialState/Render/Startup` definitions operational during the
  migration; do not make a repository-wide flag day.

Minimum focused tests:

- queued nested dispatch order
- one state commit and one presentation commit per event
- rollback after action/presenter error
- bound-control normalization and callback suppression
- project-only dirty tracking
- resource cleanup on replacement/error/figure close
- v1 and v2 definition coexistence

Exit condition: a synthetic v2 app proves the kernel without changing a
production app.

```text
phase: 1/runtime-kernel
status: complete
completed contracts: launch; v1/v2 definition coexistence; canonical project/session state; non-recursive FIFO dispatch; binding and presentation commits; renderer registration; scoped resource cleanup; capability-derived utilities
migrated apps: none
compatibility retained: v1 run, startup, hydration, render, and strict snapshot behavior
tests: focused v2 and v1 runtime tests passed; buildtool changedFast passed (UI unit, representative app GUI, project, DIC unit, full framework UI GUI)
next phase: figure interaction hub
blocker:
```

### Phase 2: Figure Interaction Hub

Required work:

- Create one hub per app figure and register preview targets by semantic id.
- Route wheel input to the pointer target without click activation.
- Own drag capture/release and all figure `Window*Fcn` callbacks centrally.
- Reconcile controlled interaction specs from presentation state.
- Support atomic grouped targets for paired/multi-axes tools.
- Ensure programmatic value synchronization never emits user edit events.
- Keep transient pointer motion hub-local and dispatch configured preview or
  commit events only.
- Adapt existing anchor, rectangle, scale-bar, popout, and zoom behavior to the
  hub before deleting their compatibility wrappers.

Minimum focused tests:

- two and three preview axes with hover wheel routing
- controls/empty figure areas do not consume axes wheel behavior
- grouped two-axes acquire/release and fallback behavior
- drag error cleanup and callback restoration
- controlled tool update versus user edit event
- target deletion and figure close disposal

Exit condition: framework GUI tests prove multi-axes behavior without an app
fallback callback chain.

```text
phase: 2/figure-interaction-hub
status: complete
completed contracts: one hub per v2 figure; semantic preview targets; hover wheel routing and default zoom; central pointer/drag callbacks; atomic grouped sessions; controlled anchors, paired anchors, rectangle, and scale-bar reference reconciliation; programmatic callback suppression; scoped disposal
migrated apps: none
compatibility retained: v1 axes-scoped interaction runtime and existing anchor, rectangle, scale-bar, popout, and zoom helpers
tests: focused Runtime V2 kernel and interaction-hub tests passed; full framework UI suite passed 20/20, including three-target routing, grouped routing/release, empty-area fallback, drag error cleanup, controlled update versus user edit, target deletion, figure disposal, and all v1 interaction compatibility tests; final buildtool changedFast passed all routed UI unit, representative app GUI, project, and framework UI GUI checks
next phase: state persistence and result manifests
blocker:
```

### Phase 3: State Persistence And Result Manifests

Required work:

- Keep `runtime.saveState/loadState` signatures as the stable public facade.
- Implement safe MAT inventory detection for `labkitProject`, `snapshot`, and
  app-declared legacy variables.
- Add the versioned `labkitProject` envelope and app payload migrations.
- Persist only project plus optional non-authoritative resume data.
- Separate explicit-file, recovery, and test-memory storage policies from the
  project codec and dialogs.
- Validate, migrate, resolve sources, and construct a fresh session before one
  live-state commit.
- Add atomic write/readback/replace behavior.
- Add dirty title/close guard, debounced autosave, bounded recovery generations,
  and recovery discovery/confirmation.
- Do not silently reopen the last explicit project by default.
- Add a read-only v1 snapshot adapter path.
- Add a read-only Video Marker legacy project adapter path.
- Add the JSON-safe `labkit.result` manifest and standard output-resource
  records based on the target design.

Minimum focused tests:

- current project round trip
- every ordered payload migration step
- newer supported minor fields survive read-save
- newer major and wrong app id reject before mutation
- migration/validation/relink cancellation leaves live state unchanged
- no shallow merge with current defaults
- legacy snapshot and Video Marker fixture imports
- atomic-write failure preserves the prior project
- autosave runs only after idle successful commits and never during drag/load/export
- recovery does not overwrite an explicit project
- result resource path traversal rejection, relative path normalization, size,
  hash, success, and partial failure records

Exit condition: the persistence engine is app-neutral and one synthetic app can
save/open/recover/migrate without app-owned dialog or autosave code.

```text
phase: 3/state-persistence-and-result-manifests
status: complete
completed contracts: stable dual-path saveState/loadState facade; MAT inventory detection; versioned labkitProject envelope; ordered app payload migrations; full project replacement plus fresh session; additive field preservation; source resolution and cancellable relinking; atomic readback/replace writes; dirty title and close wording; debounced two-generation recovery with explicit confirmed reopen; read-only snapshot and declared legacy-variable adapters; JSON-safe labkit.result manifests with normalized relative paths, file size, SHA-256, partial failures, and project provenance
migrated apps: none
compatibility retained: strict v1 snapshots; app-declared legacy adapters are read-only and all subsequent v2 writes use labkitProject
tests: focused Runtime V2 persistence test passed for current round trip, sequential migration, newer minor preservation, newer major/wrong app rejection, no default merge, snapshot import, relink cancellation, atomic-write preservation, recovery, result traversal rejection, size/hash, and partial failure records; full framework UI suite passed 21/21; final buildtool changedFast passed all routed UI unit, representative app GUI, project, and framework UI GUI checks
next phase: archetype pilots
blocker:
```

### Phase 4: Archetype Pilots

Migrate these apps in order. Do not start the full fleet until all five expose
and resolve framework gaps without adding app-id branches:

1. `chrono_overlay`: simple functional state, ordinary plot, single-file export
2. `dic_postprocess`: multiple sources, image/overlay rendering, table/image export
3. `batch_crop`: state-driven batch workflow, rectangle/scale tools, multi-file export
4. `dic_preprocess`: paired axes, point matching, crop/mask tools, hover wheel routing
5. `video_marker`: long-lived annotations, autosave/recovery, legacy project import

Each pilot must use the exact per-app checklist below. If a pilot needs a
framework mechanic, implement it app-neutrally and retest the earlier pilots.
Do not add a pilot-only compatibility surface to the final authoring API.

Exit condition: the simple, plot-heavy, batch-interaction, multi-axes, and
durable-project archetypes all work through the same target contracts.

```text
phase: 4/archetype-pilots
status: complete
completed contracts: five app-neutral V2 functional paths; dynamic presentation constraints before bindings; optional app-owned resume creation/application; service-owned input dialogs; reusable scale-bar geometry; framework-owned workflow-log presentation and source upsert; source-only Chrono Overlay and DIC Postprocess projects; source-linked Batch Crop tasks with decoded inputs in session caches and ordered v1-to-v2 migrations; Video Marker framework recovery and read-only legacy project import
migrated apps: chrono_overlay; dic_postprocess; batch_crop; dic_preprocess; video_marker
compatibility retained: v1 runtime for the remaining public/private fleet; strict v1 snapshot imports; named Video Marker legacy project import; published scientific inputs, calculations, plots, outputs, and workflow behavior
tests: all five pilot unit/GUI suites passed at their checkpoints; Batch Crop ownership checkpoint passed 39 image-family unit/guardrail tests and its GUI workflow through buildtool changed; Chrono source-only follow-up passed its unit contract and two GUI workflows
next phase: full app migration waves, beginning with the four electrochem apps
blocker:
```

Author-cost audit against pre-V2 commit `6bfd74c8`:

| Pilot | Production lines before -> after | Largest file before -> after | Audit decision |
| --- | ---: | ---: | --- |
| `chrono_overlay` | 902 -> 919 | 194 -> 180 | retain explicit source-only project migration and session DTA reconstruction; shared workflow services still reduced the main action file |
| `dic_postprocess` | 946 -> 1084 | 224 -> 209 | retain app-owned source decoding, result summaries, and overlay contracts |
| `batch_crop` | 3368 -> 3832 | 619 -> 625 | retain explicit task/source/cache assembly and v1 project migration; decoded pixels no longer live in durable tasks |
| `dic_preprocess` | 2327 -> 2127 | 637 -> 612 | naturally smaller after runtime interaction and source services |
| `video_marker` | 2489 -> 2696 | 649 -> 536 | retain domain-owned skeleton, annotation, tracking, import, export, and recovery workflows |

Production line count is audit evidence, not an acceptance threshold. A pilot
may grow when the added code makes durable project, ephemeral session, cache,
resource, migration, or result ownership explicit. Simplify repeated
app-neutral mechanics in the framework, but do not inline cohesive app
contracts, invent a universal workflow DSL, or obscure workflow order merely
to reduce file or line counts.

### Phase 5: Full App Migration Waves

Apps already completed as pilots are not repeated. Migrate remaining apps by
archetype so one framework issue is solved once per wave.

| Wave | App | Durable project focus | Resource/session focus |
| --- | --- | --- | --- |
| Electrochem | `cic` | DTA source records, selected curves, integration parameters/results | current curve and axes view |
| Electrochem | `csc` | DTA sources, scan rate, curve/result settings | remove direct control mutation/no-op render |
| Electrochem | `eis` | DTA sources and plot/export parameters | axis choice and zoom view |
| Electrochem | `vt_resistance` | DTA sources, fit parameters/results | current item and plot view |
| Neuro/wearable | `rhs_preview` | RHS source records, protocol/filter definitions | channel/time selection; remove closure state |
| Neuro/wearable | `nerve_response_analysis` | source records, analysis parameters, annotations/results | review selection and preview cache |
| Neuro/wearable | `response_review_stats` | source records, review/statistics parameters/results | review selection |
| Neuro/wearable | `ecg_print` | recording source, import/filter/segment settings, events/measurements | selected channel/segment and plot view |
| Gait | `gait_analysis` | pose source, analysis options and reproducible results | preview mode and current selection |
| Image | `curvature` | image source, curve points, calibration, fit/length results | controlled curve editor; remove handle state |
| Image | `image_enhance` | source records, ordered steps, per-item settings, export preferences | preview caches; remove ROI/listener state |
| Image | `image_match` | source/reference records, ordered match steps, export preferences | preview caches and current item |
| Image | `flir_thermal` | thermal sources, display parameters, measurements/ROIs | current item and controlled ROI resources |
| Image | `focus_stack` | image source records, alignment/stack settings and results | preview caches/mode |
| Special | `figure_studio` | imported figure reference or extracted plot model plus style | axes/graphics resources outside state |

```text
phase: 5/full-app-migration-waves
status: in progress
completed contracts: CIC source-only project, durable analysis/view parameters, session-owned decoded and analyzed DTA cache, native presenter and registered axis renderer, standard result manifest; CSC source-only project, bound comparison/plot settings, session-owned curve selection and decoded DTA cache, pure comparison/table/two-axis presentation, and result manifests for both export forms; EIS source-only project, bound plot/export parameters, session-owned multi-file selection and decoded cache, pure summary/overlay presentation, and standard result manifest; VT Resistance source-only project, bound resistance/plot settings, session-owned decoded and analyzed DTA cache, pure summary/table/two-axis presentation, and standard result manifest; app-neutral controlled interval drag and semantic wheel events; RHS Preview portable RHS/protocol/filter sources, durable channel/filter decisions, session-owned header/index/window caches, pure presentation, controlled waveform interval/zoom, and manifests for both JSON outputs; Nerve Response Analysis portable filter/protocol sources, durable analysis limits/export record, session-owned parsed JSON/analysis cache, bound parameters, pure presentation and registered count/issue renderer, and standard JSON manifest; Response Review Stats portable analysis/segment source, durable metric windows/export record, one cohesive cache rebuild path, session-owned metrics/summary/aligned data, pure presentation and registered preview, and standard CSV manifest; ECG Print portable recording source, durable import/channel/ROI/filter/segment/view parameters and compact analysis/export results, session-owned decoded signal/event/segment/template/measurement caches, pure four-axis presentation, model-based PNG export, and manifests for both exports; Gait Analysis portable pose source, durable role/calibration/detection parameters and analysis/export results, session-owned decoded pose/fingerprint/output convenience, bound options, pure trajectory/angle/step renderer, and four-output manifest
migrated apps: cic; csc; eis; vt_resistance; rhs_preview; nerve_response_analysis; response_review_stats; ecg_print; gait_analysis
compatibility retained: CIC calculations, threshold defaults, pulse modes, summary meanings, plot annotations, 8-column batch table, and 14-column CSV contract; CSC CV/CT parsing, all/single-cycle selection, comparison modes, edge-cycle filtering, plot/trim behavior, six-column visible table, full all-cycle CSV, and point-level CV CSV contracts; EIS axis choices, multi-selection, Nyquist/Bode plotting, log-axis behavior, summary, and plot-data CSV contract; VT Resistance pulse detection, steady-window and voltage modes, resistance calculations, double-axis annotations, 9-column batch table, and 15-column CSV contract; RHS lazy index/window reads, adaptive pan/zoom, waveform ROI, protocol draft, manual filter curation, and existing JSON schemas/filenames; Nerve Response Analysis filter/protocol semantics, recording limits, analysis calculations, counts/issues preview modes, summary/details, default output folder, and JSON filename/schema; Response Review Stats JSON/CSV input semantics, metric windows, automatic reload, Summary/Aligned preview, summary/details, default output folder, and CSV filename/schema; ECG import overrides, channel/ROI/filter/peak/segment/template settings, four plot meanings, summary rows, segment CSV columns, waveform PNG, and filenames; gait pose parsing, role/calibration/detection options, duplicate-run semantics, trajectory/angle/step previews, summary/step tables, four CSV filenames/schemas, and output-folder workflow
tests: CIC export/project/presenter, view, and calculation tests plus hidden GUI load/recompute/plot/export/project-reopen workflow passed 9/9; CSC 42-test electrochem non-GUI selection and hidden GUI load/compare/plot/export/project-reopen workflow passed at the migration checkpoint; EIS hidden GUI load/selection/log-plot/export/project-reopen workflow passed at its focused checkpoint; VT Resistance passed 42/42 electrochem non-GUI tests and its hidden Runtime V2 load/recompute/plot/export/project-reopen workflow; Runtime V2 interaction-hub tests passed 3/3 including interval wheel routing; RHS Preview passed 33/33 neurophysiology non-GUI tests and its hidden indexing/preview/filter/export/project-reopen workflow; Nerve Response Analysis hidden analyze/export/manifest/project-reopen/cache-rebuild workflow passed at its focused checkpoint; Response Review Stats hidden auto-load/preview/export/manifest/project-reopen/cache-rebuild workflow passed at its focused checkpoint; ECG Print passed 27/27 wearable non-GUI tests and its hidden parse/analyze/four-axis/export/manifest/project-reopen/cache-rebuild workflow; Gait Analysis passed 21/21 gait non-GUI tests and its hidden load/analyze/preview/four-CSV/manifest/project-reopen/cache-rebuild workflow
next app: curvature
blocker:
```

Phase-5 author-cost evidence against pre-V2 commit `6bfd74c8`:

| App | Production lines before -> after | Largest file before -> after | Audit decision |
| --- | ---: | ---: | --- |
| `cic` | 2032 -> 2223 | 331 -> 332 | retain explicit project/session/presentation/export ownership and centralized workflow enums; revisit only mechanics repeated by later apps |
| `csc` | 2267 -> 2271 | 644 -> 316 | retain the near-neutral total after bindings and pure presentation; deleted direct-control refresh orchestration and two dialog-only export wrappers |
| `eis` | 903 -> 1001 | 200 -> 201 | retain explicit source/session/presenter/result contracts; removed UI-registry reads and no-op refresh actions, while axis-label ownership is centralized |
| `vt_resistance` | 1558 -> 1689 | 253 -> 218 | retain explicit source/session/presenter/result contracts and domain-owned dual-axis annotations; removed direct-control rendering, UI-derived analysis options, startup action, and no-op plot refresh |
| `rhs_preview` | 2396 -> 2371 | 643 -> 463 | naturally smaller after replacing closure state, direct-control refresh, figure callback ownership, dialog wrappers, and debug glue with bindings, pure presentation, controlled interval interaction, and runtime services |
| `nerve_response_analysis` | 2068 -> 2221 | 391 -> 391 | retain domain algorithms and accept explicit project/session/presentation contracts; action code stayed neutral at 252 -> 251 while startup, direct-control reads, manual log mutation, and full-control refresh were removed |
| `response_review_stats` | 1133 -> 1225 | 244 -> 174 | retain explicit contracts and one cohesive input-to-cache rebuild helper; action code fell 244 -> 174 without new framework API while startup, direct-control reads, duplicate parsing paths, and full-control refresh were removed |
| `ecg_print` | 1119 -> 1352 | 286 -> 289 | accept explicit project/session/presentation/result contracts and keep app-owned biosignal workflow; removed startup, all control reads, manual ROI writes, no-op refresh, UI-axis export, and monolithic four-axis render while reusing the same pure waveform model for preview and PNG export |
| `gait_analysis` | 1413 -> 1493 | 474 -> 474 | retain the large app-owned gait algorithm/parser and accept explicit contracts; action code fell 207 -> 183 while startup, UI-derived option snapshots, direct controls, raw pose persistence, stale-result export, and monolithic render were removed |

Pilot durable/resource focus:

| App | Durable project focus | Resource/session focus |
| --- | --- | --- |
| `chrono_overlay` | DTA sources and plot/export parameters | current selection and plot view |
| `dic_postprocess` | MAT/reference/mask sources and display/export parameters | prepared overlays and preview selection |
| `batch_crop` | source records, crop centers/angles/scales/output preferences | canvas cache and controlled tools outside state |
| `dic_preprocess` | image sources, alignment/crop/mask/match annotations | paired/mask/crop resources outside state |
| `video_marker` | video source, skeleton, annotations, calibration, export preferences | current frame/image cache and controlled editors |

### Per-App Migration Checklist

Execute every item for one app before marking it migrated:

1. Read its definition, initial state, actions, layout, visible update,
   workflow helpers, result writers, unit tests, and GUI workflow tests.
2. Record current behavior and export names. Do not infer scientific intent
   from another app.
3. Classify every state field as durable project, ephemeral session, derived
   cache, or runtime resource. A field may have exactly one owner.
4. Create the five required project buckets and four required session buckets.
5. Move handles, listeners, editors, timers, figures/axes, debug/services, and
   tool structs into managed resources.
6. Add the app project spec: current payload version, create, validate, ordered
   migrations, source records, and any justified legacy import.
7. Convert closure/nested state handlers to named
   `(state,event,services)->state` handlers.
8. Replace trivial control get/set callbacks with layout bindings.
9. Replace direct control mutations and `refreshAll` with one deterministic
   presenter.
10. Register prepared plot renderers; do not pass app UI registries into
    calculations or project helpers.
11. Express active tools as controlled presentation interaction specs.
12. Route save/open/autosave/recovery through `saveState/loadState` services;
    remove app-owned persistence controllers after compatibility tests pass.
13. Preserve existing result files and add one standard result manifest.
14. Add project round-trip, migration/legacy, presenter, and result-manifest
    unit tests using synthetic non-sensitive data.
15. Update the existing hidden GUI workflow test to exercise the real v2 path.
16. Search the app for old control/runtime/interaction calls and delete unused
    adapters only after the new path is covered.
17. Review the diff for thresholds, labels, filenames, columns, or workflow
    changes. Revert any unapproved drift.
18. Record the app as complete in the phase checkpoint only when focused tests
    pass or an exact deferred-validation reason is recorded.

### Phase 6: Surface Reduction And Current Documentation

After every public app and test uses v2:

- Recompute public API usage dynamically.
- Internalize or delete normal app-facing `control.*` setters/getters.
- Remove app construction of interaction runtimes and obsolete callback-chain
  compatibility code.
- Fold runtime dialogs, titles, dispatch, busy, portable references, project,
  result, and debug mechanics behind launch/services while retaining the stable
  `saveState/loadState` facade.
- Keep only proven advanced plot/interaction helpers.
- Remove unused `Startup`, `Hydrate`, `Snapshot`, action effects, v1 definition,
  and v1 render paths after compatibility fixtures cover supported imports.
- Update `docs/ui.md`, `docs/apps.md`, and `docs/architecture.md` to describe
  the landed contract.
- Merge any durable rationale from `docs/ui-runtime-redesign.md` into the
  current docs, then delete or relabel the proposal so two architectures are
  not presented as current.
- Update scoped `AGENTS.md` and skills only where the target authoring contract
  changes their execution rules.
- Shrink this guide back to a compact ledger after all completion criteria pass.

Target final public surface: at most 32 `labkit.ui` public function files and
at most 20 concepts in the new-app quick-start path. Do not meet the number by
combining unrelated behavior into vague string dispatchers.

### Validation Cadence

Honor the requested staged cadence:

- Do not run broad checks after every helper or callback edit.
- During framework phases, run the smallest reusable UI unit/GUI selection that
  proves the new invariant.
- During an app wave, run focused app-owned unit and hidden GUI suites after a
  coherent app or wave checkpoint, not every file edit.
- Run `buildtool changedFast` at stable framework/pilot/wave checkpoints only
  when its broader routing adds information.
- Treat `buildtool changed` as the final stable changed-file gate, not the
  iteration loop.
- Before the final PR, run `buildtool changed`, `buildtool baseMatlab`,
  `buildtool headless`, and `buildtool gui` unless a broader completed gate
  demonstrably covers one of them. Diagnose failures with the narrowest owning
  suite before rerunning a final broad gate.
- Manually validate pointer/wheel/drag behavior for DIC Preprocess, Batch Crop,
  Curvature, Image Enhance/Match, Video Marker, and Figure Studio. Do not claim
  hidden GUI tests prove visual feel or interactive scientific correctness.
- Run MATLAB and GitHub/CI commands with host escalation as required by
  `AGENTS.md`.

### Version And Changelog Closure

Per the user's instruction, do not spend every intermediate commit resolving
all app versions, changelog records, and broad gates while the architecture is
still moving. Before the final PR:

- bump the UI facade version according to the final public contract change
- bump every changed app version from the latest mainline baseline
- update `CHANGELOG.md` with coherent framework/app evolution records and
  compatibility notes
- validate changelog metadata with the canonical release parser
- make no claim that interim version guardrails pass until this closure lands

Do not publish a release or remove a supported legacy reader as part of the
migration unless the user separately requests it.

### Non-Goals

- No scientific redesign.
- No output-column or filename cleanup hidden inside the migration.
- No new third-party dependency.
- No conversion of structs to MATLAB classes.
- No monolithic app or single launcher replacement.
- No public helper promoted from one app without the boundary test.
- No line-count-only extraction campaign.
- No deletion of old readers before real compatibility fixtures pass.

### Real Blockers

Stop and request direction only when:

- preserving a published project/result format conflicts with the target and
  source/tests cannot determine the intended compatibility behavior
- a change would alter scientific results or user-facing workflow meaning
- MATLAB behavior proves a framework invariant impossible after a minimal
  reproducible framework test and documented alternatives
- a required source format or private compatibility fixture is unavailable and
  cannot be represented synthetically
- permissions/runtime access prevent required final validation or git handoff

Large scope, hard code, temporary test failures, or an incomplete migration
wave are not blockers.

### Completion Criteria

All conditions are required:

- all 20 public apps use v2 definitions and the canonical state root
- zero closure-owned duplicate semantic state
- zero no-op presenter contract
- zero UI handles/listeners/tools/services in semantic app state
- zero production app calls to `labkit.ui.control.*`
- zero production app construction of `labkit.ui.interaction.runtime`
- zero app-owned figure callback restoration
- one queued event loop and one interaction hub per figure
- DIC paired matching stays on the main page and wheel target follows hover
- every app saves and reopens a current project through `saveState/loadState`
- every app has current payload validation and required migration tests
- supported v1 snapshots and legacy Video Marker projects import read-only
- every result export has a valid standard manifest while preserving prior files
- public UI surface meets the target without vague API consolidation
- current human docs and agent rules describe only the landed architecture
- final version/changelog closure is complete
- required focused, changed, base-MATLAB, headless, GUI, manual, and CI evidence
  is recorded without overstating coverage
- this active route is removed or reduced to exact remaining debt

### Phase Checkpoint Format

At the end of a phase, update this route with only:

```text
phase: <number/name>
status: complete | active | blocked
completed contracts: <short list>
migrated apps: <dynamic list>
compatibility retained: <short list>
tests: <commands and result or exact deferral>
next phase: <one line>
blocker: <only when real>
```

Do not append chronological diary entries or per-file logs.

## Reopen Triggers

Open a new active route here only when current scans expose concrete debt:

- a package-root app `run.m` or `+ui/runApp.m` reappears
- a new app uses broad technical buckets such as `+actions`, `+state`, `+ui`,
  `+view`, `+ops`, `+io`, or `+export`
- a substantive change would add unrelated behavior to a budget-watchlist
  action table without a responsibility audit
- helper-quality audit reports new `inline-or-merge-candidate` rows after
  excluding valid contracts such as app entrypoints, `requirements.m`,
  `version.m`, workflow layout builders, state factories, input policies,
  framework adapters, and action-driven side-effect boundaries
- a new app entry point appears without dedicated GUI coverage
- hidden workflow validation needs a new app-neutral driver operation or
  app-owned test hook to avoid OS/modal dialogs
- current JUnit timing or profiler evidence identifies a new test-performance
  hotspot whose fix would change runner behavior, validation policy, or
  app/workflow coverage
- migration exposes package-boundary drift that cannot be fixed locally without
  a new `+labkit` API decision

## Compatibility Queue

The DTA facade intentionally keeps legacy bridge fields beside canonical
unit-explicit fields. This is compatibility debt, not current cleanup debt.

Do not remove fields such as chrono `t`, `Vf`, `Im`, `alignTime`, `tAligned`,
or EIS `Pt`, `Freq`, `Zreal`, `Zimag`, `negZimag` during ordinary runner
cleanup. A removal requires an explicit DTA major-version route after
electrochem apps and tests have moved to canonical fields.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral
foundation with UI, image, DTA, RHS, thermal, and biosignal facades.
App-specific calculations, summaries, plots, exports, workflow wording, file
conventions, and result schemas stay under the owning app tree.

Migration progress means:

- a responsibility boundary becomes clearer
- deterministic behavior becomes directly testable
- the real GUI or app path uses the extracted helper
- duplicate app-neutral mechanics are removed from apps
- total workflow cognitive load falls

Migration is not progress when it only moves a large block, creates tiny
cosmetic helpers, hides app workflow behind generic names, adds noisy
guardrails, or adds docs without retiring stale debt or clarifying an active
contract.

Use `labkit-boundary-guard` before promoting behavior to `+labkit`. Use
`labkit-test-planner` for validation routing and `docs/testing.md` for exact
commands.
