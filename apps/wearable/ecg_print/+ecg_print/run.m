% App-owned runner for labkit_ECGPrint_app. Expected caller: labkit_ECGPrint_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUN Build and run the ECG Print app body.

    S = struct();
    S.recording = [];
    S.signal = [];
    S.workingSignal = [];
    S.filteredSignal = [];
    S.events = [];
    S.segments = [];
    S.template = [];
    S.measurements = [];
    S.filepath = "";

    callbacks = struct( ...
        "recordingChosen", @onRecordingChosen, ...
        "clearRecording", @(~, ~) onClearRecording(), ...
        "previewHeader", @(~, ~) onPreviewHeader(), ...
        "importOptionChanged", @(~, ~) onImportOptionChanged(), ...
        "refreshImport", @(~, ~) onRefreshImport(), ...
        "channelChanged", @(~, ~) onChannelChanged(), ...
        "analyze", @(~, ~) onAnalyze(), ...
        "exportSegments", @(~, ~) onExportSegments(), ...
        "exportWaveform", @(~, ~) onExportWaveform(), ...
        "refreshPlots", @(~, ~) refreshPlots());
    spec = ecg_print.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;

    txtFile = ui.controls.recording.status;
    txtImportStatus = ui.controls.importStatus.valueHandle;
    edtHeaderLine = ui.controls.headerLine.valueHandle;
    ddHasHeader = ui.controls.hasHeader.valueHandle;
    edtTimeColumn = ui.controls.timeColumn.valueHandle;
    ddTimeUnit = ui.controls.timeUnit.valueHandle;
    edtSignalColumns = ui.controls.signalColumns.valueHandle;
    edtFallbackFs = ui.controls.fallbackFs.valueHandle;
    ddChannel = ui.controls.channel.valueHandle;
    edtStart = ui.controls.roiStart.valueHandle;
    edtEnd = ui.controls.roiEnd.valueHandle;
    edtLow = ui.controls.lowCut.valueHandle;
    edtHigh = ui.controls.highCut.valueHandle;
    ddPeakMethod = ui.controls.peakMethod.valueHandle;
    edtPeakDist = ui.controls.peakDistance.valueHandle;
    edtWin = ui.controls.segmentWindow.valueHandle;
    edtTopN = ui.controls.templateTopN.valueHandle;
    edtSmooth = ui.controls.smoothBeats.valueHandle;
    ddTemplateView = ui.controls.templateView.valueHandle;
    summaryTable = ui.controls.summaryTable.table;
    txtFilePreview = ui.controls.filePreview.textArea;
    ui.waveAxes = ui.controls.previewAxes.axesById.wave;
    ui.noiseAxes = ui.controls.previewAxes.axesById.noise;
    ui.snrAxes = ui.controls.previewAxes.axesById.snr;
    ui.templateAxes = ui.controls.previewAxes.axesById.template;

    if debugLog.enabled
        debugLog.trace('ECG print debug trace enabled.');
    end

    resetAxes();

    function onRecordingChosen(~, event)
        if isempty(event.paths)
            addLog('Recording selection cancelled.');
            return;
        end

        S.filepath = event.paths(1);
        txtFile.Value = char(S.filepath);
        clearParsedRecording();
        updateFilePreview();
        refreshImportParsing(false);
    end

    function onClearRecording()
        S.filepath = "";
        txtFile.Value = 'No file loaded';
        txtFilePreview.Value = {'Open a CSV/text file, then use Preview file header.'};
        txtImportStatus.Value = 'Open a recording to inspect import settings.';
        clearParsedRecording();
        addLog('Cleared recording.');
    end

    function onRefreshImport()
        refreshImportParsing(true);
    end

    function refreshImportParsing(showAlertOnFailure)
        if nargin < 1
            showAlertOnFailure = true;
        end
        if strlength(S.filepath) == 0
            if showAlertOnFailure
                showError('No recording selected', 'Open a recording before parsing.');
            else
                txtImportStatus.Value = 'Open a recording before parsing.';
            end
            return;
        end

        txtImportStatus.Value = 'Parsing file...';
        selectedChannel = "";
        if ~isempty(ddChannel.Items) && ~strcmp(ddChannel.Value, '(none)')
            selectedChannel = string(ddChannel.Value);
        end

        importOpts = ecg_print.io.importOptions( ...
            edtFallbackFs.Value, ...
            edtHeaderLine.Value, ...
            ddHasHeader.Value, ...
            edtTimeColumn.Value, ...
            ddTimeUnit.Value, ...
            edtSignalColumns.Value);
        [recording, status] = labkit.biosignal.readRecording(char(S.filepath), importOpts);
        if ~status.ok
            clearParsedRecording();
            txtImportStatus.Value = char("Parse failed. Inspect header/settings, then refresh: " + status.message);
            if showAlertOnFailure
                showError('Could not parse recording', status.message);
            else
                addLog(sprintf('Automatic parse failed: %s', status.message));
            end
            return;
        end

        S.recording = recording;
        channels = labkit.biosignal.listChannels(recording);
        if isempty(channels)
            clearParsedRecording();
            txtImportStatus.Value = 'Parse failed: no numeric signal channels were found.';
            if showAlertOnFailure
                showError('Could not parse recording', 'No numeric signal channels were found.');
            end
            return;
        end
        ddChannel.Items = channels;
        if any(strcmp(channels, selectedChannel))
            ddChannel.Value = char(selectedChannel);
        else
            ddChannel.Value = channels{1};
        end
        setCurrentChannel(ddChannel.Value);
        txtImportStatus.Value = ecg_print.view.importStatusText(recording, numel(channels));
        addLog(sprintf('Parsed %d channel(s) from %s', numel(channels), char(S.filepath)));
    end

    function onPreviewHeader()
        updateFilePreview();
    end

    function updateFilePreview()
        if strlength(S.filepath) == 0
            txtFilePreview.Value = {'Open a CSV/text file, then use Preview file header.'};
            return;
        end
        txtFilePreview.Value = ecg_print.io.previewFileHeader(char(S.filepath), 18);
        addLog(sprintf('Previewed file header: %s', char(S.filepath)));
    end

    function onImportOptionChanged()
        if strlength(S.filepath) > 0
            txtImportStatus.Value = 'Import settings changed. Click Parse / refresh file.';
        end
    end

    function clearParsedRecording()
        S.recording = [];
        S.signal = [];
        S.workingSignal = [];
        S.filteredSignal = [];
        S.events = [];
        S.segments = [];
        S.template = [];
        S.measurements = [];
        ddChannel.Items = {'(none)'};
        ddChannel.Value = '(none)';
        edtStart.Value = 0;
        edtEnd.Value = 0;
        updateSummary();
        refreshPlots();
    end

    function onChannelChanged()
        if isempty(S.recording) || strcmp(ddChannel.Value, '(none)')
            return;
        end
        setCurrentChannel(ddChannel.Value);
    end

    function setCurrentChannel(channelName)
        S.signal = labkit.biosignal.getChannel(S.recording, channelName);
        S.workingSignal = S.signal;
        S.filteredSignal = [];
        S.events = [];
        S.segments = [];
        S.template = [];
        S.measurements = [];
        if ~isempty(S.signal.time)
            edtStart.Value = 0;
            edtEnd.Value = max(S.signal.time);
        end
        updateSummary();
        refreshPlots();
    end

    function onAnalyze()
        if isempty(S.signal)
            showError('No channel selected', 'Open a recording and select a channel first.');
            return;
        end

        try
            timeRange = [edtStart.Value edtEnd.Value];
            highCut = min(edtHigh.Value, max(edtLow.Value + eps, 0.45 * S.signal.fs));
            filterSpec = struct('type', 'bandpass', 'cutoffHz', [edtLow.Value highCut]);
            fullFiltered = labkit.biosignal.filterSignal(S.signal, filterSpec);
            if timeRange(2) > timeRange(1)
                S.workingSignal = labkit.biosignal.cropSignal(S.signal, timeRange);
                S.filteredSignal = labkit.biosignal.cropSignal(fullFiltered, timeRange);
            else
                S.workingSignal = S.signal;
                S.filteredSignal = fullFiltered;
            end
            peakOpts = struct('polarity', 'auto', ...
                'method', ecg_print.ops.peakMethodValue(ddPeakMethod.Value), ...
                'minDistanceSec', edtPeakDist.Value, ...
                'thresholdStd', 2.8);
            S.events = labkit.biosignal.detectEcgPeaks(S.filteredSignal, peakOpts);
            halfWin = edtWin.Value;
            S.segments = labkit.biosignal.segmentByEvents(S.filteredSignal, S.events, [-halfWin halfWin]);
            S.template = labkit.biosignal.buildTemplate(S.segments, struct('topN', edtTopN.Value));
            S.measurements = labkit.biosignal.measureSegments(S.segments, S.template);

            addLog(sprintf('Filtered channel, then analyzed ROI with %s: %d peaks, %d valid segments.', ...
                ddPeakMethod.Value, numel(S.events.index), size(S.segments.values, 2)));
            updateSummary();
            refreshPlots();
        catch ME
            showError('Analysis failed', ME.message);
        end
    end

    function onExportSegments()
        if isempty(S.measurements) || isempty(S.measurements.perSegment)
            showError('No segment SNR', 'Analyze a signal before exporting segment SNR.');
            return;
        end
        [fn, fp] = uiputfile('ecg_segment_snr.csv', 'Export segment SNR CSV');
        if isequal(fn, 0)
            addLog('Segment SNR export cancelled.');
            return;
        end
        writetable(ecg_print.export.analysisTable(S.measurements.perSegment, ...
            edtSmooth.Value), fullfile(fp, fn));
        addLog(sprintf('Exported segment SNR CSV: %s', fullfile(fp, fn)));
    end

    function onExportWaveform()
        [fn, fp] = uiputfile('ecg_waveform.png', 'Export waveform PNG');
        if isequal(fn, 0)
            addLog('Waveform export cancelled.');
            return;
        end
        exportgraphics(ui.waveAxes, fullfile(fp, fn), 'Resolution', 300);
        addLog(sprintf('Exported waveform PNG: %s', fullfile(fp, fn)));
    end

    function refreshPlots()
        resetAxes();
        if isempty(S.workingSignal)
            return;
        end

        request = ecg_print.view.waveformPlotRequest( ...
            S.workingSignal, S.filteredSignal, S.events);
        ax = ui.waveAxes;
        plot(ax, request.x, request.y, 'Color', request.lineColor, 'LineWidth', 1);
        hold(ax, 'on');
        if ~isempty(request.peakX)
            scatter(ax, request.peakX, request.peakY, ...
                24, request.peakColor, 'filled');
        end
        hold(ax, 'off');
        title(ax, request.title);
        xlabel(ax, request.xLabel);
        ylabel(ax, request.yLabel);
        grid(ax, 'on');

        if isempty(S.measurements)
            return;
        end

        T = ecg_print.export.analysisTable(S.measurements.perSegment, ...
            edtSmooth.Value);
        smoothBeats = max(1, round(edtSmooth.Value));

        noiseAx = ui.noiseAxes;
        plot(noiseAx, T.EventTime, T.NoiseRMS, '.', 'MarkerSize', 12, ...
            'Color', [0.20 0.45 0.72]);
        hold(noiseAx, 'on');
        plot(noiseAx, T.EventTime, T.NoiseRMS_smooth, '-', ...
            'LineWidth', 1.5, 'Color', [0.05 0.20 0.45]);
        hold(noiseAx, 'off');
        title(noiseAx, sprintf('Template Noise RMS Over Time | Smooth=%d beats', smoothBeats));
        xlabel(noiseAx, 'Time (s)');
        ylabel(noiseAx, 'Noise RMS');
        grid(noiseAx, 'on');

        snrAx = ui.snrAxes;
        plot(snrAx, T.EventTime, T.SNRdB, '.', 'MarkerSize', 12, ...
            'Color', [0.18 0.55 0.32]);
        hold(snrAx, 'on');
        plot(snrAx, T.EventTime, T.SNRdB_smooth, '-', ...
            'LineWidth', 1.5, 'Color', [0.05 0.32 0.16]);
        hold(snrAx, 'off');
        title(snrAx, sprintf('Template SNR Over Time | Smooth=%d beats', smoothBeats));
        xlabel(snrAx, 'Time (s)');
        ylabel(snrAx, 'SNR (dB)');
        grid(snrAx, 'on');

        refreshTemplatePlot();
    end

    function updateSummary()
        summaryTable.Data = ecg_print.view.summaryRows( ...
            S.signal, S.events, S.segments, S.measurements);
    end

    function refreshTemplatePlot()
        ax = ui.templateAxes;
        labkit.ui.view.resetAxes(ui, 'previewAxes', ...
            'Template + Residual Band', true, 'template');
        xlabel(ax, 'Time from peak (s)');
        ylabel(ax, 'Amplitude');
        request = ecg_print.view.templatePlotRequest( ...
            S.segments, S.template, S.measurements, ddTemplateView.Value);
        if ~request.ok
            return;
        end

        hold(ax, 'on');
        if request.showSegments
            plot(ax, request.timeOffset, request.segments(:, request.showIndex), ...
                'Color', [0.78 0.84 0.92], 'LineWidth', 0.5);
        else
            fill(ax, [request.timeOffset; flipud(request.timeOffset)], ...
                [request.upper; flipud(request.lower)], [0.20 0.20 0.20], ...
                'FaceAlpha', 0.15, 'EdgeColor', 'none');
        end
        title(ax, request.title);
        plot(ax, request.timeOffset, request.template, 'k-', 'LineWidth', 2);
        xline(ax, 0, '--r', 'R');
        if ~isempty(request.signalWindowSec)
            shadeMeasurementWindows(ax, request);
        end
        hold(ax, 'off');
        grid(ax, 'on');
    end

    function shadeMeasurementWindows(ax, request)
        yl = ax.YLim;
        windowHandles = gobjects(0);
        windowHandles(end+1) = drawWindow(ax, request.signalWindowSec, yl, [1.00 0.20 0.20], 0.08);
        noiseWindows = request.noiseWindowsSec;
        for k = 1:size(noiseWindows, 1)
            windowHandles(end+1) = drawWindow(ax, noiseWindows(k, :), yl, [0.00 0.45 1.00], 0.08);
        end
        try
            uistack(windowHandles, 'bottom');
        catch
        end
    end

    function h = drawWindow(ax, windowSec, yl, color, alpha)
        h = fill(ax, [windowSec(1) windowSec(2) windowSec(2) windowSec(1)], ...
            [yl(1) yl(1) yl(2) yl(2)], color, ...
            'FaceAlpha', alpha, 'EdgeColor', 'none', ...
            'HitTest', 'off', 'PickableParts', 'none');
    end

    function resetAxes()
        labkit.ui.view.resetAxes(ui, 'previewAxes', ...
            'Waveform + Peaks', true, 'wave');
        xlabel(ui.waveAxes, 'Time (s)');
        ylabel(ui.waveAxes, 'Amplitude');
        labkit.ui.view.resetAxes(ui, 'previewAxes', ...
            'Template Noise RMS Over Time', true, 'noise');
        xlabel(ui.noiseAxes, 'Time (s)');
        ylabel(ui.noiseAxes, 'Noise RMS');
        labkit.ui.view.resetAxes(ui, 'previewAxes', ...
            'Template SNR Over Time', true, 'snr');
        xlabel(ui.snrAxes, 'Time (s)');
        ylabel(ui.snrAxes, 'SNR (dB)');
        labkit.ui.view.resetAxes(ui, 'previewAxes', ...
            'Template + Residual Band', true, 'template');
        xlabel(ui.templateAxes, 'Time from peak (s)');
        ylabel(ui.templateAxes, 'Amplitude');
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'appLog', message);
        debugLog.append(message);
    end

    function showError(titleText, message)
        uialert(fig, char(message), titleText);
        addLog(sprintf('%s: %s', titleText, message));
    end
end
