classdef EcgPrintWorkflowSpec < matlab.unittest.TestCase
    %ECGPRINTWORKFLOWSPEC Specify ECG load, analysis, plot, export, restore.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function analyzesExportsAndRestoresASyntheticRecording(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = ecgWorkflowProject(string(folder));
            segmentPath = fullfile(folder, "segments.csv");
            waveformPath = fullfile(folder, "waveform.png");
            regionPath = fullfile(folder, "analysis_region.mat");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, segmentPath, waveformPath, regionPath), ...
                "alert", @(~, ~) []);
            definition = ecg_print.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, project, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            testCase.assertFalse(runtime.StartupFailed, ...
                startupDiagnostic(figureValue));
            initialWaveAxes = findall(figureValue, ...
                "Tag", "waveAxes.wave");
            testCase.assertNotEmpty(initialWaveAxes.Children, ...
                "The initial recording waveform was not rendered.");
            testCase.assertGreaterThanOrEqual(initialWaveAxes.XLim(2), 3, ...
                "The initial waveform did not fit the recording time domain.");
            highCutControl = findall(figureValue, "Tag", "highCut");
            testCase.verifyEqual(highCutControl.Limits, [0 250], ...
                AbsTol=1e-10);
            testCase.verifyEqual(highCutControl.Value, 250, AbsTol=1e-10);
            testCase.verifyEqual(runtime.State.project.parameters.lowCut, 0);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.highCut, 250, AbsTol=1e-10);
            peakLowControl = findall(figureValue, "Tag", "peakLowCut");
            testCase.verifyEqual(string(peakLowControl.Enable), "off");

            runtime.invokeAction("previewHeader");
            testCase.verifySubstring(string( ...
                runtime.State.session.cache.filePreview{1}), "time_s");
            originalRevision = runtime.State.session.cache.plotViewRevision;
            runtime.applyControlValue("headerLine", 1);
            runtime.applyControlValue("hasHeader", "Yes");
            runtime.applyControlValue("timeColumn", "time_s");
            runtime.applyControlValue("timeUnit", "seconds");
            runtime.applyControlValue("signalColumns", ...
                "ECG, Motion, ContactQuality");
            runtime.applyControlValue("fallbackFs", 500);
            testCase.verifyEqual( ...
                runtime.State.session.cache.plotViewRevision, originalRevision);
            testCase.verifySubstring( ...
                runtime.State.session.workflow.importStatus, ...
                "Import settings changed");
            runtime.invokeAction("refreshImport");
            testCase.verifyGreaterThan( ...
                runtime.State.session.cache.plotViewRevision, originalRevision);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.recording);
            testCase.verifyEqual(string( ...
                runtime.State.session.cache.channelItems), ...
                ["ECG", "Motion", "ContactQuality"]);
            waveBeforeChannel = findall(figureValue, ...
                "Tag", "waveAxes.wave");
            waveBeforeChannel.YLim = [-100 -50];
            revisionBeforeChannel = ...
                runtime.State.session.cache.plotViewRevision;
            runtime.applyControlValue("channel", "Motion");
            testCase.verifyEqual( ...
                runtime.State.session.cache.signal.displayName, "Motion");
            testCase.verifyGreaterThan( ...
                runtime.State.session.cache.plotViewRevision, ...
                revisionBeforeChannel);
            motionAxes = findall(figureValue, "Tag", "waveAxes.wave");
            testCase.verifyNotEqual(motionAxes.YLim, [-100 -50]);
            testCase.verifyEqual(string(motionAxes.YLabel.String), ...
                "Motion (ADC counts)");
            runtime.applyControlValue("channel", "ECG");
            testCase.verifyEqual( ...
                runtime.State.session.cache.signal.displayName, "ECG");
            revisionAfterChannel = ...
                runtime.State.session.cache.plotViewRevision;

            runtime.applyControlValue("peakMethod", "Local peaks");
            runtime.applyControlValue("useAnalysisBandForPeaks", false);
            runtime.applyControlValue("peakLowCut", 5);
            runtime.applyControlValue("peakHighCut", 30);
            testCase.verifyEqual(string(peakLowControl.Enable), "on");
            testCase.verifyEqual( ...
                runtime.State.session.cache.plotViewRevision, ...
                revisionAfterChannel);
            runtime.invokeAction("analyze");
            testCase.verifyEqual(runtime.State.session.cache. ...
                peakDetectionSignal.metadata.filter.cutoffHz, [5 30]);
            testCase.verifyTrue(all([runtime.State.session.cache. ...
                powerSpectra.ok]));
            for id = ["rawSpectrum" "analysisSpectrum" "peakSpectrum"]
                spectrumAxes = findall(figureValue, "Tag", ...
                    id + "Axes." + id);
                testCase.verifyEqual(numel(findall( ...
                    spectrumAxes, "Type", "line")), 1);
            end
            for id = ["wave" "noise" "peak" "snr"]
                ax = findall(figureValue, "Tag", id + "Axes." + id);
                ax.XLim = [-100 -50];
                ax.YLim = [-100 -50];
            end
            for id = ["templateResidual" "templateSegments"]
                ax = findall(figureValue, "Tag", "templateAxes." + id);
                ax.XLim = [-100 -50];
                ax.YLim = [-100 -50];
            end
            for id = ["magnitude" "phase"]
                filterAxes = findall(figureValue, ...
                    "Tag", "filterFrequencyAxes." + id);
                testCase.verifyEqual(numel(findall( ...
                    filterAxes, "Type", "line")), 3);
            end
            for id = ["groupDelay" "impulse"]
                filterAxes = findall(figureValue, ...
                    "Tag", "filterTimeAxes." + id);
                testCase.verifyEqual(numel(findall( ...
                    filterAxes, "Type", "line")), 3);
            end
            revisionBeforeAnalysis = ...
                runtime.State.session.cache.plotViewRevision;
            runtime.invokeAction("analyze");
            testCase.assertGreaterThan( ...
                runtime.State.session.cache.plotViewRevision, ...
                revisionBeforeAnalysis, lastAlertDiagnostic(figureValue));
            for id = ["wave" "noise" "peak" "snr"]
                ax = findall(figureValue, "Tag", id + "Axes." + id);
                testCase.verifyLessThanOrEqual(ax.XLim(1), 0);
                testCase.verifyGreaterThanOrEqual(ax.XLim(2), 3);
            end
            for id = ["templateResidual" "templateSegments"]
                ax = findall(figureValue, "Tag", "templateAxes." + id);
                testCase.verifyEqual(string(ax.XLimMode), "auto");
                testCase.verifyEqual(string(ax.YLimMode), "auto");
            end
            waveAxes = findall(figureValue, "Tag", "waveAxes.wave");
            testCase.assertTrue(isappdata( ...
                waveAxes, "ecgPrintTimeAxesListeners"), ...
                "The time-axis synchronization listeners were not retained.");
            timeListeners = getappdata( ...
                waveAxes, "ecgPrintTimeAxesListeners");
            testCase.assertTrue(all(cellfun(@isvalid, timeListeners)), ...
                "A time-axis synchronization listener became invalid.");
            waveAxes.YLim = [-100 -50];
            waveAxes.XLim = [1 3];
            drawnow;
            for id = ["noise" "peak" "snr"]
                linkedAxes = findall(figureValue, "Tag", id + "Axes." + id);
                testCase.verifyEqual(linkedAxes.XLim, [1 3], AbsTol=1e-12);
            end
            testCase.verifyNotEqual(waveAxes.YLim, [-100 -50]);
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
            for id = ["wave" "noise" "peak" "snr"]
                testCase.verifyNotEmpty(findall(figureValue, "Tag", ...
                    id + "Axes." + id).Children);
            end
            for id = ["templateResidual" "templateSegments"]
                testCase.verifyNotEmpty(findall(figureValue, "Tag", ...
                    "templateAxes." + id).Children);
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

function diagnostic = lastAlertDiagnostic(figureValue)
alert = getappdata(figureValue, "labkitAppLastAlert");
diagnostic = "The analysis transaction did not publish an alert.";
if isstruct(alert) && isfield(alert, "message")
    diagnostic = string(alert.message);
end
end

function diagnostic = startupDiagnostic(figureValue)
failure = getappdata(figureValue, "labkitAppStartupFailure");
diagnostic = "Runtime did not publish a startup failure diagnostic.";
if isstruct(failure) && isfield(failure, "message")
    diagnostic = string(failure.message);
    if isfield(failure, "identifier") && ...
            strlength(string(failure.identifier)) > 0
        diagnostic = diagnostic + " [" + string(failure.identifier) + "]";
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
