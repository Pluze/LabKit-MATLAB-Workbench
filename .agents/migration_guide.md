# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns only active migration debt facts,
retirement rules, and the minimum standard for handling future migration debt.

## Lifecycle

Update this ledger only when migration debt is added, reduced, retired, or
reprioritized. Keep it aligned with:

- current capability-style project guardrails
- `AppPackageStructureGuardrailTest` app package and UI 2.0 structure checks
- `docs/architecture.md` when human-facing boundary facts change

When debt is retired, remove stale ledger entries and shrink this file in the
same change. A completed migration should not remain as active roadmap text.

## Current Debt Snapshot

Current active migration debt:

```text
none
```

Current facts:

- Oversized app entry points: none.
- Oversized package-root app `run.m` runners over 500 lines: none.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
- No active runner maps exist.
- Supported app entry points launch through `labkit.ui.app.create` directly or
  through app-owned package-root `run.m` orchestration.
- Migrated apps keep ordinary data-only specs in
  `+<app_slug>/+ui/buildSpec.m`, route extracted production code through
  role-based app-owned component packages, and avoid generic helper buckets.
- The public app-facing UI surface is the layered
  `labkit.ui.app/spec/view/tool/diag` foundation documented in `docs/ui.md`.

## Goal Prompt: Complete App Cold-Start Migration

Use this section as the execution prompt when the user says start the migration or set it as a goal. The migration is allowed to be a real cleanroom rewrite of the
test and documentation architecture. Existing files are references for current
behavior and useful assertions; they are not structure that must be preserved.

### Objective

Complete the LabKit app cold-start migration so a future app author can create,
test, document, and maintain a new experiment-workflow app with low setup cost
and without learning a second project configuration system.

The finished project should have:

- a small scaffold for new apps
- app discovery and smoke coverage without a hand-maintained app registry
- a maintainer-readable test tree
- a reduced official command surface
- human docs rewritten around current reader tasks
- no mandatory app manifest, generated test registry, or permanent parallel
  testing framework

### Operating Principles

```text
convention first, scaffold once, ordinary MATLAB after generation
```

- Preserve app/library behavior unless the migration explicitly changes a test
  or documentation structure.
- Keep app-specific formulas, thresholds, result schemas, plots, exports,
  workflow wording, and data flow in the owning app.
- Treat current tests and docs as behavior evidence. Port the intent of useful
  assertions, not old suite names, file boundaries, historical guardrail
  categories, or stale prose.
- Prefer dynamic discovery over registries. The launcher and tests should use
  the existing `apps/**/labkit_*_app.m` convention unless a real runtime need
  proves otherwise.
- Keep one final official runner and one documented command surface. Temporary
  side-by-side targets are allowed only during the rewrite.

### Current Facts To Preserve

- Supported apps already share the useful lifecycle shape:
  `labkit_<AppName>_app.m`, package-root `+<app_slug>/run.m`, and data-only
  `+<app_slug>/+ui/buildSpec.m`.
- Existing app-owned component packages are role-based and optional:
  `+state`, `+io`, `+ops`, `+view`, and `+export`.
- Component needs vary by workflow. Do not force all apps to contain all role
  packages.
- `labkit_launcher` already treats `apps/**/labkit_*_app.m` as the app
  discovery convention. That convention is enough metadata for launcher and
  smoke-test discovery until a real runtime need appears.
- Existing public launch command names must remain stable.

### Target Shape

