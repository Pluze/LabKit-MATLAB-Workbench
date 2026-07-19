# Documentation Build Tools

LabKit uses three public MATLAB entry points for its documentation sources and
generated site.
`renderLabKitDocs` builds and synchronizes the site; `checkLabKitDocs` performs
an independent build and verifies that the tracked site is current;
`maintainLabKitDocLinks` checks or repairs standard relative Markdown links.
Path-organized Markdown and MATLAB help blocks are the authored sources.

## Maintain Links

```matlab
result = maintainLabKitDocLinks
result = maintainLabKitDocLinks(repoRoot)
result = maintainLabKitDocLinks(repoRoot, "Update", true)
```

The default is read-only. With `Update=true`, a missing Markdown target is
rewritten only when filename and link label identify exactly one current page.
Review the rewritten diff, then rerun the default check.

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

Rendering discovers every Markdown page, public App, history record, and
complete public help contract. It first creates a complete temporary tree,
then creates `outputRoot`
when absent, copies new or changed files, deletes obsolete generated files and
empty directories, and preserves the output root itself. Every eligible
Markdown page is included automatically, and no duplicated navigation catalog
exists in this model.

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
- [Documentation System](../maintain-and-release/documentation.md)
- [Testing](../maintain-and-release/testing.md)
- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
