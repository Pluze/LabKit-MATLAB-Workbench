# Future Design Handbook

This handbook defines the long-term design direction for LabKit. It is a
strategic target, not a description of the current codebase. Current package
boundaries remain documented in `docs/architecture.md`, and current validation
commands remain documented in `docs/testing.md`.

The goal is to grow LabKit into a mature, low-friction MATLAB app workbench:
each lab workflow remains a directly launchable app, reusable infrastructure is
small and stable, and governance prevents debt from returning without becoming
a second implementation burden.

## Reference Models

The target design borrows practices from mature open-source projects without
copying their language stack or scale:

| Project | Practice to borrow | LabKit adaptation |
| --- | --- | --- |
| Kubernetes | Architecture governance, design proposals, API review, conformance thinking. | Use lightweight LabKit design records for large boundary changes, public facade additions, and compatibility removals. |
| JupyterLab | Small core plus extension/plugin architecture where most user-visible behavior is modular. | Treat each app as the product unit and each `+labkit` facade as a narrow platform service, not a shared dumping ground. |
| Apache Airflow | Core package plus independently managed provider packages. | Keep future device/data families as peer facades or app families; do not force them through generic `+analysis`, `+io`, or `+util` surfaces. |
| scikit-learn | Strong developer guide, API conventions, testing guidance, backward compatibility discipline. | Keep app-facing contracts explicit, keep compatibility bridges named, and require direct tests for extracted behavior. |
| pandas and Django | Deprecation policy with migration guidance and compatibility windows. | Do not delete legacy app behavior or bridge fields without a named compatibility decision, warning period, tests, and documentation. |
| VS Code | Clear local build/run/debug workflow for a large app-oriented codebase. | Keep validation and manual GUI expectations discoverable, but do not let workflow details leak into architecture docs. |

Source links are listed at the end of this document.

## North Star

LabKit should become:

```text
small stable foundation + focused apps + explicit compatibility contracts
```

The long-term shape is not a monolithic lab platform and not a generic MATLAB
framework. It is a workbench where new scientific GUI workflows can be added
quickly while existing workflows stay behaviorally stable.

The final state should have these properties:

- Public app launch commands remain stable and discoverable.
- App code is organized by workflow, not by generic technical layer.
- `+labkit` exposes only reusable, domain-neutral, app-facing facades.
- Large GUI runners contain orchestration only, not hidden scientific logic.
- Compatibility behavior is named, tested, and removable by policy.
- Documentation explains the project without duplicating execution rules.
- Guardrails enforce structural invariants without becoming large policy
  monoliths.
- Tests prove extracted behavior directly rather than proving source text.

## Current Constraints To Eliminate

These are the defects that restrict future development:

1. Large runner closures still mix state, callbacks, plotting, parsing,
   summaries, exports, and user messages.
2. DIC and wearable still carry app `private/` migration debt.
3. Some app families are cleaner than others, so the documented ideal is ahead
   of the actual code.
4. Project guardrails are effective but already large enough to need their own
   structure and exit criteria.
5. Private helper contracts are still incomplete in parts of `+labkit`.
6. GUI automation is structural; it does not prove full interactive workflow
   quality.
7. Compatibility behavior exists for good reasons, but it must remain isolated
   instead of becoming a normal dependency for new tests.
8. Exact debt inventories can become stale if they do not shrink when the debt
   shrinks.

The harsh rule: moving a large runner into another large helper is not progress.
Progress means directly testable behavior leaves the runner and the real GUI
path calls that behavior.

## Target Repository Shape

The desired long-term repository shape is:

```text
LabKit/
  +labkit/
    +ui/
      +app/       shell, tabs, dispatch, busy state
      +view/      generic panels, forms, axes, tables, logs, rendering actions
      +tool/      interaction runtimes and composed tools
      +diag/      debug context, trace sinks, instrumentation
    +dta/         Gamry/DTA app-facing facade
    +biosignal/   recording, signal, event, segment, measurement facade
    +<future>/    only when a real family earns a stable facade

  apps/
    electrochem/<app_slug>/
      labkit_<AppName>_app.m
      +<app_slug>/+ui/
      +<app_slug>/+state/
      +<app_slug>/+ops/
      +<app_slug>/+view/
      +<app_slug>/+export/
      +<app_slug>/+io/
    dic/<app_slug>/
    image_measurement/<app_slug>/
    wearable/<app_slug>/

  tests/
    unit/labkit/<facade>/
    unit/apps/<family>/
    integration/project/
    gui/structural/
    gui/gesture/
    helpers/
    fixtures/

  docs/
    README.md
    architecture.md
    apps.md
    ui.md
    dta.md
    biosignal.md
    testing.md
    future_design_handbook.md
    decisions/
      0001-example.md

  .agents/
    skills/
```

