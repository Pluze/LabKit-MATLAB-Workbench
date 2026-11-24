---
name: labkit-pr-integrator
description: "Prepare, open, update, and merge LabKit PRs, including validation, branch reconciliation, and accepted-task cleanup. Ordinary local commits use labkit-checkpoint-guard; review-only findings use labkit-code-review."
---

# LabKit PR Integrator

Deliver the requested PR state. Infer it from the user's request and existing
session authorization: prepare locally, open/update a PR, or merge and clean up.
A general PR request starts with local preparation and inspection of any
existing PR. Open or update a PR when requested. Merge and accepted-task
cleanup require merge authorization. Release publication is a separate operation.

Read applicable rules, the complete task delta and existing validation, the
PR template, and `docs/develop/release.md` for component version decisions.
Use `labkit-test-planner` for missing evidence or the final local gate, and
`labkit-documentation-maintainer` for documentation impact and Change records.

## Prepare the proposed result

Establish base/head, upstream, dirty layers, scope, and ownership. Start new
work from fetched main; reconcile baseline drift in an existing task without
recycling its branch or merging main into it. An understood task-owned dirty
diff can be prepared; preserve unrelated work rather than silently staging it.

Run the inventory from the task worktree:

```bash
python3 .agents/skills/labkit-pr-integrator/scripts/audit_pr.py \
  --base origin/main --head HEAD
```

The inventory covers committed refs; also inspect staged, unstaged, and
untracked task changes before committing. For each affected versioned component,
choose one direct transition from main and reconcile requirements, public help,
exact test expectations, saved-data compatibility, and release metadata.
Consolidate one Change for each accepted logical decision, combining components
when they share that decision. Preserve accepted mainline Change identity.
Update current manuals or record why their contracts and entry points did not
change. Derive titles and the PR body from the final result.

## Validate and publish the requested state

Run focused checks while editing. Before opening the final PR, run
`changedFast` once against the settled task tree and inspect the complete diff,
data hygiene, version inventory, and manual gaps. Reuse valid evidence for the
same tree; repeat or broaden only for changes, failures, or unresolved concerns.
A failed gate requires its focused repair and a successful required gate, not
an interpretation of "once" that permits an incomplete result.

Use the repository PR template and Markdown normalizer. Commit only the owned
outcome; push and open/update the PR when requested. Once open, required CI
owns the complete platform claim. Diagnose failed identities through the test
planner, publish focused repairs, and avoid repeating broad local gates unless
scope changes. Inspect available development feedback only when relevant to a
current uncertainty; it is not merge evidence.

For authorized replay, overlapping PRs, merge, or cleanup, read
[the integration procedure](references/integration.md). Require successful CI,
review flow, and conversation resolution for the proposed head; merge using an
explicit compliant squash subject and expected-head check. Verify the exact
accepted main policy run, then complete cleanup.

## Completion

- Local preparation: coherent reviewed diff, required local evidence, and a
  drafted PR record; report any work deliberately left uncommitted.
- Open/update: the requested PR exists at the intended head; report required
  checks and unresolved review without claiming merge readiness prematurely.
- Merge: the accepted squash and exact main policy passed; task worktrees,
  local/remote heads, and clean primary-main alignment are verified.

Report relevant transitions, documentation decisions, evidence, native/manual
limits, delivery state, and real blockers. Do not start a release implicitly.
