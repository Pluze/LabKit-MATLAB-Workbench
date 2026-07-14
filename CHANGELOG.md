# LabKit MATLAB Workbench Changelog

This file is the project evolution map for users, maintainers, and agents. It
explains how LabKit changed over time, why each iteration exists, which
versions carry the change, and where to find evidence when auditing or
debugging.

The primary unit is a user-facing evolution entry, not a tag, commit, or raw
feature list. Release tags are public anchors for delivered builds. Component
versions identify the launcher, facade, or app metadata affected by an entry.
Commits and PRs belong in `Evidence`, not in the navigation structure.

## How To Use This File

- Start with `Current Version Lookup` when you only need to identify the version
  and metadata file for a launcher, facade, or app.
- Search `Structured Change Records` by Change ID, component, date, or title
  when investigating why behavior exists. Branch records use the same schema
  as mainline records; their location in Git already supplies delivery state.
- Read each record's metadata block for machine routing, then its narrative for
  context, rationale, impact, migration, validation, evidence, and limitations.
- Record meaningful behavior, compatibility, workflow, validation, diagnostics,
  and public facade changes. Do not dump raw git logs.

## Changelog Model

- `Current Version Lookup` is a state table. Keep it current with metadata
  files, but do not use it to explain history.
- A structured record has one stable Change ID and one ISO date. It may list
  versioned `introduced` events, later `component` transitions, unversioned
  repository `scope` values, or a combination. Historical events follow the
  committed version chain; current branch transitions compare directly with
  the mainline baseline rather than intermediate development commits.
- `type` uses the repository's Conventional Commit vocabulary.
  `compatibility` is `compatible`, `additive`, or `breaking`.
- Narrative sections are required because metadata alone cannot explain the
  scientific, workflow, or maintenance decision that Git history obscures.
- `tools/release/parseLabKitChangelog.m` parses schema-v1 records and rejects
  duplicate IDs, malformed dates or versions, unknown metadata, missing
  narrative sections, and records out of reverse chronological order.
- A branch does not need a separate pending state. The same record is useful
  before and after merge; evidence can name tests, a PR, a release tag, source
  anchors, or the stable Change ID used to locate the carrying commit.

## Structured Change Records

### Video Marker predictive frame navigation

```labkit-change
schema: 1
id: LK-20260714-video-marker-predictive-navigation
date: 2026-07-14
type: feat
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.1.0 -> 1.2.0`
component: `labkit.ui` | `5.1.1 -> 5.2.0`
scope: `AGENTS.md`
scope: `apps/AGENTS.md`
scope: `docs/architecture.md`
scope: `docs/ui.md`
```

#### Context

The first tracking implementation exposed separate interpolation and
previous-frame buttons. Its integer grayscale block search could only model a
small translation, and coordinate interpolation did not follow the actual
trajectory of articulated points. Users still had to request every estimate
manually.

#### Decision and rationale

Make prediction an automatic part of forward navigation. Use a mature
pyramidal Kanade-Lucas-Tomasi tracker with forward/backward rejection for
short-range point propagation, and treat every complete human edit as a new
anchor. This matches the app's correction-oriented workflow without claiming
unattended long-term or occlusion tracking.

Keep the implementation MATLAB-local. Project policy now forbids incidental
third-party runtimes, Python environments, model downloads, and first-run
network installation; additional dependencies require an explicit architecture
decision.

#### Changes

- Removed the user-facing Track and Interpolate actions.
- Added automatic forward prediction for adjacent frames and forward jumps.
- Replaced integer block matching with cropped four-level pyramidal KLT,
  forward/backward reliability checks, subpixel coordinates, and a
  constant-velocity fallback for rejected points.
- Added manual/predicted frame provenance and per-point confidence to the
  recoverable project payload while preserving marker CSV coordinates.
- Added reusable portable external-file references to `labkit.ui.runtime` and
  used them for both Video Marker projects and video-adjacent autosaves.
- Added a reusable field-labeled manual relinking fallback for malformed or
  unresolved references; app imports retain file-format validation ownership.
- Project and autosave payloads now prefer a path relative to the MAT file,
  fall back to the original path or same-folder filename, and offer video
  relinking when no automatic candidate exists.
- Made manual edits immutable anchors that reset subsequent prediction; only
  predicted drafts may be refreshed by the tracker.
- Added the repository runtime-dependency boundary to the root constitution,
  app rules, and human architecture documentation.

#### User and data impact

After users mark a complete frame, moving forward presents editable predicted
points automatically. Correcting those points establishes a fresh anchor.
Older projects are upgraded in memory with provenance defaults; marker and
coordinate CSV formats are unchanged. Project/video directory trees can move
between users, cloud-drive roots, and operating systems without editing paths.

#### Compatibility and migration

Existing Video Marker projects and autosaves remain readable. New project
payloads contain additive provenance and confidence fields. Systems without
the MATLAB KLT implementation retain coordinates through the motion fallback
and remain manually editable; no third-party installation is attempted.

#### Validation

Synthetic tests cover subpixel translated-texture tracking, provenance upgrade,
and marker CSV round trips. Hidden GUI tests cover automatic prediction on
forward navigation and the absence of manual assist buttons. Local untracked
evaluation used adjacent frames from a representative video across marker,
eye, ear, nose, and toe textures; repository fixtures contain no real sample
paths or pixels.

#### Evidence

The carrying commit is located by Change ID
`LK-20260714-video-marker-predictive-navigation`.

#### Known limitations and follow-up

KLT is a short-range tracker. Low-texture, occluded, or strongly deforming
points can be rejected and require human correction; that correction is the
next anchor rather than an error state.

### Video Marker visual skeleton setup and continuous marking

```labkit-change
schema: 1
id: LK-20260714-video-marker-continuous-marking
date: 2026-07-14
type: feat
compatibility: compatible
component: `labkit.ui` | `5.1.0 -> 5.1.1`
component: `labkit_VideoMarker_app` | `1.0.1 -> 1.1.0`
```

#### Context

Video Marker required comma-separated keypoint names, manually encoded edge
text, a start/finish edit toggle, and a separate confirm action. Those controls
made skeleton setup error-prone and added modes that did not match the direct
click-and-drag interaction already supported by the point editor.

#### Decision and rationale

Make skeleton definition the first explicit step, represent keypoints and
connections as structured controls, and keep point editing active for the
whole video session. Frame navigation is the save boundary; complete frames
confirm automatically and inherited frames remain drafts until edited.

#### Changes

- Replaced long skeleton strings with an editable ordered-keypoint table,
  mutually filtered connection endpoint selectors, and add/remove/reorder actions.
- Added editable skeleton presets led by the legacy iliac-to-foot five-point
  leg chain, while keeping blank custom construction available.
- Added a connect-in-order shortcut that fills all adjacent point connections
  without removing other user-defined edges.
- Added the domain-neutral `labkit.ui.control.setItems` API for dynamically
  updating selectable control choices without firing app callbacks.
- Added `labkit.ui.plot.replaceOverlay` so image apps can replace one named
  overlay layer without clearing peer graphics, view limits, or callbacks.
- Added hidden-test-safe `labkit.ui.runtime.confirm` for app-owned two-choice
  recovery and confirmation workflows.
- Removed start/finish and confirm controls; blank clicks add points in order,
  dragging refines them, and frame changes save and inherit coordinates.
- Made point edits refresh only the skeleton overlay so zoom, wheel handling,
  and the active continuous-marking session survive each placed point.
- Preserved the current X/Y viewport across frame navigation so users can mark
  the same zoomed ROI through consecutive frames.
- Added draft-only marking assists for temporal interpolation between nearest
  confirmed frames and lightweight local block matching from the immediately
  previous confirmed frame.
- Added atomic change-driven project-compatible autosave in a visible subfolder
  beside the source video, plus matching-video restore/start-new choices.
- Added a new-setup action that explicitly clears the current session before a
  different skeleton is declared.

#### User and data impact

Skeleton setup is visible and validated before video loading. Existing marker
CSV, coordinate CSV, and project MAT schemas remain unchanged. Point order is
still the coordinate-column identity contract.

#### Compatibility and migration

Existing marker CSV and project files remain readable. The workflow changes
are UI-only; users no longer press Apply skeleton, Start point edit, or Confirm
frame. Video Marker now requires `labkit.ui >=5.1.1 <6`.

#### Validation

Unit tests cover skeleton presets, edits, and edge remapping. Hidden GUI workflow tests
cover preset application, table-based setup, mutually filtered connection choices, automatic editor
activation, consecutive point placement with preserved zoom/scroll callbacks,
complete-frame confirmation, frame inheritance, and draft-state
preservation. UI framework tests cover dynamic selectable items.

#### Evidence

The carrying commit is located by Change ID
`LK-20260714-video-marker-continuous-marking`.

#### Known limitations and follow-up

Automated hidden-GUI tests verify callbacks and state transitions but cannot
judge visual density or pointer ergonomics; those still need a short manual
review with a representative video.

### Video Marker startup validation

```labkit-change
schema: 1
id: LK-20260714-video-marker-startup-fix
date: 2026-07-14
type: fix
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.0.0 -> 1.0.1`
scope: `tests/shared/guiTestHelpers.m`
```

#### Context

Video Marker declared its preview axes as `video` but reset an empty preview
through the nonexistent `raw` axes id. The runtime correctly converted that
deferred startup exception into a visible failure status, but the structural
GUI test continued because it checked controls before asserting that startup
had completed successfully.

#### Decision and rationale

Use the declared `video` axes id in the app and make the shared standard
workbench assertion wait for the startup lifecycle. A startup failure now
fails the GUI test with the runtime diagnostic instead of leaving the test
green after only verifying that the shell was constructed.

#### Changes

- Corrected the empty-preview reset to target `videoAxes/video`.
- Added a shared startup-success assertion to standard workbench GUI checks.
- Added a synthetic regression proving deferred startup failures are rejected.

#### User and data impact

Video Marker opens normally before a video is selected. This change does not
alter marker projects, coordinate exports, annotations, or measurement data.

#### Compatibility and migration

The fix is compatible with existing Video Marker projects and exported files.
No user migration is required.

#### Validation

The Video Marker hidden GUI test covers the corrected initial preview path.
The reusable declarative UI GUI test covers startup-failure detection in the
shared helper. Final changed-file and GUI validation are recorded in the
carrying commit and CI run.

#### Evidence

The carrying commit is located by Change ID
`LK-20260714-video-marker-startup-fix`.

#### Known limitations and follow-up

Automated startup checks validate lifecycle completion and diagnostics; they
do not replace manual review of video rendering or point-drag interaction.

### Gait Analysis app

```labkit-change
schema: 1
id: LK-20260714-gait-analysis-app
date: 2026-07-14
type: feat
compatibility: additive
introduced: `labkit_GaitAnalysis_app` | `1.0.0`
```

#### Context

Existing gait work used a script chain after pose tracking: import coordinates,
smooth marker traces, make per-step figures, compute step and joint metrics,
select useful steps, and export tables for downstream statistics. That work
belongs in its own app family because the downstream task is not image
annotation, signal import, or electrochemistry; it is gait-specific pose
analysis from already tracked coordinates.

#### Decision and rationale

Add an independent Gait Analysis app instead of extending Video Marker or
recreating a model-training workflow. The app accepts several coordinate-table
shapes, keeps gait event detection and metric definitions app-local, and
exports simple CSV tables that can be consumed by plotting or statistical
programs.

#### Changes

- Added `labkit_GaitAnalysis_app` under the new Gait family.
- Added CSV/TSV/TXT and MAT pose-coordinate import, including generic
  `point_x`/`point_y` and LabKit `point__x`/`point__y` column shapes.
