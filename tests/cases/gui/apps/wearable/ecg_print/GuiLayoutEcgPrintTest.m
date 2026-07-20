classdef GuiLayoutEcgPrintTest < matlab.unittest.TestCase
    %GUILAYOUTECGPRINTTEST Verify ECG Print GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
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
            runtime = ecg_print.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertEcgPrintLayout(h, fig);

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
ids = ["recording", "previewHeader", "importStatus", "headerLine", ...
    "hasHeader", "timeColumn", "timeUnit", "signalColumns", ...
    "fallbackFs", "refreshImport", "channel", "peakMethod", ...
    "analyze", "exportSegments", "exportWaveform", "summaryTable", ...
    "previewAxes.wave", "previewAxes.noise", "previewAxes.snr", ...
    "previewAxes.template"];
for id = ids
    assert(numel(findall(fig, "Tag", id)) == 1, ...
        "Missing ECG Print semantic target: %s.", id);
end
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
