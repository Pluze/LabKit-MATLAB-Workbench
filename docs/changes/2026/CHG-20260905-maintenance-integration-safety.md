# Preserve task work and integrate parallel PRs safely

```labkit-change
id: CHG-20260905-maintenance-integration-safety
date: 2026-09-05
type: fix
compatibility: compatible
component: repository
```

## Why

Task checkouts live beneath the ignored artifacts directory, but recursive artifact cleanup treated that whole directory as disposable output. This could remove unfinished source with generated reports. Parallel PRs also become stale as main advances; treating every necessary task-branch replay as a separate permission decision transferred routine integration work to the user. Cleanup and integration now distinguish accepted work, active task content, and disposable output at their respective owners.

## What changed

Clean Artifacts reserves the worktrees directory, removes generated siblings, and validates all selected targets before deleting any. Installations without that reserved directory retain whole-artifacts cleanup. Tool help and Launcher guidance describe the removal boundary and root-relative result paths.

A request to merge PRs authorizes the agent to review dependencies and overlapping contracts, replay task changes, reconstruct conflicting files where justified, and publish guarded task-branch updates. The agent compares the previous and proposed task deltas, preserves recoverable old tips and unrelated work, and requires current validation. Main protection, CI, and review remain enforced. Ambiguous product or scientific decisions and uncertain ownership still require resolution rather than a blind choice of one side.

The PR inventory reports new component versions and can compare task deltas across accepted main changes, exposing shared files, changed patches, and removed or added task paths. This report supports semantic review; matching patches do not prove that independently changed contracts compose. Skill portability checks ignore generated Python bytecode caches while continuing to inspect authored sources.

## Impact

Maintainers can clean generated output while task source remains available. Authorized integration handles routine branch mechanics and preserves each PR's intended behavior, including the necessary version and documentation reconciliation. A changed remote head requires fresh inspection; it cannot be overwritten by simply refreshing a lease. New-component metadata is visible in the final inventory, and executing agent scripts does not make their generated caches appear to violate source portability.

## Compatibility and limits

Cleanup retains its syntax and result fields. With worktrees present, removedTargets names removed children relative to the installation root and removedCount counts those children; the artifacts parent remains. Generated files inside worktrees stay task-owned until explicit accepted-task cleanup. Task-branch history updates require an exact old-head lease within the authorized integration; main cannot be force-pushed and repository protection cannot be weakened. App calculations, saved data, and scientific outputs are unchanged.
