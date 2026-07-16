# Structured documentation history

```labkit-change
schema: 2
id: LK-20260715-component-owned-history
date: 2026-07-15
sequence: 61
type: docs
compatibility: breaking
scope: `docs/history/records/`
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

Store each change explanation once as an independent Markdown page in the
chronological `docs/history/records/<year>/<month>/` tree. Let the component
metadata, rather than the file's physical folder, associate a record with each
affected app, framework, or library. The documentation compiler then generates
both component-specific history lists and a searchable project-wide index.

## Changes

- Split the existing recorded history into one Markdown file per Change ID and
  placed every public record under one chronological source tree.
- Removed the root aggregate changelog, duplicated current-version lookup, and
  the dedicated release-history parser.
- Replaced the launcher's custom version-history window with a direct link to
  the selected App's generated Documentation and History page.
- Routed version governance through owned component docs, distributed history,
  generated-site consistency, and source version metadata.

## User and data impact

Users see instructions, APIs, scientific context, and relevant changes from one
app or library page. Source readers can find every public history record under
`docs/history/records/`. Search still reaches the complete historical record.
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

- `docs/history/README.md` defines the human entry point.
- `tools/docs/private/loadLabKitDocumentation.m` discovers history pages.
- `DocumentationHistoryGuardrailTest` protects the distributed model.

## Known limitations and follow-up

Some older records retain the wording used when their changes were originally
made. Component metadata, rather than folder placement, determines where each
record is shown.
