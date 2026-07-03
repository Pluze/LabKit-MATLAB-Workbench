# Agent Constitution

This repository is an internal MATLAB app workbench for lab GUI workflows. It is not a monolithic analysis platform. Apps are first-class deliverables; `+labkit` is a small reusable foundation with UI, image, thermal, DTA, RHS, and biosignal facades.

## Read Order

Use the smallest read set that can answer the task safely. For narrow,
behavior-preserving source or test edits, use the fast path:

1. `AGENTS.md`
2. Any nearer scoped `AGENTS.md` files under the touched path
3. The source, test, or human docs directly involved in the task

Read `README.md` only when the task affects advertised project entry points,
app lists, user-facing setup, or default validation entry points.

Use the deep pass only when the change affects public behavior, package
boundaries, validation policy, CI handoff, app workflow rules, or migration
roadmaps:

Read component docs only when relevant:

- `docs/architecture.md` for package boundaries or entrypoint work
- `docs/ui.md` for reusable GUI shell, components, or layout work
- `docs/image.md` for image file IO, display normalization, resizing,
  filtering, enhancement primitives, or image facade work
- `docs/thermal.md` for thermal image file parsing, raw-to-temperature
  conversion, thermal rendering, or FLIR radiometric JPEG work
- `docs/dta.md` for DTA API, parser, item, pulse, or session work
- `docs/rhs.md` for RHS API, parser, channel metadata, indexing, or waveform window reads
- `docs/biosignal.md` for biosignal recording, waveform processing, events, or wearable work
- `docs/apps.md` for app entrypoints, app-owned workflow, or new app work
- `docs/testing.md` for validation choices or test layout changes

Read only the hot-path sections of `.agents/migration_guide.md` for app-runner
migrations, debt burn-down planning, app `private/` debt, or future migration
debt handling. Read debt-specific notes only when the ledger records active
debt for the touched area.

## Core Rules

- Preserve behavior unless the user explicitly asks for a behavior change.
- Keep app-specific formulas, thresholds, plots, result schemas, exports, and workflow decisions in the owning app.
- Keep reusable `+labkit` API growth conservative and domain-neutral.
- New app-facing UI work should use `labkit.ui.app.*`, `labkit.ui.spec.*`, `labkit.ui.view.*`, `labkit.ui.tool.*`, and `labkit.ui.diag.*`; the older flat `labkit.ui.*` helper surface has been removed.
- New app code must not call `labkit.io.*`, `labkit.data.*`, `labkit.analysis.*`, or `labkit.util.*`; use `labkit.dta.*`, `labkit.rhs.*`, `labkit.biosignal.*`, `labkit.image.*`, `labkit.thermal.*`, `labkit.ui.*`, or app-local helpers.
- Do not reintroduce root-level legacy command wrappers, app-specific public helper packages, or public helper-dump packages such as `+labkit/+analysis`, `+data`, `+io`, or `+util`.
- Do not convert struct models to MATLAB classes, rewrite all GUIs, replace separate app entry points with one launcher, or migrate code to another language without explicit approval.
- Treat file line budgets as maintainability backstops, not extraction goals. Do not create or preserve tiny app helpers solely to lower a `run.m` line count; keep callback-local glue local when that makes workflow order clearer, and extract only cohesive app-owned contracts or reusable framework mechanics.
- Path or file-target collections must use string arrays or cell arrays. Never build multiple paths with char bracket concatenation such as `[fullfile(...), fullfile(...)]`.
- Folder/path scalars must not be reshaped with `(:)`, because char paths become one element per character. Use `string(folder)` for one selected folder/path and reserve `paths(:)` for values already known to be string arrays or cell arrays of paths.
- UI numeric control values must be sanitized to finite scalars before they are assigned into app state, step structs, or task structs. Do not write `step.amount = double(amount)` or similar directly from callback values; use a small scalar-normalization helper with a fallback.
- User-visible UI text that also acts as a state enum, branch key, dropdown value, action label, or test contract must have one app-local source of truth, such as a `+userInterface/*Labels.m`, `+userInterface/*Choices.m`, or workflow-owned `*Items.m` helper. Do not repeat those literals in runners, view helpers, or tests; callers and tests should reference the helper. One-off section labels that are only displayed in `+userInterface/buildWorkbenchSpec.m` may stay inline.

