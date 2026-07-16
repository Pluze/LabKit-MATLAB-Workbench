# Performance Profiling

`profileLabKitTarget` runs a MATLAB target under the profiler and exports an
interactive HTML report plus a complete JSON sidecar. It supports launcher and
app startup, callbacks, scripts, functions, command strings, and already
captured `profile("info")` data.

## Syntax

```matlab
[htmlFile, artifacts] = profileLabKitTarget(target)
[htmlFile, artifacts] = profileLabKitTarget(target, htmlFile)
[htmlFile, artifacts] = profileLabKitTarget(target, htmlFile, Name, Value)
```

Batch-friendly launcher profile:

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(fullfile(repoRoot, "tools", "profiling"))
[htmlFile, artifacts] = profileLabKitTarget( ...
    "labkit_launcher", [], ...
    "OpenReport", false, ...
    "WaitForGuiClose", false, ...
    "CloseFiguresAfterRun", true, ...
    "PrintSummary", true);
```

Calling the function with an empty target opens a MATLAB file picker. A target
may also be a function handle, function name, command string, `.m` path, or a
profile-info struct containing `FunctionTable`.

## Options

| Name | Default | Meaning |
| --- | --- | --- |
| `OpenReport` | `false` | Open the HTML report after writing it. |
| `WaitForGuiClose` | `true` | Wait for newly opened figures before collecting the final profile. |
| `CloseFiguresAfterRun` | `false` | Close figures opened by the target after capture. |
| `ChangeFolder` | `true` | Temporarily use a resolved target file's folder as the working directory. |
| `OutputRoot` | `artifacts/profile/` | Default report folder when `htmlFile` is empty. |
| `InitialRows` | `500` | Initial number of function-table rows shown. Values below 20 become 20. |
| `ChartTopN` | `40` | Number of top roots in the flame control. |
| `SortBy` | `"SelfTime"` | Initial report-table sort field. |
| `ProjectRoot` | Repository root | Root used to classify project-owned functions. |
| `TargetFile` | Empty | Explicit target path when exporting supplied profile data. |
| `JsonFile` | Empty | Explicit JSON sidecar path. |
| `PrintSummary` | `false` | Print the structured summary to the MATLAB command window. |
| `SummaryTopN` | `20` | Rows retained in each summary ranking. |
| `RethrowError` | `false` | Rethrow the target error after preserving available profile data. |

## Outputs

`htmlFile` is the generated report path. `artifacts` contains `htmlFile`,
`jsonFile`, and `functionCount`. The HTML embeds the complete profile and an
`AGENT_SUMMARY` block; the JSON contains metadata, summary text and tables,
MATLAB profiler metadata, and every captured function row.

## Reading A Report

Start with `topProjectSelfTime` to find time spent directly in editable LabKit
code. Use `topProjectTotalTime` to see inclusive project costs and
`topCapturedTotalTime` to understand user actions, app launches, callbacks,
network operations, or GUI close time captured below a parent. Inspect parent
and child edges before optimizing an inclusive row.

Rows carry source tags such as `project`, `matlab_internal`, `external`, and
`profiler_tool`. Profiler-tool rows remain in the complete data but are omitted
from the default captured rankings so report generation does not appear to be
application cost.

Profile one perceived operation at a time. Separate normal and debug startup,
file registration and actual file reads, and startup and close latency. A
profile identifies cost; it does not prove correctness or scientific parity.

## Related Documentation

- [Maintainer Tools](README.md)
- [Testing](../testing.md)
- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
