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
    Contract="scientific", Name="PulseWindow", ...
    Reason="Regression: pulse-window bounds must remain stable.")
```

`Contract` is needed only when one source has more than one author-owned
boundary. `Reason` starts with `Regression`, `Invariant`, or `Compatibility`;
it records the durable behavior being protected, rather than a temporary
implementation detail. The generated file contains the required
`Contract:<name>` and `Env:<name>` tags plus an intentional failing placeholder.
Replace that placeholder with a small behavioral proof. Remove or revise a
specification when that stated behavior is intentionally retired. Never create
a test by guessing a folder, a suite range, a test tag, or a wrapper class.

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

`tests/+testfixtures/` contains only synthetic inputs reused by multiple
specification owners. Keep an owner-specific fixture beside its specification;
do not create a generic `shared`, `support`, or `helpers` test directory.

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

Environments are `headless`, `hidden-gui`, and `path-isolated`.
Headless tests do not prove GUI behavior. Hidden-GUI conformance proves that an
App can build its declared layout; it does not prove native dialogs, pointer
feel, visual quality, real lab data, or scientific review. The path-isolated
conformance probes every public App from a reset path boundary in the already
running catalog executor. It retains the deployable path boundary and batches
all App results without requiring a second concurrent MATLAB license.

## Build Tasks

Use stable Build tasks for branch and CI gates:

```bash
buildtool changedFast
buildtool headless
buildtool gui
buildtool isolated
buildtool coverage
buildtool docs
buildtool docsCheck
```

| Task | Purpose |
| --- | --- |
| `changedFast` | Local final pre-commit/pre-push gate. Reads tracked and untracked working-tree paths; on a clean checkpoint it reads `HEAD^..HEAD`. |
| `headless` | Every headless catalog identity. |
| `gui` | Every hidden-GUI catalog identity. |
| `isolated` | Every path-isolated catalog identity. |
| `coverage` | Headless catalog with Cobertura XML and HTML coverage artifacts. |
| `docs` / `docsCheck` | Render the ignored local site or verify deterministic source-derived output. |

`changedFast` prints whether its plan is `focused-local` or `full-profile`,
semantic reasons, exact identities, and any explicitly ignored paths. For
ordinary App and facade source it runs only the required contract closure.
Framework, Build, catalog, and repository-policy paths select explicit bounded
system evidence. Documentation paths are explicitly ignored because
`docsCheck` owns deterministic generation; local `site/` output is ignored by
Git. An unknown path is a planning error: declare its production role or an
explicit no-test reason; do not hide missing ownership by widening the run.

Use `labkittest.explainChanged` to inspect that decision without executing
tests. It prints each changed path's classification, selected evidence, and any
manual boundary. A focused-local result is rapid author feedback, not merge
safety evidence; CI runs the full platform profiles.

Run focused behavior during iteration. Run `changedFast` once when `develop`
is ready for final PR review. CI owns broad platform validation; do not
repeatedly run broad tasks after each small edit.

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

When a mapped layout change leaves a non-automatable boundary, its plan can
name a manual check. It is printed and recorded in `plan.json`, but it never
makes an automated run pass. Manual checks are limited to native dialogs,
pointer behavior, visual design, real-data suitability, and scientific
interpretation; they cannot replace an automated calculation, state, export,
migration, structural-GUI, or workflow proof.

For deterministic rendering regressions, use
`labkittest.visualEvidencePath(name, extension)` and write the production
image there. Keep an automated assertion over that same file; the retained
image supports human or visual-model review but is not itself a passing test.
CI includes each profile's `visual-evidence/` folder in the platform artifact.

## CI and Manual Evidence

Continuous Integration runs `headless`, `gui`, and `isolated` on Linux, macOS,
and Windows against R2022b and the latest release available to
`matlab-actions/setup-matlab`. R2022b is the LabKit minimum supported release
and also the first release with MATLAB Build Tool. macOS runs only the latest
release as an Apple Silicon and native-platform sentinel; Linux and Windows
cover both release boundaries. This matrix is compatibility evidence for the
supported product boundary. CI uses clean MATLAB runtimes without optional
Toolboxes. The R2022b entries use the fixed Ubuntu 22.04 and Windows Server
2022 runner images supported by that MATLAB release; latest MATLAB uses the
current runner images. Each matrix job installs MATLAB once and runs its
scheduled profiles in separate batch sessions, so a shard shares setup cost
without sharing MATLAB session state. Historical
timings showed that the latest Windows and macOS GUI sessions formed the CI
critical path. Those two sentinels therefore run a `gui` shard in parallel
with a `headless` plus `isolated` shard. Linux and the R2022b Windows floor
retain one all-profile job because splitting their shorter sessions would
mostly duplicate setup. This selective sharding keeps complete evidence while
avoiding both the long fully serial critical path and the setup cost of a
15-job Cartesian matrix. Linux jobs provide an X virtual framebuffer before
running MATLAB so native graphics tests have a real display service instead
of relying on release-specific no-display behavior. CI runs `docsCheck` once
on the latest release, then reports one aggregate `CI Gate` result that depends
on every required shard. Configure repository branch protection to require
`CI Gate`; the workflow does not silently replace repository protection
policy. It uploads the catalog artifacts even after failure. Coverage is an
explicit report, not a duplicate CI gate.

`main` is release-only and accepts pull requests only from the
repository-owned `develop` branch. The lightweight policy job rejects every
other PR source before MATLAB setup. It also compares
the PR base and head for App, facade, and launcher source ownership, direct
semantic version steps, and matching component-history transitions. Branch
protection separately rejects direct pushes, including administrator pushes.
Because the required PR check runs against an up-to-date merge result, the
squash-merged `main` commit has the same file tree that the PR matrix already
validated. A `main` push therefore repeats only the lightweight policy and
aggregate gate for the exact commit SHA; it does not pay for a second MATLAB
matrix or documentation render. This optimization depends on required strict
PR checks, administrator enforcement, and the direct-push prohibition. If any
of those protections are relaxed, restore full validation on `main` pushes.
Documentation delivery is separate from the tracked source tree: relevant
`main` changes trigger the Documentation Pages workflow, which installs MATLAB,
generates ignored `site/` output from that exact commit, and deploys the Pages
artifact. No workflow commits generated HTML back to a protected branch.

Every matrix shard publishes one evidence-oriented job summary after its
scheduled independent MATLAB sessions finish. All-profile summaries make the
platform compatibility claim; split summaries name `Core` or `Hidden GUI` and
claim only that shard's evidence. Their profile tables state what the scheduled
profiles prove instead of treating intentionally unscheduled profiles as
failures. A successful summary records the scoped claim, clean runtime
assumptions, display configuration, slowest tests, artifact name, and the
manual boundaries that automation does not prove. A failed summary preserves
any profiles that still passed, separates a missing JUnit report from a
reported test failure, names failed test identities, includes recorded MATLAB
diagnostics, and collapses active-test and log-tail evidence below the primary
failure. Build tasks define descriptions so the upstream MATLAB Build Results
table is meaningful as well. The repository-owned summary helper has no
third-party Python dependency and is regression-tested by the lightweight
change-policy job. A cancelled or skipped scheduled profile makes that shard
`incomplete`, not `failed`; passing profiles remain valid evidence, but the
unfinished job cannot establish its scoped claim.

CI classifies the exact pushed or pull-request diff before scheduling MATLAB.
Source, test, build, workflow, and tool changes run the complete platform
matrix. Human documentation-only changes run `docsCheck` without the platform
matrix. Agent guidance and GitHub contribution-template-only changes run the
lightweight change-policy check without starting MATLAB. Mixed changes run the
union of their required profiles, and `CI Gate` verifies every profile selected
by the classifier. Changing the classifier or workflow is itself a full-matrix
change.

Manual App validation remains required for native file dialogs, visual design,
pointer interaction, real-data suitability, and scientific interpretation.
Use synthetic, minimal fixtures in automated tests. Never add real lab files,
local paths, subject/device identifiers, timestamps, or proprietary metadata.

## Maintainer Rules

- Keep specs beside the capability that owns their behavior; tests never own a
  parallel product API.
- Keep cross-owner synthetic inputs in `tests/+testfixtures/`; keep every
  other test helper beside the specification that owns its behavior.
- Prefer direct behavioral calls over full App workflows. Add a structural GUI
  proof only when layout or wiring itself is the contract.
- Do not add legacy suite folders, stage tags, selector registries, test
  wrappers, runner options, or Code Analyzer suppression pragmas.
- Add a new public framework test API only when it is a stable product
  boundary. Test infrastructure stays private under `tests/+labkittest/`.
- Follow `.agents/migration_guide.md` only while retiring compatibility debt;
  it is not an everyday authoring checklist.
