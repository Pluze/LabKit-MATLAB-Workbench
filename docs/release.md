# Release Policy

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
and patch zero. `CHANGELOG.md` affected-version lines must record that direct
`main baseline -> branch final` transition. This prevents temporary branch
versions from accumulating into artificial public version jumps.

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

## Changelog Maintenance

`CHANGELOG.md` is the user-facing version map and project evolution map for
users, maintainers, and agents. It is separate from GitHub release notes:
release notes summarize one public release, while the changelog explains how
LabKit changed over time, why each iteration exists, which release tag or
component versions carry it, and where the audit evidence lives.

The changelog has one format for current and historical records:

- Keep every entry under `Structured Change Records` with a stable Change ID,
  ISO date, Conventional Commit type, compatibility value, and either exact
  component version transitions or an unversioned repository scope.
- Keep the required narrative sections for context, decision and rationale,
  changes, user and data impact, compatibility and migration, validation,
  evidence, and known limitations or follow-up.
- Do not add `Unreleased`, `Pending`, or another delivery-status hierarchy.
  Git branches, PRs, mainline commits, and release tags already express
  delivery state. A branch record can cite checkpoint commits or a PR and keep
  the same Change ID after merge.
- Keep the current version lookup synchronized with every launcher, facade, and
  app metadata file. Development-branch transitions compare directly with the
  merge base from `origin/main`, not with intermediate branch versions.
- Parse and validate the complete history with
  `addpath("tools/release"); parseLabKitChangelog()`. Do not maintain a second
  unstructured history or duplicate the parser grammar in another document.

When a change bumps `labkit_launcher.m`, a `+labkit/**/version.m` facade, or an
`apps/**/version.m` app metadata file, add a changelog entry in the same
change. Record the direct mainline-to-final version transition and evidence
available at that time. Do not write the entry as a raw commit-log dump;
explain the context, decision, user or data impact, migration risk, validation,
and limitations that are not obvious from blame history.

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