Default principle:

```text
same results, cleaner code, clearer boundaries
```

Governance cost rule: add or expand docs, AGENTS rules, skills, or guardrails
only when they prevent a concrete drift or clarify an active contract. Prefer
shrinking or deleting migration guidance as debt is resolved. Do not treat more
governance as progress by itself.

Token cost rule: when multiple repo skills apply, avoid rereading the same
AGENTS or docs content for each skill. Read shared context once, then read only
the skill-specific decision sections needed for the current edit.

## Documentation Separation

Human-facing docs are for human users and maintainers. Keep `README.md` and `docs/*.md` readable, task-oriented, and free of agent-only workflow mandates, Codex-specific rules, git handoff instructions, or hidden governance process.

Agent-facing rules belong in the nearest relevant `AGENTS.md` file or repo-scoped skill. Sync documentation by contract impact, not by file count. Do not treat every code change as requiring README, human docs, scoped `AGENTS.md`, skills, and tests all at once.

When behavior, package boundaries, validation strategy, or workflow rules change, update both:

- the affected human docs that explain the current project behavior or contract
- the affected scoped `AGENTS.md` files that govern future agent work

Use this decision rule:

- Internal refactors that preserve user-facing behavior and governance rules usually need source/tests only.
- User-facing app behavior changes update the human app docs that advertise or explain that behavior.
- Public facade or package-boundary changes update the relevant component docs and package guardrails.
- Test layout, validation, fixture, or hygiene-policy changes update `docs/testing.md` and test agent rules when agent routing changes.
- Agent workflow or ownership-rule changes update the nearest scoped `AGENTS.md` or repo skill; update human docs only when the human-facing contract also changes.

If a nontrivial change does not update human docs or scoped agent docs, say why in the handoff, for example: `Docs/AGENTS unchanged; behavior and governance contracts were preserved.`

Do not duplicate long policy text across human docs. Human docs may explain architecture, app behavior, public APIs, and test commands; agent docs own execution rules.

## Public API Documentation

Every public library function under `+labkit/+ui`, `+labkit/+image`, `+labkit/+thermal`, `+labkit/+dta`, `+labkit/+rhs`, and `+labkit/+biosignal` must document its app-facing call contract immediately after the function declaration. Include inputs, outputs, options/spec fields, defaults, legal values, and examples where useful.

Private and app-owned package helpers must include concise top-of-file implementation contracts: expected caller, input/output shapes, side effects, and non-obvious assumptions.

## Sensitive Sample Data

Do not introduce sensitive or identifying sample-data details into source, tests, docs, comments, commit messages, or generated artifacts.

When using local lab files to reproduce a bug:

- Do not copy raw sample files, local absolute paths, shared-drive paths, filenames, subject/user names, device serials, experiment labels, timestamps, parser-version strings, or other identifying metadata into tracked files.
- Preserve only synthetic structural details needed for regression coverage, such as preamble rows, header shape, delimiter style, count rows, footer rows, missing values, or time-column behavior.
- Use generic labels such as `DEVICE`, `PrimaryChannel`, `capture start`, and `footer metadata row`.
- Before committing sample-format fixes, search the diff for local paths, original filenames, names, device IDs, timestamps, and other recognizable source-file strings.

## Validation

Run relevant automated checks after executable MATLAB, test, fixture, package, or validation-rule changes. Use the smallest source-aligned checks during iteration and reserve broader changed-file or default non-GUI gates for coherent checkpoints, handoff, release work, or changes whose ownership is unclear.

Use `docs/testing.md` as the canonical command matrix for build tasks, CI
scope, fixture expectations, and GUI validation limits. Scoped
`AGENTS.md` files should only route by ownership and should not duplicate the
full task list.

For dirty worktrees, use a staged validation cadence. While actively editing a
known component, prefer the smallest direct `runLabKitTests("Suites", ...)`
selection that covers the behavior being changed. Run the fast changed-file
gate once at a coherent local checkpoint, and run the conservative
changed-file gate before commit, PR handoff, or direct-main push unless a
broader completed gate already covers the current diff. Do not rerun
changed-file build tasks after every small edit when a focused suite can
validate the same behavior. Prefer non-disruptive validation while the user is
actively working; local GUI gates can steal keyboard focus and should be run
only when necessary or explicitly requested.

