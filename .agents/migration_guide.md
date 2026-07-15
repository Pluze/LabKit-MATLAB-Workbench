# Agent Migration Ledger

This is the single agent-facing ledger for active LabKit migration debt. It is
not an architecture manual, validation matrix, or history. Current contracts
live in `docs/`; validation commands live in `docs/testing.md`; completed
changes live in source, tests, and `CHANGELOG.md`.

## Current Debt Snapshot

Last audited: 2026-07-15.

```text
ui-runtime-v2: final-validation-manual-interaction-and-pr-closure
app-structure-debt: none
app-project-and-result-contract-debt: none
toolbox-product-debt: none
```

Landed facts:

- All twenty public apps and the nested private Imager app use Runtime V2.
- Package-root runners, `+ui/runApp.m`, Runtime V1, the public control mutation
  facade, and public interaction editor/runtime objects are retired.
- Apps use `state.project` plus `state.session`, pure presenters, queued
  actions, managed interactions/resources, standard project persistence, and
  result manifests where they export files.
- Named legacy Video Marker projects and V1 snapshots are read-only imports;
  current writes use `labkitProject`.
- The public UI surface has 36 reviewed functions. The earlier numerical
  planning target is not a completion gate; every retained function owns a
  distinct current contract.
- Current human contracts live in `docs/ui.md`, `docs/apps.md`, and
  `docs/architecture.md`. The temporary Runtime V2 design record is retired.

## Exact Remaining Closure

Do not reopen implementation phases. Finish only these items:

1. Run the source-aligned public documentation/package guardrails, then the
   final changed-file and headless gates for the stable diff.
2. Confirm the latest public PR CI is green. The private PR has no hosted CI;
   use its repository-owned test entry point.
3. Record manual MATLAB interaction results for pointer, wheel, drag, and
   visual workflow feel in the interaction-heavy apps. Automated hidden GUI
   tests do not prove this user experience.
4. Squash-merge the private and public PRs with explicit Conventional Commit
   subjects, delete their development branches, and align both local default
   branches with their remotes.
5. After merge, re-audit the four debt fields above. If no debt remains,
   replace the first field with `none` and keep this compact ledger.

Previous stable automated evidence before the final docs/test cleanup was:
private 41/41, public base-MATLAB 7/7, changed 290, headless passed, and GUI
69/69. A Linux CI failure caused only by tests expecting an untracked empty
retired package directory was corrected by requiring that package to be absent;
the focused package guardrails pass locally. Do not treat this prior evidence
as coverage for a later executable diff.

## Toolbox Product Debt Rule

Rapid development may temporarily use a MathWorks Toolbox capability only
when the app also ships and tests a repository-owned base-MATLAB path with
comparable user-visible behavior. Record each temporary product call here with:

```text
source and symbol:
MathWorks product:
owner:
owned fallback:
base-MATLAB test:
idempotency evidence:
parity outputs and tolerance:
replacement condition:
```

When outputs feed scientific interpretation, branching, exports, or later
calculation, parity must compare the app-consumed numeric/data outputs within a
documented tolerance; visual similarity is insufficient. Identical inputs must
produce idempotent app behavior. Do not hide product calls behind reflection,
string dispatch, or test-only indirection. Close the debt only by removing the
Toolbox branch after the owned implementation replaces it.

## Reopen Triggers

Open a minimal executable route here only when a current scan finds concrete
debt, for example:

- a package-root runner, `+ui/runApp.m`, retired technical bucket, or app
  `private/` workflow implementation reappears
- a new app lacks canonical project/session state, a pure presenter, or
  dedicated GUI workflow coverage
- app code restores figure callbacks, mutates controls directly, or stores
  handles/listeners/tools/services in semantic state
- a Toolbox product call appears without the owned fallback and evidence above
- a boundary decision cannot be resolved locally without a new public
  `+labkit` contract

Do not add a route for line count alone. Record debt only when ownership,
testability, behavior, or cognitive load is concretely worse.

## Compatibility Queue

The DTA facade intentionally retains legacy bridge fields beside canonical
unit-explicit fields. Removing chrono `t`, `Vf`, `Im`, `alignTime`, `tAligned`,
or EIS `Pt`, `Freq`, `Zreal`, `Zimag`, `negZimag` requires an explicit DTA
major-version route after consumers and tests use canonical fields. This is a
compatibility contract, not current cleanup debt.

## Migration Standard

Apps are first-class products; `+labkit` is a small domain-neutral foundation.
Migration is progress only when it clarifies responsibility, makes behavior
directly testable on the real app path, removes duplicate mechanics, or lowers
workflow cognitive load. Moving code, manufacturing tiny helpers, adding
guardrails, or preserving completed roadmaps is not progress by itself.

Use `labkit-boundary-guard` before promoting behavior into `+labkit` and
`labkit-test-planner` for validation routing.