- Added smoothing, foot-relative step-event detection, hip/knee/ankle angle
  calculation, segment lengths, per-step translations, stride length, step
  time, ROM, summary metrics, and trajectory/angle/step-event previews.
- Added CSV set export for frame metrics, step metrics, summary metrics, and
  per-frame coordinates that keep raw pixel columns alongside optional
  scale-calibrated and first-frame-origin-shifted columns.

#### User and data impact

Users can analyze gait from multiple pose-coordinate sources without tying the
workflow to a specific tracking model. The exported tables are plain CSV and
separate frame-level, coordinate, step-level, and summary data for downstream
overlay, plotting, or statistics.

#### Compatibility and migration

The app is additive and does not change Video Marker, image measurement apps,
public `+labkit` facades, or existing exports. Existing script outputs can be
imported when they provide wide coordinate columns or MAT `coords` and
`pointNames`.

#### Validation

`GaitAnalysisTest` covers coordinate import, synthetic step detection, metric
tables, MAT import, coordinate export calibration/origin semantics, coordinate
CSV readback, and CSV set export. `GuiLayoutGaitAnalysisTest` covers the hidden
GUI launch and semantic control contract. Final branch validation is recorded
in the carrying PR.

#### Evidence

The carrying commit is located by Change ID `LK-20260714-gait-analysis-app`.

#### Known limitations and follow-up

The first version analyzes one tracked subject at a time and does not perform
tracking, model training, group-level statistics, EMG/CAP synchronization,
multi-limb phase analysis, or automatic step quality classification.

### Video Marker app

```labkit-change
schema: 1
id: LK-20260713-video-marker-app
date: 2026-07-13
type: feat
compatibility: additive
introduced: `labkit_VideoMarker_app` | `1.0.0`
```

#### Context

Image measurement workflows needed a generic video annotation tool for ordered
2D keypoints and skeleton connections. The app belongs with image measurement
tools because it uses the same axes interaction, scale calibration, and export
style, but the source media and frame navigation are video-specific.

#### Decision and rationale

Add a standalone Video Marker app instead of extending an existing image-only
app or adding a public video facade. The first version keeps marker semantics
app-local, uses existing UI interaction tools for ordered points and scale
calibration, and avoids training, inference, multi-subject tracking, or
per-point missing-state semantics.

#### Changes

- Added `labkit_VideoMarker_app` under Image Measurement with video loading,
  indexed frame navigation, ordered keypoint placement, skeleton overlays, and
  previous-confirmed-frame inheritance as draft annotations.
- Added a self-describing marker CSV that stores pixel coordinates for every
  frame and can be imported back into the app for overlay or editing.
- Added a separate coordinate CSV export for continuous confirmed frame ranges,
  with selectable pixel or calibrated units, top-left or first-point origin,
  and up/down Y-axis convention.
- Added project MAT save/load and debug sample-pack coverage for synthetic
  video marker assets.

#### User and data impact

Users can manually annotate video frames without depending on a model-training
workflow. Marker CSV remains the editable round-trip format; coordinate CSV is
plain plotting data and does not mutate the saved marker annotations.

#### Compatibility and migration

The app is additive and does not change existing image measurement apps or
public LabKit facades. No existing project files or exports require migration.

#### Validation

`VideoMarkerTest` covers skeleton parsing, frame inheritance, marker CSV
round trip, coordinate transforms, and project save/load. `GuiLayoutVideoMarkerTest`
covers the hidden GUI launch and semantic control contract. Final branch
validation is recorded in the carrying PR.

#### Evidence

The carrying commit is located by Change ID `LK-20260713-video-marker-app`.

#### Known limitations and follow-up

The first version is manual and single-subject. It intentionally does not
perform automatic interpolation, optical flow, model inference, multi-camera
synchronization, 3D annotation, or per-point missing/out-of-frame labeling.

### Launcher app version history

```labkit-change
schema: 1
id: LK-20260713-launcher-app-version-history
date: 2026-07-13
type: feat
compatibility: additive
component: `labkit_launcher` | `1.3.0 -> 1.4.0`
```

#### Context

The structured changelog could be parsed by maintainers, but launcher users
could not inspect the history of the selected app. Earlier normalization also
attached broad release descriptions without recording every app version event,
which made histories such as CIC appear to begin years of versions too late.

#### Decision and rationale

Expose component-filtered history in the launcher and make exact component
events the durable lookup key. A user should be able to move from the current
app catalog directly to its evolution record without reading Git history or
understanding changelog internals.

#### Changes

- Added `labkit_launcher("history", appCommand)` for programmatic history
  lookup and a Version History viewer for the selected launcher app.
- Added explicit component introduction events and reconstructed every tracked
  launcher, facade, and app version transition from `origin/main` history.
- Added continuous-history validation so missing introductions, gaps, and
  current-version mismatches fail the release guardrail.

#### User and data impact

Launcher users can inspect dated version transitions, compatibility, rationale,
impact, and evidence for the selected app. App calculations and user data are
unchanged.

#### Compatibility and migration

The launcher command and button are additive. Existing list, version, package,
maintenance, and app-launch workflows remain available.

#### Validation

`LauncherGuiTest` covers programmatic filtering and the hidden GUI viewer;
`ChangelogGuardrailTest` validates complete version chains against current
metadata.

#### Evidence

The carrying commit is located by Change ID
`LK-20260713-launcher-app-version-history`; historical component events were
reconstructed from version-file changes on `origin/main`.

#### Known limitations and follow-up

History begins when version metadata was first tracked for each component.
Behavior before that point can only be inferred from older source commits and
is not assigned invented version numbers.

### Structured evolution records

```labkit-change
schema: 1
id: LK-20260713-structured-evolution-records
date: 2026-07-13
type: docs
compatibility: additive
scope: repository changelog and release governance
```

#### Context

The previous `Unreleased` and `Pending` model mixed delivery state with
historical meaning and required records to be moved after merge. Its prose was
useful to humans but had no reliable machine contract.

#### Decision and rationale

Use stable, status-free records with a small parseable metadata header and
required explanatory sections. Git branches, PRs, tags, and evidence identify
delivery state without duplicating it in the changelog.

#### Changes

- Added schema-v1 metadata for Change ID, date, type, compatibility, component
  introductions and version transitions, and unversioned repository scopes.
- Added a base-MATLAB parser and release guardrail for schema integrity.
- Normalized every historical entry into the same schema-v1 record contract.

#### User and data impact

Users and maintainers can search one durable ID and obtain the reason, impact,
compatibility, validation, and evidence for a change without reconstructing it
from commit messages. No scientific data or runtime behavior changes.

#### Compatibility and migration

Existing links to `CHANGELOG.md` remain valid. Automation that searched the old
`Unreleased` or `Version History` headings must use the parser and stable
Change IDs.

#### Validation

`ChangelogGuardrailTest` parses every schema-v1 record and checks current
version lookup coverage and release-policy documentation.

#### Evidence

The parser lives at `tools/release/parseLabKitChangelog.m`; the normalized
historical baseline was checked against the dated mainline log and release tags.

#### Known limitations and follow-up

Some older records do not name exact test commands because that evidence was
not recorded at the time; they state that limitation instead of inventing it.

### Single-click DIC rigid point matching

```labkit-change
schema: 1
id: LK-20260713-dic-rigid-point-editor
date: 2026-07-13
type: feat
compatibility: additive
component: `labkit.ui` | `5.0.4 -> 5.1.0`
component: `labkit_DICPreprocess_app` | `1.3.6 -> 1.4.0`
```

#### Context

DIC manual rigid matching had draggable points but maintained a separate
pointer implementation and required a less consistent placement workflow than
the ROI-center anchors used by Imager Reconstruction.

#### Decision and rationale

Extend the existing app-neutral anchor editor with a discrete point mode, then
keep moving/fixed pair order, numbering, minimum pair count, and rigid-fit
policy inside DIC.

#### Changes

- Added `mode="points"`: one blank click appends a point, dragging refines it,
  no connecting curve is drawn, and deletion remains under explicit controls.
- Migrated the DIC modal to two shared point-mode editors while preserving
  ordered moving/fixed pairs, labels, undo, cancel, and acceptance rules.
- Retained toolbox-free image display and rigid alignment behavior.

#### User and data impact

Feature placement now follows the same direct click-and-drag model as Imager
ROI anchors. Point coordinates and the resulting rigid transform keep their
existing N-by-2 pixel-coordinate contract.

#### Compatibility and migration

The default anchor-editor curve mode is unchanged. DIC exports and transform
math are unchanged; this is an additive interaction improvement.

#### Validation

UI anchor-editor tests cover discrete point append and no-path behavior. The
DIC GUI workflow covers toolbox-free modal cancellation and app launch wiring.

#### Evidence

Primary sources are `labkit.ui.interaction.anchorEditor` and
`dic_preprocess.userInterface.selectRigidPointPairs`; branch checkpoint
`392a073e` carries the implementation before the final squash merge.

#### Known limitations and follow-up

Automated hidden-GUI tests cannot judge pointing ergonomics; final interaction
feel still requires a short manual placement-and-drag check.

### MATLAB-compatible image conversion API

```labkit-change
schema: 1
id: LK-20260713-matlab-compatible-image-conversion
date: 2026-07-13
type: refactor
compatibility: breaking
component: `labkit.image` | `1.2.0 -> 2.0.0`
component: `labkit_DICPostprocess_app` | `1.3.5 -> 1.3.6`
component: `labkit_BatchImageCrop_app` | `1.6.7 -> 1.6.8`
component: `labkit_CurvatureMeasurement_app` | `1.3.4 -> 1.3.5`
component: `labkit_FocusStack_app` | `1.4.8 -> 1.4.9`
component: `labkit_ImageEnhance_app` | `1.5.7 -> 1.5.8`
component: `labkit_ImageMatch_app` | `1.5.7 -> 1.5.8`
```

#### Context

The `toDouble`, `toLuma`, and `toRgbDouble` names combined class conversion,
channel shaping, and clipping in ways that differed from familiar MATLAB APIs.

#### Decision and rationale

Use MATLAB-compatible names and call contracts for replacement functions, and
keep orthogonal RGB shaping explicit so users do not need to learn a composite
LabKit normalization rule.

#### Changes

- Added base-MATLAB `labkit.image.im2double` and `labkit.image.rgb2gray`.
- Kept channel shaping in `ensureRgb` and made clipping explicit at call sites.
- Removed the ambiguous conversion helpers and centralized Rec.601 ownership.

#### User and data impact

Base-MATLAB users receive familiar image conversion behavior without hidden
toolbox requirements. Existing app image results retain their intended ranges
and channel shapes through explicit pipelines.

#### Compatibility and migration

This is a breaking facade rename. External callers replace removed helper names
with `im2double`, `rgb2gray`, and `ensureRgb` as separately needed.

#### Validation

Image facade, downstream app, toolbox-shadow, and base-MATLAB ownership tests
cover class conversion, luma values, and representative workflows.

#### Evidence

The API contracts are documented in `docs/image.md`; branch checkpoint
`e3f71c2d` carries the migration before the final squash merge.

#### Known limitations and follow-up

The compatibility layer intentionally covers the LabKit-used MATLAB contracts,
not every Image Processing Toolbox function.

### Traceable FLIR temperature calibration

```labkit-change
schema: 1
id: LK-20260713-flir-calibration-provenance
date: 2026-07-13
type: feat
compatibility: additive
component: `labkit.thermal` | `1.0.0 -> 1.1.0`
component: `labkit_FLIRThermal_app` | `1.2.8 -> 1.3.0`
```

