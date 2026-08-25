# Documentation Build Tools

```labkit-page
id: develop-tools-documentation
type: reference
audience: maintainer
summary: Build, verify, and maintain LabKit documentation through its three public MATLAB documentation tools.
```

LabKit uses three public MATLAB entry points for its documentation sources and generated site. `renderLabKitDocs` builds and synchronizes the site; `checkLabKitDocs` verifies generated internal links and deterministic output across independent builds; `maintainLabKitDocLinks` checks or repairs standard relative Markdown links. Path-organized Markdown and MATLAB help blocks are the authored sources.

## Maintain Links

```matlab
result = maintainLabKitDocLinks
result = maintainLabKitDocLinks(repoRoot)
result = maintainLabKitDocLinks(repoRoot, "Update", true)
```

The default is read-only. With `Update=true`, a missing Markdown target is rewritten only when filename and link label identify exactly one current page. Review the rewritten diff, then rerun the default check.

## Render The Site

```matlab
result = renderLabKitDocs
result = renderLabKitDocs(sourceRoot)
result = renderLabKitDocs(sourceRoot, outputRoot)
```

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(fullfile(repoRoot, "tools", "docs"))
result = renderLabKitDocs( ...
    fullfile(repoRoot, "docs"), fullfile(repoRoot, "site"));
```

Empty or omitted roots default to `docs/` and `site/` beneath the current LabKit repository. The result contains `pageCount`, `apiCount`, `generatedPageCount`, `fileCount`, `sourceRoot`, and `outputRoot`.

The default `site/` folder is ignored by Git. Generate it when local offline reading or presentation inspection is useful; GitHub Actions independently generates the deployed site from `main`.

Rendering discovers every Markdown page, public App, typed Change record, and complete public help contract. It also generates the structural documentation map and Change indexes by component and year from that validated model. It first creates a complete temporary tree, then creates `outputRoot` when absent, copies new or changed files, deletes obsolete generated files and empty directories, and preserves the output root itself. Every eligible Markdown page is included automatically, and no duplicated navigation catalog exists in this model.

## Verify The Generated Site

```matlab
result = checkLabKitDocs
result = checkLabKitDocs(sourceRoot)
result = checkLabKitDocs(sourceRoot, existingSiteRoot)
```

Without an existing site argument, the check renders to two independent temporary folders, rejects generated internal links that leave the site or name missing output, and compares generated file paths and bytes. Supplying an existing site compares one independently validated render with that folder. A broken link raises `LabKit:Docs:GeneratedLinkEscapesSite` or `LabKit:Docs:BrokenGeneratedLink`; a difference raises `LabKit:Docs:StaleGeneratedSite`. The result otherwise includes `comparedFileCount` in addition to the renderer result fields.

## Build Tasks

The supported command-line wrappers are:

```bash
buildtool docs
buildtool docsCheck
```

Use `docs` when sources changed and `docsCheck` when validation must prove generated links resolve and the renderer is deterministic. Never track or edit files under `site/` manually.

## Related Documentation

- [Developer Tools](README.md)
- [Documentation System](../documentation.md)
- [Testing](../testing.md)
- [LabKit Launcher](../../use/apps/labkit-core/launcher/README.md)
