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

- Use `labkit-agent-governance` whenever adding, changing, reviewing, or
  retiring `AGENTS.md`, repository Skills, their metadata/evals/scripts,
  `.agents/dos-and-donts.md`, or `.agents/migration_guide.md`.
- Use `labkit-checkpoint-guard` before an ordinary requested commit or push;
  use `labkit-pr-preparer` only for final task-branch integration into `main`.
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
- Treat `.agents/dos-and-donts.md` as an experience reservoir. Run its review
  through `labkit-agent-governance` after choosing a non-obvious boundary,
  replacing a failed approach, completing focused validation, receiving a user
  correction, and before commit or handoff. Repeated inspection, discarded
  approaches, rollback, time lost on the same boundary, or user correction are
  explicit activation signals even when no agent file was otherwise changed.
  Record only the unresolved agent decision trap whose rediscovery would be
  costly, including the signal that should trigger a different approach.
  Never use the reservoir as a work log or duplicate behavior already enforced
  by an `AGENTS.md`, skill, test, source contract, or manual. Let useful
  lessons survive repeated use before promotion; once another owner prevents
  the mistake, actively compress or remove the reservoir copy plus stale,
  duplicated, disproven, and low-value detail.

## Architecture and implementation

- Preserve behavior unless the user asks to change it.
- Moving behavior to a new owner does not retire its observable contract.
  Preserve appearance, interaction paths, status, results, and failure
  semantics at the new boundary before deleting the old owner.
- Apps own formulas, thresholds, units, workflow decisions, plots, results,
  exports, failures, and wording. Promote code into `+labkit` only when it is a
  stable domain-neutral contract useful beyond one app.
- Treat a new public framework API as the last boundary option. Prefer, in
  order, App-local ownership, a natural extension of an existing focused API,
  or a private framework capability. Add a public API only when multiple Apps
  need the stable contract or extending an existing API would turn it into an
  ambiguous bucket.
- App-facing packages are `labkit.app`, `image`, `thermal`, `dta`, `rhs`,
  `biosignal`, and `mark10`. Do not create public `analysis`, `data`, `io`, `util`, or
  app-specific helper surfaces.
- App shape, capability naming, callbacks, persistence, and Debug behavior are
  governed by `apps/AGENTS.md`; App SDK internals and facade contracts are
  governed by `+labkit/AGENTS.md`.
- Do not convert struct state into classes, merge all apps into one entrypoint,
  or change implementation language without explicit approval.
- Call fixed production symbols directly so static analysis, dependency
  discovery, and refactoring can see them. Use `eval`, string-based `feval`,
  or `str2func` only at a genuinely dynamic extension or compatibility
  boundary with closed input validation, explicit ownership, and contract
  tests; never construct a callable symbol from untrusted project or user
  data. `assignin` is permitted only for an explicit result export to the
  literal `base` workspace and a literal MATLAB variable name, with a
  data-shaped value and contract tests; never use it to inject runtime
  objects, handles, callbacks, or dynamically named state.
- File budgets count nonblank, non-comment MATLAB code. They are review
  backstops, not extraction targets. Keep callback-local glue local when that
  makes workflow order clearer.
- Path collections use string or cell arrays. A scalar folder becomes
  `string(folder)`; never reshape an unknown char path with `(:)`.
- Scientific constants have semantic names and nearby rationale. Structural
  indices, UI geometry, versions, and synthetic fixtures are exempt.

## Dependencies and scientific replacements

- Production Apps, facades, launchers, and shipped maintainer tools use only
  Base MATLAB and repository code. They must not call or conditionally
  accelerate with any optional MathWorks Toolbox, Python/Conda runtime,
  downloaded weights, first-run installation, or third-party runtime. A need
  that Base MATLAB cannot satisfy is an architecture blocker requiring an
  explicit user decision; it is not temporary dependency debt.
- MATLAB source also stays in the MATLAB language runtime: do not
  call Java, Python, Conda, .NET, shell commands, MEX/native libraries, or
  ActiveX/COM. Use public Base MATLAB functions or repository-owned MATLAB
  implementations. Test infrastructure may use only the exact marked shell
  boundaries owned by the codecheck allowance ledger for isolated MATLAB,
  Git, or filesystem-link fixtures; every additional call is a violation.
- Product ownership follows the documented MATLAB function contract, not a
  namespace prefix. Base MATLAB `backgroundPool`, explicit
  `parfeval(backgroundPool,...)`, and `parallel.pool.PollableDataQueue` are
  permitted background primitives; without Parallel Computing Toolbox they
  provide one worker. Do not use `parpool`, `parfor`, `spmd`, Toolbox pool or
  cluster objects, or implicit `parfeval` dispatch in production.
- Do not treat `backgroundPool` as the default App responsiveness architecture,
  move a state/UI callback onto it wholesale, or add a generic SDK task layer
  merely to make a synchronous workflow appear asynchronous. Use
  `labkit-boundary-guard` before adopting background execution.
