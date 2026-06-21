# Release Policy

Use semantic versioning for public releases.

## Version Numbers

- Patch releases, such as `v2.1.1`, are for bug fixes that do not add user-visible capabilities.
- Minor releases, such as `v2.2.0`, are for user-visible features, workflow changes, or meaningful maintenance improvements.
- Major releases, such as `v3.0.0`, are for breaking changes or intentionally incompatible workflows.

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
- Compatibility or upgrade guidance, if any.

## Validation
- Local and CI validation evidence.
```

Omit an empty section when it does not apply. Keep validation factual: name the
commands or CI workflow that passed and the commit used for the release.
