# Documentation search ranks page intent and scopes history explicitly

\`\`\`labkit-change
schema: 2
id: LK-20260720-ranked-and-scoped-documentation-search
date: 2026-07-20
sequence: 146
type: docs
compatibility: compatible
scope: Documentation system
scope: tools/docs/
scope: site search
\`\`\`

## Context

The generated documentation search treated every term in a page title, body,
and rendered component-history links as equivalent. A shared history record
could therefore make an unrelated App page appear before the App named by a
search. Readers also had no way to restrict a query to history records.

## Decision and rationale

Keep component-history links visible on their related pages, but index history
records as their own searchable documents. Give title and explicit keywords
more weight than body text, then provide a visible section filter for readers
who want Apps, APIs, history, or another documentation area.

## Changes

- Added section and keyword fields to generated search entries.
- Excluded rendered component-history link text from narrative page search
  bodies while retaining complete history-record search entries.
- Added deterministic field-weighted ranking, result excerpts, and section
  filtering to the offline-safe client search.
- Added regression coverage for search-entry separation, filters, and ranking
  contracts.

## User and data impact

Searching a named App now favors that App and its family over unrelated pages
that share a historical record. Readers can search only History when tracing a
decision. No App behavior, calculations, projects, exports, or laboratory
data changes.

## Compatibility and migration

The generated site remains usable from file:// without network fetches.
Existing documentation URLs, history records, and page-level change-history
links remain unchanged.

## Validation

Focused documentation search contract tests verify the generated index and
client controls. Documentation rendering and consistency checks regenerate the
tracked site and validate the history record.

## Evidence

renderLabKitDocs now emits separated search fields. The client script ranks
title, keyword, and body matches independently and filters by the generated
section field.

## Known limitations and follow-up

Search is intentionally dependency-free and uses exact lexical matching.
Typo-tolerant suggestions can be considered later only if they preserve the
current deterministic title-first ordering.
