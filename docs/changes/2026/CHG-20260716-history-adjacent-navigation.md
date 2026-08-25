# Adjacent navigation for history records

```labkit-change
id: CHG-20260716-history-adjacent-navigation
date: 2026-07-16
type: docs
compatibility: compatible
component: documentation
```

## Why

The complete timeline linked every recorded change, but a reader who opened one detail page had to return to the index before continuing chronologically. Dates and filenames could not safely identify adjacent records because several changes may share one date.

### Accepted choice

Use validated history `sequence` metadata to add adjacent-record links at the end of every rendered history detail page. **Previous change** means the record with `sequence - 1`; **Next change** means `sequence + 1`. This preserves one unambiguous project-history order without binding authored content to Git.

## What changed

- Added responsive previous/next navigation immediately before the generated page footer.
- Showed only existing directions at the oldest and newest ends.
- Added regression coverage for link targets, ordering, and page placement.

## Impact

Readers can traverse project history linearly without returning to the index. No MATLAB runtime, app state, scientific data, or exports change.

## Compatibility and limits

Existing history URLs and record metadata remain valid. Regenerating `site/` adds navigation to every record page and updates the search index normally.

### Remaining limits

Navigation is intentionally chronological across all project components. It does not filter to the current app or library; component-specific history remains available from each component manual.