The important point is ownership, not the exact folder count. A small app may
remain one file. A larger app should grow app-owned packages before it grows a
large runner.

## Architecture Layers

### Product Layer: Apps

Apps are the product. An app owns:

- accepted inputs
- workflow defaults
- scientific formulas and thresholds
- result schemas
- plot labels and annotations
- summaries and user-facing text
- export columns and filenames
- callback ordering and alerts

An app may use `+labkit` facades, but it must not push workflow vocabulary into
`+labkit` to make its own file smaller.

### App-Owned Package Layer

App-owned packages are the normal home for extracted workflow behavior:

| Package | Owns |
| --- | --- |
| `+ui` | App-specific control construction and layout assembly. |
| `+state` | Default state/result structs and state normalization. |
| `+ops` | Deterministic calculations, transforms, and analysis kernels. |
| `+view` | Summary rows, display tables, plot-data preparation, labels. |
| `+export` | CSV/image export table builders and output contracts. |
| `+io` | App-local file option normalization and workflow-specific readers. |

App-owned package functions should be directly unit-testable. If a helper
cannot be tested without launching the app, it probably still owns GUI state and
belongs in the runner or `+ui`.

### Foundation Layer: `+labkit`

`+labkit` is a foundation, not a general-purpose grab bag. A helper can move
there only if all conditions hold:

- It has a domain-neutral name.
- It does not encode app result columns, app wording, thresholds, or export
  schemas.
- It does not read or mutate app state.
- It has a stable app-facing contract.
- It is useful to multiple real apps or a whole workflow family.
- Moving it reduces confusion, not just local file length.

Future reusable families should appear as peer facades only after real app use
proves a coherent boundary. Generic public packages named for technical
convenience, such as `+analysis`, `+io`, `+data`, or `+util`, are not acceptable
as app-facing APIs.

### Private Implementation Layer

Private helpers are allowed, but they must have a reason:

- hide parser internals
- keep facade implementation details out of app code
- support a narrow private subsystem
- avoid exposing unstable helper names

Private helpers should not be a permanent substitute for app-owned packages.
Every private debt inventory needs an exit condition.

## Runner Design

A mature app runner should own orchestration:

- launch and debug request routing
- initial state construction
- GUI shell and control wiring
- callback registration
- alert and log wording
- refresh ordering
- coordination between UI state and app-owned helpers

A mature app runner should not own:

- scientific calculations
- export table construction
- parser normalization
- result schema construction
- axis-value generation
- reusable interaction mechanics
- duplicated copies of already-extracted helpers

Recommended runner quality gates:

- More than 500 lines is always debt unless there is a documented exception.
- More than 350 lines should trigger a migration review before new features are
  added.
- New deterministic behavior should enter `+ops`, `+view`, `+export`, `+io`, or
  `+state` first, with direct tests.
- A runner migration is incomplete until the GUI path calls the extracted
  helper.

Line count is only a signal. The real target is low coupling and direct tests.

## Documentation System

The documentation system should stay layered:

| Document | Long-term role |
| --- | --- |
| `README.md` | What this project is, app list, default start path, minimal validation pointer. |
| `docs/README.md` | Human documentation map. |
| `docs/architecture.md` | Current architecture, package boundaries, and current debt exceptions. |
| `docs/apps.md` | App entry points, app ownership, app shapes, new-app checklist. |
| `docs/ui.md` | Reusable UI facade contracts and app-facing UI patterns. |
| `docs/dta.md` | DTA facade contracts and data shapes. |
| `docs/biosignal.md` | Biosignal facade contracts and data shapes. |
| `docs/testing.md` | Canonical validation matrix and GUI validation limits. |
| `docs/decisions/` | Accepted design records for durable architecture decisions. |
| `docs/future_design_handbook.md` | Long-term direction and debt burn-down roadmap. |

