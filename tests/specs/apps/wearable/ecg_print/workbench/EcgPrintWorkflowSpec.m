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
            regionPath = context.outputPath("analysis_region.mat");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, segmentPath, waveformPath, regionPath), ...
                "alert", @(~, ~) []);
            definition = ecg_print.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, pack.InitialInput, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyControlValue("peakMethod", "Local peaks");
            runtime.invokeAction("analyze");
            summaryTab = findall(figureValue, "Tag", "summaryResults");
            summaryTab.Parent.SelectedTab = summaryTab;
            drawnow;
            clearRegion = onCleanup(@() evalin( ...
                "base", "clear ecgAnalysisRegion"));
            runtime.invokeAction("exportRegionWorkspace");
            notice = getappdata(figureValue, "labkitAppLastAlert");
            testCase.verifyEqual(notice.title, "ROI timetable exported");
            testCase.verifyEqual(notice.icon, "info");
            runtime.invokeAction("exportRegionFile");
            runtime.invokeAction("exportSegments");
            runtime.invokeAction("exportWaveform");

            testCase.verifyNotEmpty(runtime.State.session.cache.recording);
            testCase.verifyNotEmpty(runtime.State.session.cache.measurements);
            testCase.verifyEqual(string(summaryTab.Parent.SelectedTab.Tag), ...
                "summaryResults");
            for id = ["wave" "noise" "snr" "template"]
                testCase.verifyNotEmpty(findall(figureValue, "Tag", ...
                    "previewAxes." + id).Children);
            end
            testCase.verifyTrue(isfile(segmentPath));
            testCase.verifyTrue(isfile(waveformPath));
            testCase.verifyTrue(isfile(regionPath));
            workspaceRegion = evalin("base", "ecgAnalysisRegion");
            fileRegion = load(regionPath, "ecgAnalysisRegion");
            testCase.verifyClass(workspaceRegion, "timetable");
            testCase.verifyEqual(fileRegion.ecgAnalysisRegion, workspaceRegion);
            testCase.verifyEqual(height(workspaceRegion), ...
                numel(runtime.State.session.cache.workingSignal.time));
            testCase.verifyTrue(isfile( ...
                runtime.State.project.results.lastRegionExport.outputPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastSegmentExport.outputPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastWaveformExport.outputPath));
            clear clearRegion cleanup
        end
    end
end

function choice = chooseOutput(defaultPath, segmentPath, waveformPath, regionPath)
if contains(string(defaultPath), "segment", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(segmentPath);
elseif contains(string(defaultPath), "analysis_region", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(regionPath);
else
    choice = labkit.app.dialog.Choice(waveformPath);
end
end
