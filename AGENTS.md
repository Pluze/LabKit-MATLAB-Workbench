# LabKit Agent Constitution

LabKit is a MATLAB app workbench. Apps are products; `+labkit` is a small
reusable foundation. Prefer the same results with clearer ownership and less
code.

## Read order

For a narrow change read this file, the nearest scoped `AGENTS.md`, and the
affected source/tests/docs. Read component manuals only for changed contracts:

- architecture: `docs/development/build-apps/architecture.md`
- framework: `docs/framework/README.md`
- app development: `docs/development/build-apps/app-development.md`
- testing: `docs/development/maintain-and-release/testing.md`
- release: `docs/development/maintain-and-release/release.md`
- libraries: `docs/libraries/<area>/README.md`
- apps: `docs/apps/README.md`

Read `.agents/migration_guide.md` only for active migration or compatibility
retirement. A zero-debt ledger is not an everyday checklist. Active migration
roadmaps live only in that ledger; do not create future-state migration pages
under `docs/`.

## Agent skills and automation

- Treat repeated reasoning, command assembly, selector discovery, and
  trial-and-error as signals to improve the responsible skill or its scripts.
  Prefer one reusable improvement over carrying the same procedural burden
  into later tasks.
- Skill guidance and automation express stable concepts, user intent,
  ownership boundaries, and semantic operations. Do not encode a transient CI
  failure, current repository contents, one App's details, a fixed product
  version, or a one-off filename as general workflow.
- Add convenience only when it removes recurring inference or retry cost
  without hiding important choices, weakening validation, or inventing a
  parallel product interface. Keep scripts platform-independent when the
  underlying workflow is platform-independent.
- Do not create a repository-root `scripts/` directory. Put automation beside
  its single consumer: GitHub workflow helpers under `.github/scripts/`, test
  catalog support under `tests/+labkittest/`, and agent-only wrappers under the
  owning skill. Promote a script only when it has multiple stable consumers.
- Validate an edited skill and exercise the changed script path. Record
  durable policy here or in the nearest scoped `AGENTS.md`; keep step-by-step
  agent procedure in skills rather than duplicating it in human manuals.
- Use `.agents/dos-and-donts.md` only as a short incubation ledger for a costly
  reusable lesson without a stable owner. Promote mature policy, procedure,
  behavior, or product meaning to the nearest `AGENTS.md`, skill, test, source
  contract, or manual, then remove it from the ledger.

## Architecture and implementation

- Preserve behavior unless the user asks to change it.
- Apps own formulas, thresholds, units, workflow decisions, plots, results,
  exports, failures, and wording. Promote code into `+labkit` only when it is a
  stable domain-neutral contract useful beyond one app.
- Treat a new public framework API as the last boundary option. Prefer, in
  order, App-local ownership, a natural extension of an existing focused API,
  or a private framework capability. Add a public API only when multiple Apps
  need the stable contract or extending an existing API would turn it into an
  ambiguous bucket.
- App-facing packages are `labkit.app`, `image`, `thermal`, `dta`, `rhs`,
  and `biosignal`. Do not create public `analysis`, `data`, `io`, `util`, or
  app-specific helper surfaces.
- App shape, capability naming, callbacks, persistence, and Debug behavior are
  governed by `apps/AGENTS.md`; App SDK internals and facade contracts are
  governed by `+labkit/AGENTS.md`.
- Do not convert struct state into classes, merge all apps into one entrypoint,
  or change implementation language without explicit approval.
- File budgets count nonblank, non-comment MATLAB code. They are review
  backstops, not extraction targets. Keep callback-local glue local when that
  makes workflow order clearer.
- Path collections use string or cell arrays. A scalar folder becomes
  `string(folder)`; never reshape an unknown char path with `(:)`.
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
  removal condition in `tests/+labkittest/toolboxDebt.m` and the migration
  ledger.
- When a replacement affects numbers, scientific meaning, branching, exports,
  or later calculation, identical inputs must be idempotent and tests compare
  app-consumed outputs against the Toolbox reference within a justified
  tolerance. Visual similarity is not parity evidence.

## Documentation

- Human sources are path-organized Markdown under `docs/` and public MATLAB
  help. Narrative pages, App manuals, and App APIs are discovered from paths,
  launcher metadata, and complete public help contracts. `site/` is generated only by
  `tools/docs/renderLabKitDocs.m`; never edit generated assets directly.
