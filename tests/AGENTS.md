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

Every App `projectSpec.m` selects nonempty owner-level `persistence` evidence
for defaults, validation, and migration semantics. App conformance separately
validates each synthetic sample pack, keeps Debug startup on the clean default
project, and launches the synthetic project through the native adapter.

A fixture constrains only the contract under test; do not add unrelated facade
version ranges or compatibility assertions that can turn a focused fixture
into a stale cross-component test. A direct test that constructs native Runtime
owns and restores its hidden-visibility fixture even when its catalog tag is
GUI. Callback tests use a contract-complete context or a narrow fake covering
every operation the callback invokes.

`headless`, `gui`, `isolated`, and `coverage` are full catalog profiles.
`changedFast` is focused local evidence: an App or facade path maps to its
bounded closure, while framework, build, and repository-policy paths map to
explicit system evidence. Documentation paths are explicitly ignored because
`docsCheck` owns them; local generated `site/` output is ignored by Git. An
unclassified path fails planning; add
a production role or an explicit no-test classification rather than widening
the run. Generated artifacts live under `artifacts/test-results/` and are never
tracked. A plan may also name an explicit manual check; it is a handoff for
native interaction or scientific review, never passing test evidence. A
state-only geometry assertion does not prove pointer ownership or native
control creation; add hidden-GUI structure evidence when either is the
regression boundary.
