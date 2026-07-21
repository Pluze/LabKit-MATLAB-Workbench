# Public API help is complete, discoverable, and behavior checked

```labkit-change
id: LK-20260717-complete-public-api-help-contract
date: 2026-07-17
sequence: 127
type: docs
compatibility: compatible
component: `labkit.biosignal` | `1.0.2 -> 1.0.3`
component: `labkit.dta` | `2.0.2 -> 2.0.3`
component: `labkit.rhs` | `1.0.2 -> 1.0.3`
component: `labkit.thermal` | `1.1.1 -> 1.1.2`
component: `labkit.image` | `2.0.1 -> 2.0.2`
component: `labkit.ui` | `7.5.0 -> 7.5.1`
component: `labkit_DICPreprocess_app` | `1.5.7 -> 1.5.8`
component: `labkit_DICPostprocess_app` | `1.4.6 -> 1.4.7`
component: `labkit_CSC_app` | `1.4.7 -> 1.4.8`
component: `labkit_BatchImageCrop_app` | `1.7.6 -> 1.7.7`
component: `labkit_FLIRThermal_app` | `1.4.7 -> 1.4.8`
component: `labkit_ImageMatch_app` | `1.6.7 -> 1.6.8`
component: `labkit_VideoMarker_app` | `1.5.6 -> 1.5.7`
component: `labkit_NerveResponseAnalysis_app` | `1.4.7 -> 1.4.8`
component: `labkit_ResponseReviewStats_app` | `1.4.6 -> 1.4.7`
scope: Public MATLAB help
scope: Generated API reference
scope: Documentation contract tests
```

## Context

LabKit's generated function pages came from MATLAB help, but the contract test
covered a hand-maintained subset of packages and only checked broad section
presence. A public function, implemented option, default, legal value, failure
mode, or related API could therefore be omitted while the documentation suite
still passed. Several App calculation pages exposed exactly those gaps.

## Decision and rationale

Treat the callable public surface as discoverable source truth. The contract
now scans every non-private function below `+labkit` plus each App API declared
in the API catalog. It derives standard option reads from implementation code
and requires those fields to have documented values and defaults, while
required options remain explicitly distinguishable from optional ones.

Every public function also states failure behavior and a `See also`
relationship. This keeps a generated page useful for standalone MATLAB callers
instead of merely repeating a short summary.

## Changes

- Completed help for the Contract, Biosignal, DTA, RHS, Thermal, Image, UI, and
  cataloged App calculation surfaces.
- Added exact option/default/legal-value checks, package-wide discovery,
  failure-behavior checks, and related-API checks to the documentation
  contract.
- Added a synthetic regression proving the guard detects an undocumented
  option, an omitted default, a vague value domain, missing failure behavior,
  and a missing related-API link.
- Made `labkit.image.resizeToFit` reject unsupported interpolation method names
  instead of silently treating them as bilinear.
- Linked owning library and App manuals to the detailed generated reference.

## User and data impact

Readers can now determine valid calls, defaults, option domains, outputs,
empty-result behavior, errors, and adjacent functions from the generated page
for a public symbol. Developers adding a public function or a standard option
read receive a focused contract failure when the corresponding help is
incomplete.

## Compatibility and migration

No saved project or data migration is required. Existing valid calls are
unchanged. A call to `labkit.image.resizeToFit` with a method other than
`"bilinear"` or `"nearest"` now raises
`labkit:image:InvalidResizeMethod`; such values were never part of the
documented contract.

## Validation

The exact `PublicApiDocumentationContractTest` suite passes all eight tests,
including execution of cataloged examples and the new synthetic defect
regression. Image facade unit tests cover both supported resize methods and
the unsupported-method error. Generated-site consistency and changed-scope
validation are run after this record and its component manuals are rendered.

## Evidence

- [Public API index](../../../../reference/README.md)
- [LabKit App Framework](../../../../framework/README.md)
- [App catalog](../../../../apps/README.md)
- [Documentation maintenance](../../../../development/maintain-and-release/documentation.md)

## Known limitations and follow-up

Implementation-derived option discovery intentionally recognizes the
repository's standard option access patterns; unusual dynamic field access
still requires review. Private helpers remain outside the public-page
contract, and interactive `Typical Call:` sketches are not executed as
file-independent examples.
