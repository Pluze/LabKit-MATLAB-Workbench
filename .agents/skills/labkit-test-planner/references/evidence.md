# Evidence design

Read when creating or materially changing tests, fixtures, or App workflow coverage.

Use calculation/parser/migration, presenter/renderer/callback/state, generic
hidden-GUI structure, and App workflow as distinct evidence semantics rather
than substitutes ordered only by cost. Every App requires at least one bounded
native core journey from its production source boundary to a useful result,
continuation, or supported failure. Add further journeys only for distinct
user goals, reachable state-dependent chains, or failure/recovery boundaries.
Hidden GUI does not prove native dialog, visual quality, pointer feel,
real-data suitability, or scientific validity.

Audit changed App workflows through their executable specifications. Require
an owning assertion over domain state, presentation, artifacts, or supported
failures. Textual invocation counts and absence of exceptions do not establish
behavior. Do not generate a control
Cartesian product; partition equivalent values and combinations by scientific
meaning, reachable workflow state, failure risk, and platform sensitivity.

For test maintenance, apply the oracle, retirement, and assertion boundaries in
`tests/AGENTS.md` and the Evidence Design section of `docs/develop/testing.md`.
Compare the behavior protected before and after the edit. A removed assertion
needs no replacement when its behavior is retired; otherwise identify the
surviving proof or strengthen the owning test. Use a deliberate temporary
mutation when proportionate to verify that the surviving assertion detects the
intended defect. Keep that experiment in ignored artifacts, not production.

During output-failure diagnosis, retain the transcript, identify the owned
record, and rerun the smallest evidence after correcting the assertion boundary.

For fixtures, apply `tests/AGENTS.md`: reuse ordinary values and owner-local
builders; share only across real specification consumers. Do not add fixture
protocols or retire a supported outcome merely because a fixture looks awkward.