#### Context

A successful Celsius conversion did not reveal whether emissivity and
environmental values came from the file or from model defaults, which could
make an absolute temperature appear more certain than its metadata justified.

#### Decision and rationale

Preserve conversion provenance with the thermal record and show fallback use
in the app, rather than silently treating every parameter as measured.

#### Changes

- Added optional conversion diagnostics with correction mode, defaulted fields,
  parameter sources, and fallback status.
- Stored diagnostics in thermal record metadata and surfaced warnings in FLIR
  file status and details.
- Documented embedded calibration requirements and environmental fallbacks.

#### User and data impact

Users can distinguish radiometric values based entirely on embedded metadata
from values affected by fallback assumptions before interpreting temperatures.

#### Compatibility and migration

Existing one-output conversion calls remain valid. The diagnostics output and
record metadata are additive; app workflows need no migration.

#### Validation

Thermal facade and FLIR app tests cover metadata sources, fallback reporting,
and one-output compatibility.

#### Evidence

The model and provenance contract are documented in `docs/thermal.md`; branch
checkpoint `7391e293` carries the implementation before the final squash merge.

#### Known limitations and follow-up

Diagnostics describe source and fallback use; they do not estimate a physical
uncertainty interval for a particular camera, surface, or environment.

### Consistent electrochemistry batch analysis

```labkit-change
schema: 1
id: LK-20260713-electrochem-batch-consistency
date: 2026-07-13
type: fix
compatibility: additive
component: `labkit_CIC_app` | `1.3.7 -> 1.3.8`
component: `labkit_VTResistance_app` | `1.3.7 -> 1.3.8`
```

#### Context

CIC and VT Resistance could retain per-file derived values from different
control settings, and CIC could sample outside the recorded time range while
displaying a delay without units.

#### Decision and rationale

Treat analysis controls as one batch contract and recompute every file before
display/export so rows cannot silently mix stale and current parameters.

#### Changes

- Recompute all loaded files when shared controls change and once more before
  CSV export.
- Label CIC delay in microseconds, reject out-of-range sampling, and export the
  area and delay used for each result.
- Added family regression coverage and audited sibling electrochem apps.

#### User and data impact

Batch rows now represent one consistent area, delay, pulse-detection,
resistance-window, and voltage-mode configuration. Invalid delay choices fail
instead of extrapolating a misleading value.

#### Compatibility and migration

CIC CSV adds trailing `Area_cm2` and `Delay_us` columns. Existing columns keep
their names and order; VT Resistance exports remain schema-compatible.

#### Validation

Electrochem unit and GUI tests cover batch recomputation, display units,
out-of-range handling, and export-time refresh.

#### Evidence

The guarded calculations and export builders are app-owned; branch checkpoint
`67ea2286` carries the fix before the final squash merge.

#### Known limitations and follow-up

The fix enforces internal batch consistency but does not choose scientifically
appropriate area, delay, or resistance windows for the user.

### Managed scientific and conversion constants

```labkit-change
schema: 1
id: LK-20260713-managed-calculation-constants
date: 2026-07-13
type: refactor
compatibility: compatible
component: `labkit.dta` | `2.0.0 -> 2.0.1`
component: `labkit.rhs` | `1.0.0 -> 1.0.1`
component: `labkit.biosignal` | `1.0.0 -> 1.0.1`
component: `labkit_ChronoOverlay_app` | `1.3.5 -> 1.3.6`
component: `labkit_CSC_app` | `1.3.9 -> 1.3.10`
component: `labkit_NerveResponseAnalysis_app` | `1.3.4 -> 1.3.5`
component: `labkit_ResponseReviewStats_app` | `1.3.4 -> 1.3.5`
```

#### Context

Scientific coefficients, device-format gains, unit conversions, and numeric
tolerances were sometimes left as unexplained literals or repeated across
callers, making origin and change impact difficult to audit.

#### Decision and rationale

Give each semantic calculation constant one named owner and a nearby source or
purpose comment, while exempting ordinary indices and explicit UI geometry
that do not encode scientific meaning.

#### Changes

- Named and documented Rec.601, sRGB/CIE, DTA/RHS gains, SI conversions,
  tolerances, and empirical policies across facades and apps.
- Centralized repeated CSC charge-density, CIC display-unit, and curvature
  tolerance contracts.
- Added repository-wide magic-number and rectangle-interaction guardrails.

#### User and data impact

Calculation results are preserved, but future changes now expose the constant's
meaning and provenance instead of silently editing an unexplained literal.

#### Compatibility and migration

No user migration is required. Public function call contracts and output
schemas are unchanged by this record.

#### Validation

`MagicNumberGovernanceTest`, rectangle governance, facade tests, and affected
app tests cover centralized ownership and preserved numeric behavior.

#### Evidence

Source comments use the `Constant:` marker and guardrail diagnostics name the
unmanaged file and line. Branch checkpoint `125338c0` carries the governance
work before the final squash merge.

#### Known limitations and follow-up

The scanner targets semantically suspicious precision and notation; review is
still required for simple integers or short decimals whose meaning is hidden.

### Traceable and base-MATLAB CI validation

```labkit-change
schema: 1
id: LK-20260713-traceable-base-matlab-ci
date: 2026-07-13
type: ci
compatibility: compatible
scope: GitHub Actions and MATLAB validation routing
```

#### Context

CI failures and stalls could end without enough information to identify the
active test, and ordinary success on a toolbox-rich development machine did
not prove that base-MATLAB users could run representative workflows.

#### Decision and rationale

Make the existing official runner publish progress and active-test state, and
add a distinct compatibility gate that combines static calls, product
ownership, and toolbox-shadowed behavior.

#### Changes

- Added per-test progress, heartbeat, active-test, timeout-summary, and artifact
  publication behavior to CI.
- Added `buildtool baseMatlab` and representative toolbox-shadow workflows.
- Improved changed-file routing to target direct consumers while retaining
  explicit owners such as the launcher GUI suite.
- Corrected result aggregation so assumption-filtered tests remain visible as
  skipped without being misreported as shard failures.

#### User and data impact

Base-MATLAB compatibility is now an explicit supported path, and failed or
stalled CI runs provide enough state to identify the last active test. Runtime
scientific outputs are not changed by this record.

#### Compatibility and migration

Existing build tasks remain available. Maintainers can add `baseMatlab` to
local validation without installing or uninstalling toolboxes.

#### Validation

CI policy, build-task framework, changed-routing, toolbox dependency, and
representative workflow tests guard the new behavior.

#### Evidence

The command matrix is in `docs/testing.md`; CI uploads official runner logs and
active-test artifacts. Branch checkpoints `28ff8edb`, `37bd7fd5`, and
`2c9b8792` carry the implementation before the final squash merge.

#### Known limitations and follow-up

Shadow tests cover known dependency risks and cannot simulate every licensed
toolbox combination; MATLAB product-ownership analysis remains the broad check.

### Base-MATLAB image compatibility

```labkit-change
schema: 1
id: LK-20260713-base-matlab-image-compatibility
date: 2026-07-13
type: feat
compatibility: compatible
component: `labkit.image` | `1.1.0 -> 1.2.0`
component: `labkit_DICPostprocess_app` | `1.3.4 -> 1.3.5`
component: `labkit_DICPreprocess_app` | `1.3.5 -> 1.3.6`
component: `labkit_FocusStack_app` | `1.4.7 -> 1.4.8`
component: `labkit_ImageEnhance_app` | `1.5.6 -> 1.5.7`
component: `labkit_ImageMatch_app` | `1.5.6 -> 1.5.7`
```

#### Context

- CI now protects the base-MATLAB user path instead of passing only on
  machines that happen to have Image Processing Toolbox installed.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.image` `1.1.0 -> 1.2.0`
- `labkit_DICPreprocess_app` `1.3.5 -> 1.3.6`
- `labkit_DICPostprocess_app` `1.3.4 -> 1.3.5`
- `labkit_FocusStack_app` `1.4.7 -> 1.4.8`
- `labkit_ImageEnhance_app` `1.5.6 -> 1.5.7`
- `labkit_ImageMatch_app` `1.5.6 -> 1.5.7`

- Added `labkit.image.toDouble` and `labkit.image.toLuma`, and replaced hard
  Image Processing Toolbox calls in shared image facade code and image-app
  workflow paths with base-MATLAB implementations.
- DIC preprocessing now uses a toolbox-free phase-correlation translation
  path for automatic alignment and a base-MATLAB rigid warp for control-point
  alignment.
- DIC postprocessing, Focus Stack, Image Enhance, and Image Match now use
  app-local or facade-owned image normalization, resizing, smoothing, and luma
  helpers instead of requiring toolbox functions.
- Added a project hygiene guardrail that rejects unguarded toolbox image
  helper calls under `apps/` and `+labkit/`, while still allowing explicit
  optional toolbox paths with fallbacks.

#### User and data impact

- CI now protects the base-MATLAB user path instead of passing only on
  machines that happen to have Image Processing Toolbox installed.

#### Compatibility and migration

- Existing app workflows and exported schemas are preserved. Optional toolbox
  acceleration paths remain allowed only when a base-MATLAB fallback is present.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Mainline commit `bcd5f51f`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Preview-area per-axis wheel zoom

```labkit-change
schema: 1
id: LK-20260709-preview-area-per-axis-wheel-zoom
date: 2026-07-09
type: feat
compatibility: compatible
component: `labkit.ui` | `5.0.3 -> 5.0.4`
```

#### Context

- App-owned side panels such as color scales and histograms can remain compact
  and stable without disabling useful wheel interaction.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `5.0.3 -> 5.0.4`

- Added a `scrollZoomAxes` preview-area layout option so apps can declare
  whether each preview axis should mouse-wheel zoom in `xy`, `x`, or `y`.
- Preview-area side axes can now remain horizontally stable while still
  allowing app-selected vertical wheel zoom.

#### User and data impact

- App-owned side panels such as color scales and histograms can remain compact
  and stable without disabling useful wheel interaction.

#### Compatibility and migration

- Existing preview areas keep default `xy` wheel zoom unless they opt into
  another per-axis setting.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Mainline commit `3c143eb`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Default LabKit close protection

```labkit-change
schema: 1
id: LK-20260709-default-labkit-close-protection
date: 2026-07-09
type: fix
compatibility: compatible
component: `labkit.ui` | `5.0.2 -> 5.0.3`
component: `labkit_FocusStack_app` | `1.4.6 -> 1.4.7`
component: `labkit_ImageEnhance_app` | `1.5.5 -> 1.5.6`
component: `labkit_ImageMatch_app` | `1.5.5 -> 1.5.6`
```

#### Context

- Public and private apps get a baseline close-safety prompt from the framework,
  without app-owned dirty-state close logic.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `5.0.2 -> 5.0.3`
- `labkit_FocusStack_app` `1.4.6 -> 1.4.7`
- `labkit_ImageEnhance_app` `1.5.5 -> 1.5.6`
- `labkit_ImageMatch_app` `1.5.5 -> 1.5.6`

- LabKit runtime figures now show an in-window confirmation prompt before any
  framework-owned app window closes, even when the app has not marked itself
  dirty.
- Removed the app-facing `labkit.ui.runtime.setCloseGuard` API and migrated
  existing app close-guard dirty checks to the framework default behavior.
- Repeating or holding the app close shortcut while the in-window prompt is
  active confirms the close.

#### User and data impact

- Public and private apps get a baseline close-safety prompt from the framework,
  without app-owned dirty-state close logic.

#### Compatibility and migration

- Closing LabKit apps now requires one confirmation step by default. App code
  that calls `labkit.ui.runtime.setCloseGuard` must remove that call; close
  confirmation is framework-owned.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Mainline commit `0c9f472`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Multi-app launcher packages

```labkit-change
schema: 1
id: LK-20260709-multi-app-launcher-packages
date: 2026-07-09
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.2.7 -> 1.3.0`
```

