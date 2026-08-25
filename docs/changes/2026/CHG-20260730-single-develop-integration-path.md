# Single develop integration path

```labkit-change
id: CHG-20260730-single-develop-integration-path
date: 2026-07-30
type: ci
compatibility: compatible
component: repository
```

## Why

Allowing both long-lived develop work and short-lived hotfix branches created two delivery routes with different naming and validation expectations. Squash-merging develop and then merging main back into it also retained the original branch commits, the squash commit, and an additional synchronization commit, making the integration history progressively harder to read.

### Accepted choice

Use one repository-owned route for every change, including emergency repairs: `develop -> main`. Main rejects pull requests from every other branch.

After a develop pull request is merged and its exact main-push gate completes, delete develop and recreate it at the new main commit. This makes the two refs identical at the start of every delivery cycle and removes the need for synchronization commits. Deletion is permitted only after confirming that the merged pull request contains all develop changes and no open pull request depends on the branch; branch protection is restored immediately after recreation.

## What changed

- Removed hotfix branches from the documented and executable integration policy.
- Made the policy check accept only the repository-owned develop branch for a pull request targeting main.
- Replaced post-merge main-to-develop synchronization with guarded deletion and exact recreation from main.

## Impact

This changes repository maintenance only. Product behavior, project data, scientific results, and exported files are unchanged.

## Compatibility and limits

Existing open work must be placed on develop before delivery. There is no alternate emergency branch path and no reduced validation class for small repairs.

### Remaining limits

Deleting a protected develop branch requires a temporary, narrowly scoped protection change. If GitHub cannot perform that operation safely, stop and report the blocker rather than substituting a force-push or sync commit.
