# Agent Constitution

This repository is an internal MATLAB app workbench for lab GUI workflows. It is not a monolithic analysis platform. Apps are first-class deliverables; `+labkit` is a small reusable foundation with UI, DTA, and biosignal facades.

## Read Order

Before editing:

1. `README.md`
2. `AGENTS.md`
3. Any nearer scoped `AGENTS.md` files under the touched path
4. The source, test, or human docs directly involved in the task

Read component docs only when relevant:

- `docs/architecture.md` for package boundaries or entrypoint work
- `docs/ui.md` for reusable GUI shell, components, or layout work
- `docs/dta.md` for DTA API, parser, item, pulse, or session work
- `docs/biosignal.md` for biosignal recording, waveform processing, events, or wearable work
- `docs/apps.md` for app entrypoints, app-owned workflow, or new app work
- `docs/testing.md` for validation choices or test layout changes

## Core Rules

- Preserve behavior unless the user explicitly asks for a behavior change.
- Keep app-specific formulas, thresholds, plots, result schemas, exports, and workflow decisions in the owning app.
- Keep reusable `+labkit` API growth conservative and domain-neutral.
- New app-facing UI work should use `labkit.ui.createAppShell`, `labkit.ui.createDebugContext`, `labkit.ui.createInteractionRuntime`, and `labkit.ui.dispatchAppRequest`; older UI helper names are deprecated compatibility surface.
- New app code must not call `labkit.io.*`, `labkit.data.*`, `labkit.analysis.*`, or `labkit.util.*`; use `labkit.dta.*`, `labkit.biosignal.*`, `labkit.ui.*`, or app-local helpers.
- Do not reintroduce root-level legacy command wrappers, app-specific public helper packages, or public helper-dump packages such as `+labkit/+analysis`, `+data`, `+io`, or `+util`.
- Do not convert struct models to MATLAB classes, rewrite all GUIs, replace separate app entry points with one launcher, or migrate code to another language without explicit approval.

Default principle:

```text
same results, cleaner code, clearer boundaries
```

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

Every public library function under `+labkit/+ui`, `+labkit/+dta`, and `+labkit/+biosignal` must document its app-facing call contract immediately after the function declaration. Include inputs, outputs, options/spec fields, defaults, legal values, and examples where useful.

Private package helpers must include concise top-of-file implementation contracts: expected caller, input/output shapes, side effects, and non-obvious assumptions.

## Sensitive Sample Data

Do not introduce sensitive or identifying sample-data details into source, tests, docs, comments, commit messages, or generated artifacts.

When using local lab files to reproduce a bug:

- Do not copy raw sample files, local absolute paths, shared-drive paths, filenames, subject/user names, device serials, experiment labels, timestamps, parser-version strings, or other identifying metadata into tracked files.
- Preserve only synthetic structural details needed for regression coverage, such as preamble rows, header shape, delimiter style, count rows, footer rows, missing values, or time-column behavior.
- Use generic labels such as `DEVICE`, `PrimaryChannel`, `capture start`, and `footer metadata row`.
- Before committing sample-format fixes, search the diff for local paths, original filenames, names, device IDs, timestamps, and other recognizable source-file strings.

## Validation

Run relevant automated checks after executable MATLAB, test, fixture, package, or validation-rule changes. Use focused checks during iteration and the default non-GUI suite for broad changes.

Common commands:

```bash
scripts/run_matlab_tests.sh --suite project
scripts/run_matlab_tests.sh --suite labkit/dta
scripts/run_matlab_tests.sh --suite labkit/biosignal
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
scripts/run_matlab_tests.sh
```

On Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project
```

Interactive GUI workflows are checked manually by the user. Do not run interactive GUI workflows in MATLAB `-batch` mode. If MATLAB cannot run, report the blocker and do not claim tests passed.

## Git Workflow

1. Inspect status before editing.
2. Work on a dedicated development branch by default. Branch names should use the `codex/` prefix unless the user requests another name.
3. Keep commits logical and purpose-based. Commits do not need to be extremely dense; for larger efforts, prefer phase commits at stable checkpoints.
4. Do not mix unrelated functional, documentation, formatting, or test changes in the same commit.
5. Run relevant tests or explain why they were not run.
6. Review the diff for unrelated changes.
7. Commit with a concise Conventional Commits message.
8. After a coherent series of changes is complete, check the current `main` and `origin/main` state before opening a PR. If the development branch is behind, update it only with non-destructive git operations and do not discard user work.
9. Push the completed branch, open a PR, and include the change scope, test results, unverified behavior, and any intentional follow-up work.
10. After required CI passes and no blocking review remains, merge the PR and delete the development branch.
11. If permissions, CI, branch protection, review state, or tool availability prevent push, PR creation, merge, or branch deletion, stop and report the exact blocker instead of working around it.
12. Do not force-push unless explicitly approved.

Use lowercase type prefixes such as `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `refactor:`, and `chore:`.

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