#### Context

- Related LabKit apps can be distributed together without shipping unrelated
  apps or manually combining separate packages.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.2.7 -> 1.3.0`
- Project deployment tooling, multi-app bundle support.

- Added an independent `Package` checkbox column to the launcher app table so
  users can choose multiple apps without changing the row selected for Open or
  Debug.
- `Package Checked` and `Checked P-code` now create one zip containing every
  checked app, one direct entry file per app, and a multi-app manifest.
- Kept single-app package names, result fields, and manifest schema compatible
  when only one app is supplied to `packageLabKitApp`.

#### User and data impact

- Related LabKit apps can be distributed together without shipping unrelated
  apps or manually combining separate packages.

#### Compatibility and migration

- Existing direct calls that package one app continue to produce the original
  single-app package contract.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Mainline commit `8a23a52`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Runtime-only P-code app packages

```labkit-change
schema: 1
id: LK-20260708-runtime-only-p-code-app-packages
date: 2026-07-08
type: refactor
compatibility: compatible
scope: historical project evolution
```

#### Context

- P-code distributions no longer expose or depend on launcher behavior that is
  source-checkout oriented, including launcher version/date metadata and
  follow-on packaging actions.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Project deployment tooling, no component version change.

- `Package P-code` now creates a runtime-only single-app package instead of
  shipping a P-coded LabKit launcher and launcher maintenance tools.
- P-code package manifests and README instructions point users to the direct
  `run_<app_command>` entry file.
- P-code packaging no longer requires `labkit_launcher.m` or `labkit_launcher.p`
  to exist in the package root being used as the runtime source.

#### User and data impact

- P-code distributions no longer expose or depend on launcher behavior that is
  source-checkout oriented, including launcher version/date metadata and
  follow-on packaging actions.

#### Compatibility and migration

- Users of P-code packages should run `run_<app_command>` from the unzipped
  package instead of `labkit_launcher`. Source packages still include and
  support the launcher.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Mainline commit `75f63f1`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Release validation gate and GUI CI hardening

```labkit-change
schema: 1
id: LK-20260708-release-validation-gate-and-gui-ci-hardening
date: 2026-07-08
type: ci
compatibility: compatible
scope: historical project evolution
```

#### Context

- Maintainers get a concrete pre-publication release signal that covers all
  supported automated test projects, and GUI CI should fail on contract drift
  rather than platform layout rounding.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Project validation workflow, no component version change.

- Release candidate tags now run the full MATLAB test workflow gate before
  publication: headless tests, coverage, GUI tests, and a release summary gate.
- GUI layout tests now assert structural grid contracts instead of
  platform-dependent flattened pixel ordering or width comparisons.
- Shared GUI test idle waiting allows slower CI display backends more time to
  finish registered UI work.

#### User and data impact

- Maintainers get a concrete pre-publication release signal that covers all
  supported automated test projects, and GUI CI should fail on contract drift
  rather than platform layout rounding.

#### Compatibility and migration

- No known manual migration.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Mainline commit `f359518`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Debug workflows, launcher tools, and changelog governance

```labkit-change
schema: 1
id: LK-20260707-debug-workflows-launcher-tools-and-changelog-governance
date: 2026-07-07
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.2.4 -> 1.2.5`
component: `labkit_launcher` | `1.2.5 -> 1.2.6`
component: `labkit_launcher` | `1.2.6 -> 1.2.7`
component: `labkit.ui` | `5.0.0 -> 5.0.1`
component: `labkit.ui` | `5.0.1 -> 5.0.2`
component: `labkit_DICPreprocess_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.6.6 -> 1.6.7`
component: `labkit_FocusStack_app` | `1.4.5 -> 1.4.6`
component: `labkit_FigureStudio_app` | `0.1.4 -> 0.1.5`
```

#### Context

- The debug sample workflows can be exercised without false crash reports or
  disabled-looking app paths when the required user action is folder loading,
  ROI anchor completion, or crop-center confirmation.
- Code Analyzer cleanup can be reviewed from an interactive local HTML report
  without making the launcher own a growing maintenance workflow.
- A single lab workflow can be distributed into a fixed production or offline
  deployment step without shipping unrelated apps, tests, docs, or repository
  metadata.
- Developers can keep private LabKit apps next to a public checkout, use the
  ordinary launcher to open them, and push that workspace to a separate private
  repository.
- Maintainers and agents can understand project direction from the changelog
  without reconstructing intent from raw git history.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Release tag `v3.1.0`
- `labkit_launcher` `1.2.4 -> 1.2.7`
- `labkit.ui` `5.0.1 -> 5.0.2`
- `labkit_FigureStudio_app` `0.1.4 -> 0.1.5`
- `labkit_DICPreprocess_app` `1.3.4 -> 1.3.5`
- `labkit_BatchImageCrop_app` `1.6.6 -> 1.6.7`
- `labkit_FocusStack_app` `1.4.5 -> 1.4.6`

- DIC Preprocess ROI mask export now reads the live ROI editor anchors when
  building a mask, so preview/save do not misreport a drawn ROI as empty when
  editor state is newer than the app state snapshot.
- DIC Preprocess keeps the double-click ROI anchor workflow and makes the
  double-click requirement explicit in the visible details text.
- Batch Image Crop duplicate tasks now redraw with finite preview overlay
  coordinates while still requiring users to confirm the duplicated crop
  center before export.
- Figure Studio quick PNG/JPG/SVG export actions use runtime-compatible
  handler signatures.
- Focus Stack exposes a direct `Choose folder` action for loading all supported
  images from a focus-stack folder.
- Debug trace diagnostics no longer write stalled-callback crash reports while
  a file chooser modal is active.
- Moved the launcher Code Analyzer scan into `tools/codecheck`, which writes
  timestamped JSON/HTML report pairs under `artifacts/code-check/` without
  overwriting earlier runs.
- Added launcher actions and a deployment tool that package one selected LabKit
  app into a standalone zip, either as source `.m` files or encoded `.p` files.
- Added launcher discovery for local private app workspaces under
  `private_apps/apps/` and roots named by `LABKIT_PRIVATE_APP_ROOTS`.
- Clarified the public changelog model as a project evolution map organized by
  reader-facing evolution entries, with release tags and commits kept as
  anchors and evidence rather than the primary structure.

#### User and data impact

- The debug sample workflows can be exercised without false crash reports or
  disabled-looking app paths when the required user action is folder loading,
  ROI anchor completion, or crop-center confirmation.
- Code Analyzer cleanup can be reviewed from an interactive local HTML report
  without making the launcher own a growing maintenance workflow.
- A single lab workflow can be distributed into a fixed production or offline
  deployment step without shipping unrelated apps, tests, docs, or repository
  metadata.
- Developers can keep private LabKit apps next to a public checkout, use the
  ordinary launcher to open them, and push that workspace to a separate private
  repository.
- Maintainers and agents can understand project direction from the changelog
  without reconstructing intent from raw git history.

#### Compatibility and migration

- DIC ROI editing still uses double-click to add anchors; no interaction-mode
  migration is required.
- Existing file-panel image selection remains available in Focus Stack.
- Code Analyzer report consumers should read the timestamped
  `artifacts/code-check/matlab_code_issues_*.json` files.
- Full LabKit checkout installs are unchanged. Single-app packages can start
  through either the packaged launcher or the direct run file; P-code packages
  require MATLAB to run the generated `.p` files.
- Public apps, public releases, and public CI remain scoped to `apps/`.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- PR #34 squash merge and release tag `v3.1.0`.

#### Known limitations and follow-up

- Keep debug fixes moving into shared callback and editor contracts when the
  failure pattern is reusable, but keep app-specific workflow decisions in the
  owning app.
- Keep changelog entries organized around evolution themes and release lines,
  not raw tag rows or issue lists.

### UI 5 facade redesign, app migration, and plot refresh

```labkit-change
schema: 1
id: LK-20260706-ui-5-facade-redesign-app-migration-and-plot-refresh
date: 2026-07-06
type: refactor
compatibility: breaking
component: `labkit_launcher` | `1.2.3 -> 1.2.4`
component: `labkit.ui` | `4.2.0 -> 4.2.1`
component: `labkit.ui` | `4.2.1 -> 5.0.0`
component: `labkit_DICPostprocess_app` | `1.3.3 -> 1.3.4`
component: `labkit_DICPreprocess_app` | `1.3.3 -> 1.3.4`
component: `labkit_ChronoOverlay_app` | `1.3.3 -> 1.3.5`
component: `labkit_CIC_app` | `1.3.5 -> 1.3.7`
component: `labkit_CSC_app` | `1.3.7 -> 1.3.9`
component: `labkit_EIS_app` | `1.3.3 -> 1.3.4`
component: `labkit_VTResistance_app` | `1.3.5 -> 1.3.7`
component: `labkit_BatchImageCrop_app` | `1.6.5 -> 1.6.6`
component: `labkit_CurvatureMeasurement_app` | `1.3.3 -> 1.3.4`
component: `labkit_FLIRThermal_app` | `1.2.7 -> 1.2.8`
component: `labkit_FocusStack_app` | `1.4.4 -> 1.4.5`
component: `labkit_ImageEnhance_app` | `1.5.4 -> 1.5.5`
component: `labkit_ImageMatch_app` | `1.5.4 -> 1.5.5`
introduced: `labkit_FigureStudio_app` | `0.1.0`
component: `labkit_FigureStudio_app` | `0.1.0 -> 0.1.1`
component: `labkit_FigureStudio_app` | `0.1.1 -> 0.1.2`
component: `labkit_FigureStudio_app` | `0.1.2 -> 0.1.4`
component: `labkit_NerveResponseAnalysis_app` | `1.3.3 -> 1.3.4`
component: `labkit_ResponseReviewStats_app` | `1.3.3 -> 1.3.4`
component: `labkit_RHSPreview_app` | `1.3.3 -> 1.3.4`
component: `labkit_ECGPrint_app` | `1.3.4 -> 1.3.5`
```

#### Context

- App authors now use a smaller set of responsibility-named UI packages instead
  of learning old mixed app/spec/view/tool/diag buckets.
- Shared plot-area mechanics live in the framework, so app code can focus on
  domain plotting while the framework handles stale axes state, fitted ranges,
  empty previews, coordinate offsets, and registered preview utilities.
- Electrochem apps now match the active file selection after add/remove/clear
  workflows, and CIC keeps the critical Emc/Ema readout visible on dense plots.
