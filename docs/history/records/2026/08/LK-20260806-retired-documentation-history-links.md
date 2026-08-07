# Retired documentation no longer requires compatibility pages

```labkit-change
id: LK-20260806-retired-documentation-history-links
date: 2026-08-06
sequence: 175
type: docs
compatibility: compatible
scope: Published history link maintenance
scope: Documentation retirement
```

## Context

Published history can link to a design page that later becomes obsolete after
its useful behavior moves into a current manual. Treating every edit to an old
history file as a new component transition forced the obsolete path to remain
as a compatibility page even when no current reader task belonged there.

## Decision and rationale

Allow the smallest link or navigation edit needed when current documentation
is moved or retired. Preserve the historical decision and all of its metadata,
including component version transitions. This keeps history useful to readers
without turning obsolete documentation paths into permanent product surfaces.

## Changes

- The retired T-Test Wizard design page is removed completely.
- Its published history record no longer links to that obsolete path.
- PR inventory and integration policy ignore metadata-preserving history edits
  when matching current component version transitions.
- Deleting a published history record remains an integration-policy error.

## User and data impact

Readers reach the current T-Test Wizard manual and no longer encounter a
compatibility-only documentation page. No App behavior, scientific data,
project file, result, or public API changes.

## Compatibility and migration

Existing history identity, ordering, component attribution, and version
transitions remain unchanged. No source or data migration is required.

## Validation

Integration-policy unit tests cover metadata-preserving history maintenance,
published-record deletion, and the existing version-transition rules. The PR
audit, authored-link check, and deterministic documentation render exercise the
retired path in the complete repository tree.

## Evidence

- Focused Python integration-policy tests passed.
- PR audit and integration policy passed with the historical link removed.
- Authored-link and deterministic documentation checks passed without a
  compatibility page.

## Known limitations and follow-up

Automation compares structured component metadata, not the meaning of every
narrative sentence. Reviewers must still reject unrelated rewrites of published
history.
