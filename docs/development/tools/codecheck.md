# Code Analyzer Reports

`runCodecheckReport` runs MATLAB `codeIssues` over the LabKit checkout and
writes both the native JSON export and a browsable HTML report. Use it when you
need the complete analyzer result; ordinary tests and CI own their own focused
quality checks.

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
| `htmlFile` | LabKit HTML report path. |
| `fileCount` | Number of unique MATLAB files scanned. |
| `issueCount` | Unsuppressed issue count. |
| `suppressedIssueCount` | Suppressed issue count reported by MATLAB. |

Default reports are timestamped beneath `artifacts/code-check/`. A second run
within the same second receives a numeric suffix instead of overwriting the
first report.

## Behavior And Limitations

An analyzer finding is report data, not a thrown failure. File-access errors,
invalid MATLAB analyzer inputs, or report-write failures still raise their
underlying MATLAB error. LabKit source must not add Code Analyzer suppression
pragmas merely to make this report empty; fix the source shape or document a
real external limitation in project governance.

## Related Documentation

- [Maintainer Tools](README.md)
- [Testing](../maintain-and-release/testing.md)
- [LabKit Launcher](../../apps/labkit-core/launcher/README.md)