- Users can distinguish long launcher work from a frozen MATLAB session.
- Multi-plot apps expose utility actions in a clearer, less repetitive flow.
- Figure cleanup and data/script export move into a dedicated reusable workflow
  instead of crowding every popout plot window.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.2.3 -> 1.2.4`
- `labkit.ui` `4.2.0 -> 5.0.0`
- `labkit_FigureStudio_app` `0.1.0 -> 0.1.4`
- `labkit_ChronoOverlay_app` `1.3.3 -> 1.3.5`
- `labkit_CIC_app` `1.3.5 -> 1.3.7`
- `labkit_CSC_app` `1.3.7 -> 1.3.9`
- `labkit_EIS_app` `1.3.3 -> 1.3.4`
- `labkit_VTResistance_app` `1.3.5 -> 1.3.7`
- `labkit_DICPreprocess_app` `1.3.3 -> 1.3.4`
- `labkit_DICPostprocess_app` `1.3.3 -> 1.3.4`
- `labkit_BatchImageCrop_app` `1.6.5 -> 1.6.6`
- `labkit_CurvatureMeasurement_app` `1.3.3 -> 1.3.4`
- `labkit_FLIRThermal_app` `1.2.7 -> 1.2.8`
- `labkit_FocusStack_app` `1.4.4 -> 1.4.5`
- `labkit_ImageEnhance_app` `1.5.4 -> 1.5.5`
- `labkit_ImageMatch_app` `1.5.4 -> 1.5.5`
- `labkit_RHSPreview_app` `1.3.3 -> 1.3.4`
- `labkit_NerveResponseAnalysis_app` `1.3.3 -> 1.3.4`
- `labkit_ResponseReviewStats_app` `1.3.3 -> 1.3.4`
- `labkit_ECGPrint_app` `1.3.4 -> 1.3.5`

- Reorganized the UI facade into `labkit.ui.runtime`, `layout`, `control`,
  `plot`, `interaction`, and `debug` so app authors can find lifecycle,
  data-only layout, control update, plot-area, pointer/tooling, and diagnostic
  APIs by responsibility.
- Replaced the old app/spec/view/tool/diag UI paths with UI 5 names and moved
  every app to `definition(..., "Layout", @buildWorkbenchLayout)` plus
  `labkit.ui.layout.*`, `labkit.ui.control.*`, `labkit.ui.plot.*`,
  `labkit.ui.interaction.*`, and `labkit.ui.debug.*`.
- Added framework-owned plot helpers for registered axes lookup, clearing,
  empty-state messages, fitted limits, canvas framing, image preview redraw,
  and data/fraction coordinate conversion.
- Reset electrochem plot axes and legends when files are cleared, removed, or
  redrawn so old ranges, markers, shaded windows, and annotations do not remain
  after the file list changes.
- Refit CIC, Chrono Overlay, CSC all-cycle, and VT Resistance redraws to the
  current plotted data instead of preserving stale manual zoom limits.
- Staggered CIC Emc/Ema marker labels with readable white backgrounds so key
  extrema labels are less likely to be hidden by voltage-step or window
  annotations.
- Added visible busy/progress feedback for launcher actions that can wait on
  file scans, artifact cleanup, app startup, profiling, GitHub version lookup,
  or update/install work.
- Added launcher and version-manager busy gates so repeated clicks do not start
  overlapping synchronous operations.
- Replaced top workbench utility buttons with native window utility menus.
- Changed workbench plot popout/copy/save actions to operate on every
  registered preview axes in a multi-axes app.
- Replaced icon-only popout figure tools with visible text buttons for font,
  plotted-line, axes, grid, and Studio handoff controls.
- Added the LabKit Core Figure Studio app for opening MATLAB `.fig` files,
  switching between the measured LabKit single-panel style and the imported
  FIG defaults, tuning font/line/grid parameters, and exporting visible
  graphics data packages with reconstruction scripts.
- Normalized imported FIG axes before applying Studio canvas and style
  constraints so source layout/aspect metadata and file-selection titles cannot
  collapse the preview.
- Centered the managed preview canvas in the app preview grid so styled FIG
  labels and plot content render in the visible canvas instead of the corner
  cell.
- Added a `labkit.ui.plot.fitCanvas` canvas-frame helper so fixed-size preview
  axes use the framework-owned preview grid policy instead of app-owned
  row/column layout code.

#### User and data impact

- App authors now use a smaller set of responsibility-named UI packages instead
  of learning old mixed app/spec/view/tool/diag buckets.
- Shared plot-area mechanics live in the framework, so app code can focus on
  domain plotting while the framework handles stale axes state, fitted ranges,
  empty previews, coordinate offsets, and registered preview utilities.
- Electrochem apps now match the active file selection after add/remove/clear
  workflows, and CIC keeps the critical Emc/Ema readout visible on dense plots.
- Users can distinguish long launcher work from a frozen MATLAB session.
- Multi-plot apps expose utility actions in a clearer, less repetitive flow.
- Figure cleanup and data/script export move into a dedicated reusable workflow
  instead of crowding every popout plot window.

#### Compatibility and migration

- Breaking UI facade migration: app code must use the UI 5 package paths and
  require `labkit.ui >=5 <6`.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main UI 5 squash commit.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### UI utility snapshots and popout tools

```labkit-change
schema: 1
id: LK-20260704-ui-utility-snapshots-and-popout-tools
date: 2026-07-04
type: feat
compatibility: compatible
component: `labkit.ui` | `4.1.0 -> 4.2.0`
```

#### Context

- Users can preserve UI state and move plot outputs out of the GUI with less
  manual work.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `4.1.0 -> 4.2.0`

- Added UI state snapshot save/load APIs.
- Added workbench utility controls.
- Improved axes popout export and copy tools.

#### User and data impact

- Users can preserve UI state and move plot outputs out of the GUI with less
  manual work.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `0155cd12`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### FLIR display tuning

```labkit-change
schema: 1
id: LK-20260703-flir-display-tuning
date: 2026-07-03
type: feat
compatibility: compatible
component: `labkit_CSC_app` | `1.3.6 -> 1.3.7`
component: `labkit_FLIRThermal_app` | `1.2.4 -> 1.2.5`
component: `labkit_FLIRThermal_app` | `1.2.5 -> 1.2.6`
component: `labkit_FLIRThermal_app` | `1.2.6 -> 1.2.7`
```

#### Context

- CSC exports became clearer for downstream analysis, and FLIR display tuning
  no longer requires code edits.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_FLIRThermal_app` `1.2.4 -> 1.2.7`
- `labkit_CSC_app` `1.3.6 -> 1.3.7`

- Refined CSC CV export.
- Added FLIR gamma color mapping and made gamma adjustable.

#### User and data impact

- CSC exports became clearer for downstream analysis, and FLIR display tuning
  no longer requires code edits.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `ee5b8f79`, `65dbf5ae`, and `f076561e`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### CSC export and viewport policy

```labkit-change
schema: 1
id: LK-20260703-csc-export-and-viewport-policy
date: 2026-07-03
type: feat
compatibility: compatible
component: `labkit.ui` | `4.0.0 -> 4.1.0`
component: `labkit_DICPostprocess_app` | `1.3.2 -> 1.3.3`
component: `labkit_DICPreprocess_app` | `1.3.2 -> 1.3.3`
component: `labkit_ChronoOverlay_app` | `1.3.2 -> 1.3.3`
component: `labkit_CIC_app` | `1.3.4 -> 1.3.5`
component: `labkit_CSC_app` | `1.3.4 -> 1.3.6`
component: `labkit_EIS_app` | `1.3.2 -> 1.3.3`
component: `labkit_VTResistance_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.6.4 -> 1.6.5`
component: `labkit_CurvatureMeasurement_app` | `1.3.2 -> 1.3.3`
component: `labkit_FLIRThermal_app` | `1.2.3 -> 1.2.4`
component: `labkit_FocusStack_app` | `1.4.3 -> 1.4.4`
component: `labkit_ImageEnhance_app` | `1.5.3 -> 1.5.4`
component: `labkit_ImageMatch_app` | `1.5.3 -> 1.5.4`
component: `labkit_NerveResponseAnalysis_app` | `1.3.2 -> 1.3.3`
component: `labkit_ResponseReviewStats_app` | `1.3.2 -> 1.3.3`
component: `labkit_RHSPreview_app` | `1.3.2 -> 1.3.3`
component: `labkit_ECGPrint_app` | `1.3.3 -> 1.3.4`
```

#### Context

- Users can export more complete CSC cycle data, and app layouts share the same
  viewport assumptions.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `4.0.0 -> 4.1.0`
- All supported apps received aligned patch bumps.

- Added CSC all-cycle export.
- Added viewport policy support and aligned app contracts with the UI 4.x line.

#### User and data impact

- Users can export more complete CSC cycle data, and app layouts share the same
  viewport assumptions.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `a69829c6`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### UI groups migration

```labkit-change
schema: 1
id: LK-20260703-ui-groups-migration
date: 2026-07-03
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.4.5 -> 4.0.0`
component: `labkit_DICPostprocess_app` | `1.3.1 -> 1.3.2`
component: `labkit_DICPreprocess_app` | `1.3.1 -> 1.3.2`
component: `labkit_ChronoOverlay_app` | `1.3.1 -> 1.3.2`
component: `labkit_CIC_app` | `1.3.3 -> 1.3.4`
component: `labkit_CSC_app` | `1.3.3 -> 1.3.4`
component: `labkit_EIS_app` | `1.3.1 -> 1.3.2`
component: `labkit_VTResistance_app` | `1.3.3 -> 1.3.4`
component: `labkit_BatchImageCrop_app` | `1.6.3 -> 1.6.4`
component: `labkit_CurvatureMeasurement_app` | `1.3.1 -> 1.3.2`
component: `labkit_FLIRThermal_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.4.2 -> 1.4.3`
component: `labkit_ImageEnhance_app` | `1.5.2 -> 1.5.3`
component: `labkit_ImageMatch_app` | `1.5.2 -> 1.5.3`
component: `labkit_NerveResponseAnalysis_app` | `1.3.1 -> 1.3.2`
component: `labkit_ResponseReviewStats_app` | `1.3.1 -> 1.3.2`
component: `labkit_RHSPreview_app` | `1.3.1 -> 1.3.2`
component: `labkit_ECGPrint_app` | `1.3.2 -> 1.3.3`
```

#### Context

- This is the point where app action layout became a grouped UI contract instead
  of a looser action-list convention.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.4.5 -> 4.0.0`
- All supported apps received patch bumps.

- Replaced action groups with UI groups.
- Moved the reusable UI contract into the 4.x line.

#### User and data impact

- This is the point where app action layout became a grouped UI contract instead
  of a looser action-list convention.

#### Compatibility and migration

- App workflow definitions had to align with the new grouped UI contract.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `e81243a3`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### App file-selection and electrochem control fixes

```labkit-change
schema: 1
id: LK-20260703-app-file-selection-and-electrochem-control-fixes
date: 2026-07-03
type: fix
compatibility: compatible
component: `labkit_CIC_app` | `1.3.1 -> 1.3.2`
component: `labkit_CIC_app` | `1.3.2 -> 1.3.3`
component: `labkit_CSC_app` | `1.3.1 -> 1.3.2`
component: `labkit_CSC_app` | `1.3.2 -> 1.3.3`
component: `labkit_VTResistance_app` | `1.3.1 -> 1.3.2`
component: `labkit_VTResistance_app` | `1.3.2 -> 1.3.3`
component: `labkit_BatchImageCrop_app` | `1.6.2 -> 1.6.3`
component: `labkit_FLIRThermal_app` | `1.2.1 -> 1.2.2`
component: `labkit_FocusStack_app` | `1.4.1 -> 1.4.2`
component: `labkit_ImageEnhance_app` | `1.5.1 -> 1.5.2`
component: `labkit_ImageMatch_app` | `1.5.1 -> 1.5.2`
scope: historical project evolution
```

#### Context

- Multi-file workflows stopped losing appended selections, and electrochem app
  controls became less misleading.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- CIC, CSC, VT Resistance, Batch Crop, FLIR Thermal, Focus Stack, Image Enhance,
  and Image Match patch bumped for appended file selections.
- CIC, CSC, and VT Resistance patch bumped again for manual plot-control
  removal.

- Preserved appended file selections.
- Removed electrochem manual plot controls that no longer matched the workflow.

#### User and data impact

