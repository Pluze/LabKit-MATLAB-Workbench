# App Deployment Packages

```labkit-page
id: develop-tools-deployment
type: reference
audience: maintainer
summary: Package selected LabKit apps, assets, shared runtime, standalone entry files, and a machine-readable manifest into one ZIP archive.
```

`packageLabKitApp` creates one ZIP containing one or more selected LabKit apps, their assets, the shared `+labkit` runtime, standalone entry files, and a machine-readable package manifest. Packages contain MATLAB source and can be started through their standalone entries or the included Launcher.

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
```

## App Selector

`appSelector` accepts:

- one app command such as `"labkit_CIC_app"`;
- a string array or cell collection of app commands;
- an app entry-file path;
- an app folder containing exactly one entry point;
- a launcher app metadata struct or struct array.

Commands are resolved through the same public and configured private-app roots used by the launcher. Ambiguous commands, missing entry points, duplicate folder entries, or unavailable source files raise an error before packaging.

## Options

| Name | Default | Meaning |
| --- | --- | --- |
| `Root` | Repository root | Source/runtime root containing `+labkit`, apps, launcher, and tools. |
| `OutputRoot` | `artifacts/deployment/` | Folder used when `zipFile` is empty. |
| `ProgressFcn` | Empty | Function handle called as `fcn(message, value)` from 0 to 1. |

## Package Contents

- selected App folders and assets;
- the shared `+labkit` runtime;
- `labkit_launcher.m`;
- deployment and profiling tools used by the packaged Launcher;
- one `run_<command>.m` standalone entry per selected App;
- `README.txt` describing the selected Apps and entry files.

The package does not include unrelated sibling Apps.

## Result Structure

The result identifies `zipFile`, `packageRootName`, `entryFiles`, `appCommands`, app-relative folders, visibility values, and `fileCount`.

Packaging stages files in a temporary directory, replaces an existing target ZIP only after validation reaches archive creation, and removes the staging directory afterward.

## Related Documentation

- [Developer Tools](README.md)
- [LabKit Launcher](../../use/apps/labkit-core/launcher/README.md)
- [Private Apps](../private-apps.md)
- [Release Process](../release.md)
