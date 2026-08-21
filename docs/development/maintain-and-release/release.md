# Release Policy

[Development index](../README.md) | [Project history](../../history/README.md) |
[Deployment tool](../tools/deployment.md) |
[LabKit Launcher](../../apps/labkit-core/launcher/README.md)

Use semantic versioning for public releases.

## Version Numbers

- Patch releases, such as `v2.1.1`, are for bug fixes that do not add user-visible capabilities.
- Minor releases, such as `v2.2.0`, are for user-visible features, workflow changes, or meaningful maintenance improvements.
- Major releases, such as `v3.0.0`, are for breaking changes or intentionally incompatible workflows.

If a commit marked as breaking, such as `feat!`, changes user workflow or app
compatibility, choose a major version. If the implementation changes a user
workflow without intentionally breaking compatibility, describe it in the
release notes so launcher users can choose or roll back versions deliberately.

On a short-lived task branch created from current `origin/main`, choose each
component's final version directly from the PR base, not from intermediate
branch commits. A task branch may edit version metadata while work is evolving,
but its merge-ready state must be exactly one semantic-version step from the
mainline baseline: the next patch, the next minor with patch zero, or the next
major with minor and patch zero. The related component history record
describes that direct `main baseline -> PR final` transition. CI verifies
existing App, facade, and launcher transitions before MATLAB setup. This
prevents temporary branch versions from accumulating into artificial public
version jumps. Checkpoint history records may also remain provisional during
ordinary branch iteration. Before PR review, merge related records, remove
mechanical fragments and intermediate transitions, and leave each versioned
component in exactly one changed history record. Maintain user documentation
with the same squash-oriented view: it describes the final branch behavior and
one net compatibility transition, not the sequence of intermediate commits
used to develop it.

## Tags

Use `vX.Y.Z` for new release tags, for example `v2.2.0`.

Do not rename or delete historical published tags only to normalize naming.
If an older release used a different tag style, keep it for compatibility with
existing links and user checkouts. Future releases should use `vX.Y.Z`.

Complete developer-led interactive App validation before starting a release.
Then dispatch the `Release` workflow from `main`, provide the new version, and
explicitly confirm that manual validation is complete. The exact main commit
must already have a successful `Continuous Integration` push run. That
lightweight run records policy success for the exact squash commit; required
strict PR checks already proved the complete headless, hidden-GUI, and
path-isolation matrix on Toolbox-free Linux, macOS, and Windows against the
same file tree. The release workflow verifies the exact-commit integration
record instead of executing the MATLAB matrix again, then creates the
annotated tag.

An invalid version, a non-`main` dispatch, a missing manual-validation
confirmation, an existing tag or release, or the absence of a successful
same-commit main CI run prevents tag creation. Ordinary push, pull-request,
and documentation workflows never create release tags.

After the PR merge and its exact main-push CI complete, verify the accepted
squash SHA and confirm GitHub's automatic head-branch deletion removed the
merged remote branch; delete it explicitly if it remains, then remove the local
branch. Start later work from a newly fetched `origin/main`; do not recycle a
merged branch, merge main back into it, or create a branch-sync commit.

```bash
gh workflow run release.yml --ref main \
  -f version=vX.Y.Z \
  -f manual_validation_confirmed=true
gh run watch
```

Use `buildtool coverage` locally when you need a coverage report without
preparing a release.

## GitHub Releases

Use the release title format:

```text
VX.Y.Z
```

The title contains only the uppercase `V` and three-part semantic version.
The Git tag remains lowercase `vX.Y.Z`.

Use this note structure:

```text
## Highlights
- User-facing summary bullets.

## Fixes
- Bug fixes, if any.

## Upgrade Note
- Compatibility or upgrade guidance, if any. Mention app entrypoint or app
  requirement changes, launcher or app version bumps, and any LabKit facade
  contract version or supported-range changes.

## Validation
- Local and CI validation evidence.
```

Omit an empty section when it does not apply. Keep validation factual: name the
supported MATLAB and operating-system coverage, relevant interactive checks,
or other assurance a user can interpret.

Release notes are a user-facing product summary, not a release audit or a
shortened PR description. Each statement should help a reader understand what
changed in a supported workflow, whether an issue they experienced was fixed,
whether existing work remains compatible, or what action an upgrade requires.
Use App and workflow names that users recognize. Preserve safety warnings and
breaking-change guidance even when they affect only custom App authors.

