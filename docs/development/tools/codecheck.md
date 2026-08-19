# Code Analysis Reports

`runCodecheckReport` runs MATLAB `codeIssues` and
`analyzeCodeCompatibility` over the same LabKit source set. It writes the
native Code Analyzer JSON, a serialized `CodeCompatibilityAnalysis` JSON, and
one browsable HTML report that searches and filters both result sets. Use it
when you need the complete static-analysis result; ordinary tests and CI own
their own focused quality checks.

## Syntax

```matlab
report = runCodecheckReport(root)
report = runCodecheckReport(root, "OpenReport", false)
report = runCodecheckReport(root, "ProgressFcn", progressFcn)
```

Add the tool folder first:

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(fullfile(repoRoot, "tools", "codecheck"))
report = runCodecheckReport(repoRoot, "OpenReport", false);
```

## Inputs And Options

| Name | Meaning |
| --- | --- |
| `root` | LabKit checkout root to scan. It is converted to a text scalar before file discovery. |
| `OpenReport` | Logical scalar. Default `true`; opens the generated HTML report in the system browser. |
| `ProgressFcn` | Empty or a function handle called as `fcn(message, value)`, where `value` progresses from 0 to 1. |

The scan includes MATLAB files beneath `root`. It excludes `.git`, `.github`,
`.vscode`, `.codes`, `artifacts`, `node_modules`, and `photos`. Additional
private app roots configured outside `root` are included when their workspace
contains `.labkit-accept-main-guardrails`, or when
`LABKIT_GUARD_PRIVATE_APPS` explicitly enables local inspection.

## Output

The returned struct contains:

| Field | Meaning |
| --- | --- |
| `jsonFile` | Native `codeIssues` JSON export path. |
| `compatibilityJsonFile` | Serialized `CodeCompatibilityAnalysis` JSON path, including checks performed and recommendations. |
| `htmlFile` | Combined LabKit Code Analyzer and compatibility report path. |
| `fileCount` | Number of unique MATLAB files scanned. |
| `issueCount` | Unsuppressed issue count. |
| `suppressedIssueCount` | Suppressed issue count reported by MATLAB. |
| `compatibilityCheckCount` | Number of compatibility checks MATLAB performed. |
| `compatibilityRecommendationCount` | Number of compatibility recommendations found in scanned source. |

Default reports are timestamped beneath `artifacts/code-check/`. A second run
within the same second receives a numeric suffix instead of overwriting the
first report.

## Behavior And Limitations

An analyzer issue or compatibility recommendation is report data, not a thrown
failure. Compatibility results describe the MATLAB release running the scan;
they do not claim execution parity on every supported release. File-access
errors, invalid MATLAB analyzer inputs, or report-write failures still raise
their underlying MATLAB error. LabKit source must not add Code Analyzer
suppression pragmas merely to make this report empty; fix the source shape or
document a real external limitation in project governance.

## Related Documentation

- [Maintainer Tools](README.md)
- [Testing](../maintain-and-release/testing.md)
- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
