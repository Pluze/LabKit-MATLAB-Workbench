# Documentation search ranks page intent and scopes history explicitly

```labkit-change
id: CHG-20260720-ranked-and-scoped-documentation-search
date: 2026-07-20
type: docs
compatibility: compatible
component: repository
```

## Why

The generated documentation search treated every term in a page title, body, and rendered component-history links as equivalent. A shared history record could therefore make an unrelated App page appear before the App named by a search. Readers also had no way to restrict a query to history records.

### Accepted choice

Keep component-history links visible on their related pages, but index history records as their own searchable documents. Give title and explicit keywords more weight than body text, then provide a visible section filter for readers who want Apps, APIs, history, or another documentation area.

## What changed

- Added section and keyword fields to generated search entries.
- Excluded rendered component-history link text from narrative page search bodies while retaining complete history-record search entries.
- Added deterministic field-weighted ranking, result excerpts, and section filtering to the offline-safe client search.
- Added regression coverage for search-entry separation, filters, and ranking contracts.

## Impact

Searching a named App now favors that App and its family over unrelated pages that share a historical record. Readers can search only History when tracing a decision. No App behavior, calculations, projects, exports, or laboratory data changes.

## Compatibility and limits

The generated site remains usable from file:// without network fetches. Existing documentation URLs, history records, and page-level change-history links remain unchanged.

### Remaining limits

Search is intentionally dependency-free and uses exact lexical matching. Typo-tolerant suggestions can be considered later only if they preserve the current deterministic title-first ordering.
