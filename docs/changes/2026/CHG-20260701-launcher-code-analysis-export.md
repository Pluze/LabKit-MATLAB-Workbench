# Launcher code-analysis export

```labkit-change
id: CHG-20260701-launcher-code-analysis-export
date: 2026-07-01
type: feat
compatibility: compatible
component: labkit_launcher | 1.1.6 -> 1.2.0
```

## Why

The launcher offered a Code Analyzer action, but its earlier implementation carried substantial custom export code. That made a maintenance tool harder to maintain than the MATLAB analysis it was exposing.

### Accepted choice

Use MATLAB's native issue representation and export path, and keep the launcher responsible only for choosing the target and destination. This reduced custom conversion logic while preserving a launcher-level entry point for the report.

## What changed

- Exported launcher Code Analyzer issues natively.

## Impact

The launcher could export Code Analyzer findings in a MATLAB-supported form without requiring a separate script. This action inspected source code only and did not start or modify an app project.

## Compatibility and limits

Existing launcher actions remained available. Newly exported issue files used MATLAB's native representation rather than the removed custom conversion.

### Remaining limits

Code analysis remained a maintainer tool. It did not become a prerequisite for launching an app or a replacement for the repository's automated checks.
