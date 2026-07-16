---
name: labkit-migration-planner
description: "Use for active LabKit migration debt, compatibility retirement, app-structure debt scans, or migration ledger changes. Do not use for ordinary app development or general code cleanup when no migration boundary is involved."
---

# LabKit Migration Planner

## Purpose

Keep `.agents/migration_guide.md` factual and temporary. The ledger records
active migration work only; architecture, history, and validation commands
have their own owners.

## Read

1. `AGENTS.md`
2. `.agents/migration_guide.md`
3. nearest scoped `AGENTS.md`
4. affected source and tests

Use `labkit-boundary-guard` for app-versus-library ownership and
`labkit-test-planner` for validation. Read
`docs/development/architecture.md` only when a package boundary changes.

## Audit current facts

Before editing the ledger, inspect the current tree rather than trusting an old
route:

```bash
git status --short --branch
find apps -path '*/+*/run.m' -o -path '*/+ui/runApp.m'
find apps -path '*/private/*' -type f
rg -n "LegacyImports|Migrations" apps --glob 'definition.m'
```

Classify findings as:

- active debt: a current compatibility or transitional implementation with a
  concrete retirement condition;
- intentional compatibility: a documented read-only importer, ordered project
  migration, or versioned facade alias that remains supported;
- current architecture: ordinary definitions, action registries, presenters,
  workflow packages, and private framework mechanics;
- cleanup opportunity: ordinary refactoring that does not belong in the debt
  ledger.

Line count and helper count are review signals, never debt by themselves.
`definitionActions.m` is not a compatibility wrapper merely because it routes
semantic actions to app-owned workflow functions.

## Ledger entry contract

An active entry states:

- owner and affected paths;
- current behavior that must remain stable;
- obsolete layer or compatibility surface being retired;
- completion and removal conditions;
- focused automated validation and any manual GUI check.

Temporary Toolbox debt also follows the fields required by `AGENTS.md` and
`tests/runner/labkitToolboxDebt.m`.

Delete resolved routes and debt-specific guardrails in the same change. Do not
preserve completed plans, prior CI results, PR status, historical narrative, or
architecture rules in the ledger.

## Handoff

Report the facts audited, debt classification, ledger changes, focused tests,
and any compatibility behavior intentionally retained.
