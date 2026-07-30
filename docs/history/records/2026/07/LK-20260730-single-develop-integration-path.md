# Single develop integration path

```labkit-change
id: LK-20260730-single-develop-integration-path
date: 2026-07-30
sequence: 165
type: ci
compatibility: compatible
component: `repository`
scope: One integration branch with clean post-merge recreation
```

## Context

Allowing both long-lived develop work and short-lived hotfix branches created
two delivery routes with different naming and validation expectations.
Squash-merging develop and then merging main back into it also retained the
original branch commits, the squash commit, and an additional synchronization
commit, making the integration history progressively harder to read.

## Decision and rationale

Use one repository-owned route for every change, including emergency repairs:
`develop -> main`. Main rejects pull requests from every other branch.

After a develop pull request is merged and its exact main-push gate completes,
delete develop and recreate it at the new main commit. This makes the two refs
identical at the start of every delivery cycle and removes the need for
synchronization commits. Deletion is permitted only after confirming that the
merged pull request contains all develop changes and no open pull request
depends on the branch; branch protection is restored immediately after
recreation.

## Changes

- Removed hotfix branches from the documented and executable integration
  policy.
- Made the policy check accept only the repository-owned develop branch for a
  pull request targeting main.
- Replaced post-merge main-to-develop synchronization with guarded deletion
  and exact recreation from main.

## User and data impact

This changes repository maintenance only. Product behavior, project data,
scientific results, and exported files are unchanged.

## Compatibility and migration

Existing open work must be placed on develop before delivery. There is no
alternate emergency branch path and no reduced validation class for small
repairs.

## Validation

Integration-policy tests verify that develop is accepted and feature, fork,
and formerly accepted hotfix heads are rejected. Repository architecture and
documentation consistency checks verify the durable policy and history.

## Evidence

The integration policy script and tests, root and scoped agent constitutions,
release/testing manuals, and this record are the reviewable evidence.

## Known limitations and follow-up

Deleting a protected develop branch requires a temporary, narrowly scoped
protection change. If GitHub cannot perform that operation safely, stop and
report the blocker rather than substituting a force-push or sync commit.
