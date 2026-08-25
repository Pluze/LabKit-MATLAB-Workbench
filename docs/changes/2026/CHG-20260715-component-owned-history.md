# Structured documentation history

```labkit-change
id: CHG-20260715-component-owned-history
date: 2026-07-15
type: docs
compatibility: breaking
component: repository
```

## Why

Project evolution was stored in one 3,571-line root changelog. App, framework, library, validation, launcher, and release decisions were mixed together, while the new documentation site already had component pages capable of presenting the relevant history in context.

### Accepted choice

Store each change explanation once as an independent Markdown page in the chronological `docs/history/records/<year>/<month>/` tree. Let the component metadata, rather than the file's physical folder, associate a record with each affected app, framework, or library. The documentation compiler then generates both component-specific history lists and a searchable project-wide index.

## What changed

- Split the existing recorded history into one Markdown file per Change ID and placed every public record under one chronological source tree.
- Removed the root aggregate changelog, duplicated current-version lookup, and the dedicated release-history parser.
- Replaced the launcher's custom version-history window with a direct link to the selected App's generated Documentation and History page.
- Routed version governance through owned component docs, distributed history, generated-site consistency, and source version metadata.

## Impact

Users see instructions, APIs, scientific context, and relevant changes from one app or library page. Source readers can find every public history record under `docs/history/records/`. Search still reaches the complete historical record. No project files, calculations, or experimental data formats change.

## Compatibility and limits

Links that targeted the old root changelog must move to the generated Project History page or a component page. The old parser and launcher history mode are intentionally removed rather than maintained as compatibility aliases.

### Remaining limits

Some older records retain the wording used when their changes were originally made. Component metadata, rather than folder placement, determines where each record is shown.
