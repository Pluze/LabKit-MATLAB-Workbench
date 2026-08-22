---
name: labkit-pr-preparer
description: "Use for final LabKit task-branch integration into main: audit the complete squash diff, consolidate versions and history, run the final local gate, and prepare the PR record. Ordinary branch iteration routes to labkit-checkpoint-guard."
---

# LabKit PR Preparer

Treat `origin/main..HEAD` as one proposed squash result. Read repository and
changed-component rules, release/testing/history contracts, and the PR template.
Use `labkit-documentation-maintainer` for history and
`labkit-test-planner` for the final local gate.

## Establish the boundary

Fetch origin, require a same-repository short-lived task branch created from
current `origin/main` and an understood clean worktree, and record
base/head/upstream, complete diff, and intermediate commits. Branch names are
descriptive labels, not capability or agent contracts. Stop for `main`, a
reused merged branch, a misaligned delivery stream, an already frozen different
head, or inseparable local work. Never merge main into the task branch, create
a sync commit, force-push, or rewrite commits without explicit approval.

Run the bundled inventory before changing versions or history:

```bash
python3 .agents/skills/labkit-pr-preparer/scripts/audit_pr.py \
  --base origin/main --head HEAD
```

## Consolidate the squash result

- Derive one direct patch, minor, or major component transition from main.
- After choosing each final version, search the complete proposed tree and
  reconcile every owned version consumer: App `Requirements`, facade ranges,
  public help examples, exact test expectations, saved-data compatibility or
  migration branches, and release metadata. Distinguish unrelated components
  that happen to use the same numeric version; do not perform a blind global
  replacement.
- Leave one coherent changed history record per versioned component; combine a
  cross-component decision and remove intermediate checkpoint narration.
- Align final version, updated date, Change ID date, manual, rationale,
  compatibility, evidence, and follow-up with the net diff.
- Preserve published mainline history identity and decision content while
  repairing stale links to moved or retired current documentation.

Inspect this judgment manually even when inventory automation passes.

## Prove merge readiness

Run integration policy for the actual refs, repair authored links, then run
`changedFast` exactly once for the final tree. Inspect the complete diff,
sensitive data, versions, history, manuals, evidence, and native/manual gaps.
Fill the repository PR template, normalize it with
`.github/scripts/normalize_github_markdown.py`, push the final checkpoint, open
or update the PR, and freeze its task branch. Keep one physical line per prose
paragraph or list item; do not wrap GitHub-authored text to a terminal column
width.

Let required CI establish the complete platform claim. For a repair, inspect
only failed identities, use `labkit-test-planner` for focused reproduction, and
push verified repairs without repeating `changedFast` unless scope widens.
Never declare readiness before policy, local gate, CI, review, and conversation
resolution complete.

After merge, verify resolved SHAs, the exact main-push policy run, dependent
PRs, and unmerged commits before deleting the merged task branch locally and
remotely. GitHub's repository setting normally deletes the remote head on
merge; verify that outcome and delete only a confirmed accepted head if it
remains. Never infer cleanup safety from a branch name and never recycle the
merged branch for later work.

Report base/head, final transitions and history, evidence, PR/CI/review state,
manual checks, data hygiene, task-branch freeze/deletion, and blockers.
