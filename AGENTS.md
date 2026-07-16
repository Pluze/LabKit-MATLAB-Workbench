# LabKit Agent Constitution

LabKit is a MATLAB app workbench. Apps are products; `+labkit` is a small
reusable foundation. Prefer the same results with clearer ownership and less
code.

## Read order

For a narrow change read this file, the nearest scoped `AGENTS.md`, and the
affected source/tests/docs. Read component manuals only for changed contracts:

- architecture: `docs/development/architecture.md`
- framework: `docs/framework/README.md`
- app development: `docs/development/app-development.md`
- testing: `docs/development/testing.md`
- release: `docs/development/release.md`
- libraries: `docs/libraries/<area>/README.md`
- apps: `docs/apps/README.md`

Read `.agents/migration_guide.md` only for active migration or compatibility
retirement. A zero-debt ledger is not an everyday checklist.

## Architecture and implementation

- Preserve behavior unless the user asks to change it.
- Apps own formulas, thresholds, units, workflow decisions, plots, results,
  exports, failures, and wording. Promote code into `+labkit` only when it is a
  stable domain-neutral contract useful beyond one app.
- App-facing packages are `labkit.ui`, `image`, `thermal`, `dta`, `rhs`, and
  `biosignal`. Do not create public `analysis`, `data`, `io`, `util`, or
  app-specific helper surfaces.
- Apps use `labkit.ui.runtime.launch/define`, semantic layouts, presenter
  models, injected services, and managed interactions/resources. They do not
  receive registries or own lifecycle timers, readiness, callback queues, or
  concrete framework layout.
- Keep app entrypoints thin and app helpers under the owning app package. Name
  packages and functions for the capability they own, not `helpers`, `utils`,
  `process`, `handle`, or `manage`.
- Do not convert struct state into classes, merge all apps into one entrypoint,
  or change implementation language without explicit approval.
- File budgets count nonblank, non-comment MATLAB code. They are review
  backstops, not extraction targets. Keep callback-local glue local when that
  makes workflow order clearer.
- Path collections use string or cell arrays. A scalar folder becomes
  `string(folder)`; never reshape an unknown char path with `(:)`.
- Sanitize UI numeric values to finite scalars before storing them.
- Repeated labels/choices that also drive state have one app-local owner.
- Interactive rectangles use managed interaction specs. Display-only graphics
  disable hit testing, and overlay edits preserve the current viewport.
- Scientific constants have semantic names and nearby rationale. Structural
  indices, UI geometry, versions, and synthetic fixtures are exempt.

## Dependencies and scientific replacements

- Production apps and facades use MATLAB, explicitly declared MathWorks
  products, and repository code. No Python/Conda runtime, downloaded weights,
  first-run installation, or new third-party runtime dependency without
  explicit architecture/deployment/offline approval.
- Temporary Toolbox use requires a visible direct call and a repository-owned
  base-MATLAB implementation with comparable behavior. Declare source, symbol,
  product, owner, fallback test, idempotency test, parity test, tolerance, and
  removal condition in `tests/runner/labkitToolboxDebt.m` and the migration
  ledger.
- When a replacement affects numbers, scientific meaning, branching, exports,
  or later calculation, identical inputs must be idempotent and tests compare
  app-consumed outputs against the Toolbox reference within a justified
  tolerance. Visual similarity is not parity evidence.

## Documentation

- Human sources are Markdown under `docs/`, catalog/navigation JSON, and public
  MATLAB help. `site/` is generated only by
  `tools/docs/renderLabKitDocs.m`; never edit generated assets directly.
- Update human docs for user behavior or public contracts, scoped AGENTS for
  execution/ownership rules, and both only when both changed. Do not duplicate
  agent workflow in human manuals.
- Every public library function documents syntax, inputs, outputs, options,
  defaults, legal values, errors, and related APIs immediately after its
  declaration. Cataloged scientific app APIs also document units, assumptions,
  and standalone GUI-free use. Private helpers document caller, shapes, side
  effects, and assumptions.
- `Example:` help is executable in a clean MATLAB session and covered by the
  docs runner. Use `Typical Call:` for interactive or user-file-dependent
  sketches.
- Regenerate the site and run documentation consistency checks after source
  pages, catalogs, public help, or renderer changes.

## Sensitive data

Never track real lab files, local/shared-drive paths, original filenames,
subjects, users, device IDs, timestamps, proprietary metadata, or recognizable
sample values. Convert reproductions into minimal synthetic structure with
generic labels. Search the diff for identifying remnants before commit.

Private apps live in their own repositories under ignored
`private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS`; keep their code, docs,
tests, history, and details out of the public repository.

## Validation

- Run the smallest source-aligned test during iteration. Use `changedFast` at a
  coherent checkpoint and `buildtool changed` once for a stable handoff unless
  the user requested a narrower strategy or a broader completed gate covers it.
- After failure, fix and rerun the narrowest failed file, method, or suite; do not repeatedly
  invoke the planner. Exact commands and scope live in
  `docs/development/testing.md`.
- MATLAB and GitHub inspection require host runtime/network permissions. If
  MATLAB exits before a build/test banner, diagnose launcher access rather than
  source failure.
- Do not add Code Analyzer suppression pragmas.
- `artifacts/` is ignored scratch output, never tracked design state.
- Automated hidden GUI tests do not prove native dialogs, visual quality,
  pointer feel, scientific validity, or full manual workflows. Do not run
  interactive workflows in MATLAB `-batch` mode.
- For an accepted private workspace, run its own tests first. If
  `.labkit-accept-main-guardrails` is present and private changes are unpushed,
  also run the relevant public guardrail because the public changed-file
  planner cannot see the nested diff.

## Git workflow

1. Inspect status and alignment before editing. Preserve unrelated user work.
2. Work directly on aligned `main` for focused changes; use `codex/` branches
   for larger, risky, multi-commit, or review-heavy work.
3. Make logical purpose-based commits, review the diff, and report validation.
4. Push coherent checkpoints. For direct-main work, fetch/prune afterward and
   verify local `main` equals `origin/main`.
5. Inspect the final direct-main CI run once. For branch work, inspect required
   CI before merge rather than polling after every push. Read only failing logs
   and fix the underlying issue.
6. Never force-push without explicit approval. Stop and report permission,
   protection, review, CI, sync, or cleanup blockers rather than bypassing them.
7. After PR merge, fast-forward local `main`, prune refs, delete the merged
   branch, and leave the worktree synchronized.

Commit and squash subjects use exactly one lowercase Conventional Commit type:
`feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `ci`, or `chore`. Pass an
explicit compliant squash subject; do not rely on GitHub defaults.

## Versions, history, and releases

- Before direct-main push or merge, source changes to a versioned app/facade or
  launcher update its source version, owning manual, and one structured
  component history record. Cross-component changes use one record listing all
  affected components.
- History records use stable Change ID and sequence metadata plus rationale,
  compatibility, user/data impact, validation, evidence, and follow-up. Do not
  restore a root changelog or separate history parser.
- New release tags are `vX.Y.Z`; do not rename published legacy tags. Release
  titles are `LabKit MATLAB Workbench vX.Y.Z` with relevant `Highlights`,
  `Fixes`, `Upgrade Note`, and `Validation` sections.
- Release assets come from the tag blob, not the worktree. Verify byte count
  and SHA-256 before and after upload; replace a mismatched asset without moving
  a published tag.

## Handoff

Report changed files, branch, commit/push state, tests, CI/PR/merge state when
applicable, intentional non-changes, blockers, unverified manual behavior, and
the next recommended step.
