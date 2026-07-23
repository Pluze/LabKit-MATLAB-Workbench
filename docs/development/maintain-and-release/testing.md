# Testing

[Development index](../README.md) | [Architecture](../build-apps/architecture.md) |
[Maintainer Tools](../tools/README.md) | [Documentation](documentation.md)

LabKit tests specify observable contracts. They are not organized by an
implementation-stage label, suite selector, tag query, or hand-maintained test
catalog. Start from the production file whose behavior changed; the test
catalog determines its required evidence and executes exact test identities.

## Everyday Workflow

For a changed production source, ask the catalog where evidence belongs:

```matlab
addpath("tests")
labkittest.explain("apps/electrochem/cic/+cic/+analysisRun/computeCIC.m")
```

`explain` prints the exact specification folders, contracts, environments,
selected identities, and the reason for every selection. Add a new behavioral
spec without inventing a path, metadata, class shell, or runner command:

```matlab
labkittest.createSpec( ...
    "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
    Contract="scientific", Name="PulseWindow")
```

`Contract` is needed only when one source has more than one author-owned
boundary. The generated file contains the required `Contract:<name>` and
`Env:<name>` tags plus an intentional failing placeholder. Replace that
placeholder with a small behavioral proof. Never create a test by guessing a
folder, a suite range, a test tag, or a wrapper class.

During an edit, execute the narrow owner and contract that changed:

```matlab
labkittest.run(Owner="apps/electrochem/cic/analysisRun", ...
    Contract="scientific")
```

Use `labkittest.run(File=...)` only when the source maps to one complete,
known evidence closure. It refuses missing evidence instead of silently
running a partial test. A changed analysis source normally requires its
scientific behavior, result schema, and presentation consumer together.

## Test Model

Runnable specifications are under `tests/specs/`. Their owner path mirrors a
production capability, and every test declares exactly one contract and one
execution environment.

```text
tests/specs/
├── framework/<area>/
├── apps/<family>/<app>/<capability>/
├── apps/conformance/
└── system/<area>/
```

Contracts describe evidence, not test cost:

| Contract | Proves |
| --- | --- |
| `scientific` | calculations, numerical policies, and scientifically meaningful branches |
| `source` | source decoding, callbacks, and capability-local state transitions |
| `state` | durable/transient state transitions and reconstruction |
| `persistence` | project schema creation, validation, and migration |
| `result` | exports, schemas, manifests, and task identity |
| `presentation` | reader-facing snapshot data and declared layout semantics |
| `definition` / `product` | parameterized public App conformance |
| `system` | build, repository, CI, documentation, packaging, and release guardrails |

Environments are `headless`, `hidden-gui`, and `isolated-process`.
Headless tests do not prove GUI behavior. Hidden-GUI conformance proves that an
App can build its declared layout; it does not prove native dialogs, pointer
feel, visual quality, real lab data, or scientific review. The isolated-process
conformance probes every public App from reset paths in one child MATLAB
process, retaining the path boundary without paying one cold startup per App.

## Build Tasks

Use stable Build tasks for branch and CI gates:

```bash
buildtool changedFast
buildtool headless
buildtool gui
buildtool coverage
buildtool docs
buildtool docsCheck
```

| Task | Purpose |
| --- | --- |
| `changedFast` | Local final pre-commit/pre-push gate. Reads tracked and untracked working-tree paths; on a clean checkpoint it reads `HEAD^..HEAD`. |
| `headless` | Every headless catalog identity. |
| `gui` | Every hidden-GUI catalog identity. |
| `coverage` | Headless catalog with Cobertura XML and HTML coverage artifacts. |
| `docs` / `docsCheck` | Render or verify the generated documentation site. |

`changedFast` prints semantic reasons and exact identities. For ordinary App
and facade source it runs only the required contract closure. A framework,
Build, catalog, policy, or unknown path deliberately widens to every headless
specification: broad selection is a visible safety boundary, not a planner
failure. Do not weaken that fallback to make a route count look smaller.

Run focused behavior during iteration. Run `changedFast` once when the branch
is ready for review or direct-main integration. CI owns broad platform
validation; do not repeatedly run broad tasks after each small edit.

## Artifacts and Failures

Each run writes one folder beneath `artifacts/test-results/<run-name>/`:

```text
manifest.json       run identity
plan.json           exact selected identities and reasons
events.jsonl        progress and heartbeat stream
active-test.json    latest machine-readable progress state
junit.xml           CI result exchange
summary.json        pass/fail summary
coverage.xml        coverage runs only
coverage-html/      coverage runs only
```

After a failure, copy its exact class/method identity from the output and run
the smallest owner/contract or exact source that proves the repair. A zero
selection or missing-contract error is a test-authoring defect, never passing
evidence.

## CI and Manual Evidence

Continuous Integration runs `headless` and `gui` on Linux, macOS, and Windows
from a clean MATLAB runtime without optional Toolboxes. It uploads the catalog
artifacts even after failure. Coverage is an explicit report, not a duplicate
CI gate.

Manual App validation remains required for native file dialogs, visual design,
pointer interaction, real-data suitability, and scientific interpretation.
Use synthetic, minimal fixtures in automated tests. Never add real lab files,
local paths, subject/device identifiers, timestamps, or proprietary metadata.

## Maintainer Rules

- Keep specs beside the capability that owns their behavior; tests never own a
  parallel product API.
- Prefer direct behavioral calls over full App workflows. Add a structural GUI
  proof only when layout or wiring itself is the contract.
- Do not add legacy suite folders, stage tags, selector registries, test
  wrappers, runner options, or Code Analyzer suppression pragmas.
- Add a new public framework test API only when it is a stable product
  boundary. Test infrastructure stays private under `tests/+labkittest/`.
- Follow `.agents/migration_guide.md` only while retiring compatibility debt;
  it is not an everyday authoring checklist.