In noninteractive agent shells, run the selected MATLAB build task directly.
If the shell cannot find `buildtool`, locate MATLAB without adding a
repository wrapper, for example:

```bash
ls /Applications/MATLAB_*.app/bin/matlab
export PATH="/Applications/MATLAB_R2025a.app/bin:$PATH"
```

Then rerun the same build task. If MATLAB exits before printing the selected
build-task banner or a LabKit test-run banner, treat that as a MATLAB launcher
or runtime-access failure first. Do not diagnose source or test failures from
an empty launcher result.

For commands that are known to require host runtime or network/keychain access,
use escalated sandbox permissions on the first run instead of probing in the
restricted sandbox and then retrying. This includes MATLAB build/test commands
(`buildtool ...`, direct `/Applications/MATLAB_*.app/bin/matlab -batch ...`,
and focused `runLabKitTests(...)` invocations) and GitHub CLI/API inspection
commands (`gh auth status`, `gh run ...`, `gh pr ...`, `gh release ...`, and
equivalent `curl https://api.github.com/...` checks). Treat the escalated run
as the decisive local result; if escalation itself is blocked, report that
approval blocker explicitly.

Do not add MATLAB Code Analyzer suppression pragmas such as `%#ok<...>` in
source, tests, fixtures, or generated MATLAB files. Refactor the code or test
helper shape instead; the project guardrails intentionally reject suppression
pragmas.

Interactive GUI workflows are checked manually by the user. Do not run interactive GUI workflows in MATLAB `-batch` mode. If MATLAB cannot run, report the blocker and do not claim tests passed.

## Git Workflow

1. Inspect status before editing.
2. For small, focused updates, work directly on `main` by default after
   confirming local `main` is aligned with `origin/main`. Use a dedicated
   development branch only for larger, riskier, multi-commit, cross-area, or
   review-heavy work. Branch names should use the `codex/` prefix unless the
   user requests another name.
3. Keep commits logical and purpose-based. Commits do not need to be extremely dense; for larger efforts, prefer phase commits at stable checkpoints.
4. Do not mix unrelated functional, documentation, formatting, or test changes in the same commit.
5. Run relevant tests or explain why they were not run.
6. Review the diff for unrelated changes.
7. Commit with a concise Conventional Commits message.
8. After a coherent series of changes is complete, check the current `main` and `origin/main` state before pushing directly or opening a PR. If the development branch is behind, update it only with non-destructive git operations and do not discard user work.
9. For direct-`main` work, push `main` after validation and then fetch/prune
   `origin` and verify local `main` still matches `origin/main`. For branch
   work, push the completed branch, open a PR, and include the change scope,
   test results, unverified behavior, and any intentional follow-up work.
10. For branch/PR work, do not inspect or poll CI after every push unless the
    user explicitly asks, a local validation result needs remote confirmation,
    or GitHub reports an obvious failure that must be triaged before more work.
    Record the pushed branch and PR, then defer CI inspection until the branch
    is ready to merge. For direct-`main` work, inspect the final triggered CI
    run once because there is no later merge gate. When CI inspection is
    required, prefer low-output status checks such as `gh run list` or
    `gh run view --json status,conclusion,jobs`; use streaming `gh run watch`
    only when concise status polling is insufficient. If the user requests a
    follow-up while a previous direct-main CI run is still in progress, continue
    the follow-up locally and inspect CI for the newest pushed commit instead
    of waiting for a superseded run. If CI fails, read only the failing job
    logs, fix the underlying issue, rerun the relevant local checks, push the
    fix, and repeat until required CI passes. A task is not complete while
    required CI for the latest pushed commit is red, unless CI access or
    infrastructure is blocked and the blocker is reported explicitly.
11. Before merging a PR, inspect required CI. If a status read needs waiting,
    find the most recent successful run for the same workflow/branch and wait
    at least that run's total elapsed duration; use the same duration as the
    minimum interval between later status reads so CI polling does not become
    noisy. After required CI passes and no blocking review remains, merge the PR with
    an allowed repository merge method and delete the remote development
    branch.