- When a GUI or diagnostic viewer must remain usable after the client event
  loop hangs, use a user- or environment-managed independent MATLAB process;
  `backgroundPool`, timers, and additional figures in the same client are not
  fault isolation. Repository production code must not spawn that process
  through a shell command.
- Clean CI runtimes without optional Toolboxes are the executable dependency
  boundary. Keep fixed production symbols directly visible, exercise shipped
  paths there, and add a focused source guard when retiring a concrete Toolbox
  entry point so the dependency cannot silently return.
- When replacing a Toolbox implementation affects numbers, scientific meaning,
  branching, exports, or later calculation, identical inputs must be
  idempotent and tests compare App-consumed outputs against preserved reference
  evidence within a justified tolerance. Visual similarity is not parity
  evidence; the retired Toolbox call must not remain in production or tests.

## Documentation

- Human sources are path-organized Markdown under `docs/` and public MATLAB
  help. Follow `docs/AGENTS.md` for authored page ownership and
  `labkit-documentation-maintainer` for renderer, history, link, or deployment
  workflows. `site/` is ignored generated output; never track or edit it.
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

## Sensitive data

Never track real lab files, local/shared-drive paths, original filenames,
subjects, users, device IDs, timestamps, proprietary metadata, or recognizable
sample values. Convert reproductions into minimal synthetic structure with
generic labels. Search the diff for identifying remnants before commit.

Private apps live in their own repositories under ignored
`private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS`; keep their code, docs,
tests, history, and details out of the public repository.

## Validation

- Run the smallest source-aligned test during iteration. Use
  `labkit-test-planner` for selectors, failure repair, CI scope, GUI checks,
  fixtures, and the one final pre-PR `changedFast` run. Required PR CI owns the
  complete platform claim; the protected main push records policy for the
  already-validated squash tree.
- After a local or hosted-CI failure, inspect only the failing identity and its
  log, fix the smallest responsible source boundary, and rerun the narrowest
  failed method, specification file, or owner/contract. Push the focused repair
  and let required CI re-establish the complete claim; do not rerun
  `changedFast` or a local full profile after every CI repair. Re-plan only when
  the repair intentionally widens the changed behavior or ownership boundary.
  Exact commands and scope live in
  `docs/development/maintain-and-release/testing.md`.
- MATLAB and GitHub inspection require host runtime/network permissions. Run
  every `gh` command with host permissions on its first attempt, including
  `gh auth status`; sandboxed `gh` cannot access the macOS Keychain and can
  falsely report a valid token as invalid. Never ask the user to reauthenticate
  based only on sandboxed output. If MATLAB exits before a build/test banner,
  diagnose launcher access rather than source failure.
- Never launch or open the MATLAB IDE or MATLAB Desktop for any task. Use a
  bounded noninteractive MATLAB process for tests, analysis, and MATLAB API
  screenshot capture. If a required check cannot run without the IDE, report
  that boundary instead of opening it.
- Do not add Code Analyzer suppression pragmas.
- `artifacts/` is ignored scratch output, never tracked design state.
- Automated hidden GUI tests do not prove native dialogs, visual quality,
  pointer feel, scientific validity, or full manual workflows. Do not run
  interactive workflows in MATLAB `-batch` mode.
- Before editing an App when the change risks unintended visual differences,
  save a before-change interface baseline unless the requested outcome
  deliberately adds or removes UI elements or changes the design. Capture
  every LabKit App screenshot through MATLAB's own APIs: locate the target
  figure by its stable handle or tag and export the App window with
  `exportapp` from a bounded noninteractive MATLAB process; do not use desktop
  screenshot automation.
- A validation entry point expected to run longer than 30 seconds reports its
  current stage and completed/total work, and emits a heartbeat at least every
  30 seconds while one unit remains active. Reuse the owning progress plugin
  or callback instead of making callers infer progress from process liveness.
- For an accepted private workspace, run its own tests first. If
  `.labkit-accept-main-guardrails` is present and private changes are unpushed,
  also run the relevant public guardrail because the public changed-file
  planner cannot see the nested diff.
- Treat development feedback as non-gating author feedback, never merge
  evidence. Inspect it only when requested, needed by a checkpoint, or blocking
  current work; do not poll it during ordinary iteration.

## Git workflow

1. Inspect status and alignment before editing. Preserve unrelated user work.
   Fetch `origin/main`, then create one short-lived task branch from its exact
   current commit. Use a concise descriptive branch name; do not require an
   agent, tool, user, or fixed category prefix. Never edit or commit directly
   on `main`, including for documentation, CI, release preparation, emergency
   repairs, and bug fixes.
2. Keep an active multi-commit migration roadmap only in
   `.agents/migration_guide.md`; never create a future-state migration page
   under `docs/`. Remove completed entries before final PR preparation.
3. One task branch owns one coherent delivery stream. Commit and push logical
   checkpoints when the work benefits from them; do not delay a coherent
   checkpoint merely to accumulate a larger batch. Once its PR to `main`
   opens, freeze that branch until the PR is merged or closed; do not mix later
   work or another task into its moving head.
