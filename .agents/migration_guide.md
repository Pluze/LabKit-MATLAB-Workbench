# Agent Migration Guide

This is the agent-facing migration ledger for LabKit app-runner migrations and
debt burn-down. It is not a second architecture manual.

Human-facing architecture, app behavior, and validation command details live in
`docs/`. This guide owns only active migration facts, tactical runner maps, and
debt retirement rules for agents.

Lifecycle contract:

- Update this guide when migration debt is added, reduced, retired, or
  reprioritized.
- Keep debt facts aligned with `ProjectDebtGuardrailTest`,
  `ProjectDocumentationGuardrailTest`, `ProjectStructureGuardrailTest`,
  `docs/architecture.md`, and `docs/testing.md`.
- Shrink this guide when debt is resolved. Do not keep completed migrations as
  active roadmap items.
- Use `labkit-migration-planner` for debt scans, recent-history reviews, and
  updates to this file.

Read-scope contract:

- Read through `Migration Standard` for most migration tasks.
- Read `Current Oversized Runner Inventory` to choose active runner debt.
- Read a `## \`path\`` runner map only when touching that runner.
- Read `Completed Migration Baselines` only when changing a completed app or
  checking its guardrail invariants.
- Use `docs/testing.md` through `labkit-test-planner` for exact commands.

## North Star

```text
small stable foundation + focused apps + explicit compatibility contracts
```

Apps are first-class products. `+labkit` stays a small foundation with UI, DTA,
and biosignal facades. Workflow-specific calculations, summaries, plots,
exports, and file conventions belong under the owning app tree.

## Current Debt Snapshot

Current facts:

- Oversized app entry points: none.
- Oversized app runners over 500 lines: none.
- App `private/` debt: none.
- Private helper contract debt: none.
- Completed app package migrations: ECG Print, DIC Preprocess, DIC Postprocess,
  CIC runner normalization, CSC runner normalization.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.

Executable sources of truth:

- `ProjectDebtGuardrailTest.expectedOversizedRunnerDebtFiles`
- `ProjectDebtGuardrailTest.expectedAppPrivateDebtFiles`
- `ProjectDocumentationGuardrailTest.expectedPrivateContractDebtFiles`
- `ProjectStructureGuardrailTest` package and startup path checks

When debt shrinks, update source, tests or guardrails, and this guide in the
same change. Stale debt entries are defects.

## Health Signals

Migration work is healthy when it removes legacy surfaces, keeps public app
behavior stable, adds direct tests for extracted behavior, keeps CI green, and
shrinks this guide.

Migration work is risky when it mostly moves files, splits tiny helpers without
reducing runner complexity, adds exact guardrails for unstable internals, or
expands governance faster than debt shrinks.

Stop extracting once a runner mostly owns callbacks, axes side effects, alerts,
logging text, and refresh ordering. Do not turn GUI choreography into another
large helper.

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
directly testable behavior leaves the runner and the real GUI path calls it.

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

Move a helper into `+labkit` only when it is domain-neutral, app-state-free,
directly testable, useful to multiple real apps or a whole workflow family, and
clearer as a public facade than as app-local code.

## Current Oversized Runner Inventory

No active oversized runner debt remains. If a future `+ui/runApp.m` grows over
the 500-line guardrail threshold, add a narrow map for that file and extract
only app-owned deterministic behavior or static control construction that the
real GUI path uses.

## Completed Migration Baselines

These apps are completed baselines, not active roadmap work:

| App | Location | Public command | Guardrail invariants |
| --- | --- | --- | --- |
| ECG Print | `apps/wearable/ecg_print/` | `labkit_ECGPrint_app` | no direct `apps/wearable/+ecg_print`; no wearable private runner; direct tests for non-UI helpers |
| DIC Preprocess | `apps/dic/dic_preprocess/` | `labkit_DICPreprocess_app` | no `apps/dic/private/runDICPreprocessApp.m`; direct tests for non-UI helpers |
| DIC Postprocess | `apps/dic/dic_postprocess/` | `labkit_DICPostprocess_app` | no `apps/dic/private/`; no `apps/dic/labkit_DICPostprocess_app.m`; direct tests for non-UI helpers |
| CIC | `apps/electrochem/cic/` | `labkit_CIC_app` | runner stays below 500 lines; static controls live in `cic.ui.buildControls`; deterministic helpers stay in `+ops`, `+view`, and `+export` |
| CSC | `apps/electrochem/csc/` | `labkit_CSC_app` | runner stays below 500 lines; static controls live in `csc.ui.buildControls`; deterministic helpers stay in `+ops` and `+view` |

Manual GUI review still applies to visual workflows such as point selection,
crop dragging, mask drawing, strain overlay inspection, and workflow feel.

## Active Roadmap

1. Keep debt inventories exact.
   Remove stale expected-debt entries from guardrails and this guide as soon as
   debt is retired. Do not keep completed DIC or ECG work as active phases.

2. Keep runner debt at zero.
   New `+ui/runApp.m` files should stay under the guardrail threshold by moving
   static control construction into app-owned `+ui` helpers and deterministic
   behavior into `+ops`, `+view`, `+export`, `+io`, or `+state` helpers.

3. Simplify guardrails only when failures become hard to interpret.
   Split by concern or introduce structured inventory helpers when that lowers
   maintenance cost. Do not add governance machinery just because migration
   guidance exists.

## Validation Routing

Use `docs/testing.md` for exact commands. Default routing:

| Change | Minimum validation |
| --- | --- |
| Debt inventory, app path, package boundary, or this guide | `testProject` |
| Electrochem app-owned helpers | `testAppsElectrochem`; add `testAppsElectrochemGui` for layout or wiring |
| DIC app-owned helpers or DIC migration | `testAppsDicGui` plus `testProject` |
| Wearable app-owned helpers or migration regression | `testAppsWearableGui` plus `testProject` |
| Reusable UI boundary | `testLabkitUiGui`; add affected app-family GUI tasks |

After any push intended to complete work, inspect CI. If required CI fails,
read only failing job logs, fix the issue, rerun relevant local checks, push,
and repeat until CI passes or an infrastructure/access blocker is explicit.

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
