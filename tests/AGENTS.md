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

After a meaningful validation or test-design checkpoint, add any durable
lesson about selectors, evidence scope, fixtures, or runner behavior to
`.agents/dos-and-donts.md`. Consolidate it regularly and retain stable test
catalog rules here rather than duplicating them in the ledger.

`headless`, `gui`, `isolated`, and `coverage` are full catalog profiles.
`changedFast` is focused local evidence: an App or facade path maps to its
bounded closure, while framework, build, and repository-policy paths map to
explicit system evidence. Documentation and generated site paths are explicitly
ignored because `docsCheck` owns them. An unclassified path fails planning; add
a production role or an explicit no-test classification rather than widening
the run. Generated artifacts live under `artifacts/test-results/` and are never
tracked. A plan may also name an explicit manual check; it is a handoff for
native interaction or scientific review, never passing test evidence.
