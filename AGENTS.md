# LabKit Agent Constitution

LabKit is a MATLAB app workbench. Apps are products; `+labkit` is a small
reusable foundation. Prefer the same results with clearer ownership and less
code.

## Read order

Read this file and every applicable ancestor `AGENTS.md` for the affected
paths, including intermediate scopes. Reuse already-loaded guidance. Start
with affected source/tests/docs; read component manuals for changed contracts:

- architecture: `docs/develop/app-authoring/architecture.md`
- framework: `docs/develop/framework/README.md`
- app development: `docs/develop/app-authoring/app-development.md`
- testing: `docs/develop/testing.md`
- release: `docs/develop/release.md`
- libraries: `docs/develop/libraries/<area>/README.md`
- apps: `docs/use/apps/README.md`

Use `.agents/migration_guide.md` only while a concrete architecture migration
or compatibility retirement is active. Create it with the first owned entry
and delete it when the last entry closes. Active migration roadmaps live only
there; current supported behavior belongs under `docs/`.

## Agent guidance

Use `labkit-agent-governance` for agent instructions, metadata, evaluations,
scripts, or an active migration ledger. Durable rules have one authoritative
owner: global invariants here, local invariants in scoped AGENTS, procedures
in Skills, and fragile repeatable mechanics in their owning scripts. Read
conditional references only for the current operation. A supporting Skill
inherits the caller's scope and delivery mode; review stays read-only and
invocation does not authorize unrelated changes or external actions.

User instructions and existing authorization determine the task. Continue
routine authorized work; ask only for consequential unresolved choices or
permission boundaries, identifying the exact instruction when it blocks work.
Honor explicit durable policy requests. Promote one-off corrections only when
repeated current evidence establishes a stable rule. Avoid turning transient
failures, example filenames, or a single App's details into general procedure.

Keep automation beside its consumer: `.github/scripts/` for CI,
`tests/+labkittest/` for catalog support, and the owning Skill for agent-only
helpers. Never create a root `scripts/` directory. Improve repeated mechanics
when that removes recurring cost within the task; otherwise report the follow-up.
Validate changed guidance and scripts through the governance Skill.

Derive final artifacts from the accepted baseline, final result, and evidence.
Discarded drafts and session corrections are control data, not project history.
Keep current facts in source/tests/manuals, rationale in structured Changes,
and delivery evidence in the PR. Retain historical comparisons only when a
reader needs them for the requested audit, science, safety, or compatibility.

## Architecture and implementation

- Preserve required scientific meaning and supported user outcomes unless the
  task changes them. Existing implementation shape, internal interfaces, and
  accidental behavior are not compatibility obligations.
- For refactoring, prefer a coherent replacement of a flawed design over a
  smaller diff that adds wrappers, aliases, or parallel state. Trace supported
  consumers and migrate them with the owner; remove superseded code and tests.
  Preserve a compatibility path only for an identified external consumer or
  saved-data promise, with an explicit owner and retirement condition. Resolve
  uncertain scientific or external compatibility changes before removing them.
- Apps own formulas, thresholds, units, workflow decisions, plots, results,
  exports, failures, and wording. Promote code into `+labkit` only when it is a
  stable domain-neutral contract useful beyond one app.
- Treat a new public framework API as the last boundary option. Prefer, in
  order, App-local ownership, a natural extension of an existing focused API,
  or a private framework capability. Add a public API only when multiple Apps
  need the stable contract or extending an existing API would turn it into an
  ambiguous bucket.
- `apps/AGENTS.md` owns App shape, callbacks, persistence, and diagnostics;
  `+labkit/AGENTS.md` owns library and SDK contracts. Keep app-facing packages
  to `app`, `image`, `thermal`, `dta`, `rhs`, `biosignal`, and `mark10`.
  Do not create public `analysis`, `data`, `io`, `util`, or App-specific helpers.
- Converting App struct state to classes, merging all Apps into one entrypoint,
  or changing implementation language requires an explicit user decision.
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

- Production Apps use Base MATLAB, their own App package, and public LabKit
  facades declared in their Definition requirements. They must never call or
  conditionally accelerate with an optional MathWorks Toolbox, Python/Conda,
  Java, .NET, shell commands, MEX/native libraries, ActiveX/COM, or a vendor
  SDK directly. Vendor types and handles never enter App state or callbacks.
- Facades, launchers, and shipped maintainer tools otherwise use only Base
  MATLAB and repository code. An explicitly approved hardware facade may use
  a narrowly identified end-user-installed official vendor runtime only from
  exact package-private adapter files recorded by the codecheck allowance
  ledger. The facade exposes MATLAB-native values and opaque repository-owned
  tokens, provides a non-opening availability diagnostic, revalidates on
  connect, and turns missing, incompatible, busy, disconnected, and read
  failures into documented outcomes. It never downloads, installs, bundles,
  or redistributes the vendor runtime. A new facade or dependency remains an
  architecture decision, not an implied precedent for other packages.
- MATLAB source otherwise stays in the MATLAB language runtime. Test
  infrastructure may use only the exact marked shell boundaries owned by the
  codecheck allowance ledger for isolated MATLAB, Git, or filesystem-link
  fixtures; the exact codecheck-ledgered NI-DMM private adapters are the only
  production secondary-runtime allowance. Every additional call is a
  violation.
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

