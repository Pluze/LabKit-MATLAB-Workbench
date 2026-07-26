classdef EcgPrintWorkflowSpec < matlab.unittest.TestCase
    %ECGPRINTWORKFLOWSPEC Specify ECG load, analysis, plot, export, restore.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function analyzesExportsAndRestoresASyntheticRecording(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = ecg_print.syntheticInputs.writeSamplePack(context);
            segmentPath = context.outputPath("segments.csv");
            waveformPath = context.outputPath("waveform.png");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, segmentPath, waveformPath), ...
                "alert", @(~, ~) []);
            definition = ecg_print.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, pack.InitialProject, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyControlValue("peakMethod", "Local peaks");
            runtime.invokeAction("analyze");
            runtime.invokeAction("exportSegments");
            runtime.invokeAction("exportWaveform");

            testCase.verifyNotEmpty(runtime.State.session.cache.recording);
            testCase.verifyNotEmpty(runtime.State.session.cache.measurements);
            for id = ["wave" "noise" "snr" "template"]
                testCase.verifyNotEmpty(findall(figureValue, "Tag", ...
                    "previewAxes." + id).Children);
            end
            testCase.verifyTrue(isfile(segmentPath));
            testCase.verifyTrue(isfile(waveformPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastSegmentExport.manifestPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastWaveformExport.manifestPath));
            saved = fullfile(folder, "ecg-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.restoreProject(saved);
            testCase.verifyNotEmpty(runtime.State.session.cache.measurements);
            clear cleanup
        end
    end
end

function choice = chooseOutput(defaultPath, segmentPath, waveformPath)
if contains(string(defaultPath), "segment", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(segmentPath);
else
    choice = labkit.app.dialog.Choice(waveformPath);
end
end
