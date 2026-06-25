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

Attach `labkit_launcher.m` to each GitHub release. The root README download
link points at the latest release asset so browsers download the launcher
instead of opening the raw source text.

The launcher version manager lists recent releases, tags, and main-branch
commits. Keep release titles and upgrade notes clear enough for users to select
an older release when the newest build is unsuitable for their workflow.

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
