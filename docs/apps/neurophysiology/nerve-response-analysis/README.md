# Nerve Response Analysis

Nerve Response Analysis reads the recording list prepared in RHS Preview,
finds stimulation events, groups them into trains, and measures compound action
potential responses in the assigned channels.

## Open Nerve Response Analysis

From the launcher, select **Nerve Response Analysis** and choose **Open**. From
a source checkout, run:

```matlab
labkit_NerveResponseAnalysis_app
```

## Analyze A Recording Set

1. On **Setup**, choose the filter JSON created by RHS Preview.
2. On **Protocol**, choose the protocol JSON that assigns channel roles. A
   protocol is optional, but strongly recommended.
3. Set **Max recordings** or **Max duration** only when you want a shorter test
   run. A value of zero means no limit.
4. Choose **Analyze Filtered Files**.
5. On **Review**, inspect the counts and switch the plot between **Counts** and
   **Issues**.
6. On **Export**, choose an output folder and then **Export Analysis**.

Changing the filter, protocol, or limits clears the previous analysis so that
an export cannot silently use outdated settings.

The filter record and optional protocol share the standard project
`inputs.sources` collection and retain distinct `filterRecord` and `protocol`
roles. Version 1 projects with separate role-specific fields are combined on
load and the next save writes payload version 2. This lets common project
save/load and missing-file relinking inspect every external dependency.

## Project And Session State

The durable project stores portable references for the filter record and
optional protocol, the two run limits, and the last export paths. The fixed
source IDs are `filterRecord` and `protocol`; each uses the same value as its
role so loading, presentation, and relinking address one unambiguous record.

Parsed JSON, analysis tables, issue details, preview selection, log messages,
and output-folder convenience are transient session state. Opening a project
reparses its JSON sources but does not persist or silently reuse old analysis
tables; choose **Analyze Filtered Files** to calculate them again.
If an existing selected JSON file is malformed, project restore stops and
preserves the current document. An absent optional protocol remains valid.

For developers, `nerve_response_analysis.definition` is the complete product
contract. `nerve_response_analysis.projectSpec` owns project creation,
validation, and the version-1 upgrade in one file, while
`nerve_response_analysis.createSession` rebuilds transient state. Runtime V2
owns the migration loop and source-reference representation.

## What The Analysis Does

For each readable recording, the app selects an event source from the protocol
and recording metadata, reads the required waveform, and finds sharp changes
using the absolute first difference. A robust noise estimate sets the default
detection threshold. Nearby peaks are reduced according to the minimum event
spacing, then grouped into trains by their time gaps and train rules.

For every event and response channel, the app measures a pre-event baseline,
baseline noise, positive and negative peaks, peak-to-peak amplitude, peak time,
latency, and SNR. The response search starts after the pulse-blanking interval
to avoid measuring the stimulation artifact itself.

Detection and measurement settings are scientific choices. Confirm that the
event source and timing shift match the physical stimulus before interpreting
latency.

## Output Files

**Export Analysis** writes:

- `nerve_response_analysis.json`, containing source information, the protocol,
  events, trains, response measurements, and issues;
- `nerve_response_analysis.labkit.json`, containing the selected inputs,
  run limits, output identity, and result counts.

An unreadable recording or missing channel is recorded in the issues table so
that other recordings can still complete.

## Detect Events In MATLAB Code

<!-- labkit-runnable-example -->
```matlab
sampleRate = 10000;
timeSec = (0:1/sampleRate:0.12).';
eventSignal = zeros(size(timeSec));
pulseTimes = 0.03 + (0:4).' * 0.01;
eventSignal(round(pulseTimes * sampleRate) + 1) = 5;
eventOptions = struct( ...
    "sourceId", "stim", ...
    "stimShiftSec", 0, ...
    "train", struct("minDetectedPulses", 5));
[events, trains] = ...
    nerve_response_analysis.analysisRun.detectEventTrains( ...
        timeSec, eventSignal, eventOptions);
```

`timeSec` and `eventSignal` must be equal-length numeric vectors. Options can
set the threshold multiplier, minimum score, minimum peak spacing, train gap,
minimum pulse count, maximum train duration, isolation rule, and reported
stimulus-time shift. With no candidates, the function returns empty tables.

## Measure CAP Features In MATLAB Code

```matlab
metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
    timeSec, responseSignal, events.timeSec, metricOptions);
```

`metricOptions` can set `baselineWindowSec`, `blankingAfterPulseSec`, and
`searchEndAfterPulseSec`. The output contains one row per event. If the search
window contains no samples, that row is kept with status `noSamples`.

To process an RHS file or an entire filter record, use
`nerve_response_analysis.analysisRun.analyzeRecording` or
`nerve_response_analysis.analysisRun.analyzeSession`.

## Errors And Limitations

- Time and signal vectors must have the same length.
- A detection peak marks an electrical transition; it is not automatically the
  physical onset of the delivered stimulus.
- Default timing windows are starting points, not universal physiological
  constants.
- Missing events produce empty results rather than fabricated measurements.
- Review the issues table before comparing counts across recordings.

## Related Functions And Apps

- `nerve_response_analysis.analysisRun.analyzeSession`
- `nerve_response_analysis.analysisRun.detectEventTrains`
- `nerve_response_analysis.analysisRun.measureCapMetrics`
- [RHS Preview](../rhs-preview/README.md)
- [Response Review and Stats](../response-review-stats/README.md)

## Framework Compatibility

This App uses the Runtime V2 lifecycle and requires `labkit.ui >=7 <8` and
`labkit.rhs >=1.0 <2`. App code uses semantic actions, `sourcePaths`, and the
injected source-upsert service; migration iteration, busy state, and portable
reference serialization remain framework-private.

The project validator requires the source collection and retains the
App-specific `filterRecord`/`protocol` ID-role rules, run limits, and export
state; Runtime validates canonical buckets and each source record first.

Its session factory returns only App-specific workflow, preview view, and
decoded analysis cache fields. Runtime supplies absent canonical buckets and
owns workflow-log initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/runtime.md#layout-and-action-rules):
every referenced action must be registered and resolves during layout construction.
