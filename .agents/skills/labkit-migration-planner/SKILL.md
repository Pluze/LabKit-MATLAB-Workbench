---
name: labkit-migration-planner
description: "Use for LabKit migration-debt work, runner/private helper debt scans, app-owned package migration planning, project-health and overengineering reviews from git history, migration guide updates, or aligning guardrails with current debt. Coordinate with labkit-boundary-guard for app-vs-library ownership and labkit-test-planner for validation routing."
---

# LabKit Migration Planner

## Goal

Keep LabKit migration guidance executable and current without creating another
governance layer.

This skill owns the workflow for auditing and updating
`.agents/migration_guide.md`. The guide may contain active migration debt,
retirement rules, and explicitly requested executable goal prompts. It does not
own architecture policy, app-building patterns, or the validation command
matrix.

## Required Read Order

Start with a quick pass:

1. `AGENTS.md`
2. `.agents/migration_guide.md` through `Current Debt Snapshot`
3. Relevant scoped `AGENTS.md` files and touched source/tests

Use a deep pass only when the task needs it:

- read `Migration Standard` and `Future Debt Rules` before editing the guide
- read any `Goal Prompt:` section completely before executing or revising an
  unattended migration route
- read debt-specific notes only if the guide records active debt for that area
- read `docs/development/architecture.md` for package-boundary or debt-exception changes
- read `docs/apps/README.md` for current app workflows and
  `docs/development/app-development.md` for app-owned package shape changes
- read `docs/development/testing.md` only when validation routing or CI scope changes

Use `labkit-boundary-guard` when deciding whether code belongs in `+labkit` or
an app-owned package. Use `labkit-test-planner` before running or reporting
validation, but do not reread shared AGENTS/docs content already inspected in
this pass.

## Audit Pass

Before changing migration guidance, inspect current facts instead of trusting
old prose:

```bash
git status --short --branch
git log --oneline -n 40
find apps -path '*+ui/runApp.m' -print | sort
find apps -path '*/+*/run.m' -print | sort
find apps -path '*+userInterface/buildWorkbenchLayout.m' -print | sort
find apps -path '*/private/*' -type f -print | sort
rg -n "expected\\w*Debt\\w*" tests/contract
```

For runner size checks, count package-root `run.m` files. A `+ui/runApp.m`
file is active app-structure debt. Do not treat a line-count drop as success
unless directly tested behavior moved out of the runner and the GUI path calls
the extracted helper.

For runner-complexity work, scan helper quality as well as file length:

- count package-root `run.m` files and sort by line count
- count short app helpers, excluding public entrypoints, `requirements.m`,
  `version.m`, package-root `run.m`, and target
  `+userInterface/buildWorkbenchLayout.m`
- identify repeated micro-helper families and one-call pass-through wrappers
- classify short helpers by boundary signal before proposing new extraction:
  public framework API, framework-private implementation, app state contract,
  IO/input policy, export or dialog side-effect boundary, view formatting,
  small pure operation, test/runner API, or generic helper
- treat a one-call generic helper without test references as an inline/merge
  candidate; treat a one-call role helper as a contract-review candidate, not
  as automatic debt
- treat roughly 500 runner lines as a review threshold and roughly 625 lines as
  a budget-watchlist trigger. A watchlist runner is not active migration debt
  by line count alone; record debt only when the next change would add
  unrelated behavior or the audit finds a concrete responsibility split.

## Health Review

When asked about project health, overengineering, management quality, or
whether migration work is useful, ground the answer in evidence:

- recent commit mix: feature, fix, test, refactor, docs, CI, and merge density
- current debt facts: budget-watchlist runners, app `private` helpers, stale
  debt ledger entries, helper-audit findings, and removed legacy surfaces
- validation health: latest local checks, latest CI, and whether red CI was
  fixed before more migration work
- governance weight: size and overlap of docs, AGENTS, skills, migration guide,
  and project guardrails
- behavior evidence: direct tests for extracted helpers and real GUI paths that
  call those helpers

Call work healthy only when refactoring reduces real complexity or risk. Flag
work as overengineered when it adds rules, documents, helper layers, or exact
guardrails without reducing active debt or clarifying an app-facing contract.

## Executable Goal Prompt Mode

