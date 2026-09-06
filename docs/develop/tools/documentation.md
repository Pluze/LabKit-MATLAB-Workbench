# Documentation Build Tools

```labkit-page
id: develop-tools-documentation
type: reference
audience: maintainer
summary: Build, verify, and maintain LabKit documentation through its three public MATLAB documentation tools.
```

LabKit uses three public MATLAB entry points for its documentation sources and generated site. `renderLabKitDocs` compiles and validates a complete temporary site before synchronizing it; `checkLabKitDocs` executes self-contained examples and compares independently validated renders for determinism; `maintainLabKitDocLinks` checks or repairs standard relative Markdown links. Path-organized Markdown and MATLAB help blocks are the authored sources.

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

Rendering discovers every Markdown page, public App, typed Change record, and complete public help contract. It generates API catalogs, current-to-Change relationships, the structural documentation map, and Change indexes by component and year from that validated model. It then validates the entire temporary output before creating or changing `outputRoot`; only a valid tree is synchronized, obsolete generated files and empty directories are removed, and the output root itself is preserved. Every eligible Markdown page and public API is included automatically, so handwritten global catalogs do not own coverage.

The output gate rejects missing pages, duplicate HTML IDs, missing landmarks, invalid heading order, empty semantic tables, broken links or fragments, pages unreachable from Home, incomplete search or map coverage, and public APIs without a current narrative entry point. This gate runs for both `docs` and `docsCheck`, so an incomplete site cannot be published merely because two builds reproduce the same mistake.

## Verify The Generated Site

```matlab
result = checkLabKitDocs
result = checkLabKitDocs(sourceRoot)
result = checkLabKitDocs(sourceRoot, existingSiteRoot)
```

Before rendering, the check discovers `Example:` blocks from the same public API model as the site and MATLAB fences immediately preceded by `<!-- labkit-runnable-example -->` from narrative pages. It runs each in a fresh function workspace and temporary working folder, restoring the path, random-number state, and figure visibility and removing figures created by that example. Run `buildtool docsCheck` in a clean noninteractive MATLAB process; persistent state and external resources are not a security sandbox. Only trusted repository documentation should be executed. Device- and user-file-dependent sketches belong under `Typical Call:` and are not executed. Empty or malformed marked examples raise `LabKit:Docs:InvalidRunnableExample`; a runtime or assertion failure raises `LabKit:Docs:ExampleFailed` with its source and cause. Execution reports completed/total examples and a heartbeat for an active example.

Without an existing site argument, the check renders two independently validated temporary folders and compares generated file paths and bytes. Supplying an existing site compares one independently validated render with that folder. Semantic failures use focused `LabKit:Docs:*` identifiers such as `DuplicateGeneratedId`, `BrokenGeneratedAnchor`, `UnreachableGeneratedPage`, `IncompleteApiCatalog`, and `InvalidSearchCoverage`; a byte or file-list difference raises `LabKit:Docs:StaleGeneratedSite`. The result otherwise includes `exampleCount` and `comparedFileCount` in addition to the renderer result fields.

## Build Tasks

The supported command-line wrappers are:

```bash
buildtool docs
buildtool docsCheck
```

Use `docs` for a validated local site and `docsCheck` when delivery evidence must additionally prove deterministic output. Never track or edit files under `site/` manually.

## Related Documentation

- [Developer Tools](README.md)
- [Documentation System](../documentation.md)
- [Testing](../testing.md)
- [LabKit Launcher](../../use/apps/labkit-core/launcher/README.md)