Human docs should describe behavior, contracts, architecture, and rationale.
Execution rules belong in scoped `AGENTS.md` files and task skills. Guardrails
should automate only the rules that are stable enough to enforce.

## Design Records

Large changes should create a lightweight design record before implementation.
This borrows the proposal discipline of large open-source projects without
creating a heavy committee process.

Use a design record when a change:

- adds or removes a public `+labkit` facade
- changes an app launch command
- changes export schemas or compatibility behavior
- migrates a private runner to an app-owned package
- creates a new app family
- changes validation or guardrail strategy
- removes a compatibility bridge

Suggested record template:

```text
# NNNN Short Title

Status: Proposed | Accepted | Superseded
Date:

## Context
What problem exists, and what current debt or limitation motivates this?

## Decision
What boundary, API, app shape, or policy is being accepted?

## Alternatives
What was rejected and why?

## Compatibility
What public launch commands, exports, fields, or behavior must remain stable?

## Migration Plan
How will the change be split into safe steps?

## Validation
What tests or manual checks prove the behavior?

## Exit Criteria
What must be true before old debt or compatibility code can be removed?
```

Design records should be short. If a record grows into a second architecture
manual, it is too broad.

## Agent Rule System

The future rule system should be intentionally small:

| Layer | Owns |
| --- | --- |
| Root `AGENTS.md` | Repository constitution, cross-cutting safety rules, documentation separation, sensitive data, git expectations. |
| Scoped `AGENTS.md` | Ownership rules for a source tree such as apps, tests, or `+labkit`. |
| Skills | Task procedure: how to plan tests, judge boundaries, or build an app. |
| Guardrails | Automated enforcement for stable structural rules. |

Rules should follow this standard:

- Every rule has an owner.
- Every debt exception has an exit condition.
- Every guardrail failure should name the violated boundary and the next action.
- No rule should be duplicated across human docs, scoped rules, and skills unless
  the duplication is deliberate and short.
- A procedural instruction should not become a human documentation requirement
  unless it changes the human-facing contract.

## Guardrail Design

Project guardrails should stay focused. The target is many small checks, not a
few giant policy files.

Good guardrails:

- protect public API surfaces
- prevent forbidden package dependencies
- prevent private runner debt from growing
- prevent source-string behavior tests from returning
- prevent sensitive sample details from entering tracked files
- ensure app-owned package helpers document implementation contracts

Weak guardrails:

- freeze exact component lists for app-owned packages that are still evolving
- encode line-count goals as success instead of using them as review triggers
- keep stale debt files after the debt has been removed
- require reading hundreds of lines to understand one failure
- duplicate current documentation prose in test assertions

Exact inventories are appropriate for stable public API surfaces. Debt
inventories should be temporary and should shrink aggressively.

## Testing System

The future testing model has five layers:

| Layer | Purpose |
| --- | --- |
| Unit tests | Direct behavior for facades, app-owned helpers, calculations, parsers, export builders, and formatters. |
| Integration tests | Project path, package boundaries, public surface, documentation ownership, fixture hygiene. |
| GUI structural tests | App launch, layout contracts, callback wiring, reusable UI tool handles. |
| GUI gesture tests | Focused noninteractive interaction lifecycle for shared tools. |
| Manual GUI scenarios | File selection, drawing ergonomics, visual output quality, full workflow feel. |

Testing principles:

- Extracted behavior must be tested directly.
- Compatibility bridges must live in named compatibility tests.
- Source scans belong only in project guardrails.
- GUI structural tests are not a substitute for real user workflow validation.
- Test helpers should not contain app formulas, scientific expected values, or
  export schemas.

## Compatibility And Deprecation

LabKit should use an explicit compatibility policy before removing legacy
behavior.

Compatibility categories:

| Category | Examples | Removal rule |
| --- | --- | --- |
| Public launch command | `labkit_ECGPrint_app` | Preserve unless a design record approves replacement and docs provide migration. |
| Public facade field | DTA canonical fields and legacy aliases | Keep bridge tests until a removal decision exists. |
| Export schema | CSV column names, units, output filenames | Treat as user-facing behavior; changes require focused tests and docs. |
| GUI wording and labels | Plot labels, summary text, alert text | Preserve unless behavior change is intentional. |
| Temporary migration debt | private runner, stale helper shape | Remove when exit criteria are met; do not preserve for compatibility. |

Deprecation should prefer:

