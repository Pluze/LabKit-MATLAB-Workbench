function varargout = labkit_ECGPrint_app(varargin)
%LABKIT_ECGPRINT_APP Explore ECG quality, SNR, and printable waveforms.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ECGPrint_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ECGPrint_app:TooManyOutputs', ...
                'labkit_ECGPrint_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ECGPrint_app:TooManyOutputs', ...
            'labkit_ECGPrint_app returns at most the app figure handle.');
    end

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
            {140, 255, 120, 235, 100, 125}, ...
            struct('resizeRows', [1 2 3 4 5])), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {210, '1x'}, ...
            struct('resizeRows', 1)), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];

    ui = labkit.ui.app.createShell(struct( ...
        'title', 'ECG Signal Print + SNR Explorer', ...
        'position', [80 70 1480 880], ...
        'leftWidth', 410, ...
        'options', opts));
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    recordingPanel = labkit.ui.view.section(layFA, 'Recording', 1, [3 2], ...
        struct('rowHeight', {repmat({'fit'}, 1, 3)}, ...
        'columnWidth', {{135, '1x'}}));
    recordingGrid = recordingPanel.grid;

    btnOpen = uibutton(recordingGrid, 'Text', 'Open recording', 'ButtonPushedFcn', @onOpenRecording);
    btnOpen.Layout.Row = 1;
    btnOpen.Layout.Column = [1 2];

    txtFile = labkit.ui.view.form(recordingGrid, 'readonly', 'Value', 'No file loaded');
    txtFile.Layout.Row = 2;
    txtFile.Layout.Column = [1 2];

    btnPreviewHeader = uibutton(recordingGrid, 'Text', 'Preview file header', ...
        'ButtonPushedFcn', @onPreviewHeader);
    btnPreviewHeader.Layout.Row = 3;
    btnPreviewHeader.Layout.Column = [1 2];

    importPanel = labkit.ui.view.section(layFA, 'Import Parsing', 2, [8 2], ...
        struct('rowHeight', {repmat({'fit'}, 1, 8)}, ...
        'columnWidth', {{135, '1x'}}));
    importGrid = importPanel.grid;

    txtImportStatus = labkit.ui.view.form(importGrid, 'readonly', ...
        'Value', 'Open a recording to inspect import settings.');
    txtImportStatus.Layout.Row = 1;
    txtImportStatus.Layout.Column = [1 2];

    [lblHeaderLine, edtHeaderLine] = labkit.ui.view.form(importGrid, 'spinner', ...
        'CSV header line:', 'Value', 0, 'Limits', [0 Inf], 'Step', 1, ...
        'ValueChangedFcn', @onImportOptionChanged);
    lblHeaderLine.Layout.Row = 2;
    lblHeaderLine.Layout.Column = 1;
    edtHeaderLine.Layout.Row = 2;
    edtHeaderLine.Layout.Column = 2;

    [lblHasHeader, ddHasHeader] = labkit.ui.view.form(importGrid, 'dropdown', ...
        'CSV header:', ...
        'Items', {'Auto', 'Yes', 'No'}, ...
        'Value', 'Auto', ...
        'ValueChangedFcn', @onImportOptionChanged);
    lblHasHeader.Layout.Row = 3;
    lblHasHeader.Layout.Column = 1;
    ddHasHeader.Layout.Row = 3;
    ddHasHeader.Layout.Column = 2;

    [lblTimeColumn, edtTimeColumn] = labkit.ui.view.form(importGrid, 'edit', ...
        'Time column:', 'text', 'Value', '', ...
        'ValueChangedFcn', @onImportOptionChanged);
    lblTimeColumn.Layout.Row = 4;
    lblTimeColumn.Layout.Column = 1;
    edtTimeColumn.Layout.Row = 4;
    edtTimeColumn.Layout.Column = 2;

    [lblTimeUnit, ddTimeUnit] = labkit.ui.view.form(importGrid, 'dropdown', ...
        'Time unit:', ...
        'Items', {'Auto', 'seconds', 'milliseconds', 'microseconds', 'nanoseconds'}, ...
        'Value', 'Auto', ...
        'ValueChangedFcn', @onImportOptionChanged);
    lblTimeUnit.Layout.Row = 5;
    lblTimeUnit.Layout.Column = 1;
    ddTimeUnit.Layout.Row = 5;
    ddTimeUnit.Layout.Column = 2;

    [lblSignalColumns, edtSignalColumns] = labkit.ui.view.form(importGrid, 'edit', ...
        'Signal columns:', 'text', 'Value', '', ...
        'ValueChangedFcn', @onImportOptionChanged);
    lblSignalColumns.Layout.Row = 6;
    lblSignalColumns.Layout.Column = 1;
    edtSignalColumns.Layout.Row = 6;
    edtSignalColumns.Layout.Column = 2;

    [lblFallbackFs, edtFallbackFs] = labkit.ui.view.form(importGrid, 'spinner', ...
        'Fallback Fs:', 'Value', 2000, 'Limits', [0 Inf], 'Step', 100, ...
        'ValueChangedFcn', @onImportOptionChanged);
    lblFallbackFs.Layout.Row = 7;
    lblFallbackFs.Layout.Column = 1;
    edtFallbackFs.Layout.Row = 7;
    edtFallbackFs.Layout.Column = 2;

    btnRefreshImport = uibutton(importGrid, 'Text', 'Parse / refresh file', ...
        'ButtonPushedFcn', @onRefreshImport);
    btnRefreshImport.Layout.Row = 8;
    btnRefreshImport.Layout.Column = [1 2];

    channelPanel = labkit.ui.view.section(layFA, 'Channel + ROI', 3, [3 2], ...
        struct('rowHeight', {repmat({'fit'}, 1, 3)}, ...
        'columnWidth', {{135, '1x'}}));
    channelGrid = channelPanel.grid;

    [lblChannel, ddChannel] = labkit.ui.view.form(channelGrid, 'dropdown', 'Channel:', ...
        'Items', {'(none)'}, 'Value', '(none)', 'ValueChangedFcn', @onChannelChanged);
    lblChannel.Layout.Row = 1;
    lblChannel.Layout.Column = 1;
    ddChannel.Layout.Row = 1;
    ddChannel.Layout.Column = 2;

    [lblStart, edtStart] = labkit.ui.view.form(channelGrid, 'spinner', ...
        'ROI start (s):', 'Value', 0, 'Limits', [0 Inf], 'Step', 1);
    lblStart.Layout.Row = 2;
    lblStart.Layout.Column = 1;
    edtStart.Layout.Row = 2;
    edtStart.Layout.Column = 2;

    [lblEnd, edtEnd] = labkit.ui.view.form(channelGrid, 'spinner', ...
        'ROI end (s):', 'Value', 0, 'Limits', [0 Inf], 'Step', 1);
    lblEnd.Layout.Row = 3;
    lblEnd.Layout.Column = 1;
    edtEnd.Layout.Row = 3;
    edtEnd.Layout.Column = 2;

    procPanel = labkit.ui.view.section(layFA, 'Signal Processing + SNR', 4, [9 2], ...
        struct('rowHeight', {repmat({'fit'}, 1, 9)}, ...
        'columnWidth', {{135, '1x'}}));
    procGrid = procPanel.grid;

    [lblLow, edtLow] = labkit.ui.view.form(procGrid, 'spinner', ...
        'Bandpass low Hz:', 'Value', 0.5, 'Limits', [0 Inf], 'Step', 0.1);
    lblLow.Layout.Row = 1;
    lblLow.Layout.Column = 1;
    edtLow.Layout.Row = 1;
    edtLow.Layout.Column = 2;

    [lblHigh, edtHigh] = labkit.ui.view.form(procGrid, 'spinner', ...
        'Bandpass high Hz:', 'Value', 40, 'Limits', [0 Inf], 'Step', 1);
    lblHigh.Layout.Row = 2;
    lblHigh.Layout.Column = 1;
    edtHigh.Layout.Row = 2;
    edtHigh.Layout.Column = 2;

    [lblPeakMethod, ddPeakMethod] = labkit.ui.view.form(procGrid, 'dropdown', ...
        'Peak method:', ...
        'Items', {'QRS streaming', 'Pan-Tompkins', 'Local peaks'}, ...
        'Value', 'QRS streaming');
    lblPeakMethod.Layout.Row = 3;
    lblPeakMethod.Layout.Column = 1;
    ddPeakMethod.Layout.Row = 3;
    ddPeakMethod.Layout.Column = 2;

    [lblPeakDist, edtPeakDist] = labkit.ui.view.form(procGrid, 'spinner', ...
        'Peak distance (s):', 'Value', 0.28, 'Limits', [0.01 Inf], 'Step', 0.01);
    lblPeakDist.Layout.Row = 4;
    lblPeakDist.Layout.Column = 1;
    edtPeakDist.Layout.Row = 4;
    edtPeakDist.Layout.Column = 2;

    [lblWin, edtWin] = labkit.ui.view.form(procGrid, 'spinner', ...
        'Segment half win (s):', 'Value', 0.7, 'Limits', [0.01 Inf], 'Step', 0.05);
    lblWin.Layout.Row = 5;
    lblWin.Layout.Column = 1;
    edtWin.Layout.Row = 5;
    edtWin.Layout.Column = 2;

    [lblTopN, edtTopN] = labkit.ui.view.form(procGrid, 'spinner', ...
        'Template top N:', 'Value', 30, 'Limits', [1 Inf], 'Step', 1);
    lblTopN.Layout.Row = 6;
    lblTopN.Layout.Column = 1;
    edtTopN.Layout.Row = 6;
    edtTopN.Layout.Column = 2;

    [lblSmooth, edtSmooth] = labkit.ui.view.form(procGrid, 'spinner', ...
        'Smooth beats:', 'Value', 15, 'Limits', [1 Inf], 'Step', 1, ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lblSmooth.Layout.Row = 7;
    lblSmooth.Layout.Column = 1;
    edtSmooth.Layout.Row = 7;
    edtSmooth.Layout.Column = 2;

    [lblView, ddTemplateView] = labkit.ui.view.form(procGrid, 'dropdown', ...
        'Template plot:', ...
        'Items', {'Template + residual band', 'Template + segments'}, ...
        'Value', 'Template + residual band', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lblView.Layout.Row = 8;
    lblView.Layout.Column = 1;
    ddTemplateView.Layout.Row = 8;
    ddTemplateView.Layout.Column = 2;

    btnAnalyze = uibutton(procGrid, 'Text', 'Analyze current ROI', ...
        'ButtonPushedFcn', @onAnalyze);
    btnAnalyze.Layout.Row = 9;
    btnAnalyze.Layout.Column = [1 2];

    exportPanel = labkit.ui.view.section(layFA, 'Exports', 5, [2 1], ...
        struct('rowHeight', {{'fit','fit'}}));
    exportGrid = exportPanel.grid;
    btnExportSegments = uibutton(exportGrid, 'Text', 'Export segment SNR CSV', ...
        'ButtonPushedFcn', @onExportSegments);
    btnExportSegments.Layout.Row = 1;
    btnExportOverlay = uibutton(exportGrid, 'Text', 'Export waveform PNG', ...
        'ButtonPushedFcn', @onExportWaveform);
    btnExportOverlay.Layout.Row = 2;

    labkit.ui.view.panel(layFA, 'text', 'Workflow Notes', 6, { ...
        '1. Open MAT/CSV data, select a numeric channel, and optionally set a time ROI.', ...
        '2. Use File Header Preview and Import Parsing only when CSV/text auto-detection needs correction.', ...
        '3. Analysis filters the selected channel with edge padding, then crops the filtered signal to the ROI for peak/SNR measurement.'});

    summaryTable = uitable(laySR, 'ColumnName', {'Metric','Value'}, ...
        'Data', initialSummaryRows());
    labkit.ui.view.place(summaryTable, laySR, 1);

    previewUi = labkit.ui.view.panel(laySR, 'text', 'File Header Preview', 2, ...
        {'Open a CSV/text file, then use Preview file header.'});
    txtFilePreview = previewUi.textArea;

    logUi = labkit.ui.view.panel(layLog, 'log', 1, {'Ready.'});
    txtLog = logUi.textArea;

    ui.waveAxes = uiaxes(ui.rightGrid);
    ui.waveAxes.Layout.Row = 1;
    ui.noiseAxes = uiaxes(ui.rightGrid);
    ui.noiseAxes.Layout.Row = 2;
    ui.snrAxes = uiaxes(ui.rightGrid);
    ui.snrAxes.Layout.Row = 3;
    ui.templateAxes = uiaxes(ui.rightGrid);
    ui.templateAxes.Layout.Row = 4;

    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('ECG print debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetAxes();
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

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

        importOpts = currentImportOptions();
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
        txtImportStatus.Value = importStatusText(recording, numel(channels));
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
        txtFilePreview.Value = previewFileHeader(char(S.filepath), 18);
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

    function optsOut = currentImportOptions()
        optsOut = struct('fallbackFs', edtFallbackFs.Value);
        if edtHeaderLine.Value > 0
            optsOut.headerLine = round(edtHeaderLine.Value);
        end
        switch string(ddHasHeader.Value)
            case "Yes"
                optsOut.hasHeader = true;
            case "No"
                optsOut.hasHeader = false;
        end
        if strlength(strtrim(string(edtTimeColumn.Value))) > 0
            optsOut.timeColumn = parseColumnSpec(edtTimeColumn.Value);
        end
        if string(ddTimeUnit.Value) ~= "Auto"
            optsOut.timeUnit = ddTimeUnit.Value;
        end
        if strlength(strtrim(string(edtSignalColumns.Value))) > 0
            optsOut.signalColumns = parseColumnList(edtSignalColumns.Value);
        end
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
                'method', peakMethodValue(ddPeakMethod.Value), ...
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
        writetable(analysisTable(), fullfile(fp, fn));
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

        sig = S.workingSignal;
        if ~isempty(S.filteredSignal)
            sig = S.filteredSignal;
        end

        ax = ui.waveAxes;
        plot(ax, sig.time, sig.values, 'Color', [0.15 0.38 0.72], 'LineWidth', 1);
        hold(ax, 'on');
        if ~isempty(S.events) && ~isempty(S.events.index)
            scatter(ax, sig.time(S.events.index), sig.values(S.events.index), ...
                24, [0.85 0.25 0.15], 'filled');
        end
        hold(ax, 'off');
        title(ax, 'Waveform + Peaks');
        xlabel(ax, 'Time (s)');
        ylabel(ax, char(sig.name));
        grid(ax, 'on');

        if isempty(S.measurements)
            return;
        end

        T = analysisTable();
        smoothBeats = max(1, round(edtSmooth.Value));

        noiseAx = ui.noiseAxes;
        plot(noiseAx, T.EventTime, T.NoiseRMS, '.', 'MarkerSize', 12, ...
            'Color', [0.20 0.45 0.72]);
        hold(noiseAx, 'on');
        plot(noiseAx, T.EventTime, movingMedian(T.NoiseRMS, smoothBeats), '-', ...
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
        plot(snrAx, T.EventTime, movingMedian(T.SNRdB, smoothBeats), '-', ...
            'LineWidth', 1.5, 'Color', [0.05 0.32 0.16]);
        hold(snrAx, 'off');
        title(snrAx, sprintf('Template SNR Over Time | Smooth=%d beats', smoothBeats));
        xlabel(snrAx, 'Time (s)');
        ylabel(snrAx, 'SNR (dB)');
        grid(snrAx, 'on');

        refreshTemplatePlot();
    end

    function updateSummary()
        summaryTable.Data = buildSummaryRows();
    end

    function refreshTemplatePlot()
        ax = ui.templateAxes;
        labkit.ui.view.draw(ax, 'reset', 'Template + Residual Band');
        xlabel(ax, 'Time from peak (s)');
        ylabel(ax, 'Amplitude');
        if isempty(S.segments) || isempty(S.template) || isempty(S.segments.values)
            return;
        end

        X = double(S.segments.values);
        t = double(S.segments.timeOffset(:));
        template = double(S.template.values(:));
        if isempty(X) || isempty(template)
            return;
        end

        hold(ax, 'on');
        if strcmp(ddTemplateView.Value, 'Template + segments')
            maxShow = min(40, size(X, 2));
            showIdx = unique(round(linspace(1, size(X, 2), maxShow)));
            plot(ax, t, X(:, showIdx), 'Color', [0.78 0.84 0.92], 'LineWidth', 0.5);
            title(ax, 'Template + Segments');
        else
            residStd = std(X - template, 0, 2, 'omitnan');
            upper = template + residStd;
            lower = template - residStd;
            fill(ax, [t; flipud(t)], [upper; flipud(lower)], [0.20 0.20 0.20], ...
                'FaceAlpha', 0.15, 'EdgeColor', 'none');
            title(ax, 'Template + Residual Band');
        end
        plot(ax, t, template, 'k-', 'LineWidth', 2);
        xline(ax, 0, '--r', 'R');
        if strcmp(ddTemplateView.Value, 'Template + residual band')
            shadeMeasurementWindows(ax);
        end
        hold(ax, 'off');
        grid(ax, 'on');
    end

    function shadeMeasurementWindows(ax)
        if isempty(S.measurements) || ~isfield(S.measurements, 'metadata')
            return;
        end
        meta = S.measurements.metadata;
        if ~isfield(meta, 'signalWindowSec') || ~isfield(meta, 'noiseWindowsSec')
            return;
        end
        yl = ax.YLim;
        windowHandles = gobjects(0);
        windowHandles(end+1) = drawWindow(ax, meta.signalWindowSec, yl, [1.00 0.20 0.20], 0.08);
        noiseWindows = meta.noiseWindowsSec;
        for k = 1:size(noiseWindows, 1)
            windowHandles(end+1) = drawWindow(ax, noiseWindows(k, :), yl, [0.00 0.45 1.00], 0.08);
        end
        try
            uistack(windowHandles, 'bottom');
        catch
        end
    end

    function T = analysisTable()
        T = S.measurements.perSegment;
        smoothBeats = max(1, round(edtSmooth.Value));
        T.SignalP2P_smooth = movingMedian(T.SignalP2P, smoothBeats);
        T.NoiseRMS_smooth = movingMedian(T.NoiseRMS, smoothBeats);
        T.SNRdB_smooth = movingMedian(T.SNRdB, smoothBeats);
    end

    function rows = buildSummaryRows()
        rows = initialSummaryRows();
        if ~isempty(S.signal)
            rows = [rows; {
                'Channel', char(S.signal.displayName);
                'Samples', sprintf('%d', numel(S.signal.values));
                'Estimated Fs (Hz)', sprintf('%.3g', S.signal.fs);
                'Duration (s)', sprintf('%.3g', max(S.signal.time) - min(S.signal.time))}];
        end
        if ~isempty(S.events)
            methodLabel = '';
            if isfield(S.events, 'metadata') && isfield(S.events.metadata, 'method')
                methodLabel = sprintf(' (%s)', char(S.events.metadata.method));
            end
            rows = [rows; {'Detected peaks', sprintf('%d%s', numel(S.events.index), methodLabel)}];
        end
        if ~isempty(S.segments)
            rows = [rows; {'Valid segments', sprintf('%d', size(S.segments.values, 2))}];
        end
        if ~isempty(S.measurements) && ~isempty(S.measurements.summary)
            M = S.measurements.summary;
            rows = [rows; {
                'Mean SNR (dB)', sprintf('%.3g', M.SNRdBMean);
                'SNR std (dB)', sprintf('%.3g', M.SNRdBStd);
                'Mean template corr.', sprintf('%.3g', M.TemplateCorrelationMean)}];
        end
    end

    function y = movingMedian(x, width)
        x = double(x(:));
        width = max(1, round(width));
        y = nan(size(x));
        for i = 1:numel(x)
            i1 = max(1, i - floor((width - 1) / 2));
            i2 = min(numel(x), i + ceil((width - 1) / 2));
            y(i) = median(x(i1:i2), 'omitnan');
        end
    end

    function value = parseColumnSpec(textValue)
        textValue = strtrim(string(textValue));
        numericValue = str2double(textValue);
        if isfinite(numericValue) && numericValue == floor(numericValue)
            value = numericValue;
        else
            value = char(textValue);
        end
    end

    function values = parseColumnList(textValue)
        parts = split(string(textValue), {',', ';'});
        parts = strtrim(parts);
        parts = parts(strlength(parts) > 0);
        numericValues = str2double(parts);
        if all(isfinite(numericValues)) && all(numericValues == floor(numericValues))
            values = numericValues(:).';
        else
            values = cellstr(parts);
        end
    end

    function method = peakMethodValue(label)
        switch string(label)
            case "Pan-Tompkins"
                method = "pan-tompkins";
            case "Local peaks"
                method = "local";
            otherwise
                method = "qrs-streaming";
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

function rows = initialSummaryRows()
    rows = {'Status', 'No signal analyzed'};
end

function text = importStatusText(recording, channelCount)
    meta = recording.metadata;
    pieces = strings(1, 0);
    pieces(end+1) = sprintf('%d channel(s)', channelCount);
    if isfield(meta, 'timeColumn') && strlength(string(meta.timeColumn)) > 0
        pieces(end+1) = "time: " + string(meta.timeColumn);
    end
    if isfield(meta, 'timeUnit')
        pieces(end+1) = "unit: " + string(meta.timeUnit);
    end
    if isfield(meta, 'timeSource')
        pieces(end+1) = "source: " + string(meta.timeSource);
    end
    if isfield(meta, 'timeRepair')
        repair = meta.timeRepair;
        if isfield(repair, 'repairedBackwardCount') && repair.repairedBackwardCount > 0
            pieces(end+1) = sprintf('repaired backward: %d', repair.repairedBackwardCount);
        end
        if isfield(repair, 'largeGapCount') && repair.largeGapCount > 0
            pieces(end+1) = sprintf('large gaps: %d', repair.largeGapCount);
        end
    end
    text = char(strjoin(pieces, ' | '));
end

function lines = previewFileHeader(filepath, maxLines)
    lines = {};
    fid = fopen(filepath, 'r');
    if fid < 0
        lines = {'Could not open file preview.'};
        return;
    end
    cleaner = onCleanup(@() fclose(fid));
    for k = 1:maxLines
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        lines{end+1, 1} = sprintf('%02d: %s', k, line); %#ok<AGROW>
    end
    if isempty(lines)
        lines = {'File is empty or could not be previewed.'};
    end
end
