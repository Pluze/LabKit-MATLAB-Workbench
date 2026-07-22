classdef GuiLayoutEcgPrintTest < matlab.unittest.TestCase
    %GUILAYOUTECGPRINTTEST Verify ECG Print GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutRestoresEcgProductSurface(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            fig = labkit_ECGPrint_app();

            assertEcgPrintLayout(h, fig);
            clear cleanup
        end

        function ecg_print_workflow_loads_analyzes_and_plots_recording(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            recordingPath = fullfile(folder, 'synthetic_ecg.csv');
            writeSyntheticEcgCsv(recordingPath);
            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            outputs = ["ecg_segment_snr.csv", "ecg_waveform.png"];
            outputIndex = 0;
            backend = struct( ...
                "chooseOutputFile", @chooseOutput, ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                ecg_print.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            h.assertStartupSucceeded(fig);

            runtime.applyFileSelection("recording", recordingPath, 1);
            runtime.applyControlValue("peakMethod", "Local peaks");
            runtime.invokeAction("analyze");

            testCase.verifyTrue(contains( ...
                runtime.State.session.cache.filepath, 'synthetic_ecg.csv'));
            importStatus = string( ...
                findall(fig, "Tag", "importStatus").Value);
            testCase.verifyFalse(any(contains(importStatus, 'Parse failed')));
            testCase.verifyFalse(any(contains( ...
                importStatus, 'Open a recording')));
            channel = findall(fig, "Tag", "channel");
            testCase.verifyTrue(any(string(channel.Items) == "ECG"));

            summary = findall(fig, "Tag", "summaryTable").Data;
            metricNames = string(summary(:, 1));
            testCase.verifyTrue(any(metricNames == "Detected peaks"));
            testCase.verifyTrue(any(metricNames == "Mean SNR (dB)"));
            for id = ["wave", "noise", "snr", "template"]
                ax = findall(fig, "Tag", "previewAxes." + id);
                testCase.verifyNotEmpty(ax.Children, ...
                    "ECG Print should draw the " + id + " preview.");
            end

            runtime.invokeAction("exportSegments");
            runtime.invokeAction("exportWaveform");
            testCase.verifyTrue(isfile(fullfile(outputFolder, outputs(1))));
            testCase.verifyTrue(isfile(fullfile(outputFolder, outputs(2))));
            manifests = [ ...
                "ecg_segment_snr.labkit.json", ...
                "ecg_waveform.labkit.json"];
            for manifest = manifests
                manifestPath = fullfile(outputFolder, manifest);
                testCase.verifyTrue(isfile(manifestPath));
                decoded = jsondecode(fileread(manifestPath));
                testCase.verifyEqual(string(decoded.format), ...
                    "labkit.result");
                testCase.verifyEqual(string(decoded.app.id), ...
                    "ecg_print");
            end
            segmentExport = ...
                runtime.State.project.results.lastSegmentExport;
            waveformExport = ...
                runtime.State.project.results.lastWaveformExport;
            testCase.verifyEqual(string(segmentExport.manifestPath), ...
                string(fullfile(outputFolder, manifests(1))));
            testCase.verifyEqual(string(waveformExport.manifestPath), ...
                string(fullfile(outputFolder, manifests(2))));
            assertDisplayGraphicsAreNonPickable(testCase, fig);

            projectPath = fullfile( ...
                outputFolder, 'ecg-print-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 2);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'cache'));
            testCase.verifyFalse(isfield( ...
                runtime.State.project.results.lastAnalysis, 'recording'));
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.recording);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.measurements);
            delete(recordingPath);
            runtime.invokeAction("refreshImport");
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 1);
            testCase.verifyTrue(contains(string( ...
                runtime.State.session.workflow.importStatus), ...
                "Parse failed"));
            testCase.verifyEqual(string( ...
                runtime.State.session.cache.filepath), ...
                string(recordingPath));
            testCase.verifyEmpty(fieldnames( ...
                runtime.State.project.results.lastAnalysis));
            clear runtimeCleanup outputCleanup folderCleanup cleanup;

            function choice = chooseOutput(~, ~)
                outputIndex = outputIndex + 1;
                choice = labkit.app.dialog.Choice( ...
                    fullfile(outputFolder, outputs(outputIndex)));
            end
        end
    end
end

function assertEcgPrintLayout(h, fig)
h.assertStartupSucceeded(fig);
ids = ["recording", "recording.choose", "recording.status", ...
    "previewHeader", "importStatus", "headerLine", ...
    "hasHeader", "timeColumn", "timeUnit", "signalColumns", ...
    "fallbackFs", "refreshImport", "channel", "roiStart", "roiEnd", ...
    "lowCut", "highCut", "peakMethod", "peakDistance", ...
    "segmentWindow", "templateTopN", "smoothBeats", "templateView", ...
    "analyze", "exportSegments", "exportWaveform", "summaryTable", ...
    "filePreview", "appLog", ...
    "previewAxes.wave", "previewAxes.noise", "previewAxes.snr", ...
    "previewAxes.template"];
for id = ids
    assert(numel(findall(fig, "Tag", id)) == 1, ...
        "Missing ECG Print semantic target: %s.", id);
end
for id = ["headerLine", "fallbackFs", "roiStart", "roiEnd", ...
        "lowCut", "highCut", "peakDistance", "segmentWindow", ...
        "templateTopN", "smoothBeats"]
    assert(numel(findall(fig, "Tag", id + ".slider")) == 1, ...
        "ECG numeric control must retain its panner slider: %s.", id);
end
tabs = findall(fig, "Type", "uitab");
assert(isequal(sort(string({tabs.Title})), ...
    sort(["Files + Analysis", "Summary + Results", "Log"])));
for title = ["Recording", "Import Parsing", "Channel + ROI", ...
        "Signal Processing + SNR", "Exports", "Summary", ...
        "File Header Preview", "Log", "Workflow Notes"]
    assert(~isempty(findall(fig, "Title", title)), ...
        "Missing ECG Print titled surface: %s.", title);
end
assert(numel(findall(fig, "Title", "ECG Preview")) >= 2);
assert(string(component(fig, "recording.choose").Text) == ...
    "Open recording");
h.assertAxesContract(fig, { ...
    h.axesSpec("Waveform + Peaks", "Time (s)", "Amplitude"), ...
    h.axesSpec("Template Noise RMS Over Time | Smooth=15 beats", ...
    "Time (s)", "Noise RMS"), ...
    h.axesSpec("Template SNR Over Time | Smooth=15 beats", ...
    "Time (s)", "SNR (dB)"), ...
    h.axesSpec("Template + Residual Band", ...
    "Time from peak (s)", "Amplitude")});
end

function assertDisplayGraphicsAreNonPickable(testCase, fig)
for id = ["wave", "noise", "snr", "template"]
    ax = component(fig, "previewAxes." + id);
    graphics = allchild(ax);
    for k = 1:numel(graphics)
        if isprop(graphics(k), "HitTest")
            testCase.verifyEqual(string(graphics(k).HitTest), "off");
        end
        if isprop(graphics(k), "PickableParts")
            testCase.verifyEqual( ...
                string(graphics(k).PickableParts), "none");
        end
    end
end
end

function value = component(fig, tag)
value = findall(fig, "Tag", char(tag));
assert(isscalar(value), "Expected one component with Tag %s.", tag);
end

function writeSyntheticEcgCsv(filepath)
fs = 500;
durationSec = 4;
time = (0:(durationSec * fs - 1)).' ./ fs;
ecg = 0.05 .* sin(2 .* pi .* 1.7 .* time) + ...
    0.02 .* sin(2 .* pi .* 23 .* time);
for peakTime = 1:durationSec - 1
    ecg = ecg + 1.8 .* exp(-((time - peakTime) ./ 0.018).^2);
    ecg = ecg - 0.25 .* exp( ...
        -((time - peakTime - 0.045) ./ 0.026).^2);
end
T = table(time, ecg, 'VariableNames', {'time_s', 'ECG'});
writetable(T, filepath);
end

function removeTempFolder(folder)
if exist(folder, 'dir') == 7
    rmdir(folder, 's');
end
end
