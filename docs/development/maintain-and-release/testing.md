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
├── labkit/<package>/...
├── tools/<area>/...
├── tests/labkittest/
├── apps/<family>/<app>/<capability>/
├── apps/conformance/
├── labkit_launcher/
└── repository/
```

The owner path is a mechanical mirror of the production capability. Do not
replace source paths with logical aliases such as `framework/<area>` or
`system/<area>`; contract and environment tags describe behavior without
changing physical ownership.

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
buildtool codecheck
buildtool docs
buildtool docsCheck
```

| Task | Purpose |
| --- | --- |
| `changedFast` | Final local pre-PR review gate, run once after the complete `develop` diff is ready. Reads tracked and untracked working-tree paths; on a clean checkpoint it reads `HEAD^..HEAD`. |
| `headless` | Every headless catalog identity. |
| `gui` | Every hidden-GUI catalog identity. |
| `isolated` | Every path-isolated catalog identity. |
| `coverage` | Headless catalog with Cobertura XML and HTML coverage artifacts. |
| `codecheck` | Lightweight pre-commit gate over all public-repository MATLAB source. Prints one `CODECHECK_RESULT` line and fails unless analyzer issues, suppressions, compatibility recommendations, and unreviewed secondary-runtime calls are all zero. Accepted private workspaces retain their own runtime policy. |
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

Every push to `develop` also starts a non-gating `Development Feedback`
workflow on latest Ubuntu and latest Base MATLAB. It passes the complete GitHub
push range to the same changed-path planner, runs its focused evidence, and
checks deterministic documentation. This job is rapid cross-environment author
feedback only: a green result does not establish merge safety, replace the one
local pre-PR `changedFast` checkpoint, or reduce the complete PR matrix. A new
push cancels an older in-progress feedback run so rapid iteration does not build
a stale queue. While an open `develop`-to-`main` PR owns complete validation,
push-triggered feedback stops after a quick scope check instead of repeating
MATLAB and documentation work; a manual dispatch still runs the complete
feedback lane. Read the non-gating result when its evidence is needed rather
than monitoring it throughout ordinary development.

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
the smallest method, specification file, owner/contract, or exact source that
proves the repair. Do not invoke the planner again when the failing identity is
already known. A zero selection or missing-contract error is a test-authoring
defect, never passing evidence.

### CI Repair Loop

Once the pull request exists, required CI owns the broad platform claim. For a
failed check:

1. let an already-running platform matrix finish when its remaining jobs can
   still provide independent failure evidence; collect the complete set of
   failed identities before pushing another head;
2. inspect only the failed checks and logs for those exact failing identities;
3. reproduce each method, specification file, or smallest owner/contract
   locally when reproduction is useful;
4. repair the smallest responsible source boundaries and rerun only that focused
   evidence;
5. batch the verified repairs into one push to the existing PR branch and let
   CI rerun its required profiles.

An early repair push is appropriate only when a prerequisite failure, such as
branch policy, checkout, dependency setup, or test discovery, prevents the
remaining jobs from producing useful evidence. A first completed test failure
is not evidence that the matrix has no other failures. Do not invalidate a
mostly complete run merely because the first failure is simple to repair.

Do not run `changedFast`, `headless`, `gui`, `isolated`, or the complete local
matrix after every CI repair. The one pre-PR `changedFast` run remains the local
integration checkpoint; CI re-establishes the complete claim after later
focused fixes. Re-run a wider local closure only when the repair itself expands
the intended behavior, component ownership, or compatibility boundary beyond
the original failure.

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

Continuous Integration separates MATLAB-version compatibility from desktop
platform compatibility instead of repeating their Cartesian product. Clean
Linux and Windows R2022b runtimes run `headless`, `gui`, and `isolated` at the
minimum supported MATLAB boundary. Current Linux runs the complete profiles in
one clean runtime so setup cost and installation tail latency are paid once.
Current Windows and Apple Silicon macOS run the platform-sensitive `gui` and
`isolated` profiles; the full headless catalog is not repeated on those
current-version jobs. No job installs optional Toolboxes.
Linux GUI jobs use a real virtual display service. The current Linux runtime
is cached between runs; floor and desktop-platform installations remain clean
and uncached. CI also runs `docsCheck` once and uploads catalog artifacts after
failures. Coverage is an explicit report, not a duplicate merge gate.

`CI Gate` is the required aggregate result. `main` accepts pull requests only
from the repository-owned `develop` branch, and policy checks verify source
ownership, direct semantic version steps, and matching component history.
Strict branch protection rejects direct pushes and requires the pull request to
be current with `main`. The accepted `main` push therefore records policy for
the exact squash commit instead of repeating the MATLAB matrix. If those
protection assumptions change, restore full validation on `main` pushes.

Job summaries identify the profiles actually run, failed test identities,
available diagnostics, artifacts, and manual boundaries. A cancelled or
skipped required profile is incomplete rather than passing. Read the summary
first, then inspect only the named failing artifact or log.

Pull requests always run repository policy, the complete MATLAB platform
matrix, and `docsCheck`. This single claim is intentionally independent of the
changed paths. Every accepted `main` push starts Documentation Pages, which
generates ignored `site/` output from that exact source; generated HTML is
never committed.

`Continuous Integration` also has a manual recovery trigger. Dispatch a named
ref only when GitHub did not create a usable required check, rerun is
unavailable, or an existing check record is stuck. It resolves the ref against
`main`, then reuses the same policy, complete platform matrix, documentation
check, and aggregate gate as a pull request. Each dispatch has independent
concurrency state. Manual recovery changes how full validation starts, not what
it proves.

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
