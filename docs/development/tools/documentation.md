# Documentation Build Tools

LabKit uses two public MATLAB entry points for its generated documentation.
`renderLabKitDocs` builds and synchronizes the site; `checkLabKitDocs` performs
an independent build and verifies that the tracked site is current. Markdown,
catalog JSON, and MATLAB help blocks remain the only authored sources.

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

Empty or omitted roots default to `docs/` and `site/` beneath the current
LabKit repository. The result contains `pageCount`, `apiCount`, `fileCount`,
`sourceRoot`, and `outputRoot`.

Rendering first creates a complete temporary tree. It then creates `outputRoot`
when absent, copies new or changed files, deletes obsolete generated files and
empty directories, and preserves the output root itself. A source page must be
registered through `site.json`, an app catalog, history discovery, or public
API discovery; an unrelated Markdown file is not published automatically.

## Check The Tracked Site

```matlab
result = checkLabKitDocs
result = checkLabKitDocs(sourceRoot, committedSiteRoot)
```

The check renders to a temporary folder and compares generated file paths and
bytes with the tracked site. A difference raises
`LabKit:Docs:StaleGeneratedSite`; the result otherwise includes
`comparedFileCount` in addition to the renderer result fields.

## Build Tasks

The supported command-line wrappers are:

```bash
buildtool docs
buildtool docsCheck
```

Use `docs` when sources changed and `docsCheck` when validation must prove the
tracked HTML is already current. Never edit files under `site/` manually.

## Related Documentation

- [Maintainer Tools](README.md)
- [Documentation System](../documentation.md)
- [Testing](../testing.md)
- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