1. Document the new canonical path.
2. Add direct tests for the canonical path.
3. Isolate legacy behavior in compatibility tests.
4. Emit warnings only when user workflows can tolerate them.
5. Remove only after a named release or decision point.

## Release And Status Model

LabKit app status should be explicit:

| Status | Meaning |
| --- | --- |
| `experimental` | Useful but still changing; behavior can evolve with tests and notes. |
| `active` | Real workflow under refinement; behavior changes require clear rationale. |
| `routine` | Daily-use workflow; preserve behavior by default. |
| `deprecated` | Still available, but a replacement path is documented. |
| `archived` | Kept for reference; not part of active validation unless explicitly stated. |

Reusable facade status should also be explicit:

| Status | Meaning |
| --- | --- |
| `private` | Implementation detail; may change freely if public behavior stays stable. |
| `app-owned` | Stable inside one app family; not a shared public API. |
| `public facade` | App-facing `+labkit` contract; changes need compatibility review. |
| `experimental facade` | Public enough to try, but documented as unstable. |

## Debt Burn-Down Roadmap

### Phase 0: Clean Stale Governance

Goal: make governance trustworthy before adding more rules.

Actions:

- Remove debt inventory entries that no longer match current facts.
- Split broad guardrail files when new unrelated checks are needed.
- Add exit criteria to every remaining expected debt list.
- Keep `docs/testing.md` as the only command matrix.

Exit criteria:

- Oversized-runner inventory matches actual oversized runners.
- Debt guardrails fail only on real debt growth or real boundary violations.
- No new human doc duplicates validation matrices or execution procedures.

### Phase 1: Normalize Runner Architecture

Goal: make the runner pattern uniform across app families.

Actions:

- Define an app-runner checklist: orchestration only, no deterministic behavior.
- For each app runner over the threshold, identify responsibilities by type:
  state, UI, ops, view, export, io, callback-only.
- Extract one responsibility at a time into app-owned packages.
- Add direct unit tests before relying on GUI structural tests.

Exit criteria:

- No runner keeps a local copy of a package helper.
- New deterministic behavior enters package helpers first.
- Large runners have migration maps instead of vague debt labels.

### Phase 2: Migrate Wearable ECG Print

Goal: prove the no-wholesale-move migration pattern on a real large runner.

Target shape:

```text
apps/wearable/ecg_print/labkit_ECGPrint_app.m
apps/wearable/ecg_print/+ecg_print/+ui/
apps/wearable/ecg_print/+ecg_print/+state/
apps/wearable/ecg_print/+ecg_print/+ops/
apps/wearable/ecg_print/+ecg_print/+view/
apps/wearable/ecg_print/+ecg_print/+export/
apps/wearable/ecg_print/+ecg_print/+io/
```

Recommended extraction order:

1. Import option parsing and normalization.
2. Channel selection and ROI option normalization.
3. Analysis table construction.
4. Summary rows and import status text.
5. Export table and image naming.
6. Plot-data preparation where it can be separated from axes handles.
7. UI runner relocation after behavior is covered.

Exit criteria:

- Public launch command is unchanged.
- Old private runner is gone.
- GUI path calls the extracted package helpers.
- Ordinary tests use the new app-owned package helpers directly.

### Phase 3: Migrate DIC Preprocess

Goal: remove the largest private-runner debt without damaging workflow behavior.

Start with a migration map, not code movement. Classify every private helper:

| Class | Destination |
| --- | --- |
| Image geometry and masks | `apps/dic/preprocess/+dic_preprocess/+ops/` |
| Preview and display data | `+view/` |
| Export builders | `+export/` |
| File/path defaults | `+io/` |
| Default state structs | `+state/` |
| GUI control construction | `+ui/` |
| Callback-only coordination | runner |

Exit criteria:

- `apps/dic/private/runDICPreprocessApp.m` is removed.
- Shared DIC family helpers either become app-owned package helpers or remain
  narrowly justified private helpers with contracts.
- No DIC behavior moves into `+labkit` unless it satisfies the reusable-library
  extraction rule.

### Phase 4: Complete Private Contract Hygiene

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

### Phase 5: Modernize Guardrails

Goal: prevent the governance layer from becoming another large runner.

Actions:

- Split guardrails by concern when files become broad.
- Convert exact debt lists into structured inventory helpers when lists are
  still needed.
- Use generated or printed summaries for dashboards, but keep pass/fail checks
  narrow.
