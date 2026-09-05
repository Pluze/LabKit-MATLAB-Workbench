---
name: labkit-checkpoint-guard
description: "Use to prepare an ordinary LabKit task-branch commit, authorized push, or logical checkpoint by auditing scope, focused evidence, staged content, commit identity, and upstream state. Final integration routes to labkit-pr-preparer."
---

# LabKit Checkpoint Guard

Prepare one coherent ordinary development checkpoint. Read `AGENTS.md`, the
nearest scoped rules, the complete task diff, and validation already performed.
Use `labkit-pr-preparer` instead for final merge readiness.

## Establish scope

1. Record branch, HEAD, upstream, staged, unstaged, and untracked layers.
2. Separate pre-existing user work from the requested outcome. Never absorb an
   unrelated file merely because it is already modified or staged.
3. Inspect every intended hunk against its baseline. Remove incidental cleanup,
   speculative contracts, generated output, and abandoned approaches.
4. Check the intended diff for sensitive data, local paths, debug residue, and
   whitespace errors.
5. Run `buildtool codecheck` against the exact intended worktree before
   staging. Require the single `CODECHECK_RESULT` line to report `PASS`, zero
   issues, zero suppressions, zero compatibility recommendations, and zero
   unreviewed secondary-runtime calls. Re-run after any later MATLAB source
   edit; do not inspect large analyzer JSON for an ordinary checkpoint and do
   not bypass the gate with suppression or a broad source exclusion.

Use `labkit-test-planner` only when source-aligned evidence remains to be
selected or run. Use `labkit-agent-governance` for agent contracts and
`labkit-documentation-maintainer` for documentation discovery or rendering.
Do not run `changedFast`; it belongs to final PR preparation.

## Commit and push

Stage explicit intended paths, then inspect the complete cached diff and name
status. Require one logical outcome and a lowercase Conventional Commit subject
using an allowed type. Commit within the authorized task. Ordinary checkpoint
history rewrites require explicit authorization; integration replay and
exact-lease updates follow AGENTS.md and labkit-pr-preparer. Verify the new
commit and remaining worktree afterward.

Before an authorized push, fetch when needed, verify the exact outgoing
commits, and inspect unexpected divergence or scope changes before proceeding.
Preserve other work and stop for unresolved ownership or external permission
and protection barriers. For an authorized integration update, require the
reviewed candidate and exact old-SHA task-branch lease from labkit-pr-preparer;
do not ask again for routine mechanics already authorized by the merge request.
Never use unguarded force or force-push main. Report the remote result without
claiming incomplete hosted CI or review evidence.

Report branch, commit and push state, included and preserved local changes,
focused validation, deferred final gates, and blockers.
