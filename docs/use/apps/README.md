# LabKit Apps

```labkit-page
id: apps
type: landing
audience: app-user
summary: Choose a LabKit app by the laboratory result you need, then use its manual for supported inputs, workflow, calculations, outputs, and recovery.
```

LabKit apps are independent MATLAB tools for complete laboratory workflows. Choose an app by the result you need, then use its app page for supported inputs, controls, interaction behavior, calculations, outputs, recovery, and programmatic APIs.

Use the buttons in the left pane to switch workflow steps. Choose a result view beside the App title. A dropdown replaces the buttons when there are more than three views or when the header is too narrow. The **LabKit ▾** button opens plot-copy and session diagnostics tools.

## Start An App

Open `labkit_launcher`, select one App, and choose **Open Selected App**. Choose **Open App Guide** when you want the selected App's manual online or from a generated local copy.

Source-checkout users can also call an app command after adding LabKit to the MATLAB path:

```matlab
labkit_launcher
% Or, after repository path setup:
labkit_CIC_app
```

See [Use LabKit](../README.md) for installation, updating, version selection, and source-checkout setup. The [LabKit Launcher manual](labkit-core/launcher/README.md) documents its complete interactive and programmatic surface.

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
| Record NI-DMM voltage, current, resistance, or diode measurements | [NI-DMM Recorder](electrical-measurement/ni-dmm-recorder/README.md) | NI-DMM instrument | UTC-aligned CSV and complete MAT recording |
| Convert tracked points into gait metrics | [Gait Analysis](gait/gait-analysis/README.md) | Current Video Marker archive MAT | Frame, step, coordinate, and summary tables |
| Monitor, record, replay, and fit Mark-10 force/travel data | [Mark-10 Monitor](force-gauges/mark10-monitor/README.md) | ESM303 + Series 5, CSV, LOG, or MAT | Live plots, recordings, branch stiffness, and modulus CSV |
| Compare image intensity inside reusable regions | [ROI Analyzer](image-measurement/roi-analyzer/README.md) | Scalar or RGB images | ROI statistics, project MAT, parameter JSON, and CSV |
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
| Inspect ECG and measure segment SNR | [ECG Print](wearable/ecg-print/README.md) | BIOPAC ACQ, MAT, or delimited table | Per-beat measurements, ROI timetable, and waveform image |
| Mark EMG baseline and activity and inspect SNR and spectral content | [EMG Review](wearable/emg-review/README.md) | BIOPAC ACQ, MAT, or delimited table | Paired RMS and SNR, PSD, spectrogram, and metrics CSV |

## Browse By Family

- [DIC](dic/README.md) - preparation and postprocessing around a DIC solver.
- [Electrochemistry](electrochemistry/README.md) - DTA-based chrono, CV/CT, impedance, charge, and resistance workflows.
- [Electrical Measurement](electrical-measurement/README.md) - direct electrical-instrument recording and synchronized exports.
- [Gait](gait/README.md) - pose-coordinate analysis and gait metrics.
- [Force Gauges](force-gauges/README.md) - force/travel monitoring, recording, safe gauge setup, replay, and specimen analysis.
- [Image Measurement](image-measurement/README.md) - calibrated image, thermal, annotation, crop, fusion, and appearance workflows.
- [LabKit Core](labkit-core/README.md) - the launcher and general MATLAB graphics tools.
- [Neurophysiology](neurophysiology/README.md) - RHS inspection, response analysis, and review.
- [Statistics](statistics/README.md) - explicit first-versus-each t-tests and result-based group plotting.
- [Wearable](wearable/README.md) - wearable biosignal workflows.

## Common App Behavior

Open **LabKit ▾ > Diagnostics** for the session log and optional TRACE capture. Session logs are retained under `artifacts/logs/sessions/`. Apps that support saving work provide their own save and open controls.

Keep inputs and exported results outside the replaceable LabKit runtime folder. Inputs are preserved unless the App guide explicitly describes an in-place operation.

## Programmatic Use

Important scientific and deterministic app operations can be called without opening the GUI. Each app page identifies its supported app-owned functions and links them to the generated [API Reference](../../reference/README.md). Reusable file parsers and generic processing functions live in the public `labkit.*` libraries.

MATLAB must be able to see both the repository root and the owning app root. The launcher prepares these paths automatically. In a source checkout, add them explicitly before calling an app package:

```matlab
repoRoot = "/path/to/LabKit-MATLAB-Workbench";
addpath(repoRoot)
addpath(fullfile(repoRoot, "apps", "electrochem", "cic"))

help cic.analysisRun.computeCIC
```

For another app, replace the final app path with the directory that directly contains its `+package` folder. Do not add every repository subfolder with `genpath`; app roots are independent and may contain same-named private or development files that should not become global MATLAB commands.