- Add a `docs/` page only for the currently supported architecture or a
  delivered new feature. Keep active migration plans, checkpoints, legacy
  removal lists, and future-state acceptance gates in
  `.agents/migration_guide.md`.
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
  pages, public help, discovery rules, or renderer changes. After moving
  Markdown, use `maintainLabKitDocLinks(..., "Update", true)` to repair
  standard relative links before rendering.

## Sensitive data

Never track real lab files, local/shared-drive paths, original filenames,
subjects, users, device IDs, timestamps, proprietary metadata, or recognizable
sample values. Convert reproductions into minimal synthetic structure with
generic labels. Search the diff for identifying remnants before commit.

Private apps live in their own repositories under ignored
`private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS`; keep their code, docs,
tests, history, and details out of the public repository.

## Validation

- Run the smallest source-aligned test during branch iteration. Before a branch
  is ready for PR review, do not run broad changed-file or full-suite gates;
  use focused fast tests for the current small step. Run `changedFast` once
  when preparing a branch for PR review or direct-main integration. There is no
  conservative local changed task; PR and main-push CI own complete validation.
- After failure, fix and rerun the narrowest failed file, method, or suite; do not repeatedly
  invoke the planner. Exact commands and scope live in
  `docs/development/maintain-and-release/testing.md`.
- MATLAB and GitHub inspection require host runtime/network permissions. Run
  every `gh` command with host permissions on its first attempt, including
  `gh auth status`; sandboxed `gh` cannot access the macOS Keychain and can
  falsely report a valid token as invalid. Never ask the user to reauthenticate
  based only on sandboxed output. If MATLAB exits before a build/test banner,
  diagnose launcher access rather than source failure.
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
2. When a multi-commit migration needs a roadmap, write it in
   `.agents/migration_guide.md` and land that ledger update as a standalone
   direct-main checkpoint before creating the implementation branch. Do not
   add a future-state migration page under `docs/`. Start the implementation
   branch from that main commit; the active ledger entry is removed by the
   final zero-debt squash merge after durable final behavior and rationale are
   recorded in the owning manual and component history.
3. Work directly on aligned `main` for focused changes; use `codex/` branches
   for larger, risky, multi-commit, or review-heavy work.
4. Keep branch work stable with small logical purpose-based commits and focused
   validation. Prepare user docs, component versions, and structured history as
   the single net change that the PR will squash into; do not accumulate
   release semantics from intermediate branch commits.
5. Push each completed, committed checkpoint promptly so finished work is not
   left only on the local machine. Do not defer a safe branch push merely
   because PR preparation or broader validation will happen later. For
   direct-main work, fetch/prune afterward and verify local `main` equals
   `origin/main`.
6. Inspect the final direct-main CI run once. For branch work, inspect required
   CI before merge rather than polling after every push. Read only failing logs
   and fix the underlying issue.
7. Never force-push without explicit approval. Stop and report permission,
   protection, review, CI, sync, or cleanup blockers rather than bypassing them.
8. After PR merge, fast-forward local `main`, prune refs, delete the merged
   branch, and leave the worktree synchronized.

When creating a public GitHub Issue or pull request, use the matching template
under `.github/` as the required structure. A bug report names its target,
reproduction, expected/actual behavior, impact, and redacted evidence; a
workflow request names its target App, user goal, inputs, outputs, acceptance
criteria, and out-of-scope behavior. A pull request records goal/scope,
user-visible behavior, exact validation evidence, remaining manual checks,
documentation/boundary decisions, delivery state, and data hygiene. Do not
invent a parallel issue or PR format, and do not include sensitive lab data or
local paths.

Commit and squash subjects use exactly one lowercase Conventional Commit type:
`feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `ci`, or `chore`. Pass an
explicit compliant squash subject; do not rely on GitHub defaults.

## Versions, history, and releases

- Version semantics belong only in dedicated facade/App version metadata,
  dependency requirements, saved-data migration branches, structured history,
  and release records. Do not encode versions in package, folder, file,
  function, class, type, protocol, test, or current-architecture names; use one
  stable semantic name and let the version contract express compatibility.
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
- Start the manual `Release` workflow only after developer-led interactive App
  validation and a successful `Continuous Integration` main-push run for the
  exact commit. It then creates the validated tag and a draft GitHub Release.
  Review its notes and asset before publishing; ordinary CI never creates
  tags, and CI runners never install optional Toolboxes.
- Release assets come from the tag blob, not the worktree. Verify byte count
  and SHA-256 before and after upload; replace a mismatched asset without moving
  a published tag.

## Handoff

Report changed files, branch, commit/push state, tests, CI/PR/merge state when
applicable, intentional non-changes, blockers, unverified manual behavior, and
the next recommended step.
