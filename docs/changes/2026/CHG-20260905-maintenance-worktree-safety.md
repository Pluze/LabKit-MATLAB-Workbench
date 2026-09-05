# Artifact cleanup preserves task worktrees

```labkit-change
id: CHG-20260905-maintenance-worktree-safety
date: 2026-09-05
type: fix
compatibility: compatible
component: repository
```

## Why

Task checkouts live beneath the ignored artifacts directory, but recursive artifact cleanup treated that whole directory as disposable output. This could remove unfinished task source along with generated reports. The cleanup owner now reserves the worktrees directory without trying to infer task acceptance from Git state; deciding when a task can be removed belongs to integration cleanup.

## What changed

Clean Artifacts preserves the worktrees directory and its contents, removes generated siblings, and validates all selected targets before deleting any of them. Installations without that reserved directory retain whole-artifacts cleanup. The developer tool help and Launcher guidance describe the removal boundary and root-relative result paths.

## Impact

Maintainers can remove generated reports while task checkouts and their pending changes remain available. Repeated cleanup remains idempotent. Unsafe linked targets stop cleanup before any selected sibling is removed.

## Compatibility and limits

The tool retains its call syntax and result fields. With worktrees present, removedTargets names the removed children relative to the installation root and removedCount counts those children; the artifacts parent remains. Generated files inside worktrees remain with their owning task. Task directories require explicit Git cleanup after acceptance. App calculations, saved data, and scientific outputs are unchanged.
