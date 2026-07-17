# Migration Debt And Maturity Plan

This file is the active execution ledger for architecture migration debt.
Current supported behavior belongs in `docs/`; exact validation commands belong
in `docs/development/testing.md`; completed work belongs in component history.
Do not describe a migration area as complete while an accepted public or
private App still relies on the retired contract.

## Working order

Work in two gated stages:

1. reproduce and close every concrete defect in this ledger;
2. only after the closure gate passes, measure the stable system and make
   evidence-backed maturity improvements.

Do not mix speculative simplification into defect fixes. Each coherent repair
owns its regression test, documentation or agent-rule correction when needed,
version/history update when required by project policy, and a small independent
commit. Public and private repositories commit and push their work separately.

## Active debt

Last audited: 2026-07-17.

```text
private-app-ui7-compatibility: open-critical
app-path-isolation: open-high
project-restore-failure-semantics: open-high
retired-ui-runtime-compatibility: open-high
documentation-and-agent-contract-drift: open-high
validation-isolation-coverage: open-high
toolbox-product-debt: none
```

### Private App UI 7 compatibility

Owner:
: The independent private App repository.

Evidence:
: Imager Reconstruction still uses separate `requirements.m`, `version.m`,
  generic `startup.m`, `+appLifecycle`, `+appState`, the transitional
  three-factory launch form, and `Project.Migrations`. It declares
  `labkit.ui >=6 <7`, while the accepted public checkout provides UI 7 and
  rejects the App before launch.

Affected scope:
: `private_apps/apps/imaging/imager_reconstruction/`, its private tests,
  manual, history, and private repository rules.

Completion condition:
: The App uses one definition-owned identity/version/requirements contract,
  one `projectSpec.m`, an optional root `createSession.m`, concrete
  capability-owned packages, and UI 7-compatible requirements. A Start action
  remains only when it names real post-layout initialization. Generic
  lifecycle/state packages and split metadata files are gone.

Focused validation:
: Run the private repository tests first, then an isolated-path
  requirements/version request and hidden launch against the accepted public
  checkout. Run the relevant public structure and facade-compatibility
  guardrails intentionally because the public changed-file planner cannot see
  the nested private Git diff.

Removal condition:
: Delete this entry after the private App launches from only the public root
  plus its own App root, its current tests and documentation use the same
  contract, both repositories are pushed, and the public framework no longer
  needs source-structure compatibility for it.

### App path isolation

Owner:
: Gait Analysis for the current defect; project architecture tests for
  recurrence prevention.

Evidence:
: `gait_analysis.debug.writeSamplePack` calls `video_marker.projectSpec`,
  `video_marker.skeletonDefinition`, and `video_marker.frameAnnotations`.
  The launcher adds only the selected App root, while the test setup adds every
  public App root. Gait debug sample generation therefore passes in the shared
  test path but fails in an isolated launcher-equivalent path.

Affected scope:
: Gait debug sample generation, Video Marker-to-Gait file compatibility,
  test path setup, App dependency guardrails, and single-App packaging.

Completion condition:
: Gait production and debug code consume the documented Video Marker MAT
  format without calling the Video Marker package. A test-only integration
  check may invoke both Apps to prove producer-consumer file compatibility.
  Every App debug sample writer resolves with only the repository root and its
  owning App root.

Focused validation:
: Exercise the Gait debug writer in an isolated MATLAB path, import a current
  synthetic Video Marker project into Gait, run the Gait unit and hidden-GUI
  workflow tests, and run the App boundary and packaging guardrails.

Removal condition:
: Delete this entry when isolated debug generation and the producer-consumer
  file-contract test both pass and a general guardrail prevents production or
  debug calls into sibling App packages.

### Project restore failure semantics

Owner:
: The affected Apps for decode policy; `labkit.ui.runtime` for atomic restore,
  relinking, cancellation, and diagnostic delivery.

Evidence:
: FLIR Thermal, Focus Stack, Image Enhance, Image Match, and Figure Studio
  catch every exception while rebuilding transient session caches and present
  an empty cache. Runtime already resolves or interactively relinks required
  sources before `createSession`, so damaged, unsupported, or undecodable files
  can be mislabeled as an unresolved path and the real defect is hidden.

Affected scope:
: All App `createSession.m` factories, Runtime project restoration, source
  relinking, diagnostics, and project-load workflow tests.

