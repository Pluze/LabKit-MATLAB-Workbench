# Public library help contracts and reference validation

```labkit-change
id: CHG-20260716-public-api-help-contracts
date: 2026-07-16
type: docs
compatibility: compatible
component: labkit.biosignal | 1.0.1 -> 1.0.2
component: labkit.dta | 2.0.1 -> 2.0.2
component: labkit.image | 2.0.0 -> 2.0.1
component: labkit.rhs | 1.0.1 -> 1.0.2
component: labkit.thermal | 1.1.0 -> 1.1.1
```

## Why

The public library reference identified functions and basic syntax but did not consistently explain option values, units, returned structures, failure behavior, or the distinction between executable examples and calls that need a user-supplied file. Readers still had to inspect implementation files to use several GUI-free APIs correctly.

### Accepted choice

Treat each public MATLAB help block as the source-level call contract and render that contract into one API page per function. Detailed library validation is kept separate from project-navigation validation so both remain focused and within the repository's effective-code-line budget.

The patch versions record a compatible documentation-contract improvement. Function signatures, calculations, returned data, and error identifiers are unchanged.

## What changed

- Expanded public help with syntax, inputs, outputs, option names and legal values, defaults, units, errors, examples or typical calls, and related APIs.
- Distinguished self-contained `Example:` sections from interactive or file-dependent `Typical Call:` sections.
- Added generated-reference checks for thermal conversion and rendering, DTA schemas and pulse modes, and RHS lazy reads and waveform units.
- Corrected stale biosignal documentation links in package guidance and an implementation contract.
- Made label-ownership and package-boundary scans ignore prose-only substring collisions while continuing to reject literals and forbidden MATLAB tokens in executable code.

## Impact

Users can discover the supported call contract through both `help` and the generated HTML reference without launching an app. No file format, saved project, calculation, or exported value changes.

## Compatibility and limits

This is a patch-level compatible change. Existing calls require no migration.

### Remaining limits

Interactive calls and calls requiring laboratory files remain `Typical Call:` sketches until the repository provides synthetic, non-sensitive fixtures that make them executable examples.