Use this mode when the user asks to execute or complete a migration route,
asks for an unattended goal, or asks to make `.agents/migration_guide.md`
runnable by another agent.

Treat a `Goal Prompt:` section as the active task contract. It should be
specific enough for a capable coding agent to continue until the migration is
complete without asking for another plan. Before executing it:

- verify current repository facts instead of trusting stale prompt prose
- convert the workstreams into an explicit task plan
- keep the guide updated when facts, workstreams, blockers, validation gates, or
  completion criteria change
- prefer dynamic discovery and current source contracts over hard-coded lists
- continue by phase until completion criteria are met or a blocker in the prompt
  is actually reached

A good executable prompt includes:

- objective
- operating principles
- current facts to preserve
- target shape
- required workstreams
- non-goals
- validation gates
- blockers
- completion criteria
- handoff expectations

During execution, update the guide at phase boundaries and when decisions
change. Do not log every micro-step. When the migration completes, shrink the
guide again: remove completed route detail unless it still defines an active
contract or future debt rule.

At completion, do a final omission audit before handoff:

- inspect whether the migration exposed follow-up issues that are still active
  debt
- if no active migration debt remains, shrink `.agents/migration_guide.md` to
  the compact no-task ledger
- if active debt remains, record only the current debt facts and the minimum
  executable prompt needed to finish them
- do not leave completed `Goal Prompt:` sections, stale workstreams, or
  historical route detail in the guide

## Update Rules

- Keep `.agents/migration_guide.md` as the only active migration debt ledger.
- Allow an explicitly requested `Goal Prompt:` section while a migration route
  is active. Treat it as executable state, not as permanent architecture docs.
- Human docs should describe current behavior and boundaries, not migration
  execution steps.
- Debt inventories must match guardrail expectations and current files.
- Remove resolved debt from the guide and guardrails in the same change.
- When all debt inventories are empty, keep the guide as a compact zero-debt
  ledger. Prefer shrinking roadmap prose over adding new plans, scripts, or
  governance layers.
- Do not add a second governance doc or standalone migration handbook.
- Do not add scripts for v1 audits unless repeated manual scans prove the need.
- Do not preserve old guide prose just because it helped a completed migration.
  Finished routes should either become current docs/tests/contracts or be
  removed.

## Migration Decision

For each proposed migration, classify work as:

- app-owned deterministic behavior: extract under the owning app package
- ordinary UI: keep the data-only spec in
  `+<app_slug>/+userInterface/buildWorkbenchLayout.m`; use app-local custom
  builders only for justified interactions
- runtime orchestration: use the current `labkit.ui.runtime.define` plus
  `labkit.ui.runtime.launch`; public entrypoints stay thin launch wrappers and
  request dispatch, runtime construction, queueing, and presentation commits
  remain private framework mechanics
- reusable foundation: use `labkit-boundary-guard` before touching `+labkit`
- validation routing: use `labkit-test-planner`
- documentation drift: update only the source that owns the changed contract

Migration progress means behavior becomes clearer, directly testable, and used
by the real GUI path. Moving a large block into another large helper is not
progress.

For helper extraction, prefer responsibility quality over helper count:

- keep small callback-local code inline or nested when a separate file hides
  state mutation or workflow order
- keep or create app-owned helpers when they protect deterministic state,
  IO/file discovery, GUI-free operations, export boundaries, display data, or
  focused custom UI/tool glue. Prefer workflow-named packages such as
  `+sourceFiles`, `+analysisRun`, `+resultFiles`, `+cropGeometry`,
  `+thermalFrames`, or `+debugArtifacts` for new target-shape code
- treat short output-writer files as valid side-effect boundaries when they
  isolate output writes behind an explicit export contract
- treat small public facades, test helpers, state factories, input filters, and
  app-owned side-effect boundaries as valid files when their names expose a
  caller-facing contract
- promote to `+labkit` only after the boundary guard proves a domain-neutral
  app-facing contract
- do not add a blocking short-helper guardrail until a reviewed dry-run report
  can avoid false positives for valid small contracts

## Handoff Requirements

Report:

- current debt facts checked
- migration guide changes
- active goal prompt status when a `Goal Prompt:` route is being executed
- guardrail inventory changes
- docs or scoped AGENTS intentionally unchanged, with reason
- validation commands and CI status when pushed
