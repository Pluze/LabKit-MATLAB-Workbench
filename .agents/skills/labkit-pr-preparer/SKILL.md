---
name: labkit-pr-preparer
description: "Prepare LabKit develop for a squash PR into main by auditing the complete base-to-head diff, consolidating component versions and structured history, running the one final local gate, and assembling the repository PR record. Use only when the user asks to prepare, open, update, review, or make merge-ready a develop-to-main PR. Do not use during ordinary branch iteration."
---

# LabKit PR Preparer

Treat `origin/main..develop` as one proposed squash result. Read repository and
changed-component rules, release/testing/history contracts, and the PR template.
Use `labkit-documentation-maintainer` for history and
`labkit-test-planner` for the final local gate.

## Establish the boundary

Fetch origin, require canonical `develop` and an understood clean worktree, and
record base/head/upstream, complete diff, and intermediate commits. Stop for a
misaligned delivery stream, an already frozen different head, or inseparable
local work. Never merge main into develop, create a sync commit, force-push, or
rewrite commits without explicit approval.

Run the bundled inventory before changing versions or history:

```bash
python3 .agents/skills/labkit-pr-preparer/scripts/audit_pr.py \
  --base origin/main --head develop
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
Fill the repository PR template, push the final checkpoint, open or update the
PR, and freeze develop.

Let required CI establish the complete platform claim. For a repair, inspect
only failed identities, use `labkit-test-planner` for focused reproduction, and
push verified repairs without repeating `changedFast` unless scope widens.
Never declare readiness before policy, local gate, CI, review, and conversation
resolution complete.

After merge, verify resolved SHAs, main-push policy, dependent PRs, and unmerged
commits before recreating develop at exact `origin/main`; never infer cleanup
safety from branch names.

Report base/head, final transitions and history, evidence, PR/CI/review state,
manual checks, data hygiene, develop freeze, and blockers.
