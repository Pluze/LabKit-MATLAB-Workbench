#!/usr/bin/env bash
set -e

git switch develop

if [[ -n "$(git status --porcelain)" ]]; then
    echo "sync-develop: worktree is not clean. Commit or stash changes first." >&2
    exit 1
fi

git fetch --prune origin
git reset --hard origin/main
git branch --set-upstream-to=origin/develop develop >/dev/null 2>&1 || true
git status --short --branch
