# App Deployment Packages

`packageLabKitApp` creates one ZIP containing one or more selected LabKit apps,
their assets, the shared `+labkit` runtime, standalone entry files, and a
machine-readable package manifest. Source and P-code packages serve different
deployment needs.

## Syntax

```matlab
result = packageLabKitApp(appSelector)
result = packageLabKitApp(appSelector, zipFile)
result = packageLabKitApp(appSelector, zipFile, Name, Value)
```

Typical calls:

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(fullfile(repoRoot, "tools", "deployment"))

one = packageLabKitApp("labkit_CIC_app");
several = packageLabKitApp( ...
    ["labkit_CIC_app", "labkit_EIS_app"], [], ...
    "OutputRoot", fullfile(repoRoot, "artifacts", "deployment"));
runtimeOnly = packageLabKitApp( ...
    "labkit_CIC_app", [], "CodeFormat", "pcode");
```

## App Selector

`appSelector` accepts:

- one app command such as `"labkit_CIC_app"`;
- a string array or cell collection of app commands;
- an app entry-file path;
- an app folder containing exactly one entry point;
- a launcher app metadata struct or struct array.

Commands are resolved through the same public and configured private-app roots
used by the launcher. Ambiguous commands, missing entry points, duplicate
folder entries, or unavailable source files raise an error before packaging.

## Options

| Name | Default | Meaning |
| --- | --- | --- |
| `Root` | Repository root | Source/runtime root containing `+labkit`, apps, launcher, and tools. |
| `OutputRoot` | `artifacts/deployment/` | Folder used when `zipFile` is empty. |
| `ProgressFcn` | Empty | Function handle called as `fcn(message, value)` from 0 to 1. |
| `CodeFormat` | `"source"` | `"source"`/`"m"` for M-files, or `"pcode"`/`"p"` for runtime-only P-code. |

## Source And P-code Packages

| Property | Source | P-code |
| --- | --- | --- |
| App implementation | `.m` files | `.p` files |
| Standalone entry | `run_<command>.m` | `run_<command>.p` |
| `labkit_launcher.m` | Included | Omitted |
| Deployment/profiling tools | Included | Omitted |
| `+labkit` and selected app assets | Included | Included in encoded runtime form |

Both formats include `README.txt` and `packaged_app_manifest.json`. Neither
format includes unrelated sibling apps. P-code is a deployment format, not a
source backup; retain the corresponding private or public source repository.

## Result Structure

The result identifies `zipFile`, `packageRootName`, `entryFiles`,
`appCommands`, app-relative folders, visibility values, `codeFormat`, and
`fileCount`. Legacy scalar fields `entryFile`, `appCommand`,
`appRelativeFolder`, and `visibility` describe the first selected app.

Packaging stages files in a temporary directory, replaces an existing target
ZIP only after validation reaches archive creation, and removes the staging
directory afterward.

## Related Documentation

- [Maintainer Tools](README.md)
- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
- [Private Apps](../private-apps.md)
- [Release Process](../release.md)
