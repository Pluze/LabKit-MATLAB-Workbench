# History record format

Each file under `docs/history/records/<year>/<month>/` records one durable
project decision or user-visible evolution. This page is the sole authority
for its authored structure. The documentation renderer validates every record,
builds the timeline from its sequence, adds component links, and indexes its
scopes for search.

## Canonical metadata

The title is the first line. It is followed by one blank line and exactly one
`labkit-change` block. Metadata fields use the shown order; no other metadata
fields are legal.

````text
[Level-one Markdown title: concise change title]

```labkit-change
id: LK-YYYYMMDD-lowercase-change-slug
date: YYYY-MM-DD
sequence: N
type: feat
compatibility: compatible
component: `component-id` | `old-version -> new-version`
scope: Search phrase
```
````

| Field | Required | Value | Used for |
| --- | --- | --- | --- |
| `id` | Yes, once | `LK-` + ISO date without hyphens + lowercase hyphenated slug | Stable change identity and search |
| `date` | Yes, once | ISO date: `YYYY-MM-DD` | Timeline display and ordering check |
| `sequence` | Yes, once | Next positive integer; all records are contiguous from `1` | Definitive timeline order |
| `type` | Yes, once | `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `ci`, or `chore` | Timeline classification and search |
| `compatibility` | Yes, once | `compatible` or `breaking` | Upgrade expectation and search |
| `component` | Optional, repeated | `` `component-id` `` or `` `component-id` \| `old-version -> new-version` ``; use ``new -> X.Y.Z`` for an introduced component | Component-page history aggregation |
| `scope` | Yes, one or more | A trimmed, human-readable search phrase of at most 96 characters | Search keywords |

Use a component ID only when the record should appear on that component's
documentation page. A record may have multiple components and scopes; list all
components before all scopes. Do not add a `schema` field or encode release
state in a record.

## Canonical narrative

After the metadata block, every record contains these headings exactly once and
in this order. Each heading has substantive content.

```text
## Context
## Decision and rationale
## Changes
## User and data impact
## Compatibility and migration
## Validation
## Evidence
## Known limitations and follow-up
```

State what changed and why in the first three sections; state affected users,
data, compatibility, and validation in the next four; reserve the last section
for remaining limits or explicitly state that none are known. Write one
cross-component record rather than duplicating a narrative across components.

## When to write a record

Write a record for a versioned App, launcher, or facade change, or for a
meaningful project evolution decision. Do not create one solely for generated
site output, a typo-only edit, or mechanical formatting churn.
