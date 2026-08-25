# Release notes describe the product for users

```labkit-change
id: CHG-20260806-reader-facing-release-notes
date: 2026-08-06
type: docs
compatibility: compatible
component: repository
```

## Why

Release notes had gradually accumulated delivery evidence and implementation detail that belonged in pull requests, workflow records, and asset checks. That made it harder for readers to understand what a release changed for them.

### Accepted choice

Treat every GitHub Release as a user-facing product summary. Notes describe recognizable workflows, corrected behavior, compatibility, safety warnings, and required upgrade actions. Maintainer evidence remains available at its own source instead of competing with the release summary.

## What changed

- Historical Release notes were rewritten around user-visible outcomes.
- The release manual and agent guidance now exclude delivery logs and internal implementation evidence from public notes.
- New draft Releases start from a reader-facing section template instead of an automatically generated commit list.

## Impact

Users can compare releases without interpreting repository or CI details. No App behavior, scientific data, projects, results, or public API changed.

## Compatibility and limits

Published tags, release titles, dates, assets, and version identities remain unchanged. Existing downloads require no action.

### Remaining limits

Historical notes remain summaries of their original releases; they do not retroactively add behavior that was not delivered at the time.