Human sources are Markdown under `docs/` and public MATLAB help. Read
`docs/AGENTS.md` when changing those contracts and use
`labkit-documentation-maintainer` for the affected procedure. Generated `site/`
is ignored output; never track or hand-edit it. Agent instructions are not
reader pages. Classify documentation impact before final integration, including
an evidence-backed no-current-doc-change result in the PR when appropriate.

## Sensitive data

Never track real lab files, local/shared-drive paths, original filenames,
subjects, users, device IDs, timestamps, proprietary metadata, or recognizable
sample values. Convert reproductions into minimal synthetic structure with
generic labels. Search the diff for identifying remnants before commit.

Private apps live in their own repositories under ignored
`private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS`; keep their code, docs,
tests, history, and details out of the public repository.

## Validation

Use `labkit-test-planner` for selectors, test design/execution, fixtures, GUI
checks, or CI repair. Reuse source-aligned evidence and add tests only for real
contract gaps. The final pre-PR `changedFast` gate includes `codecheck` and
`docsCheck`; required PR CI owns the full platform claim. After CI failures,
repair and rerun the failed owner rather than repeating broad local gates,
unless the repair intentionally widens scope.

Run MATLAB and every `gh` command with host runtime/network permissions from
the first attempt. Sandboxed `gh` cannot access the macOS Keychain; do not
request reauthentication from that output. Diagnose launcher access when MATLAB
exits before its build banner. Never open MATLAB IDE/Desktop; use bounded
noninteractive processes. Do not run interactive workflows in `-batch`.

Before an App edit that risks unintended visual differences, capture the
baseline unless the task deliberately changes the design. All App screenshots
use MATLAB `exportapp` and a stable target figure from a bounded noninteractive
process, never desktop screenshot automation. Hidden GUI does not establish
native dialogs, pointer feel, visual quality, scientific validity, or real-data
suitability; preserve these distinctions in the evidence report.

Do not add Code Analyzer suppression pragmas. Keep scratch artifacts under
ignored `artifacts/`. Validation lasting over 30 seconds exposes named stages,
completed/total work, and a heartbeat at least every 30 seconds, through the
owning progress facility. Development Feedback is non-gating; inspect it only
when requested, needed for checkpoint evidence, or blocking current work.

## Delivery and authorization

- Use a new linked worktree under `artifacts/worktrees/<task-name>/` for every
  delivery branch. Before editing, inspect local work, fetch `origin/main`,
  and branch from that exact commit. Keep the primary checkout clean on main;
  preserve unrelated worktrees and never reuse a merged branch.
- Use `labkit-checkpoint-guard` for ordinary commits and authorized pushes;
  use `labkit-pr-integrator` for preparing, opening, updating, or merging a PR.
  A merge request includes necessary replay, conflict repair, and exact-lease
  task updates. A request only to prepare or open a PR stops at that state.
- Main accepts same-repository PRs only. Preserve required `CI Gate`, review
  flow, conversation resolution, linear history, and administrator enforcement.
  Never bypass protection, push directly to main, force-push main, or delete it.
- Never merge main into a task branch for bookkeeping. A non-fast-forward task
  update requires integration authorization and
  `--force-with-lease=refs/heads/<task>:<verified-old-sha>`. If the remote head
  changes, inspect the new work before preparing another candidate. Other
  history rewrites require explicit authorization.
- Keep a PR's scope fixed after opening, except accepted scope changes,
  baseline reconciliation, and validation repairs. Bundle related improvements
  when their combined ownership, evidence, and delivery boundary are clear.
- After an authorized merge, verify its exact main-push policy run and complete
  accepted-task cleanup through the integration reference. Preserve dirty or
  unaccepted work; fast-forward the clean primary checkout to accepted main.
- Use the matching `.github/` template for Issues, PRs, and Release notes.
  Before writing GitHub Markdown, run
  `.github/scripts/normalize_github_markdown.py`; use `--check` for templates.
  Keep one physical line per prose paragraph and list item. GitHub owns hosted
  status; PR bodies own scope, rationale, local/manual evidence, and risks.
- Commit and explicit squash subjects use one lowercase Conventional Commit
  type: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `ci`, or `chore`.

## Versions and releases

Version semantics belong in component metadata, requirements, saved-data
migration branches, compatibility documentation, and release records, not in
implementation names. Before a source-changing PR is merge-ready, each affected
versioned App, facade, or launcher advances exactly one direct semantic version
step from the base, updates its current manual, and records the accepted
logical change and transitions once. One cross-component decision has one
Change record. `labkit-pr-integrator` owns consolidation.

Release publication is a separate requested operation owned by
`labkit-documentation-maintainer` and its release reference. Only the exact
accepted main commit with successful policy and developer-led interactive
validation may be released. Ordinary CI does not tag or publish releases.

## Handoff

Report the requested outcome, changed files, exact validation and remaining
limits. Include branch, commit/push, PR/CI/merge, and cleanup state only when
those delivery operations apply.
