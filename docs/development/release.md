# Release Policy

[Development index](README.md) | [Project history](../history.md)

Use semantic versioning for public releases.

## Version Numbers

- Patch releases, such as `v2.1.1`, are for bug fixes that do not add user-visible capabilities.
- Minor releases, such as `v2.2.0`, are for user-visible features, workflow changes, or meaningful maintenance improvements.
- Major releases, such as `v3.0.0`, are for breaking changes or intentionally incompatible workflows.

If a commit marked as breaking, such as `feat!`, changes user workflow or app
compatibility, choose a major version. If the implementation changes a user
workflow without intentionally breaking compatibility, describe it in the
release notes so launcher users can choose or roll back versions deliberately.

On a development branch, choose each component's final version directly from
the merge base with `origin/main`, not from intermediate branch commits. A
branch may edit version metadata while work is evolving, but its merge-ready
state must be exactly one semantic-version step from the mainline baseline:
the next patch, the next minor with patch zero, or the next major with minor
and patch zero. The related component history record should describe that
direct `main baseline -> branch final` transition. This prevents temporary
branch versions from accumulating into artificial public version jumps.

## Tags

Use `vX.Y.Z` for new release tags, for example `v2.2.0`.

Do not rename or delete historical published tags only to normalize naming.
If an older release used a different tag style, keep it for compatibility with
existing links and user checkouts. Future releases should use `vX.Y.Z`.

## GitHub Releases

Use the release title format:

```text
LabKit MATLAB Workbench vX.Y.Z
```

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
commands or CI workflow that passed and the commit used for the release.

Before publishing a GitHub release, push the `vX.Y.Z` release tag and wait for
the `MATLAB Tests` workflow's `Release Test Gate` job to pass on that tag. The
gate requires the public `headless`, `coverage`, and `gui` build tasks to pass
for the release candidate.

Attach `labkit_launcher.m` to each GitHub release. The root README download
link points at the latest release asset so browsers download the launcher
instead of opening the raw source text.

The launcher version manager lists recent releases, tags, and main-branch
commits. Keep release titles and upgrade notes clear enough for users to select
an older release when the newest build is unsuitable for their workflow.

## Component History

Release notes summarize one public release. Long-lived change explanations
live with the framework, library, app, launcher, or project documentation they
affect. Each record is one Markdown file under a relevant `history/` directory.
The generated documentation site aggregates those files into the
[Project History](../history.md) page and automatically lists matching records
on every related component page.

When a change bumps `labkit_launcher.m`, a `+labkit/**/version.m` facade, or an
`apps/**/version.m` app metadata file:

1. update the owning component documentation;
2. add one history record with a stable Change ID, ISO date, change type,
   compatibility value, affected components, and direct version transition;
3. explain context, decision and rationale, changes, user/data impact,
   compatibility, validation, evidence, and known follow-up;
4. rebuild the generated site and verify the record appears on each affected
   component page.

Write a cross-component change once and list every affected component in its
metadata. Do not copy its narrative into multiple app pages. Current versions
come from launcher, facade, and app source metadata, so there is no separate
lookup table to synchronize. Git branches, PRs, tags, and commits express
delivery state; do not add a second pending/unreleased hierarchy.

Before tagging a release that adds, renames, or removes release-blocking
guardrail tests, verify that the buildfile CI shard tasks still discover the
intended suite and tag coverage. The workflow should call those build tasks
through `matlab-actions/run-build` rather than maintaining long-lived test
class selectors.

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
