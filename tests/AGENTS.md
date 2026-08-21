# LabKit Test Catalog

Runnable specifications live under `tests/specs/`. Every test has exactly one
`Contract:<name>` and one `Env:<name>` tag. Physical owner paths mirror the
production capability without logical aliases: `+labkit/+app/...` maps below
`tests/specs/labkit/app/...`, `tools/<area>/...` maps below
`tests/specs/tools/<area>/...`, and App capability packages map below the same
`apps/<family>/<app>/<capability>/` path. Contract and environment metadata
describe behavior but never change physical ownership.
`tests/+labkittest/` owns discovery, authoring,
execution, artifacts, and conformance support. `tests/+testfixtures/` owns
only input construction reused by more than one specification owner; a fixture
used by one owner stays beside that specification. Do not create a generic
shared, support, or helper directory.

Fixtures are private input construction, not a test product model. Pass an
ordinary destination folder or exact input values and return the production
value the specification consumes. Do not create Context, Pack, Artifact,
scenario-manifest, launcher, or other test-only protocols. Delete fixtures
whose only consumers were manual reproduction or tests of the fixture itself.

Tests protect current observable contracts and costly regressions, not the
history of how the repository reached its present design. Remove a test when
its behavior is retired; do not keep rejection tests for already-removed
options, absence checks for completed migration paths, exact implementation
file maps, arbitrary size/count limits, or assertions whose only purpose is to
enforce taste. When compatibility remains supported, test the saved input and
current output rather than the migration project or intermediate shape that
introduced it. Before adding a narrow regression, first extend an existing
owner-level behavior proof when that preserves a clear failure identity.

Place a rule that applies uniformly to every App in `apps/conformance/`, or at
the narrowest family root when it truly applies to that whole family. Do not
copy the same guard into individual Apps, because that both duplicates upkeep
and leaves unlisted Apps unprotected. Keep App-local tests when scientific
meaning, fixtures, workflow state, output schema, or failure semantics are
genuinely App-owned; do not force abstraction when it would hide those
differences or require a parallel test-only product model.

Production Apps and downstream App specifications, including accepted private
repositories, never call `labkit.app.internal`. Use the focused
`labkittest` test seams for runtime construction, callback contexts, and
compiled definition inspection. Only SDK-owned
white-box specifications under `tests/specs/labkit/app/` and the concentrated
`tests/+labkittest/` adapters may name SDK internals directly.

Start from production with `labkittest.explain`. Create a missing App-owned
specification with `labkittest.createSpec`; never create test paths, suite
folders, selector registries, wrappers, or stage tags by hand. Run focused
evidence through `labkittest.run`, and use `buildtool changedFast` only at the
final integration gate.

Initial state is exercised through App conformance and the smallest owner-level
behavior that consumes each meaningful default; do not require a dedicated
state specification for implementation-only struct shape. Persistence evidence
exists only for an App-owned continuation workflow and tests that App's
explicit archive contract rather than a generic runtime save/load path. App
conformance launches clean default state. App-specific input builders are
ordinary owner-level fixtures, not a Definition or Runtime capability, and
exist only while an automated behavior specification consumes them.

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

All durable suite runners use `labkittest.ProgressPlugin` so the console and
event artifact identify suite size, the active test, completed/total work, and
a heartbeat no less often than every 30 seconds during a long test. Detailed
result output alone is insufficient because it can remain silent inside one
slow test.
