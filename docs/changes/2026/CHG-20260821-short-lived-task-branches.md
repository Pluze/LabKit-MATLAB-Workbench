# Short-lived task branch integration

```labkit-change
id: CHG-20260821-short-lived-task-branches
date: 2026-08-21
type: ci
compatibility: compatible
component: repository
```

## Why

Squash-merging a long-lived develop branch creates a new main commit whose history diverges from the original branch even when both trees are identical. Restoring exact alignment then requires deleting or force-updating a protected branch, temporarily changing protection, and maintaining a synchronization script whose only consumer is the branch model itself.

### Accepted choice

Each delivery now uses one short-lived same-repository task branch created from current main and merged directly back through a squash pull request. Branch names describe the task but do not require an agent, tool, user, or category prefix. After merge, the accepted branch is deleted instead of synchronized or reused.

This makes branch lifetime match task lifetime and removes a permanent branch whose recreation existed only to support its own integration convention.

## What changed

- Main integration policy now accepts any distinct same-repository task branch instead of one specially named branch.
- Development feedback follows every non-main task branch and suppresses duplicate work only for an open pull request from that exact branch.
- Agent and maintainer guidance now derives the squash boundary from the current task branch and verifies automatic branch deletion after merge.
- The root synchronization script and its catalog-only test contract were removed.

## Impact

This changes repository maintenance only. LabKit behavior, scientific results, saved task data, and exported files are unchanged.

## Compatibility and limits

Existing work may finish on its current branch. New work starts from a freshly fetched main commit on a new descriptive task branch. The former long-lived develop branch is retired after this transition reaches main.

### Remaining limits

Pull requests remain restricted to same-repository branches. Contributors who cannot create one need a maintainer-owned task branch; fork-based integration is intentionally not enabled by this change.
