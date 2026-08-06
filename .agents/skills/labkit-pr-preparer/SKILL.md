---
name: labkit-pr-preparer
description: "Prepare LabKit develop for a squash PR into main by auditing the complete base-to-head diff, consolidating component versions and structured history, running the one final local gate, and assembling the repository PR record. Use only when the user asks to prepare, open, update, review, or make merge-ready a develop-to-main PR. Do not use during ordinary branch iteration."
---

# LabKit PR Preparer

Treat `origin/main..develop` as one proposed product change. Intermediate
commits, temporary versions, and checkpoint history files are working state;
the merge-ready tree must describe one coherent squash result.

## Read

Read `AGENTS.md`, the nearest changed-component rules,
`docs/development/maintain-and-release/release.md`,
`docs/development/maintain-and-release/testing.md`,
`docs/history/record-format.md`, and `.github/pull_request_template.md`.
Use `labkit-documentation-maintainer` when rewriting component history and
`labkit-test-planner` for the final local gate.

## Establish the PR boundary

1. Fetch `origin` with host network permission.
2. Require the canonical `develop` branch and a clean understood worktree.
3. Record `origin/main`, `develop`, `origin/develop`, the complete
   `origin/main...develop` diff, and the intermediate commit list.
4. Stop if `develop` was not created from the current main delivery stream,
   an existing develop-to-main PR already freezes a different head, or
   unrelated local work cannot be separated safely.

Do not merge `main` into `develop`, create a sync commit, force-push, or rewrite
Git commits without explicit approval. PR preparation rewrites the proposed
tree and authored component history; GitHub performs the final squash.

Run the bundled inventory before editing versions or history. It resolves
versions from both current and legacy metadata owners, maps every net
transition to changed history, and reports policy errors without reconstructing
the inventory by hand:

```bash
python3 .agents/skills/labkit-pr-preparer/scripts/audit_pr.py \
  --base origin/main --head develop
```

## Consolidate versions and history

Build one inventory of every changed App definition, facade `version.m`,
launcher metadata file, manual, and structured history record.

- Derive every final component version directly from `origin/main`, never from
  an intermediate develop version. Choose exactly one direct patch, minor, or
  major step for the net behavior.
- Align each new versioned history record's date and date-bearing Change ID
  with the final component `Updated` date in the squash candidate. Intermediate
  checkpoint dates do not survive consolidation.
- Delete intermediate transitions such as `2.1.0 -> 2.2.0` followed by
  `2.2.0 -> 2.3.0`. The merge-ready history contains only the chosen direct
  main-baseline-to-PR-final transition.
- Require one changed structured history record per versioned component. A
  cross-component decision uses one record listing all affected components.
  Merge related checkpoint records; remove tiny mechanical records and
  duplicate unversioned component references that fragment the same PR story.
- Rewrite titles, IDs, filenames, scopes, rationale, compatibility, evidence,
  and follow-up as the net delivered behavior. Preserve published mainline
  history metadata and decision content. When this PR retires or moves a
  current document, repair or remove stale links in published records without
  changing their identity, sequence, components, scopes, or version
  transitions. Freely consolidate records introduced only on `develop` while
  keeping global sequence metadata valid.
- Update each owning manual once for the net public behavior. Do not repeat
  framework defaults in App manuals or preserve prose that merely narrates
  intermediate commits.

Inspect the result manually even when policy automation passes. Automation can
prove exact transitions and record presence; it cannot decide whether two
records tell one logical product story.

## Run merge-readiness checks

Run the integration policy against the actual proposed refs before broad
MATLAB validation:

```bash
python3 .github/scripts/check_integration_policy.py \
  --event-name pull_request \
  --base-ref main \
  --head-ref develop \
  --head-repository Pluze/LabKit-MATLAB-Workbench \
  --repository Pluze/LabKit-MATLAB-Workbench \
  --base-sha origin/main \
  --head-sha develop
```

Then:

1. Run authored-link maintenance after moved Markdown and review rewrites.
2. Run `changedFast` exactly once for the final merge-ready tree.
3. Inspect the complete diff, data hygiene, component versions, structured
   history, manuals, test evidence, and remaining native/manual checks.
4. Fill the repository PR template with net behavior and exact evidence.
5. Push the final develop checkpoint, open or update the PR, and freeze
   `develop` until the PR is merged or closed.
6. Unless a prerequisite failure prevents useful downstream execution, let an
   active platform matrix finish and collect every failed identity before the
   next push. Read only those failing logs, repair the narrowest responsible
   boundaries, rerun exact evidence, and batch the verified repairs into one
   push. Do not repeat `changedFast` after every repair.

Do not declare merge readiness when the policy audit, final local gate,
required PR CI, review, or conversation resolution is incomplete.

After merge, use resolved SHAs rather than branch-name assumptions. Verify the
PR is merged, the exact main-push policy gate passed, no open PR depends on
`develop`, and `develop` contains no unmerged commit. Only then delete and
recreate local and remote `develop` at `origin/main`, restore its protection,
and verify both refs are identical. Never delete a branch based only on a
successful merge command response.

## Handoff

Report the base and head SHAs, consolidated version transitions and history
records, final local evidence, PR/CI state, manual checks, data-hygiene result,
develop freeze state, and any blocker. Distinguish completed automated proof
from developer-led interactive validation.
