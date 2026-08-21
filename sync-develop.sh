#!/usr/bin/env bash
set -euo pipefail

if [[ -n "$(git status --porcelain)" ]]; then
    echo "sync-develop: worktree is not clean. Commit or stash changes first." >&2
    exit 1
fi

git fetch --prune origin

if ! git show-ref --verify --quiet refs/remotes/origin/develop; then
    echo "sync-develop: origin/develop does not exist." >&2
    echo "Complete the guarded post-merge develop recreation first." >&2
    exit 1
fi

git switch -C develop origin/develop
git branch --set-upstream-to=origin/develop develop >/dev/null
git status --short --branch