Generated apps follow this hard convention:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/run.m
apps/<family>/<app_slug>/+<app_slug>/+ui/buildSpec.m
```

Optional generated role packages:

```text
+<app_slug>/+state/
+<app_slug>/+io/
+<app_slug>/+ops/
+<app_slug>/+view/
+<app_slug>/+export/
```

The final test tree should be easy to explain:

```text
tests/unit/        pure library and app-owned helper behavior
tests/smoke/       app discovery, launch, debug, and trace checks
tests/contract/    long-lived package, repo, docs, and hygiene boundaries
tests/gui/         focused noninteractive GUI layout and tool interaction checks
tests/support/     shared setup, assertions, fixtures, artifacts, and GUI helpers
```

The final human docs should be reader-oriented:

```text
README.md              shortest path to open LabKit
docs/apps.md           use apps, create apps, app directory convention
docs/testing.md        small official command surface and focused selectors
docs/architecture.md   current ownership and package boundaries
docs/reference/*.md    stable UI, DTA, and biosignal facade references
```

### Required Workstreams

1. Cleanroom target sketch
   - Write the target test/docs structure into the working change before moving
     files.
   - Keep the target small enough that a new maintainer can understand it from
     the directory names and `docs/testing.md`.

2. Dynamic app smoke
   - Replace `tests/helpers/appEntryManifest.m` with discovery from
     `labkit_launcher("list")` or the same entrypoint convention.
   - Keep broad smoke checks: every discovered app launches, supports debug
     mode, avoids legacy path leakage, and exposes visible debug trace.

3. Contract test rewrite
   - Rebuild project guardrails as a few contract tests from current long-lived
     requirements: package surface, app ownership, repository hygiene, sensitive
     sample hygiene, and build/docs synchronization.
   - Delete historical guardrails after their still-useful assertions are
     represented in the clean contract layer.
   - Do not keep resolved-debt inventories or duplicate responsibility checks.

4. Runner and command surface
   - Keep `runLabKitTests` as the official MATLAB test runner.
   - Simplify human-facing build tasks to the smallest useful set for normal
     maintainers.
   - Preserve focused runner selectors for diagnosis and CI internals.
   - Do not add per-app build tasks or a generated test registry.

5. Human docs rewrite
   - Rewrite `docs/testing.md`, `docs/apps.md`, and `docs/architecture.md` from
     current behavior rather than editing around old prose.
   - Keep only current app use, new-app workflow, validation choices, and
     ownership boundaries.
   - Remove historical migration prose, agent-only workflow, CI internals, and
     repeated task matrices from human docs.

6. App scaffold
   - Build `scripts/create_labkit_app.m` as a small copy-and-substitute scaffold
     using `apps/templates/starter_app` as the source shape.
   - Ask only for app family, slug, display label, public entrypoint name, and
     optional role packages.
   - Generate ordinary MATLAB files and ordinary test skeletons. After
     generation, the app is normal project code that authors can evolve.
   - Do not generate empty role folders, manifest files, custom build tasks, app
     registries, project metadata, inheritance bases, DSLs, pipeline engines, or
     a shared app-state framework.

7. Generator coverage and trial
   - Test `create_labkit_app.m` by generating a temporary app and verifying the
     generated entrypoint, package-root runner, `+ui/buildSpec.m`, and generated
     test skeletons.
   - Use the scaffold once to create a disposable or real small app and refine
     only the cold-start pain points exposed by that trial.

### Non-Goals

- Do not introduce mandatory `appManifest.m`.
- Do not introduce a generated test registry.
- Do not introduce per-app build tasks.
- Do not introduce a broad app catalog generator.
- Do not turn callbacks, file IO, plotting, exports, or test discovery into a
  universal runtime framework.
- Do not preserve old test file names, suite boundaries, docs sections, or
  guardrail categories merely because they exist today.

### Validation Gates

Use focused checks during migration, but do not mark the goal complete until
all relevant final gates have been run or a concrete blocker is reported:

```bash
git diff --check
scripts/matlab_batch.sh "buildtool testProject"
scripts/matlab_batch.sh "buildtool test"
```

Run GUI checks when MATLAB graphics support is available and the changed scope
touches GUI discovery, launch, layout, or callback behavior:

```bash
scripts/matlab_batch.sh "buildtool testAppsGui"
scripts/matlab_batch.sh "buildtool testLabkitGui"
```

If the official command surface changes, also run or list the task catalog and
update `docs/testing.md` in the same migration.

### Blockers

Stop and report an explicit blocker only when progress is no longer possible
without user input or an external state change. Examples:

- MATLAB is unavailable and executable/test validation is required to complete.
- A behavior-preserving rewrite exposes a real app behavior ambiguity that
  cannot be resolved from current tests, docs, or source.
- CI, branch protection, permission, or remote access prevents required final
  handoff after local validation is green.

Do not stop only because the rewrite is large. Continue by phase, keep commits
logical, and use current tests/docs as references rather than as structures to
protect.

### Completion Criteria

The migration is complete only when:

- new app cold-start works through `create_labkit_app.m`
- generated apps are launchable and editable as ordinary MATLAB code
- app smoke tests discover current apps automatically
- `tests/helpers/appEntryManifest.m` and equivalent hand-maintained app
  registries are gone
- the official test tree is centered on `unit/smoke/contract/gui`
- project guardrails are fewer, contract-oriented, and free of resolved-debt
  inventories
- human docs are rewritten around current reader tasks and no longer preserve
  stale history, agent workflow, or repeated command matrices
- existing app behavior and public launch commands are stable
- no mandatory manifest, generated registry, per-app build task, or broad app
  catalog generator has been introduced
- final validation gates pass, or the remaining blocker is explicit and
  reproducible

Final remote handoff follows the active user instruction. If the user says not
to open a PR, stop after local commits and validation. Otherwise use the normal
branch, push, PR, CI, merge, and branch-cleanup workflow.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral foundation
with UI, DTA, and biosignal facades. App-specific calculations, summaries,
plots, exports, workflow wording, file conventions, and result schemas stay
under the owning app tree.

A healthy runner owns orchestration only: launch/debug wiring, shell assembly,
state coordination, callback registration, alerts, log wording, and refresh
ordering.

Extract only behavior that becomes clearer and directly testable, and only when
the real GUI path calls the extracted helper. Use app-owned packages for
app-specific deterministic behavior. Use `labkit-boundary-guard` before moving
anything into `+labkit`.

Do not create new app `private` runners, root legacy command wrappers,
`*Workflow.m` adapters, app `+core/dispatch.m` routers, or convenience public
packages such as `+labkit/+analysis`, `+io`, `+data`, or `+util`.

## Future Debt Rules

- If guardrails detect new migration debt, update this ledger and the affected
  source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
