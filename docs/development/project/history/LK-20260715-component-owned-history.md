# Component-owned documentation history

```labkit-change
schema: 1
id: LK-20260715-component-owned-history
date: 2026-07-15
type: docs
compatibility: breaking
scope: `docs/**/history/`
scope: `tools/docs/`
scope: `tools/release/`
scope: `CHANGELOG.md`
```

## Context

Project evolution was stored in one 3,571-line root changelog. App, framework,
library, validation, launcher, and release decisions were mixed together, while
the new documentation site already had component pages capable of presenting
the relevant history in context.

## Decision and rationale

Store each change explanation once as an independent Markdown page under the
documentation area that owns it. Let the MATLAB documentation compiler associate
records with every component named in metadata and generate both component-local
history lists and a searchable project-wide index.

## Changes

- Split the existing recorded history into one Markdown file per Change ID.
- Removed the root aggregate changelog, duplicated current-version lookup, and
  the dedicated release-history parser.
- Replaced the launcher's custom version-history window with a direct link to
  the selected App's generated Documentation and History page.
- Routed version governance through owned component docs, distributed history,
  generated-site consistency, and source version metadata.

## User and data impact

Users see instructions, APIs, scientific context, and relevant evolution from
one App or library page. Search still reaches the complete historical record.
No project files, calculations, or experimental data formats change.

## Compatibility and migration

Links that targeted the old root changelog must move to the generated Project
History page or a component page. The old parser and launcher history mode are
intentionally removed rather than maintained as compatibility aliases.

## Validation

The documentation compiler validates unique history identities, required
metadata, source pages, generated links, search indexing, and deterministic
output. Project release guardrails validate the distributed record set and
component aggregation.

## Evidence

- `docs/history.md` defines the human entry point.
- `tools/docs/private/loadLabKitDocumentation.m` discovers history pages.
- `DocumentationHistoryGuardrailTest` protects the distributed model.

## Known limitations and follow-up

Historical records retain the wording and primary physical owner chosen at the
time of migration. Cross-component metadata, rather than folder placement,
determines where a record is shown.
