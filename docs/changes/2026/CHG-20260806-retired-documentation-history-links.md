# Retired documentation no longer requires compatibility pages

```labkit-change
id: CHG-20260806-retired-documentation-history-links
date: 2026-08-06
type: docs
compatibility: compatible
component: repository
```

## Why

Published history can link to a design page that later becomes obsolete after its useful behavior moves into a current manual. Treating every edit to an old history file as a new component transition forced the obsolete path to remain as a compatibility page even when no current reader task belonged there.

### Accepted choice

Allow the smallest link or navigation edit needed when current documentation is moved or retired. Preserve the historical decision and all of its metadata, including component version transitions. This keeps history useful to readers without turning obsolete documentation paths into permanent product surfaces.

## What changed

- The retired T-Test Wizard design page is removed completely.
- Its published history record no longer links to that obsolete path.
- PR inventory and integration policy ignore metadata-preserving history edits when matching current component version transitions.
- Deleting a published history record remains an integration-policy error.

## Impact

Readers reach the current T-Test Wizard manual and no longer encounter a compatibility-only documentation page. No App behavior, scientific data, project file, result, or public API changes.

## Compatibility and limits

Existing history identity, ordering, component attribution, and version transitions remain unchanged. No source or data migration is required.

### Remaining limits

Automation compares structured component metadata, not the meaning of every narrative sentence. Reviewers must still reject unrelated rewrites of published history.