4. Use `labkit-checkpoint-guard` before every requested commit or push. A clean
   `codecheck` is mandatory after the final MATLAB edit; stage only the owned
   outcome and proportionate evidence.
5. Use `labkit-pr-preparer` for the complete `origin/main..HEAD` squash
   boundary, versions, structured history, final local gate, PR record, CI,
   review, merge, and post-merge task-branch deletion. Main accepts PRs only
   from same-repository short-lived task branches. Never merge `main` back into
   a task branch merely for branch bookkeeping and never create a sync commit.
   Keep GitHub's automatic head-branch deletion enabled; after merge verify the
   accepted task branch is gone and delete it explicitly only if automation did
   not complete.
6. After merge, release only the exact accepted main commit after its policy
   gate succeeds. Do not repeat the complete PR MATLAB matrix.
7. Never force-push without explicit approval. Stop and report permission,
   protection, review, CI, or cleanup blockers rather than bypassing them.
   Branch protection must require `CI Gate`, PR review flow, linear main
   history, and conversation resolution for administrators as well as ordinary
   contributors; it must reject direct pushes, force pushes, and deletion.

When creating a public GitHub Issue or pull request, use the matching template
under `.github/` as the required structure. A bug report names its target,
reproduction, expected/actual behavior, impact, and redacted evidence; a
workflow request names its target App, user goal, inputs, outputs, acceptance
criteria, and out-of-scope behavior. A pull request records goal/scope,
user-visible behavior, exact validation evidence, remaining manual checks,
documentation/boundary decisions, delivery state, and data hygiene. Do not
invent a parallel issue or PR format, and do not include sensitive lab data or
local paths. Treat the PR body as a review record. A checkbox is reserved for a
universal, author-controlled, binary pre-merge obligation; never use one for
branch, commit, hosted-CI, review, or merge state that GitHub owns, or for
conditional alternatives and `N/A` choices. Record why the change exists, its
net behavior and ownership decisions, exact local/manual evidence, and risks
or follow-up, including compatibility, versions, documentation, boundaries,
and data handling when relevant.

Write GitHub Issue, pull-request, review, and Release Markdown as one physical
line per prose paragraph and one physical line per list item. Do not insert
column-width wrapping; GitHub owns visual wrapping. Preserve newlines only for
Markdown structure, fenced or indented code, tables, separate standalone links,
or an intentional hard break. Before a `gh` body or notes write, pass drafted
Markdown through `.github/scripts/normalize_github_markdown.py`; use `--check`
for repository-owned GitHub templates.

Commit and squash subjects use exactly one lowercase Conventional Commit type:
`feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `ci`, or `chore`. Pass an
explicit compliant squash subject; do not rely on GitHub defaults.

## Versions, history, and releases

- Version semantics belong only in dedicated facade/App version metadata,
  dependency requirements, saved-data migration branches, structured history,
  and release records. Do not encode versions in package, folder, file,
  function, class, type, protocol, test, or current-architecture names; use one
  stable semantic name and let the version contract express compatibility.
- Before a task-branch PR is merge-ready, source changes to a
  versioned app/facade or launcher update its source version, owning manual,
  and one structured component history record. Compare the PR base and head:
  each existing component advances by exactly one direct patch, minor, or
  major step. Cross-component changes use one record listing all affected
  components.
- For a history record introduced on a task branch, align its date and date-bearing
  Change ID with the final component `Updated` date used by the squash
  candidate. Do not preserve an intermediate checkpoint date after versions
  and history have been consolidated.
- History records use stable Change ID and sequence metadata plus rationale,
  compatibility, user/data impact, validation, evidence, and follow-up. Do not
  restore a root changelog or separate history parser.
- Treat unpublished history as the net squash decision, not a commit diary.
  Fold follow-on edits into the smallest coherent records and describe the
  final user outcome, compatibility, and evidence.
- New release tags are `vX.Y.Z`; do not rename published legacy tags. Release
  titles contain only `VX.Y.Z` with an uppercase `V` and relevant `Highlights`,
  `Fixes`, `Upgrade Note`, and `Validation` sections.
- Treat release notes as a user-facing product summary, not a release audit.
  Describe observable behavior, affected workflows, compatibility, and actions
  a user may need to take. Do not publish commit or run identifiers, commands,
  test inventories, CI architecture, internal package movement, hashes, byte
  counts, or maintainer-only evidence; keep those in the PR, workflow record,
  structured history, or release asset verification.
- Start the manual `Release` workflow only after developer-led interactive App
  validation, successful required PR validation, and a successful lightweight
  `Continuous Integration` main-push run for the exact squash commit. It then
  creates the validated tag and a draft GitHub Release. Review its notes and
  asset before publishing; ordinary CI never creates tags, and CI runners never
  install optional Toolboxes.
- Release assets come from the tag blob, not the worktree. Verify byte count
  and SHA-256 before and after upload; replace a mismatched asset without moving
  a published tag.

## Handoff

Report changed files, branch, commit/push state, tests, CI/PR/merge state when
applicable, intentional non-changes, blockers, unverified manual behavior, and
the next recommended step.
