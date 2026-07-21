# History records use one canonical authored format

```labkit-change
id: LK-20260721-canonical-history-record-format
date: 2026-07-21
sequence: 149
type: docs
compatibility: compatible
scope: Project History
scope: Documentation Search
```

## Context

History records mixed a transport-oriented schema marker with several related
but inconsistent metadata conventions. Authors had to infer valid fields and
values from renderer internals and agent guidance.

## Decision and rationale

Use one compact, authored record format without a schema field. A single public
format page defines every legal field, value, ordering rule, and narrative
section so a record can be written and reviewed from repository documentation.

## Changes

Rewrote every existing record into the canonical metadata form, preserved its
identity, date, sequence, narrative, and component history links, and added a
strict renderer parser. Scopes now feed the documentation search index.

## User and data impact

Readers retain the complete history timeline and component links while gaining
more useful search terms. This documentation-only change does not alter saved
projects, experimental data, or App behavior.

## Compatibility and migration

The source format changes incompatibly for record authors: remove `schema` and
replace an introduction entry with a `component` transition using `new ->`.
Existing records are migrated in this same change, so no compatibility reader
is retained.

## Validation

The documentation renderer validates every migrated record, rebuilds the site,
and documentation guardrails verify the canonical source and generated output.

## Evidence

The renderer parser is the executable enforcement of the published format; the
record format page provides its human-readable counterpart.

## Known limitations and follow-up

No known follow-up is required. Future history changes use this format directly
rather than adding compatibility metadata variants.