Completion condition:
: Missing paths use Runtime relinking; user cancellation leaves live state
  unchanged; damaged or unsupported existing files report a field-specific
  failure and diagnostic exception; programming errors are not swallowed.
  Any intentionally recoverable catch reports through diagnostics and has a
  test for the exact recovery.

Focused validation:
: For each affected App, cover successful restore, missing-source relink,
  cancellation, and an existing corrupt or unsupported source. Verify state
  rollback, visible error semantics, and diagnostic evidence.

Removal condition:
: Delete this entry after the repository-wide `createSession` audit finds no
  unreported broad catch and the focused restore tests pass.

### Retired UI Runtime compatibility

Owner:
: `labkit.ui.runtime`.

Evidence:
: Runtime still accepts the transitional three-factory `launch` form and
  `Project.Migrations`. It also validates and builds a `toolPanel` node even
  though the public constructor is gone, no current App uses it, and component
  history says the API was replaced. Current framework documentation and some
  diagnostics still direct developers to the nonexistent constructor.

Affected scope:
: Runtime launch and project validation/read paths, layout validation and
  builders, framework tests, public UI help/manuals, facade version, and UI
  component history.

Completion condition:
: After accepted private consumers migrate, App launch uses only one
  definition; project migration uses only one version-aware `Migrate`
  callback; `toolPanel` implementation, validation, diagnostics, tests, and
  current documentation are removed. Keep only real read-only saved-data
  compatibility such as declared legacy MAT imports and supported payload
  migrations.

Focused validation:
: Search configured public and accepted private App roots for remaining
  consumers, then run Runtime definition/project/layout tests, package public
  surface and dependency guardrails, and downstream hidden-GUI App coverage
  selected by the changed-file planner.

Removal condition:
: Delete this entry when no source consumer uses the retired forms, their
  implementation branches are absent, current docs contain no active
  `toolPanel` guidance, and supported legacy data still opens through explicit
  read-only adapters.

### Documentation and agent contract drift

Owner:
: The owning manuals, public MATLAB help, agent skills/rules, and documentation
  contract tests.

Evidence:
: The complete-App tutorial repeats canonical project checks that the Runtime
  manual assigns to the framework; private App guidance still teaches retired
  files; the boundary skill assigns App metadata to `version.m`; the Runtime
  manual advertises `toolPanel`; and the migration ledger previously reported
  no debt while the defects above remained. The public-help guard checks
  section presence and at least one option but does not prove every option,
  default, legal value, error, or related API is documented. Its module scan
  omits the rendered public `labkit.ui.version` page.

Affected scope:
: Current development/framework/private-App manuals, public help, relevant
  skills and scoped rules, documentation renderer inputs, generated `site/`,
  and documentation tests.

Completion condition:
: Current manuals and agent instructions name one owner for canonical
  validation and definition metadata, describe only existing APIs, and agree
  with real public/private App structure. Every public API participates in the
  help contract. Struct options are all explained with defaults and legal
  values; errors or an explicit no-error contract and related APIs are present;
  executable examples run in a clean owning path.

Focused validation:
: Run the narrow documentation contract and renderer regression tests while
  editing, regenerate `site/` only through `renderLabKitDocs`, run `docsCheck`,
  verify links/search, and visually inspect representative changed pages when
  rendered structure changes.

Removal condition:
: Delete this entry after source help, authored manuals, agent instructions,
  generated pages, and focused tests agree. Do not claim semantic accuracy from
  a successful byte-for-byte documentation build alone.

### Validation isolation coverage

Owner:
: Project test architecture and the private repository's own test runner.

Evidence:
: The public test setup adds all public App roots, which can hide sibling-App
  dependencies. Public architecture and facade compatibility discovery covers
  public `apps/` but does not give an accepted independent private repository
  an equivalent launch-contract check. Hidden GUI tests remain intentionally
  unable to prove native dialogs, pointer feel, visual quality, real data, or
  scientific validity.

Affected scope:
: App boundary tests, debug-sample coverage, private compatibility tests,
  changed-file routing, and CI scope.

Completion condition:
: Fast isolated-path tests protect App metadata, debug samples, and package
  independence; the private repository checks its own facade compatibility;
  test documentation continues to state manual limits honestly. Evaluate a
  measured changed-App GUI smoke lane for ordinary CI without moving the full
  GUI suite out of scheduled/manual/release validation unless runtime evidence
  justifies it.