Do not publish commit or workflow-run identifiers, pull-request links, shell
commands, test inventories, CI routing, internal package movement, file hashes,
byte counts, or asset-verification procedure in release notes. Those details
remain available in the PR review record, structured component history,
workflow record, and release asset checks. The
`.github/RELEASE_NOTES_TEMPLATE.md` draft prompts the required reader-facing
sections and must be rewritten for the actual release before publication.

After it verifies the required CI run, the workflow exports
`labkit_launcher.m` from the annotated tag blob, verifies its SHA-256 against
that blob, pushes the tag, creates a draft GitHub Release, uploads the launcher,
and verifies the remote asset. The tag points at the same `github.sha` recorded
by that Base MATLAB CI run; a later advance of `main` does not move it.

Automation deliberately stops at a draft. Before publishing, rewrite or
complete the generated notes with the required sections above, confirm the
version and tag target, inspect the launcher asset, and record the final manual
and CI evidence outside the public note. Publishing the draft is a developer
release decision, not a side effect of ordinary CI.

Attach `labkit_launcher.m` to each GitHub release. The root README download
link points at the latest release asset so browsers download the launcher
instead of opening the raw source text.

The launcher version manager lists published releases only. Keep release titles
and upgrade notes clear enough for users to select an older release when the
newest build is unsuitable for their workflow.

## Component History

Release notes summarize one public release. Long-lived change explanations
live with the framework, library, app, launcher, or project documentation they
affect. Each record is one Markdown file under a relevant `history/` directory.
The generated documentation site aggregates those files into the
[Project History](../../history/README.md) page and automatically lists matching records
on every related component page.

When a change bumps `labkit_launcher.m`, a `+labkit/**/version.m` facade, or an
App's `AppVersion` metadata in `apps/**/definition.m`:

1. update the owning component documentation;
2. add one history record using the authoritative
   [history record format](../../history/record-format.md), including the
   stable Change ID, next global history sequence, affected components, and
   direct version transition;
3. complete every required narrative section in that format;
4. rebuild the generated site and verify the record appears on each affected
   component page.

Write a cross-component change once and list every affected component in its
metadata. Do not copy its narrative into multiple app pages. Current versions
come from launcher, facade, and app source metadata, so there is no separate
lookup table to synchronize. Git branches, PRs, tags, and commits express
delivery state; do not add a second pending/unreleased hierarchy.

Published history remains a durable decision record, but its reader-facing
links are not immutable. When a current page is moved or retired, update or
remove the stale history link instead of preserving an obsolete page solely as
a redirect. Keep the record's identity, sequence, classification, components,
scopes, and version transitions unchanged. Integration policy treats such
metadata-preserving maintenance as documentation work rather than a new
component transition.

Before tagging a release that adds, renames, or removes release-blocking
guardrail tests, verify that the buildfile CI tasks still discover the intended
suite and tag coverage. The workflow should call those build tasks through
`matlab-actions/run-build` rather than maintaining long-lived test class
selectors.

## Launcher Asset Reproducibility

Generate the launcher asset from the release tag, not from an editor buffer,
copied file, or platform-dependent checkout. This keeps the release asset byte
for byte identical to the tagged source file, including line endings.

Use a tag-specific staging folder:

```bash
mkdir -p artifacts/release/vX.Y.Z
git show vX.Y.Z:labkit_launcher.m > artifacts/release/vX.Y.Z/labkit_launcher.m
```

Before upload, compare the staged launcher against the tag blob:

```bash
git show vX.Y.Z:labkit_launcher.m | shasum -a 256
shasum -a 256 artifacts/release/vX.Y.Z/labkit_launcher.m
wc -c artifacts/release/vX.Y.Z/labkit_launcher.m
```

After creating the GitHub release, verify that the uploaded asset reports the
same byte count and SHA-256 digest:

```bash
gh release view vX.Y.Z --json assets
```

If the asset digest or size differs from the tag-exported file, delete only the
incorrect asset and re-upload the tag-exported `labkit_launcher.m`. Do not move
or recreate an already-published release tag to fix an asset upload mistake.