- Keep exact file-list assertions only for stable public surfaces.

Exit criteria:

- A guardrail failure points to one concern.
- Debt dashboards are easy to update when debt shrinks.
- Adding a new app does not require editing unrelated project guardrails.

### Phase 6: Mature App Family Expansion

Goal: make future apps easy to add without copying old debt.

Actions:

- Use app-owned packages from the first nontrivial extraction.
- Promote reusable UI tools only after two real apps need the same mechanics.
- Add future data/device facades only after repeated app use proves a coherent
  app-facing API.
- Keep app family docs short and behavior-focused.

Exit criteria:

- New apps do not create `private` runners.
- New app helpers do not become public helper packages.
- Reusable facades grow slowly and intentionally.

## Maturity Model

| Level | Name | Description |
| --- | --- | --- |
| 0 | Legacy runner | Single large runner or private runner owns most behavior. |
| 1 | Managed runner | Runner still large, but deterministic behavior is being extracted and tested. |
| 2 | App-owned package | Workflow behavior lives in app-owned packages; runner orchestrates. |
| 3 | Stable app | App behavior, exports, tests, docs, and compatibility contracts are aligned. |
| 4 | Reusable pattern | Shared behavior has proven reuse and becomes a narrow `+labkit` facade or documented app template. |

No app should skip directly from Level 0 to Level 4. That path usually creates
generic abstractions before the workflow is understood.

## Metrics To Track

Track these as trend metrics, not as vanity targets:

- app runners over 500 lines
- app runners over 350 lines
- `apps/**/private/*.m` count
- `+labkit/**/private/*.m` without contracts
- app-owned helper functions with direct unit tests
- source-string behavior tests outside project guardrails
- compatibility tests versus ordinary tests using legacy fields
- guardrail file line counts
- manual GUI scenario coverage for routine apps

The healthiest trend is not fewer files. The healthiest trend is fewer hidden
responsibilities per file and more directly tested behavior.

## Anti-Patterns

Do not do these:

- Move a 900-line runner into a 900-line helper and call it refactoring.
- Create public `+labkit/+analysis`, `+io`, `+data`, or `+util` surfaces for
  convenience.
- Put experiment-specific result schemas into reusable UI helpers.
- Freeze evolving app-owned package internals with exact file-list guardrails.
- Treat GUI structural tests as full workflow validation.
- Add source-string tests to prove app business behavior.
- Add a generic launcher that hides separate app entry points.
- Convert struct models to classes just to look more formal.
- Let docs describe a cleaner architecture than the code actually implements.
- Keep a debt exception after the reason for the exception is gone.

## Definition Of Done For The Vision

The future vision is substantially achieved when:

- All public app launch commands still work.
- DIC and wearable private runner debt is removed.
- No app runner over the debt threshold lacks a migration map.
- App-owned packages hold deterministic app behavior with direct tests.
- `+labkit` exposes only small, documented facades.
- Private helper contract debt is zero.
- Compatibility bridges are isolated and named.
- Guardrails are narrow, current, and shrinking debt lists when debt shrinks.
- Human docs explain current behavior and boundaries without becoming execution
  manuals.
- Manual GUI validation scenarios exist for routine workflows.

## External Sources

- [Kubernetes SIG Architecture](https://www.kubernetes.dev/community/community-groups/sigs/architecture/): architecture governance, API conventions, enhancement proposals, and conformance thinking.
- [JupyterLab Extension Developer Guide](https://jupyterlab.readthedocs.io/en/3.6.x/extension/extension_dev.html): core application plus extension/plugin model.
- [Apache Airflow Providers](https://airflow.apache.org/docs/apache-airflow-providers/index.html): modular core plus separately versioned provider packages.
- [scikit-learn Developer Guide](https://scikit-learn.org/stable/developers/index.html): contributor guide, testing, documentation, code review, and backward compatibility practices.
- [pandas Development Policies](https://pandas.pydata.org/docs/development/policies.html): versioning, API compatibility, and deprecation policy.
- [Django Release Process](https://docs.djangoproject.com/en/4.2/internals/release-process/): release cadence, compatibility windows, and deprecation lifecycle.
- [VS Code Contribution Guide](https://github.com/microsoft/vscode/wiki/How-to-Contribute): discoverable local build, run, and debug workflow for a large app codebase.
