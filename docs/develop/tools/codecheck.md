# Code Analysis Reports

```labkit-page
id: develop-tools-codecheck
type: reference
audience: maintainer
summary: Run MATLAB code and compatibility analysis over the LabKit source set and inspect the JSON and searchable HTML reports.
```

`runCodecheckReport` runs MATLAB `codeIssues` and `analyzeCodeCompatibility` over the same LabKit source set. It writes the native Code Analyzer JSON, a serialized `CodeCompatibilityAnalysis` JSON, and one browsable HTML report that searches and filters both result sets. Use it when you need the complete static-analysis result; ordinary tests and CI own their own focused quality checks.

## Syntax

```matlab
report = runCodecheckReport(root)
report = runCodecheckReport(root, "OpenReport", false)
report = runCodecheckReport(root, "ProgressFcn", progressFcn)
report = runCodecheckReport(root, "WriteArtifacts", false, "RequireClean", true)
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
| `WriteArtifacts` | Logical scalar. Default `true`. Set false for a lightweight agent/checkpoint run with no JSON or HTML writes. |
| `RequireClean` | Logical scalar. Default `false`. When true, any issue, suppression, compatibility recommendation, or unreviewed secondary-runtime call fails with `LabKit:Codecheck:Findings`. |

The scan includes MATLAB files beneath `root`. It excludes `.git`, `.github`, `.vscode`, `.codes`, `artifacts`, `node_modules`, `photos`, and nested `private_apps`. Analyze a private repository by calling `runCodecheckReport` with that repository as `root`; public reports never add ambient private roots.

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
| `runtimeViolationCount` | Number of direct Java, Python, Conda, shell, MEX/native, .NET, or ActiveX entry points outside the exact public test-infrastructure allowance ledger. |
| `runtimeViolations` | Compact file, line, category, and matched-entry descriptions for runtime-boundary findings. |
| `summary` | One compact `CODECHECK_RESULT` line containing status and all gate counts. |

Default reports are timestamped beneath `artifacts/code-check/`. A second run within the same second receives a numeric suffix instead of overwriting the first report.

For ordinary agent and checkpoint validation, run:

```bash
buildtool codecheck
```

This mode writes no report artifacts. Its final line is intentionally small:

```text
CODECHECK_RESULT status=PASS files=1701 issues=0 suppressed=0 compatibility=0 runtime=0
```

The file count varies with the checkout; the status/count fields are the machine-readable contract. Ordinary commits are blocked unless all counts are zero and the status is `PASS`.

The runtime boundary scans every public-repository MATLAB source file, including tests. Five marked and counted `system` calls are retained only for isolated MATLAB processes, synthetic Git state, and filesystem-link fixtures; adding another call fails the gate. Accepted private workspaces may be included in MATLAB analyzer and compatibility results, but their independent repository owns its runtime exceptions and submission gate.

## Behavior And Limitations

An analyzer issue or compatibility recommendation is report data, not a thrown failure. Compatibility results describe the MATLAB release running the scan; they do not claim execution parity on every supported release. File-access errors, invalid MATLAB analyzer inputs, or report-write failures still raise their underlying MATLAB error. LabKit source must not add Code Analyzer suppression pragmas merely to make this report empty; fix the source shape or document a real external limitation in project governance.

## Related Documentation

- [Developer Tools](README.md)
- [Testing](../testing.md)
- [LabKit Launcher](../../use/apps/labkit-core/launcher/README.md)
