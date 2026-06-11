% App-owned runner for labkit_ECGPrint_app. Expected caller: labkit_ECGPrint_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = runApp(debugLog)
%RUNAPP Build and run the ECG Print app body.

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

    opts = struct( ...
        'rightTitle', 'ECG Preview', ...
        'rightGridSize', [4 1], ...
        'rightRowHeight', {{'1.2x', '1x', '1x', '1x'}}, ...
        'rightRowSpacing', 8);
    opts.tabs = [ ...
        labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', [6 1], ...
            {140, 255, 120, 235, 100, 125}), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {210, '1x'}), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];

    ui = labkit.ui.app.createShell(struct( ...
        'title', 'ECG Signal Print + SNR Explorer', ...
        'position', [80 70 1480 880], ...
        'leftWidth', 410, ...
        'options', opts));
    fig = ui.fig;

    callbacks = struct( ...
        'onOpenRecording', @onOpenRecording, ...
        'onPreviewHeader', @onPreviewHeader, ...
        'onImportOptionChanged', @onImportOptionChanged, ...
        'onRefreshImport', @onRefreshImport, ...
        'onChannelChanged', @onChannelChanged, ...
        'onAnalyze', @onAnalyze, ...
        'onExportSegments', @onExportSegments, ...
        'onExportWaveform', @onExportWaveform, ...
        'onRefreshPlots', @(~,~) refreshPlots());
    controls = ecg_print.ui.createControls(ui, callbacks);

    txtFile = controls.txtFile;
    txtImportStatus = controls.txtImportStatus;
    edtHeaderLine = controls.edtHeaderLine;
    ddHasHeader = controls.ddHasHeader;
    edtTimeColumn = controls.edtTimeColumn;
    ddTimeUnit = controls.ddTimeUnit;
    edtSignalColumns = controls.edtSignalColumns;
    edtFallbackFs = controls.edtFallbackFs;
    ddChannel = controls.ddChannel;
    edtStart = controls.edtStart;
    edtEnd = controls.edtEnd;
    edtLow = controls.edtLow;
    edtHigh = controls.edtHigh;
    ddPeakMethod = controls.ddPeakMethod;
    edtPeakDist = controls.edtPeakDist;
    edtWin = controls.edtWin;
    edtTopN = controls.edtTopN;
    edtSmooth = controls.edtSmooth;
    ddTemplateView = controls.ddTemplateView;
    summaryTable = controls.summaryTable;
    txtFilePreview = controls.txtFilePreview;
    txtLog = controls.txtLog;
    ui.waveAxes = controls.waveAxes;
    ui.noiseAxes = controls.noiseAxes;
    ui.snrAxes = controls.snrAxes;
    ui.templateAxes = controls.templateAxes;

    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('ECG print debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetAxes();

    function onOpenRecording(~, ~)
        [fn, fp] = uigetfile( ...
            {'*.mat;*.csv;*.txt;*.tsv', 'Biosignal files (*.mat, *.csv, *.txt, *.tsv)'; ...
            '*.*', 'All files'}, ...
            'Select biosignal recording');
        if isequal(fn, 0)
            addLog('Recording selection cancelled.');
            return;
        end

        S.filepath = string(fullfile(fp, fn));
        txtFile.Value = char(S.filepath);
        clearParsedRecording();
        updateFilePreview();
        refreshImportParsing(false);
    end

    function onRefreshImport(~, ~)
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

    function onPreviewHeader(~, ~)
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

    function onImportOptionChanged(~, ~)
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

    function onChannelChanged(~, ~)
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

    function onAnalyze(~, ~)
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

    function onExportSegments(~, ~)
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

    function onExportWaveform(~, ~)
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
        labkit.ui.view.draw(ax, 'reset', 'Template + Residual Band');
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
        labkit.ui.view.draw(ui.waveAxes, 'reset', 'Waveform + Peaks');
        xlabel(ui.waveAxes, 'Time (s)');
        ylabel(ui.waveAxes, 'Amplitude');
        labkit.ui.view.draw(ui.noiseAxes, 'reset', 'Template Noise RMS Over Time');
        xlabel(ui.noiseAxes, 'Time (s)');
        ylabel(ui.noiseAxes, 'Noise RMS');
        labkit.ui.view.draw(ui.snrAxes, 'reset', 'Template SNR Over Time');
        xlabel(ui.snrAxes, 'Time (s)');
        ylabel(ui.snrAxes, 'SNR (dB)');
        labkit.ui.view.draw(ui.templateAxes, 'reset', 'Template + Residual Band');
        xlabel(ui.templateAxes, 'Time from peak (s)');
        ylabel(ui.templateAxes, 'Amplitude');
    end

    function addLog(message)
        labkit.ui.view.update(txtLog, 'appendLog', message);
        debugLog.append(message);
    end

    function showError(titleText, message)
        uialert(fig, char(message), titleText);
        addLog(sprintf('%s: %s', titleText, message));
    end
end
