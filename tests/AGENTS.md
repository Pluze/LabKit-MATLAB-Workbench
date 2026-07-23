# LabKit Test Catalog

Runnable specifications live under `tests/specs/`. Every test has exactly one
`Contract:<name>` and one `Env:<name>` tag. Physical owner paths mirror the
production capability; `tests/+labkittest/` owns discovery, authoring,
execution, artifacts, and conformance support. `tests/+testfixtures/` owns
only synthetic inputs reused by more than one specification owner; a fixture
used by one owner stays beside that specification. Do not create a generic
shared, support, or helper directory.

Start from production with `labkittest.explain`. Create a missing App-owned
specification with `labkittest.createSpec`; never create test paths, suite
folders, selector registries, wrappers, or stage tags by hand. Run focused
evidence through `labkittest.run`, and use `buildtool changedFast` only at the
final integration gate.

`headless`, `gui`, and `coverage` are catalog profiles. A framework, build, or
unknown change widens to all headless specs deliberately. Generated artifacts
live under `artifacts/test-results/` and are never tracked.
