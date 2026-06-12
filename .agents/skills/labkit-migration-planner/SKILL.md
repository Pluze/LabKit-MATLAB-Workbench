---
name: labkit-migration-planner
description: "Use for LabKit migration roadmap work, runner/private helper debt scans, app-owned package migration planning, project-health and overengineering reviews from git history, migration guide updates, or aligning guardrail inventories with current debt. Coordinate with labkit-boundary-guard for app-vs-library ownership and labkit-test-planner for validation routing."
---

# LabKit Migration Planner

## Goal

Keep LabKit migration guidance current without creating another governance
layer.

This skill owns the workflow for auditing and updating
`.agents/migration_guide.md`. It does not own architecture policy, app-building
patterns, or the validation command matrix.

## Required Read Order

Start with a quick pass:

1. `AGENTS.md`
2. `.agents/migration_guide.md` through `Current Debt Snapshot`
3. Relevant scoped `AGENTS.md` files and touched source/tests

Use a deep pass only when the task needs it:

- read `Migration Standard` and `Future Debt Rules` before editing the guide
- read debt-specific notes only if the guide records active debt for that area
- read `docs/architecture.md` for package-boundary or debt-exception changes
- read `docs/apps.md` for app entrypoint or app-owned package shape changes
- read `docs/testing.md` only when validation routing or CI scope changes

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
find apps -path '*+ui/buildSpec.m' -print | sort
find apps -path '*/private/*' -type f -print | sort
rg -n "expected\\w*Debt\\w*" tests/integration/project
```

For runner size checks, count migrated package-root `run.m` files. A
`+ui/runApp.m` file is migration debt, not the final app structure. Do not
treat a line-count drop as success unless directly tested behavior moved out of
the runner and the GUI path calls the extracted helper.

## Health Review

When asked about project health, overengineering, management quality, or
whether migration work is useful, ground the answer in evidence:

- recent commit mix: feature, fix, test, refactor, docs, CI, and merge density
- current debt facts: oversized runners, app `private` helpers, stale expected
  debt lists, and removed legacy surfaces
- validation health: latest local checks, latest CI, and whether red CI was
  fixed before more migration work
- governance weight: size and overlap of docs, AGENTS, skills, migration guide,
  and project guardrails
- behavior evidence: direct tests for extracted helpers and real GUI paths that
  call those helpers

Call work healthy only when refactoring reduces real complexity or risk. Flag
work as overengineered when it adds rules, documents, helper layers, or exact
guardrails without reducing active debt or clarifying an app-facing contract.

## Update Rules

- Keep `.agents/migration_guide.md` as the only active migration debt ledger.
- Human docs should describe current behavior and boundaries, not migration
  execution steps.
- Debt inventories must match guardrail expectations and current files.
- Remove resolved debt from the guide, guardrail expected lists, and roadmap in
  the same change.
- When all debt inventories are empty, keep the guide as a compact zero-debt
  ledger. Prefer shrinking roadmap prose over adding new plans, scripts, or
  governance layers.
- Do not add a second governance doc or standalone migration handbook.
- Do not add scripts for v1 audits unless repeated manual scans prove the need.

## Migration Decision

For each proposed migration, classify work as:

- app-owned deterministic behavior: extract under the owning app package
- migrated ordinary UI: keep the data-only spec in
  `+<app_slug>/+ui/buildSpec.m`; use app-local custom builders only for
  justified interactions
- runner orchestration: keep it in package-root `run.m` after migration; public
  entrypoints stay thin wrappers
- reusable foundation: use `labkit-boundary-guard` before touching `+labkit`
- validation routing: use `labkit-test-planner`
- documentation drift: update only the source that owns the changed contract

Migration progress means behavior becomes clearer, directly testable, and used
by the real GUI path. Moving a large block into another large helper is not
progress.

## Handoff Requirements

Report:

- current debt facts checked
- migration guide changes
- guardrail inventory changes
- docs or scoped AGENTS intentionally unchanged, with reason
- validation commands and CI status when pushed
