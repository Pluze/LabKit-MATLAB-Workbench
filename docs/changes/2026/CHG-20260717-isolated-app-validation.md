# App validation no longer relies on sibling App paths

```labkit-change
id: CHG-20260717-isolated-app-validation
date: 2026-07-17
type: test
compatibility: compatible
component: repository
```

## Why

The ordinary public test setup adds every App entry folder so family and cross-App contract suites can run efficiently. That broad path can conceal an accidental dependency on a sibling App package. Static source scans rejected direct sibling calls, and individual Gait/private launch tests used isolated paths, but there was no uniform executable contract for every public App or automatic changed-file route to that contract.

### Accepted choice

Keep the convenient broad path for ordinary suites, but add one fast independent proof. For each public App, restore MATLAB's default path, add only the repository root and the owning App root, load its complete definition, check declared facade compatibility, and write its synthetic debug sample. Run this contract whenever public App source changes.

Static call scanning and dynamic isolation cover different risks and remain separate. The former identifies the forbidden source reference; the latter proves metadata, framework requirements, and debug generation work in the same path shape as a single-App package.

## What changed

- Added one isolated-path contract covering all 20 public Apps.
- Routed every App source change to that contract in both conservative and fast changed-file plans.
- Added a planner regression so future routing changes cannot silently drop isolation coverage.
- Documented why independent private workspaces must run their own compatibility checks without inheriting public App roots.
- Evaluated, but did not add, a hidden-GUI job to every pull request.

## Impact

There is no App or saved-data behavior change. A new sibling package dependency, stale facade requirement, incomplete definition, or broken debug sample now fails in a focused non-GUI contract instead of passing because all Apps happened to be on the developer's MATLAB path.

## Compatibility and limits

No migration is required. Existing test commands remain unchanged; the changed-file planner adds the focused isolation selection automatically.

### Remaining limits

MATLAB process-global function caches cannot replace package-boundary source review, so the static sibling-call guard remains required. Hidden GUI tests remain bounded semantic checks rather than substitutes for manual interaction and visual assessment.
