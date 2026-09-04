---
name: labkit-pr-preparer
description: "Use for final LabKit task-branch integration into main: audit the complete squash diff, consolidate versions and Change records, run the final local gate, and prepare the PR record. Ordinary branch iteration routes to labkit-checkpoint-guard."
---

# LabKit PR Preparer

Treat `origin/main..HEAD` as one proposed squash result. Read repository and
changed-component rules, release/testing/Change contracts, and the PR template.
Use `labkit-documentation-maintainer` for Change records and
`labkit-test-planner` for the final local gate.

## Establish the boundary

Fetch origin, require a same-repository short-lived task branch created from
current `origin/main` and an understood clean worktree, and record
base/head/upstream, complete diff, and intermediate commits. Branch names are
descriptive labels, not capability or agent contracts. Stop for `main`, a
reused merged branch, an unreviewable or accidental bundle, an already frozen
different head, or inseparable local work. A branch may intentionally bundle
multiple features when its PR states the complete scope and the combined review,
risk, dependency, and delivery boundary remains clear. Never merge main into
the task branch, create a sync commit, force-push, or rewrite commits without
explicit approval.

Run the bundled inventory before changing versions or Change records:

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
- Leave one coherent changed Change record per versioned component; combine a
  cross-component decision and remove intermediate checkpoint narration.
- Align final version, updated date, Change ID date, manual, rationale,
  compatibility, evidence, and follow-up with the net diff.
- Preserve accepted mainline Change identity and decision content. Current
  documentation uses only current destinations; do not create route aliases or
  repair retired URLs.

Inspect this judgment manually even when inventory automation passes.

## Prove merge readiness

Run integration policy for the actual refs, repair authored links, then run
`changedFast` exactly once for the final tree. Inspect the complete diff,
sensitive data, versions, Change records, manuals, evidence, and native/manual gaps.
When a completed task-branch Development Feedback run is already available for
the exact head, inspect its status and summary as supplemental branch evidence.
Do not wait for or repeatedly poll that run, and do not treat it as a substitute
for the local gate or required pull-request CI.
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
PRs, unmerged commits, and the task's registered worktrees. Close the task in
this order:

1. Inspect each task-owned linked worktree. Remove it only when its contents
   are accepted, or when any remaining dirt is verified disposable validation
   output with no unaccepted work. Never remove another task's worktree.
2. Delete the local task branch only after no linked worktree uses it and the
   accepted squash commit is verified.
3. Verify GitHub's automatic remote-head deletion. Delete a remaining remote
   branch only when it is the exact accepted head; never infer cleanup safety
   from a branch name.
4. When the primary checkout is clean, fast-forward it to the accepted
   `origin/main` commit and verify clean alignment. Stop and report unrelated
   local work instead of switching, cleaning, or overwriting it.

Do not recycle a merged branch or leave a completed task's worktree, local
branch, or remote branch as normal residue.

Report base/head, final transitions and Change records, evidence, PR/CI/review state,
manual checks, data hygiene, worktree/local-branch/remote-branch cleanup,
primary-main alignment, and blockers.