- Multi-file workflows stopped losing appended selections, and electrochem app
  controls became less misleading.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `6348185e` and `674d5d4b`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Declarative app runtime

```labkit-change
schema: 1
id: LK-20260703-declarative-app-runtime
date: 2026-07-03
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.4.4 -> 3.4.5`
component: `labkit_DICPostprocess_app` | `1.3.0 -> 1.3.1`
component: `labkit_DICPreprocess_app` | `1.3.0 -> 1.3.1`
component: `labkit_ChronoOverlay_app` | `1.3.0 -> 1.3.1`
component: `labkit_CIC_app` | `1.3.0 -> 1.3.1`
component: `labkit_CSC_app` | `1.3.0 -> 1.3.1`
component: `labkit_EIS_app` | `1.3.0 -> 1.3.1`
component: `labkit_VTResistance_app` | `1.3.0 -> 1.3.1`
component: `labkit_BatchImageCrop_app` | `1.6.1 -> 1.6.2`
component: `labkit_CurvatureMeasurement_app` | `1.3.0 -> 1.3.1`
component: `labkit_FLIRThermal_app` | `1.2.0 -> 1.2.1`
component: `labkit_FocusStack_app` | `1.4.0 -> 1.4.1`
component: `labkit_ImageEnhance_app` | `1.5.0 -> 1.5.1`
component: `labkit_ImageMatch_app` | `1.5.0 -> 1.5.1`
component: `labkit_NerveResponseAnalysis_app` | `1.3.0 -> 1.3.1`
component: `labkit_ResponseReviewStats_app` | `1.3.0 -> 1.3.1`
component: `labkit_RHSPreview_app` | `1.3.0 -> 1.3.1`
component: `labkit_ECGPrint_app` | `1.3.1 -> 1.3.2`
```

#### Context

- Maintainers can reason about app wiring through workflow definitions instead
  of hand-following callback construction.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.4.4 -> 3.4.5`
- All supported apps received patch bumps.

- Migrated apps to declarative workflow runtime.

#### User and data impact

- Maintainers can reason about app wiring through workflow definitions instead
  of hand-following callback construction.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `568b3e9b`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Startup responsiveness

```labkit-change
schema: 1
id: LK-20260702-startup-responsiveness
date: 2026-07-02
type: perf
compatibility: compatible
component: `labkit_launcher` | `1.2.2 -> 1.2.3`
component: `labkit.ui` | `3.4.2 -> 3.4.4`
```

#### Context

- Users see responsive windows sooner instead of waiting on discovery and setup
  work before the GUI appears.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.2.2 -> 1.2.3`
- `labkit.ui` `3.4.2 -> 3.4.4`

- Painted launcher and app windows earlier.
- Deferred launcher app discovery and lazy preview scroll setup.

#### User and data impact

- Users see responsive windows sooner instead of waiting on discovery and setup
  work before the GUI appears.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `7d4ef11e`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Profiling and validation speedups

```labkit-change
schema: 1
id: LK-20260702-profiling-and-validation-speedups
date: 2026-07-02
type: ci
compatibility: compatible
component: `labkit_launcher` | `1.2.0 -> 1.2.1`
component: `labkit_launcher` | `1.2.1 -> 1.2.2`
component: `labkit.ui` | `3.4.0 -> 3.4.1`
component: `labkit.ui` | `3.4.1 -> 3.4.2`
component: `labkit_BatchImageCrop_app` | `1.6.0 -> 1.6.1`
component: `labkit_ECGPrint_app` | `1.3.0 -> 1.3.1`
```

#### Context

- Maintainers get faster diagnosis and faster validation without changing app
  behavior.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.2.0 -> 1.2.2`
- `labkit.ui` `3.4.0 -> 3.4.2`
- `labkit_BatchImageCrop_app` `1.6.0 -> 1.6.1`
- `labkit_ECGPrint_app` `1.3.0 -> 1.3.1`

- Added LabKit profiling and build-managed test routing to the launcher.
- Reduced GUI profiling overhead and deferred Batch Crop image reads until
  preview/export.
- Compressed validation runtime with bounded GUI waits.

#### User and data impact

- Maintainers get faster diagnosis and faster validation without changing app
  behavior.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `c07dfc0a`, `74025fee`, `eadcca82`, `25912c54`, and `fcfc36d8`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Launcher code-analysis export

```labkit-change
schema: 1
id: LK-20260701-launcher-code-analysis-export
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.6 -> 1.2.0`
```

#### Context

- Maintainers can inspect launcher code issues through the workbench tooling
  without a separate manual MATLAB setup.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.1.6 -> 1.2.0`

- Exported launcher Code Analyzer issues natively.

#### User and data impact

- Maintainers can inspect launcher code issues through the workbench tooling
  without a separate manual MATLAB setup.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `8fd3ddff`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Debug sample packs

```labkit-change
schema: 1
id: LK-20260701-debug-sample-packs
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit.ui` | `3.3.1 -> 3.4.0`
component: `labkit_DICPostprocess_app` | `1.2.4 -> 1.3.0`
component: `labkit_DICPreprocess_app` | `1.2.2 -> 1.3.0`
component: `labkit_ChronoOverlay_app` | `1.2.1 -> 1.3.0`
component: `labkit_CIC_app` | `1.2.1 -> 1.3.0`
component: `labkit_CSC_app` | `1.2.1 -> 1.3.0`
component: `labkit_EIS_app` | `1.2.1 -> 1.3.0`
component: `labkit_VTResistance_app` | `1.2.1 -> 1.3.0`
component: `labkit_BatchImageCrop_app` | `1.5.1 -> 1.6.0`
component: `labkit_CurvatureMeasurement_app` | `1.2.4 -> 1.3.0`
component: `labkit_FLIRThermal_app` | `1.1.2 -> 1.2.0`
component: `labkit_FocusStack_app` | `1.3.0 -> 1.4.0`
component: `labkit_ImageEnhance_app` | `1.4.1 -> 1.5.0`
component: `labkit_ImageMatch_app` | `1.4.1 -> 1.5.0`
component: `labkit_NerveResponseAnalysis_app` | `1.2.4 -> 1.3.0`
component: `labkit_ResponseReviewStats_app` | `1.2.3 -> 1.3.0`
component: `labkit_RHSPreview_app` | `1.2.4 -> 1.3.0`
component: `labkit_ECGPrint_app` | `1.2.2 -> 1.3.0`
```

#### Context

- Reproducing app failures became a maintained workflow instead of an ad hoc
  collection of local files.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.3.1 -> 3.4.0`
- All supported apps moved into the `1.3.x`, `1.4.x`, `1.5.x`, or `1.6.x`
  debug-sample-pack lines.

- Added app-owned debug sample packs.
- Added debug artifact sample and output folders.

#### User and data impact

- Reproducing app failures became a maintained workflow instead of an ad hoc
  collection of local files.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `279befbc`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Image app workflow improvements

```labkit-change
schema: 1
id: LK-20260701-image-app-workflow-improvements
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.5 -> 1.1.6`
component: `labkit.image` | `1.0.0 -> 1.1.0`
component: `labkit.ui` | `3.2.10 -> 3.3.0`
component: `labkit.ui` | `3.3.0 -> 3.3.1`
component: `labkit_BatchImageCrop_app` | `1.4.0 -> 1.5.0`
component: `labkit_BatchImageCrop_app` | `1.5.0 -> 1.5.1`
component: `labkit_FLIRThermal_app` | `1.0.0 -> 1.1.0`
component: `labkit_FLIRThermal_app` | `1.1.0 -> 1.1.2`
component: `labkit_ImageEnhance_app` | `1.4.0 -> 1.4.1`
component: `labkit_ImageMatch_app` | `1.4.0 -> 1.4.1`
```

#### Context

- Large image workflows became more predictable and less likely to spend time on
  unnecessary preview work.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.image` `1.0.0 -> 1.1.0`
- `labkit.ui` `3.2.10 -> 3.3.1`
- Batch Crop `1.4.0 -> 1.5.1`
- FLIR Thermal `1.0.0 -> 1.1.2`
- `labkit_launcher` `1.1.5 -> 1.1.6`

- Added preview-budget helpers.
- Improved image app range and preview controls.
- Improved image measurement workflows.

#### User and data impact

- Large image workflows became more predictable and less likely to spend time on
  unnecessary preview work.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `15a798ba` and `70bfcfd4`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Thermal facade and FLIR app

```labkit-change
schema: 1
id: LK-20260701-thermal-facade-and-flir-app
date: 2026-07-01
type: feat
compatibility: compatible
introduced: `labkit.thermal` | `1.0.0`
component: `labkit.ui` | `3.2.9 -> 3.2.10`
introduced: `labkit_FLIRThermal_app` | `1.0.0`
```

#### Context

- Thermal image parsing and rendering became a reusable LabKit contract instead
  of app-local logic.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.thermal` `1.0.0`
- `labkit.ui` `3.2.9 -> 3.2.10`
- `labkit_FLIRThermal_app` `1.0.0`

- Added the thermal facade.
- Added the FLIR Thermal Postprocess app.

#### User and data impact

- Thermal image parsing and rendering became a reusable LabKit contract instead
  of app-local logic.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `977c9457`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Launcher update reliability

```labkit-change
schema: 1
id: LK-20260701-launcher-update-reliability
date: 2026-07-01
type: fix
compatibility: compatible
component: `labkit_launcher` | `1.1.3 -> 1.1.4`
component: `labkit_launcher` | `1.1.4 -> 1.1.5`
```

#### Context

- Updating the self-contained launcher became less fragile.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.1.3 -> 1.1.5`

- Sped up launcher zip updates.
- Simplified launcher zip replacement.

#### User and data impact

- Updating the self-contained launcher became less fragile.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `ebf86cf2` and `becf9391`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Shared image facade

```labkit-change
schema: 1
id: LK-20260630-shared-image-facade
date: 2026-06-30
type: feat
compatibility: compatible
introduced: `labkit.image` | `1.0.0`
component: `labkit_BatchImageCrop_app` | `1.3.9 -> 1.4.0`
component: `labkit_CurvatureMeasurement_app` | `1.2.3 -> 1.2.4`
component: `labkit_FocusStack_app` | `1.2.5 -> 1.3.0`
component: `labkit_ImageEnhance_app` | `1.3.5 -> 1.4.0`
component: `labkit_ImageMatch_app` | `1.3.5 -> 1.4.0`
scope: historical project evolution
```

#### Context

- Image app behavior became more consistent, and reusable image IO stopped
  living inside individual GUI workflows.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.image` `1.0.0`
- Batch Crop, Curvature, Focus Stack, Image Enhance, and Image Match advanced
  within their image-facade adoption lines.

- Added a GUI-free image facade for file input, display normalization, basic
  processing, and preview support.
- Adopted that facade across image-measurement apps.

#### User and data impact

- Image app behavior became more consistent, and reusable image IO stopped
  living inside individual GUI workflows.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `7023e87e`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Migration helper cleanup

```labkit-change
schema: 1
id: LK-20260630-migration-helper-cleanup
date: 2026-06-30
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.2.8 -> 3.2.9`
component: `labkit_DICPostprocess_app` | `1.2.3 -> 1.2.4`
component: `labkit_BatchImageCrop_app` | `1.3.7 -> 1.3.8`
component: `labkit_BatchImageCrop_app` | `1.3.8 -> 1.3.9`
component: `labkit_ImageEnhance_app` | `1.3.4 -> 1.3.5`
component: `labkit_RHSPreview_app` | `1.2.2 -> 1.2.3`
component: `labkit_RHSPreview_app` | `1.2.3 -> 1.2.4`
scope: historical project evolution
```

