# Testing

```labkit-page
id: develop-testing
type: task
audience: maintainer
summary: Select focused evidence, run stable local and CI gates, and diagnose failures from the production contract that changed.
```

[Development index](README.md) | [Architecture](app-authoring/architecture.md) | [Developer Tools](tools/README.md) | [Documentation](documentation.md)

LabKit tests specify observable contracts. They are not organized by an implementation-stage label, suite selector, tag query, or hand-maintained test catalog. Start from the production file whose behavior changed; the test catalog determines its required evidence and executes exact test identities. A test is necessary only when its stated failure would identify a supported behavior, regression, compatibility promise, or risk decision. Executing code is not evidence by itself: an assertion must fail when the protected behavior is plausibly broken.

## Everyday Workflow

For a changed production source, ask the catalog where evidence belongs:

```matlab
addpath("tests")
labkittest.explain("apps/electrochem/cic/+cic/+analysisRun/computeCIC.m")
```

`explain` prints the exact specification folders, contracts, environments, selected identities, and the reason for every selection. Add a new behavioral spec without inventing a path, metadata, class shell, or runner command:

```matlab
labkittest.createSpec( ...
    "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
    Contract="scientific", Name="PulseWindow", ...
    Reason="Regression: pulse-window bounds must remain stable.")
```

`Contract` is needed only when one source has more than one author-owned boundary. `Reason` starts with `Regression`, `Invariant`, or `Compatibility`; it records the durable behavior being protected, rather than a temporary implementation detail. The generated file contains the required `Contract:<name>` and `Env:<name>` tags plus an intentional failing placeholder. Replace that placeholder with a small behavioral proof. Remove or revise a specification when that stated behavior is intentionally retired. Never create a test by guessing a folder, a suite range, a test tag, or a wrapper class.

During an edit, execute the narrow owner and contract that changed:

```matlab
labkittest.run(Owner="apps/electrochem/cic/analysisRun", ...
    Contract="scientific")
```

Use `labkittest.run(File=...)` only when the source maps to one complete, known evidence closure. It refuses missing evidence instead of silently running a partial test. A changed analysis source normally requires its scientific behavior, result schema, and presentation consumer together.

## Test Model

Runnable specifications are under `tests/specs/`. Their owner path mirrors a production capability, and every test declares exactly one contract and one execution environment.

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

The owner path is a mechanical mirror of the production capability. Do not replace source paths with logical aliases such as `framework/<area>` or `system/<area>`; contract and environment tags describe behavior without changing physical ownership.

`tests/+testfixtures/` contains only input construction reused by multiple specification owners, grouped by the App or data facade that owns the shape. Keep a single-owner fixture beside its specification; keep test-run machinery under `tests/+labkittest/`; do not create a generic `shared`, `support`, or `helpers` directory. Fixtures accept ordinary folders or values and return the production value under test rather than a test-only context, pack, artifact, scenario, or manifest model.

Contracts describe evidence, not test cost:

| Contract | Proves |
| --- | --- |
| `scientific` | calculations, numerical policies, and scientifically meaningful branches |
| `source` | source decoding, callbacks, and capability-local state transitions |
| `state` | durable/transient state transitions and reconstruction |
| `persistence` | an App-owned save/open archive or final-state restore contract |
| `result` | exports, schemas, manifests, and task identity |
| `presentation` | reader-facing snapshot data and declared layout semantics |
| `workflow` | an App-owned source-to-result user journey through the native runtime |
| `definition` / `product` | parameterized public App conformance |
| `system` | build, repository, CI, documentation, packaging, and release guardrails |

Environments are `headless`, `hidden-gui`, and `path-isolated`. Headless tests do not prove GUI behavior. Hidden-GUI product conformance proves that an App can build its declared layout; a hidden-GUI `workflow` additionally drives the native runtime through an App-owned user goal and verifies state, presentation, result, and failure semantics at the points the journey crosses. Neither proves operating-system dialogs, pointer feel, visual quality, real lab data, or scientific review. The path-isolated conformance probes every public App from a reset path boundary in the already running catalog executor. It retains the deployable path boundary and batches all App results without requiring a second concurrent MATLAB license.

## Evidence Design

Each App owns one or more core journeys beginning at the same source boundary a user enters and ending at a useful result, saved continuation, or explicit failure. The journey uses the production decoder and native runtime; it must not inject a post-import state that bypasses the defect-prone boundary it claims to protect. Synthetic files are valid only when they obey the production format and are consumed by the production reader. A fixture and its consumer cannot define each other's expected answer: scientific or schema assertions come from an independent formula, preserved reference evidence, a hand-audited small case, an invariant, or a separately owned compatibility contract.

GUI evidence has three distinct responsibilities. Framework conformance proves generic controls and signals are created and dispatched correctly. App interaction evidence proves every declared signal is driven through its exact native runtime operation. Core journeys prove meaningful action order, enablement, recovery, and user-visible outcomes. Merely locating a control, matching a callback name, invoking every callback from default state, or asserting that no exception occurred is not sufficient App evidence. Disabled or state-dependent actions are exercised only in a reachable state; equivalent combinations use risk-based partitions or pairwise cases, while every scientifically distinct branch remains explicit.