Focused validation:
: Run new isolation tests alone, then their owning contract suites. At the
  stable closure checkpoint run `buildtool changed`; reserve full GUI and
  release gates for the scopes defined in the testing manual.

Removal condition:
: Delete this entry when the known masking behavior has a regression test,
  private compatibility is protected in its owning repository, routing selects
  the new tests, and CI cost has been measured rather than guessed.

## Intentional compatibility

Read-only saved-data compatibility is not automatically migration debt.
Retain it when a current user file needs it and the current writer always emits
the current format:

- Video Marker imports its declared legacy project variable and writes the
  current `labkitProject` envelope.
- Current App project specs migrate supported older payload versions through
  one version-aware `Migrate` entry.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version decision.

Do not use a saved-data promise to justify old source layouts, launch
factories, migration callback collections, or undocumented UI nodes.

## Defect closure gate

Do not begin general architecture simplification until all of these are true:

- the accepted private Imager App is UI 7 compatible and independently tested;
- Gait debug generation works in a launcher-equivalent isolated path;
- no App production or debug package calls a sibling App package;
- missing, cancelled, damaged, and unsupported project sources have distinct,
  tested outcomes and no broad exception is silently swallowed;
- retired `toolPanel`, launch, and migration-source paths are gone after their
  consumers migrate;
- current manuals, public help, skills, tests, and generated pages describe the
  same contract;
- focused suites pass, one stable `buildtool changed` gate passes, both Git
  worktrees are clean, and coherent commits are pushed to their own remotes.

## Maturity work after closure

After the closure gate, remeasure the stable code before opening new work.
Apply these rules rather than pursuing raw file or line-count reduction.

### Progressive App capability

A static App needs only its entrypoint, definition, and data-only layout. Add
actions, presentation, durable project state, transient session reconstruction,
renderers, interactions, and Start behavior only for a demonstrated product
capability. Remove an optional component only when its owned behavior is truly
absent; do not move the same behavior into an ambiguously named helper.

### Protocols between Apps

Apps exchange versioned files or documented data structures, not implementation
calls. Producer-consumer integration belongs in tests. A shared public facade
is justified only by a domain-neutral contract with two real consumers or a
clear existing-facade owner.

### Runtime stability

Treat Runtime complexity as centralized infrastructure, not proof that it
should become public. Maintain an internal ownership map for definition,
transactions/queueing, persistence/relinking, layout, presentation,
interactions/resources, startup, and diagnostics. Refactor a hotspot only for
a reproduced defect, measured performance problem, duplicated ownership, or
unclear failure boundary.

### Failure model

Classify failures consistently:

- recoverable input problems preserve state and explain the next action;
- cancellation exits without side effects;
- damaged or unsupported data fails explicitly;
- programming errors remain visible to diagnostics and tests;
- App-owned batch policy decides whether one failed row continues or stops;
- Runtime state transactions roll back on failure.

### Performance evidence

Measure startup-to-first-visible, startup-to-first-useful-view, file
registration, selected-file decode, file switching, project restoration,
common callbacks, Run, and Export on bounded small and large synthetic inputs.
Keep selection and first preview lazy when the workflow permits it. Open
performance debt only from a reproducible profile and close it with an
outcome-based regression test or justified budget.

### Documentation as contract

Public help and manuals explain real callable behavior; examples execute;
options, units, assumptions, defaults, legal values, errors, and related APIs
are complete. `site/` remains generated. History records completed evolution,
not planned work. Stable accepted principles update existing architecture,
framework, App-development, or testing manuals rather than creating another
permanent roadmap that can drift.

### Testing and debt governance

Use direct scientific/unit tests, state and file-contract tests, bounded hidden
GUI workflows, isolation/architecture guardrails, and explicit manual checks
for native dialogs, pointer interaction, visual quality, and scientific
validity. Debt requires observable evidence, an owner, a focused test,
completion criteria, and a removal condition. File length, helper count, or a
possible future abstraction is not debt by itself.

## Maintaining this ledger

Open an entry only for a concrete current problem with ownership, behavior,
testability, performance, or cognitive load. Temporary MathWorks Toolbox use
must also record the exact source symbol, product, repository fallback,
fallback test, idempotency evidence, numeric parity outputs and tolerance, and
the condition for deleting the Toolbox branch; its machine-readable declaration
lives in `tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve the durable decision and evidence in component history when
project policy requires it. Keep this ledger compact again when every concrete
field is genuinely `none`.
