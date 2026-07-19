# LabKit Apps

LabKit apps are independent MATLAB tools for complete laboratory workflows.
Choose an app by the result you need, then use its app page for supported
inputs, controls, interaction behavior, calculations, outputs, recovery, and
programmatic APIs.

## Start An App

Open `labkit_launcher`, select one app, and choose **Open**. The launcher's
**Documentation and History** action opens the selected app page.

Source-checkout users can also call an app command after adding LabKit to the
MATLAB path:

```matlab
labkit_launcher
% Or, after repository path setup:
labkit_CIC_app
```

See [Getting Started](../getting-started/README.md) for installation, updating,
version selection, and source-checkout setup. The
[LabKit Launcher manual](labkit-core/launcher/README.md) documents its complete
interactive and programmatic surface.

## Choose An App

| Task | App | Input | Principal output |
| --- | --- | --- | --- |
| Discover, install, launch, diagnose, and package LabKit apps | [LabKit Launcher](labkit-core/launcher/README.md) | Installed or source LabKit tree | Running app, maintenance report, or deployment ZIP |
| Register, crop, and mask image pairs for DIC | [DIC Preprocess](dic/dic-preprocess/README.md) | Reference and moving images | Aligned images, crops, mask |
| Render and summarize Ncorr strain results | [DIC Postprocess](dic/dic-postprocess/README.md) | Ncorr MAT, reference image, mask | Strain overlays and summary CSV |
| Overlay chrono voltage and current traces | [Chrono Overlay](electrochemistry/chrono-overlay/README.md) | Chrono DTA | Plot and CSV |
| Measure charge-injection capacity | [CIC](electrochemistry/cic/README.md) | Chrono DTA | CIC result table and CSV |
| Compare cyclic and time-domain CSC | [CSC](electrochemistry/csc/README.md) | CV/CT DTA | Per-cycle CSC and CV data |
| Inspect impedance curves | [EIS](electrochemistry/eis/README.md) | EIS DTA | Nyquist/Bode plots and CSV |
| Estimate voltage-transient resistance | [VT Resistance](electrochemistry/vt-resistance/README.md) | Chrono DTA | Resistance table and CSV |
| Convert tracked points into gait metrics | [Gait Analysis](gait/gait-analysis/README.md) | Coordinate table or marker MAT | Frame, step, coordinate, and summary tables |
| Crop image batches at repeatable geometry | [Batch Image Crop](image-measurement/batch-crop/README.md) | Image files | Same-size crops and manifest |
| Measure curve radius, curvature, and length | [Curvature Measurement](image-measurement/curvature/README.md) | Image | Overlay and measurement CSV |
| Decode and measure radiometric images | [FLIR Thermal](image-measurement/flir-thermal/README.md) | FLIR radiometric image | Temperature data, measurements, rendered image |
| Fuse focal planes | [Focus Stack](image-measurement/focus-stack/README.md) | Aligned image stack | Fused image and focus map |
| Apply a repeatable enhancement pipeline | [Image Enhance](image-measurement/image-enhance/README.md) | Image files | Enhanced images and manifest |
| Match appearance to a reference image | [Image Match](image-measurement/image-match/README.md) | Source and reference images | Matched images and manifest |
| Annotate ordered landmarks across video | [Video Marker](image-measurement/video-marker/README.md) | Video | Project MAT and coordinate CSV |
| Restyle figures and export visible plot data | [Figure Studio](labkit-core/figure-studio/README.md) | FIG or popout axes | Styled figure and plot data |
| Inspect RHS recordings and define channels | [RHS Preview](neurophysiology/rhs-preview/README.md) | RHS file or folder | Preview, protocol JSON, filter record |
| Detect trains and measure neural responses | [Nerve Response Analysis](neurophysiology/nerve-response-analysis/README.md) | Filter record and protocol JSON | Analysis JSON and CAP metrics |
| Review aligned responses and statistics | [Response Review and Stats](neurophysiology/response-review-stats/README.md) | Analysis JSON or segment CSV | Metrics CSV and summary |
| Compare multiple groups with the first using t-tests and one mean/SD plot | [T-Test Wizard](statistics/ttest-wizard/README.md) | CSV, TSV, workbook, or entered values | Result family, CSVs, and comparison plot |
| Inspect ECG and measure segment SNR | [ECG Print](wearable/ecg-print/README.md) | MAT or delimited table | Segment SNR CSV and waveform image |

## Browse By Family

- [DIC](dic/README.md) - preparation and postprocessing around a DIC solver.
- [Electrochemistry](electrochemistry/README.md) - DTA-based chrono, CV/CT,
  impedance, charge, and resistance workflows.
- [Gait](gait/README.md) - pose-coordinate analysis and gait metrics.
- [Image Measurement](image-measurement/README.md) - calibrated image,
  thermal, annotation, crop, fusion, and appearance workflows.
- [LabKit Core](labkit-core/README.md) - the launcher and general MATLAB graphics tools.
- [Neurophysiology](neurophysiology/README.md) - RHS inspection, response
  analysis, and review.
- [Statistics](statistics/README.md) - explicit first-versus-each t-tests and
  result-based group plotting.
- [Wearable](wearable/README.md) - wearable biosignal workflows.

## How To Read An App Page

Concrete app pages use a common MATLAB-style order:

1. purpose, requirements, and launch command;
2. supported inputs and the shortest successful workflow;
3. controls and interaction behavior;
4. calculation or algorithm semantics, units, and assumptions;
5. outputs, project files, autosave, and recovery behavior;
6. GUI-free MATLAB examples and public app-owned APIs;
7. errors, limitations, troubleshooting, related topics, and history.

The app page documents stable user-visible behavior. Exact callable syntax and
data shapes live on the linked API reference pages. Internal callbacks and
private implementation helpers are intentionally omitted.

## Common App Behavior

The App Framework owns lifecycle, busy state, file selection, state snapshots,
screenshot actions, plot tools, and managed interactions. Apps own scientific
choices, workflow-specific defaults, result schemas, and exports. See the
[App Framework](../framework/README.md) for behavior shared across apps.

Input data and exported results should remain outside the replaceable LabKit
runtime folder. Apps do not overwrite source files unless an app page states
an explicit in-place operation.

## Programmatic Use

Important scientific and deterministic app operations can be called without
opening the GUI. Each app page identifies its supported app-owned functions
and links them to the generated [API Reference](../reference/README.md).
Reusable file parsers and generic processing functions live in the public
`labkit.*` libraries.

MATLAB must be able to see both the repository root and the owning app root.
The launcher prepares these paths automatically. In a source checkout, add
them explicitly before calling an app package:

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(repoRoot)
addpath(fullfile(repoRoot, "apps", "electrochem", "cic"))

help cic.analysisRun.computeCIC
```

For another app, replace the final app path with the directory that directly
contains its `+package` folder. Do not add every repository subfolder with
`genpath`; app roots are independent and may contain same-named private or
development files that should not become global MATLAB commands.

## Related Documentation

- [Getting Started](../getting-started/README.md)
- [LabKit Launcher](labkit-core/launcher/README.md)
- [App Framework](../framework/README.md)
- [API Reference](../reference/README.md)
- [App Development](../development/build-apps/app-development.md)
- [Component History](../history/README.md)