12. After a successful merge, keep the local checkout aligned with the remote
    default branch before ending the task: fetch/prune `origin`, switch to
    `main`, fast-forward local `main` to `origin/main`, delete the merged local
    development branch, and verify `git status --short --branch` shows local
    `main` and `origin/main` in sync. Do not leave the workspace on a merged
    feature branch or with stale development refs unless a permission,
    unmerged-work, or local-change blocker prevents cleanup.
13. If permissions, CI, branch protection, review state, tool availability,
    merge-method policy, fast-forward sync, or branch deletion prevent push, CI
    inspection, PR creation, merge, local/remote cleanup, or branch deletion,
    stop and report the exact blocker instead of working around it.
14. Do not force-push unless explicitly approved.

Any text that can become a commit subject must satisfy the same Conventional
Commit prefix rule below. This includes local `git commit -m` subjects,
`git commit --amend` subjects, PR titles when the repository may squash-merge
from the title, `gh pr merge --squash --subject ...`, auto-merge subjects, and
any manual merge, backport, or release commit subject. Never rely on GitHub or
`gh` defaults for squash commits; pass an explicit compliant `--subject` or
rename the PR title before merging. Do not use `[codex]`, ticket labels, branch
labels, or other non-Conventional prefixes in any subject that may land in git
history.

Use exactly one lowercase Conventional Commit type prefix from this list:

- `feat:` for a user-visible capability, public API, app workflow, supported
  command, or documented behavior that did not exist before.
- `fix:` for correcting broken, regressed, incompatible, or misleading
  behavior. Use this when the primary effect is restoring expected behavior,
  even if the patch also refactors code.
- `perf:` for a measured or clearly performance-motivated change whose primary
  user or maintainer effect is lower latency, lower memory use, less repeated
  work, faster startup/shutdown, or faster validation. Prefer `refactor:` when
  the performance effect is incidental or unmeasured.
- `refactor:` for behavior-preserving source restructuring, boundary cleanup,
  helper extraction/inlining, or implementation simplification that is not
  primarily a bug fix or performance change.
- `test:` for test files, fixtures, runner behavior, validation routing, or
  guardrails. Use `ci:` instead when the change is mainly workflow
  infrastructure.
- `docs:` for human docs, AGENTS rules, skills, or process text when tracked
  executable behavior is not changed.
- `ci:` for GitHub Actions, build automation, release automation, CI shard
  wiring, or hosted-runner policy.
- `chore:` for version metadata, dependency metadata, repository housekeeping,
  generated metadata, or other maintenance that does not fit the types above.

Do not invent new type prefixes. When a commit mixes scopes, choose the type
for the primary user-visible or maintenance effect, and split the commit when
one type would hide a distinct behavior, test, documentation, or CI change.

## Release Workflow

Use `docs/release.md` as the human-facing source of truth for version-number
selection, release tag naming, and GitHub release note format.

For new releases, use `vX.Y.Z` tags, for example `v2.2.0`. Do not rename or
delete already published historical tags only to normalize naming; preserve
them for compatibility with existing links and user checkouts. If a legacy tag
such as `2.1` already exists, keep it and use the normalized `vX.Y.Z` style for
future releases.

Use GitHub release titles in the form `LabKit MATLAB Workbench vX.Y.Z` and
organize notes with `Highlights`, `Fixes`, `Upgrade Note`, and `Validation`
sections, omitting empty sections. Before publishing, verify the release tag
points at the intended commit and report the release URL.

Release assets must be reproducible from the tag. Export `labkit_launcher.m`
from the tag blob, for example
`git show vX.Y.Z:labkit_launcher.m > artifacts/release/vX.Y.Z/labkit_launcher.m`,
and upload that exported file rather than a working-tree copy. Before upload,
compare the tag blob and staged asset with `shasum -a 256` and `wc -c`. After
publishing, inspect `gh release view vX.Y.Z --json assets` and verify the
uploaded asset size and SHA-256 digest match the staged file. If they differ,
replace only the asset with the tag-exported file; do not move a published tag.

## Handoff

Report:

- changed files
- branch name
- commit hash and push status
- PR URL, CI status, merge status, and branch deletion status when remote handoff was attempted
- what was intentionally not changed
- test commands and results
- blockers or unverified behavior
- recommended next step
