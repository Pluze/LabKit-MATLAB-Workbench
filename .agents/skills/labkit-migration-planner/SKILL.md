---
name: labkit-migration-planner
description: "Use for LabKit migration roadmap work, runner/private helper debt scans, app-owned package migration planning, migration guide updates, recent git-history reviews, or aligning guardrail inventories with current debt. Coordinate with labkit-boundary-guard for app-vs-library ownership and labkit-test-planner for validation routing."
---

# LabKit Migration Planner

## Goal

Keep LabKit migration guidance current without creating another governance
layer.

This skill owns the workflow for auditing and updating
`.agents/migration_guide.md`. It does not own architecture policy, app-building
patterns, or the validation command matrix.

## Required Read Order

1. `AGENTS.md`
2. `.agents/migration_guide.md`
3. `docs/architecture.md`
4. `docs/apps.md` when app entrypoint or app-owned package shape is involved
5. `docs/testing.md` when validation routing or CI scope is involved
6. Relevant scoped `AGENTS.md` files and touched source/tests

Use `labkit-boundary-guard` when deciding whether code belongs in `+labkit` or
an app-owned package. Use `labkit-test-planner` before running or reporting
validation.

## Audit Pass

Before changing migration guidance, inspect current facts instead of trusting
old prose:

```bash
git status --short --branch
git log --oneline -n 40
find apps -path '*+ui/runApp.m' -print | sort
find apps -path '*/private/*' -type f -print | sort
rg -n "expectedOversizedRunnerDebtFiles|expectedAppPrivateDebtFiles|expectedPrivateContractDebtFiles" tests/integration/project
```

For runner size checks, count the `+ui/runApp.m` files that matter to the
requested migration. Do not treat a line-count drop as success unless directly
tested behavior moved out of the runner and the GUI path calls the extracted
helper.

## Update Rules

- Keep `.agents/migration_guide.md` as the only active migration roadmap.
- Human docs should describe current behavior and boundaries, not migration
  execution steps.
- Debt inventories must match guardrail expectations and current files.
- Remove resolved debt from the guide, guardrail expected lists, and roadmap in
  the same change.
- Do not add a second governance doc or standalone migration handbook.
- Do not add scripts for v1 audits unless repeated manual scans prove the need.

## Migration Decision

For each proposed migration, classify work as:

- app-owned deterministic behavior: extract under the owning app package
- runner orchestration: leave in the public entrypoint or `+ui/runApp.m`
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
