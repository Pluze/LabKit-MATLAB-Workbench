# Private validation ownership

```labkit-change
id: LK-20260823-private-validation-ownership
date: 2026-08-23
sequence: 191
type: refactor
compatibility: compatible
scope: Private App validation ownership
scope: Code Analyzer repository boundary
```

## Context

Private App repositories are independent source stores with their own local validation choices. Public Code Analyzer opt-in markers and ambient private-root discovery made a mounted private workspace part of public merge evidence even though the public repository could not own its diff or release state.

## Decision and rationale

Public validation covers only the public repository. Private repositories select focused local tests and may reuse public `labkittest` and App runtime seams without enrolling their source in public changed-file planning, Code Analyzer gates, or CI.

## Changes

The Code Analyzer now scans only the root supplied by its caller and continues to exclude a nested `private_apps` mount. Public guidance no longer defines a private guardrail marker or asks public validation to compensate for an independent private diff.

## User and data impact

Launcher discovery, private App packaging, and public testing utilities remain available. No App calculation, file format, launch command, or laboratory data handling changes.

## Compatibility and migration

The change is compatible for public LabKit users and private Apps. Maintainers should run private checks from the private workspace instead of expecting a public checkout to add private roots implicitly.

## Validation

Focused Code Analyzer specifications verify ordinary reports, failure behavior, runtime-boundary detection, and isolation from ambient private roots. Repository Skill validation, deterministic documentation checks, and the public Code Analyzer gate cover the changed public surfaces.

## Evidence

The owner-mapped Code Analyzer specification passed four exact tests, including an external-root isolation regression. The complete remaining private App suite passed 37 local identities after repository-governance specifications were retired.

## Known limitations and follow-up

Private repositories remain responsible for choosing evidence proportionate to their own changes; public LabKit intentionally does not assert that those local checks ran.
