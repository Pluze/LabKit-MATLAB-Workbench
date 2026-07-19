# Maintainer Tools

LabKit keeps a small set of MATLAB tools for source-checkout maintenance. They
can be launched from the LabKit Launcher or called directly after adding the
owning tool directory to the MATLAB path. They are not dependencies of normal
app calculations and write generated output under ignored `artifacts/` paths
unless an explicit destination is supplied.

## Choose A Tool

| Goal | Entry point | Reference |
| --- | --- | --- |
| Scan MATLAB source and export reviewable issues | `runCodecheckReport` | [Code Analyzer Reports](codecheck.md) |
| Package one or more apps for offline use | `packageLabKitApp` | [App Deployment Packages](deployment.md) |
| Regenerate or verify the static documentation site | `renderLabKitDocs`, `checkLabKitDocs` | [Documentation Build Tools](documentation.md) |
| Profile startup, callbacks, scripts, or functions | `profileLabKitTarget` | [Performance Profiling](profiling.md) |

## Direct Invocation Pattern

Add the narrow tool folder, not all of `tools/` recursively:

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(fullfile(repoRoot, "tools", "profiling"))
profileLabKitTarget("labkit_launcher")
```

Each public tool file owns its private implementation folder. Adding the public
folder makes those private helpers available only to that tool, without
turning them into global commands.

## Launcher And Command-Line Use

The launcher provides the common interactive defaults: it supplies the current
checkout root, selected app commands, progress UI, and sensible report
locations. Direct calls are preferable for automation, custom output paths,
batch MATLAB, reusable profile targets, or packaging several named apps.

Tool reports and ZIPs are generated artifacts, not source documentation or app
project data. **Clean Artifacts** may remove them. Copy any evidence that must
be retained outside `artifacts/` or attach it to the relevant release or issue.

## Related Documentation

- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
- [Testing](../maintain-and-release/testing.md)
- [Documentation System](../maintain-and-release/documentation.md)
- [Release Process](../maintain-and-release/release.md)
- [Architecture](../build-apps/architecture.md)
