# Structured evolution records

```labkit-change
id: LK-20260713-structured-evolution-records
date: 2026-07-13
sequence: 52
type: docs
compatibility: compatible
scope: repository changelog and release governance
```

## Context

The previous `Unreleased` and `Pending` model mixed delivery state with
historical meaning and required records to be moved after merge. Its prose was
useful to humans but had no reliable machine contract.

## Decision and rationale

Use stable, status-free records with a small parseable metadata header and
required explanatory sections. Git branches, PRs, tags, and evidence identify
delivery state without duplicating it in the changelog.

## Changes

- Added schema-v1 metadata for Change ID, date, type, compatibility, component
  introductions and version transitions, and unversioned repository scopes.
- Added a base-MATLAB parser and release guardrail for schema integrity.
- Normalized every historical entry into the same schema-v1 record contract.

## User and data impact

Users and maintainers can search one durable ID and obtain the reason, impact,
compatibility, validation, and evidence for a change without reconstructing it
from commit messages. No scientific data or runtime behavior changes.

## Compatibility and migration

Existing links to `CHANGELOG.md` remain valid. Automation that searched the old
`Unreleased` or `Version History` headings must use the parser and stable
Change IDs.

## Validation

`ChangelogGuardrailTest` parses every schema-v1 record and checks current
version lookup coverage and release-policy documentation.

## Evidence

The parser lives at `tools/release/parseLabKitChangelog.m`; the normalized
historical baseline was checked against the dated mainline log and release tags.

## Known limitations and follow-up

Some older records do not name exact test commands because that evidence was
not recorded at the time; they state that limitation instead of inventing it.
