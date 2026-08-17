---
name: labkit-checkpoint-guard
description: "Use when preparing an ordinary LabKit development commit, push, or logical checkpoint by auditing scope, focused evidence, staged content, commit identity, and upstream state. Do not use for final develop-to-main PR preparation, review-only requests, or a push the user did not authorize."
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

Use `labkit-test-planner` only when source-aligned evidence remains to be
selected or run. Use `labkit-agent-governance` for agent contracts and
`labkit-documentation-maintainer` for documentation discovery or rendering.
Do not run `changedFast`; it belongs to final PR preparation.

## Commit and push

Stage explicit intended paths, then inspect the complete cached diff and name
status. Require one logical outcome and a lowercase Conventional Commit subject
using an allowed type. Commit only when requested; do not amend or rewrite
existing commits without explicit approval. Verify the new commit and remaining
worktree afterward.

Before an authorized push, fetch when needed, verify the exact outgoing
commits, and stop on unexpected divergence, protection, permission, or frozen
develop state. Never force-push without explicit approval. Report the remote
result without claiming incomplete hosted CI or review evidence.

Report branch, commit and push state, included and preserved local changes,
focused validation, deferred final gates, and blockers.