#### Context

- Maintainers no longer need to route through temporary migration helpers to
  understand these workflows.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- DIC Post, Batch Crop, and RHS Preview patch bumped.

- Retired migration helper debt.
- Consolidated RHS preview window bounds, Batch Crop scale state, and Image
  Enhance export helpers.

#### User and data impact

- Maintainers no longer need to route through temporary migration helpers to
  understand these workflows.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `7f73b71b`, `e3349af6`, `733fb951`, `98a2b02c`, and `391540a7`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### App alerts through UI facade

```labkit-change
schema: 1
id: LK-20260630-app-alerts-through-ui-facade
date: 2026-06-30
type: feat
compatibility: compatible
component: `labkit.ui` | `3.2.7 -> 3.2.8`
component: `labkit_DICPostprocess_app` | `1.2.2 -> 1.2.3`
component: `labkit_DICPreprocess_app` | `1.2.1 -> 1.2.2`
component: `labkit_ChronoOverlay_app` | `1.2.0 -> 1.2.1`
component: `labkit_CIC_app` | `1.2.0 -> 1.2.1`
component: `labkit_CSC_app` | `1.2.0 -> 1.2.1`
component: `labkit_EIS_app` | `1.2.0 -> 1.2.1`
component: `labkit_VTResistance_app` | `1.2.0 -> 1.2.1`
component: `labkit_BatchImageCrop_app` | `1.3.6 -> 1.3.7`
component: `labkit_CurvatureMeasurement_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.2.4 -> 1.2.5`
component: `labkit_ImageEnhance_app` | `1.3.3 -> 1.3.4`
component: `labkit_ImageMatch_app` | `1.3.4 -> 1.3.5`
component: `labkit_ECGPrint_app` | `1.2.1 -> 1.2.2`
```

#### Context

- App error reporting became testable without each app inventing its own alert
  mechanics.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.2.7 -> 3.2.8`
- DIC, electrochem, image-measurement, and ECG apps patch bumped where alert
  routing changed.

- Routed app alerts through hidden-test-safe `labkit.ui.app.showAlert`.

#### User and data impact

- App error reporting became testable without each app inventing its own alert
  mechanics.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `8d7c83b1`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Close guards and caught-exception diagnostics

```labkit-change
schema: 1
id: LK-20260630-close-guards-and-caught-exception-diagnostics
date: 2026-06-30
type: feat
compatibility: compatible
component: `labkit.ui` | `3.2.6 -> 3.2.7`
component: `labkit_DICPostprocess_app` | `1.2.1 -> 1.2.2`
component: `labkit_BatchImageCrop_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.3.5 -> 1.3.6`
component: `labkit_CurvatureMeasurement_app` | `1.2.1 -> 1.2.2`
component: `labkit_FocusStack_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.2.3 -> 1.2.4`
component: `labkit_ImageEnhance_app` | `1.3.2 -> 1.3.3`
component: `labkit_ImageMatch_app` | `1.3.2 -> 1.3.3`
component: `labkit_ImageMatch_app` | `1.3.3 -> 1.3.4`
component: `labkit_NerveResponseAnalysis_app` | `1.2.3 -> 1.2.4`
component: `labkit_ResponseReviewStats_app` | `1.2.2 -> 1.2.3`
component: `labkit_RHSPreview_app` | `1.2.1 -> 1.2.2`
component: `labkit_ECGPrint_app` | `1.2.0 -> 1.2.1`
```

#### Context

- Crashes and interrupted workflows leave better evidence for maintainers, and
  users get safer close behavior around incomplete image workflows.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.2.6 -> 3.2.7`
- DIC, Batch Crop, Curvature, Focus Stack, Image Match, neurophysiology apps,
  and ECG Print patch bumped for diagnostics or close-guard work.

- Reported caught app-runner exceptions through framework debug diagnostics.
- Promoted file-entry index helpers.
- Connected dirty/incomplete workflow state to close guards.

#### User and data impact

- Crashes and interrupted workflows leave better evidence for maintainers, and
  users get safer close behavior around incomplete image workflows.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `c0028a81` and `a81853ef`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Output folder prompts

```labkit-change
schema: 1
id: LK-20260630-output-folder-prompts
date: 2026-06-30
type: feat
compatibility: compatible
component: `labkit.ui` | `3.2.5 -> 3.2.6`
component: `labkit_DICPostprocess_app` | `1.2.0 -> 1.2.1`
component: `labkit_DICPreprocess_app` | `1.2.0 -> 1.2.1`
component: `labkit_BatchImageCrop_app` | `1.3.3 -> 1.3.4`
component: `labkit_FocusStack_app` | `1.2.1 -> 1.2.2`
component: `labkit_ImageEnhance_app` | `1.3.1 -> 1.3.2`
component: `labkit_ImageMatch_app` | `1.3.1 -> 1.3.2`
component: `labkit_NerveResponseAnalysis_app` | `1.2.1 -> 1.2.3`
component: `labkit_ResponseReviewStats_app` | `1.2.1 -> 1.2.2`
```

#### Context

- Apps gained consistent output-folder behavior without hard-coding dialog
  mechanics into each workflow.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.2.5 -> 3.2.6`
- DIC apps, Batch Crop, Focus Stack, Image Enhance/Match, Nerve Response, and
  Response Review patch bumped.

- Added `promptOutputFolder`.
- Migrated output-folder prompts with chooser injection and safe defaults.

#### User and data impact

- Apps gained consistent output-folder behavior without hard-coding dialog
  mechanics into each workflow.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `c5055b98`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### File-panel layout stabilization

```labkit-change
schema: 1
id: LK-20260630-file-panel-layout-stabilization
date: 2026-06-30
type: fix
compatibility: compatible
component: `labkit.ui` | `3.2.3 -> 3.2.4`
component: `labkit.ui` | `3.2.4 -> 3.2.5`
```

#### Context

- File-heavy app workflows became easier to scan and less layout-fragile.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.2.3 -> 3.2.5`

- Stabilized and compacted single file-panel layout.

#### User and data impact

- File-heavy app workflows became easier to scan and less layout-fragile.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `7f8df1cd` and `02b2f1b6`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Tool-panel hosts and image app fixes

```labkit-change
schema: 1
id: LK-20260629-tool-panel-hosts-and-image-app-fixes
date: 2026-06-29
type: fix
compatibility: compatible
component: `labkit.ui` | `3.2.0 -> 3.2.2`
component: `labkit.ui` | `3.2.2 -> 3.2.3`
component: `labkit_BatchImageCrop_app` | `1.3.2 -> 1.3.3`
component: `labkit_CurvatureMeasurement_app` | `1.2.0 -> 1.2.1`
component: `labkit_ImageEnhance_app` | `1.3.0 -> 1.3.1`
component: `labkit_ImageMatch_app` | `1.3.0 -> 1.3.1`
```

#### Context

- Reusable tools gained a real layout host, and image app reports/ROI controls
  became less surprising.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.2.0 -> 3.2.3`
- Batch Crop, Curvature, Image Enhance, and Image Match patch bumped where
  layouts or image-app behavior changed.

- Hardened file-panel entry normalization and deterministic ID regeneration.
- Fixed output-size reporting and White ROI responsiveness.
- Added semantic `toolPanel` hosts.

#### User and data impact

- Reusable tools gained a real layout host, and image app reports/ROI controls
  became less surprising.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `f2189aef`, `77084fbe`, and `871739cd`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### UI diagnostics and release v3.0.0

```labkit-change
schema: 1
id: LK-20260629-ui-diagnostics-and-release-v3-0-0
date: 2026-06-29
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.2 -> 1.1.3`
component: `labkit.ui` | `3.1.3 -> 3.2.0`
```

#### Context

- Maintainers got better evidence when app callbacks failed, and users got a
  clearer release line to roll back to.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Release tag `v3.0.0`
- `labkit.ui` `3.1.3 -> 3.2.0`
- `labkit_launcher` `1.1.2 -> 1.1.3`

- Improved UI diagnostics and validation documentation.
- Published the v3.0.0 release line around UI diagnostics, validation docs, and
  duplicate CI avoidance.

#### User and data impact

- Maintainers got better evidence when app callbacks failed, and users got a
  clearer release line to roll back to.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `21eff4dc` and release tag commit `349a7549`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Protected image enhancement workflows

```labkit-change
schema: 1
id: LK-20260629-protected-image-enhancement-workflows
date: 2026-06-29
type: feat
compatibility: compatible
component: `labkit_ImageEnhance_app` | `1.2.2 -> 1.3.0`
component: `labkit_ImageMatch_app` | `1.2.1 -> 1.3.0`
scope: historical project evolution
```

#### Context

- The image enhancement apps gained a more deliberate workflow boundary before
  later image-facade adoption.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Image Enhance `1.2.2 -> 1.3.0`
- Image Match `1.2.1 -> 1.3.0`

- Added protected image enhancement workflows.

#### User and data impact

- The image enhancement apps gained a more deliberate workflow boundary before
  later image-facade adoption.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `1768dd57`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### App diagnostics and hardened UI workflows

```labkit-change
schema: 1
id: LK-20260628-app-diagnostics-and-hardened-ui-workflows
date: 2026-06-28
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.1 -> 1.1.2`
component: `labkit.ui` | `3.1.0 -> 3.1.2`
component: `labkit.ui` | `3.1.2 -> 3.1.3`
component: `labkit_BatchImageCrop_app` | `1.3.0 -> 1.3.1`
component: `labkit_BatchImageCrop_app` | `1.3.1 -> 1.3.2`
component: `labkit_FocusStack_app` | `1.2.0 -> 1.2.1`
component: `labkit_ImageEnhance_app` | `1.2.0 -> 1.2.1`
component: `labkit_ImageEnhance_app` | `1.2.1 -> 1.2.2`
component: `labkit_ImageMatch_app` | `1.2.0 -> 1.2.1`
component: `labkit_NerveResponseAnalysis_app` | `1.2.0 -> 1.2.1`
component: `labkit_ResponseReviewStats_app` | `1.2.0 -> 1.2.1`
component: `labkit_RHSPreview_app` | `1.2.0 -> 1.2.1`
```

#### Context

- Maintainers get structured failure evidence instead of relying on screenshots
  or vague crash reports.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.1.0 -> 3.1.3`
- Batch Crop, Focus Stack, Image Enhance/Match, neurophysiology apps, and the
  launcher patch bumped where runtime behavior changed.

- Hardened LabKit UI workflows.
- Added crash reports, active-operation reports, caught-error reports, and stall
  diagnostics.

#### User and data impact

- Maintainers get structured failure evidence instead of relying on screenshots
  or vague crash reports.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `e966457b` and `f5bc6f98`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Batch Crop file workflow feedback

```labkit-change
schema: 1
id: LK-20260628-batch-crop-file-workflow-feedback
date: 2026-06-28
type: feat
compatibility: compatible
component: `labkit.ui` | `3.0.1 -> 3.1.0`
component: `labkit_BatchImageCrop_app` | `1.2.0 -> 1.3.0`
```

#### Context

- Users can see which selected file a preview or result belongs to.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.ui` `3.0.1 -> 3.1.0`
- Batch Crop `1.2.0 -> 1.3.0`

- Added selected-file title context.
- Improved Batch Crop file workflow feedback.

#### User and data impact

- Users can see which selected file a preview or result belongs to.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `61e8edd3`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Launcher manager and stale callback fix

```labkit-change
schema: 1
id: LK-20260626-launcher-manager-and-stale-callback-fix
date: 2026-06-26
type: fix
compatibility: compatible
component: `labkit_launcher` | `1.0.0 -> 1.1.0`
component: `labkit_launcher` | `1.1.0 -> 1.1.1`
component: `labkit.ui` | `3.0.0 -> 3.0.1`
```

#### Context

- Users gained a deliberate path to choose recent releases, tags, or main
  commits, and image interactions stopped carrying stale callback state.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit_launcher` `1.0.0 -> 1.1.1`