Every new or materially changed test states its oracle and should survive a counterfactual review: identify a small plausible production mutation, such as a reversed condition, stale view revision, changed unit conversion, omitted result field, or disconnected callback, that makes the test fail for the intended reason. Use mutation tooling where it is reliable, but do not optimize a mutation score or keep low-value tests solely to raise it. Negative, cancellation, invalid-input, retry, and restore paths are included when they are supported user behavior, not generated as a mechanical Cartesian product.

This model follows mature project guidance to test user-visible behavior and resilient interaction boundaries ([Playwright](https://playwright.dev/docs/best-practices), [Testing Library](https://testing-library.com/docs/guiding-principles)), separate unit, integration, and functional GUI evidence ([napari](https://napari.org/stable/developers/contributing/testing.html), [Qt Test](https://doc.qt.io/qt-6/qtest-overview.html)), and reserve deterministic image comparison for an actual visual contract ([Matplotlib](https://matplotlib.org/stable/devel/testing.html#image-comparison-tests)). LabKit adapts those ideas to deterministic scientific oracles and Base MATLAB runtime constraints rather than copying another project's suite structure.

## Assertion Boundaries

Assert the smallest producer-owned value: a returned field, record, event, identifier, artifact, or observable state transition. Diagnostic presentation is not a substitute for that contract. If a console record matters, identify it by a stable semantic marker, assert its multiplicity and fields, and attach the complete captured output as the assertion diagnostic. Do not count every newline or nonblank line in an `evalc` transcript; ambient warnings and runner diagnostics are not part of the record unless its supported interface says otherwise. Require an exact complete transcript only when that text is itself a supported user or developer interface.

When an unexpected console line causes a failure, retain its content before assigning a cause. A platform or MATLAB-version correlation is evidence about where the symptom appeared, not proof that the runtime produced it.

## Build Tasks

Use stable Build tasks for branch and CI gates:

```bash
buildtool
buildtool headless
buildtool apps
buildtool codecheck
buildtool docs
buildtool docsCheck
```

| Task | Purpose |
| --- | --- |
| `changedFast` | Default final local pre-PR review gate, also selected by bare `buildtool`. Runs `codecheck` and `docsCheck`, then reads tracked and untracked working-tree paths for focused tests; on a clean checkpoint it reads `HEAD^..HEAD`. |
| `headless` | Every headless catalog identity. |
| `apps` | Every hidden-GUI identity followed by the reset-path isolation probe for every public App in the same MATLAB build. |
| `codecheck` | Lightweight pre-commit gate over all public-repository MATLAB source. Prints one `CODECHECK_RESULT` line and fails unless analyzer issues, suppressions, compatibility recommendations, and unreviewed secondary-runtime calls are all zero. Accepted private workspaces retain their own runtime policy. |
| `docs` / `docsCheck` | Render the ignored local site or verify deterministic source-derived output. |

The default `buildtool` command runs `changedFast`; name a specialist task only for broad headless or App-boundary investigation, code analysis, or documentation generation. `changedFast` first requires clean code analysis and deterministic documentation, then prints whether its test plan is `focused-local` or `full-profile`, semantic reasons, exact identities, and any explicitly ignored paths. For ordinary App and facade source it runs only the required contract closure. Framework, Build, catalog, and repository-policy paths select explicit bounded system evidence. Documentation paths are explicitly ignored by the test planner because the same gate's `docsCheck` dependency owns deterministic generation; local `site/` output is ignored by Git. An unknown path is a planning error: declare its production role or an explicit no-test classification rather than widening the run.

Use `labkittest.explainChanged` to inspect that decision without executing tests. It prints each changed path's classification, selected evidence, and any manual boundary. A focused-local result is rapid author feedback, not merge safety evidence; CI runs the full platform profiles.

Run focused behavior during iteration. Run `changedFast` once when the task branch is ready for final PR review. CI owns broad platform validation; do not repeatedly run broad tasks after each small edit.

Every push to a non-`main` task branch also starts a non-gating `Development Feedback` workflow on latest Ubuntu and latest Base MATLAB. It passes the complete GitHub push range to the same changed-path planner, runs its focused evidence, and checks deterministic documentation. This job is rapid cross-environment author feedback only: a green result does not establish merge safety, replace the one local pre-PR `changedFast` checkpoint, or reduce the complete PR matrix. A new push cancels an older in-progress feedback run so rapid iteration does not build a stale queue. The workflow checks for an open PR both before checkout and again before MATLAB setup, so a PR created while lightweight feedback is starting can take ownership before expensive duplicate work begins. A manual dispatch still runs the complete independent feedback lane. Read the non-gating result when its evidence is needed rather than monitoring it throughout ordinary development.

## CI and Manual Evidence

Continuous Integration separates MATLAB-version compatibility from desktop platform compatibility instead of repeating their Cartesian product. Clean Linux and Windows R2022b runtimes run `headless` and `apps` at the minimum supported MATLAB boundary. Current Linux runs both profiles in one clean runtime so setup cost and installation tail latency are paid once. Current Windows and Apple Silicon macOS run the platform-sensitive `apps` profile; the full headless catalog is not repeated on those current-version jobs. The `apps` runner groups hidden-GUI identities and the path-isolated conformance by environment, continues to the isolation group after ordinary GUI test failures, and writes one combined JUnit result. No job installs optional Toolboxes. Linux App jobs use a real virtual display service. The current Linux runtime is cached between runs; floor and desktop-platform installations remain clean and uncached. CI also runs `docsCheck` once and uploads catalog artifacts after failures.

`CI Gate` is the required aggregate result. `main` accepts pull requests only from same-repository short-lived task branches; branch names carry no product, agent, or workflow semantics. Policy checks verify source ownership, direct semantic version steps, and matching structured Change records. Strict branch protection rejects direct pushes and requires the pull request to be current with `main`. The accepted `main` push therefore records policy for the exact squash commit instead of repeating the MATLAB matrix. If those protection assumptions change, restore full validation on `main` pushes.

Job summaries identify the profiles actually run, failed test identities, available diagnostics, artifacts, and manual boundaries. A cancelled or skipped required profile is incomplete rather than passing. Read the summary first, then inspect only the named failing artifact or log.

Pull requests always run repository policy, the complete MATLAB platform matrix, and `docsCheck`. This single claim is intentionally independent of the changed paths. Every accepted `main` push starts Documentation Pages, which generates ignored `site/` output from that exact source; generated HTML is never committed.

Manual App validation remains required for native file dialogs, visual design, pointer interaction, real-data suitability, and scientific interpretation. Use synthetic, minimal fixtures in automated tests. Never add real lab files, local paths, subject/device identifiers, timestamps, or proprietary metadata.

## Artifacts and Failures

Each run writes one folder beneath `artifacts/test-results/<run-name>/`:

```text
manifest.json       run identity
plan.json           exact selected identities and reasons
events.jsonl        progress and heartbeat stream
active-test.json    latest machine-readable progress state
junit.xml           CI result exchange
summary.json        pass/fail summary
```

After a failure, copy its exact class/method identity from the output and run the smallest method, specification file, owner/contract, or exact source that proves the repair. Do not invoke the planner again when the failing identity is already known. A zero selection or missing-contract error is a test-authoring defect, never passing evidence.

### CI Repair Loop

Once the pull request exists, required CI owns the broad platform claim. For a failed check:

1. let an already-running platform matrix finish when its remaining jobs can still provide independent failure evidence; collect the complete set of failed identities before pushing another head;
2. inspect only the failed checks and logs for those exact failing identities;
3. reproduce each method, specification file, or smallest owner/contract locally when reproduction is useful;
4. repair the smallest responsible source boundaries and rerun only that focused evidence;
5. batch the verified repairs into one push to the existing PR branch and let CI rerun its required profiles.

An early repair push is appropriate only when a prerequisite failure, such as branch policy, checkout, dependency setup, or test discovery, prevents the remaining jobs from producing useful evidence. A first completed test failure is not evidence that the matrix has no other failures. Do not invalidate a mostly complete run merely because the first failure is simple to repair.

Do not run `changedFast`, `headless`, `apps`, or the complete local matrix after every CI repair. The one pre-PR `changedFast` run remains the local integration checkpoint; CI re-establishes the complete claim after later focused fixes. Re-run a wider local closure only when the repair itself expands the intended behavior, component ownership, or compatibility boundary beyond the original failure.

When a mapped layout change leaves a non-automatable boundary, its plan can name a manual check. It is printed and recorded in `plan.json`, but it never makes an automated run pass. Manual checks are limited to native dialogs, pointer behavior, visual design, real-data suitability, and scientific interpretation; they cannot replace an automated calculation, state, export, migration, structural-GUI, or workflow proof.

For deterministic rendering regressions, use `labkittest.visualEvidencePath(name, extension)` and write the production image there. Keep an automated assertion over that same file; the retained image supports human or visual-model review but is not itself a passing test. CI includes each profile's `visual-evidence/` folder in the platform artifact.

## Maintainer Rules

- Keep specs beside the capability that owns their behavior; tests never own a parallel product API.
- Keep cross-owner generated inputs in an owner-named package under `tests/+testfixtures/`; keep every other input builder beside the specification that consumes it. Delete manual-replay builders and tests whose only outcome is proving the fixture itself.
- Prefer direct behavioral calls for narrow formulas and state transitions, and require at least one native core workflow for every App. Add more workflows only for a distinct user goal, state-dependent chain, or failure boundary.
- Audit every declared App signal with `labkittest.appEvidence`. Every signal needs an exact native-runtime operation. This remains an omission check: the owning workflow must assert the domain or user-visible outcome, and the callback's internal decisions remain owned by its direct contract tests.
- Do not add legacy suite folders, stage tags, selector registries, test wrappers, runner options, or Code Analyzer suppression pragmas.
- Add a new public framework test API only when it is a stable product boundary. Test infrastructure stays private under `tests/+labkittest/`.
- Follow `.agents/migration_guide.md` only while that active compatibility retirement exists; the file is absent when no migration is open.