- `labkit.ui` `3.0.0 -> 3.0.1`

- Added the launcher version manager and managed-manifest requirement.
- Released stale image drag callbacks.

#### User and data impact

- Users gained a deliberate path to choose recent releases, tags, or main
  commits, and image interactions stopped carrying stale callback state.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `fe8654c9`, `ef89cf77`, and `3d23b7f1`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### File-panel migration

```labkit-change
schema: 1
id: LK-20260624-file-panel-migration
date: 2026-06-24
type: refactor
compatibility: breaking
component: `labkit.dta` | `1.0.0 -> 2.0.0`
component: `labkit.ui` | `2.2.1 -> 3.0.0`
component: `labkit_DICPostprocess_app` | `1.0.1 -> 1.2.0`
component: `labkit_DICPreprocess_app` | `1.0.1 -> 1.2.0`
component: `labkit_ChronoOverlay_app` | `1.0.0 -> 1.2.0`
component: `labkit_CIC_app` | `1.0.0 -> 1.2.0`
component: `labkit_CSC_app` | `1.0.0 -> 1.2.0`
component: `labkit_EIS_app` | `1.0.0 -> 1.2.0`
component: `labkit_VTResistance_app` | `1.0.0 -> 1.2.0`
component: `labkit_BatchImageCrop_app` | `1.0.0 -> 1.2.0`
component: `labkit_CurvatureMeasurement_app` | `1.0.1 -> 1.2.0`
component: `labkit_FocusStack_app` | `1.0.0 -> 1.2.0`
component: `labkit_ImageEnhance_app` | `1.0.0 -> 1.2.0`
component: `labkit_ImageMatch_app` | `1.0.0 -> 1.2.0`
component: `labkit_NerveResponseAnalysis_app` | `1.0.0 -> 1.2.0`
component: `labkit_ResponseReviewStats_app` | `1.0.0 -> 1.2.0`
component: `labkit_RHSPreview_app` | `1.0.0 -> 1.2.0`
component: `labkit_ECGPrint_app` | `1.0.0 -> 1.2.0`
```

#### Context

- File selection became a shared UI workflow instead of app-specific task-input
  plumbing.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.dta` `1.0.0 -> 2.0.0`
- `labkit.ui` `2.2.1 -> 3.0.0`
- All supported apps moved from `1.0.x` into the `1.2.0` workflow line.

- Replaced task inputs with file panels.
- Removed the old DTA session helper surface.

#### User and data impact

- File selection became a shared UI workflow instead of app-specific task-input
  plumbing.

#### Compatibility and migration

- This was a breaking workflow migration. Older app code expecting task inputs
  or the removed DTA session helpers needed migration.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `b145c904`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Version metadata baseline

```labkit-change
schema: 1
id: LK-20260623-version-metadata-baseline
date: 2026-06-23
type: feat
compatibility: compatible
introduced: `labkit_launcher` | `1.0.0`
component: `labkit.ui` | `2.1.0 -> 2.2.0`
introduced: `labkit_DICPostprocess_app` | `1.0.0`
introduced: `labkit_DICPreprocess_app` | `1.0.0`
introduced: `labkit_ChronoOverlay_app` | `1.0.0`
introduced: `labkit_CIC_app` | `1.0.0`
introduced: `labkit_CSC_app` | `1.0.0`
introduced: `labkit_EIS_app` | `1.0.0`
introduced: `labkit_VTResistance_app` | `1.0.0`
introduced: `labkit_BatchImageCrop_app` | `1.0.0`
introduced: `labkit_CurvatureMeasurement_app` | `1.0.0`
introduced: `labkit_FocusStack_app` | `1.0.0`
introduced: `labkit_ImageEnhance_app` | `1.0.0`
introduced: `labkit_ImageMatch_app` | `1.0.0`
introduced: `labkit_NerveResponseAnalysis_app` | `1.0.0`
introduced: `labkit_ResponseReviewStats_app` | `1.0.0`
introduced: `labkit_RHSPreview_app` | `1.0.0`
introduced: `labkit_ECGPrint_app` | `1.0.0`
```

#### Context

- This is the first point where app and launcher versions became first-class
  user-facing metadata.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Release tag `v2.4.0`
- `labkit_launcher` `1.0.0`
- All supported apps `1.0.0`
- `labkit.ui` `2.1.0 -> 2.2.0`

- Added app and launcher version metadata.
- Added versioned titles, lightweight version requests, launcher catalog version
  display, and version guardrails.

#### User and data impact

- This is the first point where app and launcher versions became first-class
  user-facing metadata.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commit `d70c2607`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Facade contract baseline and release validation hardening

```labkit-change
schema: 1
id: LK-20260623-facade-contract-baseline-and-release-validation-hardening
date: 2026-06-23
type: ci
compatibility: compatible
introduced: `labkit.biosignal` | `1.0.0`
introduced: `labkit.dta` | `1.0.0`
introduced: `labkit.rhs` | `1.0.0`
introduced: `labkit.ui` | `2.0.0`
component: `labkit.ui` | `2.0.0 -> 2.1.0`
component: `labkit.ui` | `2.2.0 -> 2.2.1`
component: `labkit_DICPostprocess_app` | `1.0.0 -> 1.0.1`
component: `labkit_DICPreprocess_app` | `1.0.0 -> 1.0.1`
component: `labkit_CurvatureMeasurement_app` | `1.0.0 -> 1.0.1`
```

#### Context

- Reusable facades gained explicit compatibility contracts before the later
  app-version and launcher-version work.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- `labkit.biosignal` `1.0.0`
- `labkit.dta` `1.0.0`
- `labkit.rhs` `1.0.0`
- `labkit.ui` `2.0.0 -> 2.2.1`
- DIC Pre/Post and Curvature `1.0.0 -> 1.0.1`
- Release tags `v2.4.1` and `v2.4.2`

- Added facade contract metadata and requirement checks.
- Hardened app lifecycle and release validation contracts.
- Routed MATLAB CI shards through build tasks.

#### User and data impact

- Reusable facades gained explicit compatibility contracts before the later
  app-version and launcher-version work.

#### Compatibility and migration

No manual migration was recorded for this historical change.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main commits `a25b79f9`, `3673e548`, `49d9f41b`, and `7e39b558`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

### Initial app workbench foundation

```labkit-change
schema: 1
id: LK-20260528-initial-app-workbench-foundation
date: 2026-05-28
type: feat
compatibility: compatible
scope: historical project evolution
```

#### Context

- This is the period where LabKit changed from loose scripts into an app
  workbench with a small reusable foundation.

#### Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

#### Changes

- Release tags `v1.0`, `v2.0`, legacy `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, and `v2.3.3`.

- Imported legacy MATLAB code and split it into app entry points.
- Extracted DTA parsers, electrochem calculations, DIC workflows, image
  measurement workflows, biosignal support, and ECG workflows.
- Replaced root legacy GUI entry points with package-backed runners.
- Added app shell behavior, axes popout, shared UI controls, debug trace
  logging, launcher/project metadata, release updater support, and reproducible
  release-asset rules.

#### User and data impact

- This is the period where LabKit changed from loose scripts into an app
  workbench with a small reusable foundation.

#### Compatibility and migration

- Component/app version files did not exist yet, so this era is tracked by
  release tags, commit ranges, and workflow milestones rather than per-app
  version numbers.

#### Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

#### Evidence

- Main history from `5973bde0` through `a7e7dfb1`.
- Release tags: `v1.0`, `v2.0`, `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, `v2.3.3`.

#### Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

## Current Version Lookup

Audited against working-tree metadata on 2026-07-14; version transitions use
the `origin/main` merge-base values.

| Component | Current version | Family | Metadata location |
|---|---:|---|---|
| `labkit_launcher` | `1.4.0` | Launcher | `labkit_launcher.m` |
| `labkit.ui` | `5.2.0` | Facade | `+labkit/+ui/version.m` |
| `labkit.dta` | `2.0.1` | Facade | `+labkit/+dta/version.m` |
| `labkit.image` | `2.0.0` | Facade | `+labkit/+image/version.m` |
| `labkit.thermal` | `1.1.0` | Facade | `+labkit/+thermal/version.m` |
| `labkit.rhs` | `1.0.1` | Facade | `+labkit/+rhs/version.m` |
| `labkit.biosignal` | `1.0.1` | Facade | `+labkit/+biosignal/version.m` |
| `labkit_FigureStudio_app` | `0.1.5` | LabKit Core | `apps/labkit_core/figure_studio/+figure_studio/version.m` |
| `labkit_ChronoOverlay_app` | `1.3.6` | Electrochem | `apps/electrochem/chrono_overlay/+chrono_overlay/version.m` |
| `labkit_CIC_app` | `1.3.8` | Electrochem | `apps/electrochem/cic/+cic/version.m` |
| `labkit_CSC_app` | `1.3.10` | Electrochem | `apps/electrochem/csc/+csc/version.m` |
| `labkit_EIS_app` | `1.3.4` | Electrochem | `apps/electrochem/eis/+eis/version.m` |
| `labkit_VTResistance_app` | `1.3.8` | Electrochem | `apps/electrochem/vt_resistance/+vt_resistance/version.m` |
| `labkit_DICPreprocess_app` | `1.4.0` | DIC | `apps/dic/dic_preprocess/+dic_preprocess/version.m` |
| `labkit_DICPostprocess_app` | `1.3.6` | DIC | `apps/dic/dic_postprocess/+dic_postprocess/version.m` |
| `labkit_BatchImageCrop_app` | `1.6.8` | Image Measurement | `apps/image_measurement/batch_crop/+batch_crop/version.m` |
| `labkit_CurvatureMeasurement_app` | `1.3.5` | Image Measurement | `apps/image_measurement/curvature/+curvature/version.m` |
| `labkit_FLIRThermal_app` | `1.3.0` | Image Measurement | `apps/image_measurement/flir_thermal/+flir_thermal/version.m` |
| `labkit_FocusStack_app` | `1.4.9` | Image Measurement | `apps/image_measurement/focus_stack/+focus_stack/version.m` |
| `labkit_ImageEnhance_app` | `1.5.8` | Image Measurement | `apps/image_measurement/image_enhance/+image_enhance/version.m` |
| `labkit_ImageMatch_app` | `1.5.8` | Image Measurement | `apps/image_measurement/image_match/+image_match/version.m` |
| `labkit_VideoMarker_app` | `1.2.0` | Image Measurement | `apps/image_measurement/video_marker/+video_marker/version.m` |
| `labkit_GaitAnalysis_app` | `1.0.0` | Gait | `apps/gait/gait_analysis/+gait_analysis/version.m` |
| `labkit_RHSPreview_app` | `1.3.4` | Neurophysiology | `apps/neurophysiology/rhs_preview/+rhs_preview/version.m` |
| `labkit_NerveResponseAnalysis_app` | `1.3.5` | Neurophysiology | `apps/neurophysiology/nerve_response_analysis/+nerve_response_analysis/version.m` |
| `labkit_ResponseReviewStats_app` | `1.3.5` | Neurophysiology | `apps/neurophysiology/response_review_stats/+response_review_stats/version.m` |
| `labkit_ECGPrint_app` | `1.3.5` | Wearable | `apps/wearable/ecg_print/+ecg_print/version.m` |
