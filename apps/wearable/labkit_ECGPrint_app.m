function varargout = labkit_ECGPrint_app(varargin)
%LABKIT_ECGPRINT_APP Explore ECG quality, SNR, and printable waveforms.

    if nargin > 0
        error('labkit_ECGPrint_app:UnsupportedInput', ...
            'labkit_ECGPrint_app does not accept input arguments.');
    end
    if nargout > 1
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
    S.groupRows = table();

    opts = struct( ...
        'rightTitle', 'ECG Preview', ...
        'rightKind', 'dualPlot', ...
        'showPlotControls', false, ...
        'topPlotTitle', 'Waveform + Peaks', ...
        'bottomPlotTitle', 'SNR Over Time');
    opts.tabs = [ ...
        labkit.ui.tabSpec('filesAnalysis', 'Files + Analysis', [4 1], ...
            {210, 255, 250, 175}, ...
            struct('resizeRows', [1 2 3])), ...
        labkit.ui.tabSpec('summaryResults', 'Summary + Results', [3 1], ...
            {185, 185, '1x'}, ...
            struct('resizeRows', [1 2])), ...
        labkit.ui.tabSpec('log', 'Log', [1 1], {'1x'})];

    ui = labkit.ui.createWorkbench( ...
        'ECG Signal Print + SNR Explorer', [80 70 1480 880], 410, opts);
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    dataPanel = labkit.ui.createPanelGrid(layFA, 'Recording + Channel', 1, [6 2], ...
        struct('rowHeight', {{'fit','fit','fit','fit','fit','fit'}}, ...
        'columnWidth', {{135, '1x'}}));
    dataGrid = dataPanel.grid;

    btnOpen = uibutton(dataGrid, 'Text', 'Open recording', 'ButtonPushedFcn', @onOpenRecording);
    btnOpen.Layout.Row = 1;
    btnOpen.Layout.Column = [1 2];

    txtFile = uieditfield(dataGrid, 'text', 'Editable', 'off', 'Value', 'No file loaded');
    txtFile.Layout.Row = 2;
    txtFile.Layout.Column = [1 2];

    [lblChannel, ddChannel] = labkit.ui.createLabeledDropdown(dataGrid, 'Channel:', ...
        'Items', {'(none)'}, 'Value', '(none)', 'ValueChangedFcn', @onChannelChanged);
    lblChannel.Layout.Row = 3;
    lblChannel.Layout.Column = 1;
    ddChannel.Layout.Row = 3;
    ddChannel.Layout.Column = 2;

    [lblClass, edtClass] = labkit.ui.createLabeledEditField(dataGrid, ...
        'Class label:', 'text', 'Value', 'sample');
    lblClass.Layout.Row = 4;
    lblClass.Layout.Column = 1;
    edtClass.Layout.Row = 4;
    edtClass.Layout.Column = 2;

    [lblStart, edtStart] = labkit.ui.createLabeledEditField(dataGrid, ...
        'ROI start (s):', 'numeric', 'Value', 0, 'Limits', [0 Inf]);
    lblStart.Layout.Row = 5;
    lblStart.Layout.Column = 1;
    edtStart.Layout.Row = 5;
    edtStart.Layout.Column = 2;

    [lblEnd, edtEnd] = labkit.ui.createLabeledEditField(dataGrid, ...
        'ROI end (s):', 'numeric', 'Value', 0, 'Limits', [0 Inf]);
    lblEnd.Layout.Row = 6;
    lblEnd.Layout.Column = 1;
    edtEnd.Layout.Row = 6;
    edtEnd.Layout.Column = 2;

    procPanel = labkit.ui.createPanelGrid(layFA, 'Signal Processing + SNR', 2, [8 2], ...
        struct('rowHeight', {repmat({'fit'}, 1, 8)}, ...
        'columnWidth', {{135, '1x'}}));
    procGrid = procPanel.grid;

    [lblLow, edtLow] = labkit.ui.createLabeledEditField(procGrid, ...
        'Bandpass low Hz:', 'numeric', 'Value', 0.5, 'Limits', [0 Inf]);
    lblLow.Layout.Row = 1;
    lblLow.Layout.Column = 1;
    edtLow.Layout.Row = 1;
    edtLow.Layout.Column = 2;

    [lblHigh, edtHigh] = labkit.ui.createLabeledEditField(procGrid, ...
        'Bandpass high Hz:', 'numeric', 'Value', 40, 'Limits', [0 Inf]);
    lblHigh.Layout.Row = 2;
    lblHigh.Layout.Column = 1;
    edtHigh.Layout.Row = 2;
    edtHigh.Layout.Column = 2;

    [lblPeakDist, edtPeakDist] = labkit.ui.createLabeledEditField(procGrid, ...
        'Peak distance (s):', 'numeric', 'Value', 0.28, 'Limits', [0.01 Inf]);
    lblPeakDist.Layout.Row = 3;
    lblPeakDist.Layout.Column = 1;
    edtPeakDist.Layout.Row = 3;
    edtPeakDist.Layout.Column = 2;

    [lblWin, edtWin] = labkit.ui.createLabeledEditField(procGrid, ...
        'Segment half win (s):', 'numeric', 'Value', 0.7, 'Limits', [0.01 Inf]);
    lblWin.Layout.Row = 4;
    lblWin.Layout.Column = 1;
    edtWin.Layout.Row = 4;
    edtWin.Layout.Column = 2;

    [lblTopN, edtTopN] = labkit.ui.createLabeledEditField(procGrid, ...
        'Template top N:', 'numeric', 'Value', 30, 'Limits', [1 Inf]);
    lblTopN.Layout.Row = 5;
    lblTopN.Layout.Column = 1;
    edtTopN.Layout.Row = 5;
    edtTopN.Layout.Column = 2;

    [lblView, ddBottomView] = labkit.ui.createLabeledDropdown(procGrid, ...
        'Bottom plot:', ...
        'Items', {'SNR over time', 'Template + segments'}, ...
        'Value', 'SNR over time', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lblView.Layout.Row = 6;
    lblView.Layout.Column = 1;
    ddBottomView.Layout.Row = 6;
    ddBottomView.Layout.Column = 2;

    btnAnalyze = uibutton(procGrid, 'Text', 'Analyze current ROI', ...
        'ButtonPushedFcn', @onAnalyze);
    btnAnalyze.Layout.Row = 7;
    btnAnalyze.Layout.Column = [1 2];

    btnAddGroup = uibutton(procGrid, 'Text', 'Add current SNR to class comparison', ...
        'ButtonPushedFcn', @onAddToComparison);
    btnAddGroup.Layout.Row = 8;
    btnAddGroup.Layout.Column = [1 2];

    exportPanel = labkit.ui.createPanelGrid(layFA, 'Exports', 3, [4 1], ...
        struct('rowHeight', {{'fit','fit','fit','fit'}}));
    exportGrid = exportPanel.grid;
    btnExportSegments = uibutton(exportGrid, 'Text', 'Export segment SNR CSV', ...
        'ButtonPushedFcn', @onExportSegments);
    btnExportSegments.Layout.Row = 1;
    btnExportStats = uibutton(exportGrid, 'Text', 'Export class stats CSV', ...
        'ButtonPushedFcn', @onExportStats);
    btnExportStats.Layout.Row = 2;
    btnExportOverlay = uibutton(exportGrid, 'Text', 'Export waveform PNG', ...
        'ButtonPushedFcn', @onExportWaveform);
    btnExportOverlay.Layout.Row = 3;
    btnClearGroups = uibutton(exportGrid, 'Text', 'Clear class comparison', ...
        'ButtonPushedFcn', @onClearGroups);
    btnClearGroups.Layout.Row = 4;

    notePanel = labkit.ui.createPanelGrid(layFA, 'Workflow Notes', 4, [1 1], ...
        struct('rowHeight', {{'1x'}}));
    txtNotes = uitextarea(notePanel.grid, 'Editable', 'off');
    txtNotes.Value = { ...
        '1. Open MAT/CSV data, select a numeric channel, and optionally set a time ROI.', ...
        '2. Analyze current ROI to filter, detect peaks, segment beats, build a template, and compute SNR.', ...
        '3. Add analyses to class comparison with class labels, then export segment SNR or group statistics.'};

    summaryTable = uitable(laySR, 'ColumnName', {'Metric','Value'}, ...
        'Data', initialSummaryRows());
    summaryTable.Layout.Row = labkit.ui.layoutRow(laySR, 1);

    classTable = uitable(laySR, 'ColumnName', {'Group','N','Mean','Std','Median','Min','Max'}, ...
        'Data', cell(0, 7));
    classTable.Layout.Row = labkit.ui.layoutRow(laySR, 2);

    pairTable = uitable(laySR, 'ColumnName', {'GroupA','GroupB','MeanDiff','T','DF','P'}, ...
        'Data', cell(0, 6));
    pairTable.Layout.Row = labkit.ui.layoutRow(laySR, 3);

    logUi = labkit.ui.createLogPanel(layLog, 1, {'Ready.'});
    txtLog = logUi.textArea;

    resetAxes();
    if nargout == 1
        varargout{1} = fig;
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

        filepath = fullfile(fp, fn);
        [recording, status] = labkit.biosignal.readRecording(filepath, struct('fallbackFs', 2000));
        if ~status.ok
            showError('Could not read recording', status.message);
            return;
        end

        S.recording = recording;
        txtFile.Value = filepath;
        channels = labkit.biosignal.listChannels(recording);
        ddChannel.Items = channels;
        ddChannel.Value = channels{1};
        setCurrentChannel(channels{1});
        addLog(sprintf('Loaded %d channel(s) from %s', numel(channels), filepath));
    end

    function onChannelChanged(~, ~)
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
            if timeRange(2) > timeRange(1)
                S.workingSignal = labkit.biosignal.cropSignal(S.signal, timeRange);
            else
                S.workingSignal = S.signal;
            end

            highCut = min(edtHigh.Value, max(edtLow.Value + eps, 0.45 * S.workingSignal.fs));
            filterSpec = struct('type', 'bandpass', 'cutoffHz', [edtLow.Value highCut]);
            S.filteredSignal = labkit.biosignal.filterSignal(S.workingSignal, filterSpec);
            peakOpts = struct('polarity', 'auto', ...
                'minDistanceSec', edtPeakDist.Value, ...
                'thresholdStd', 2.8);
            S.events = labkit.biosignal.detectPeaks(S.filteredSignal, peakOpts);
            halfWin = edtWin.Value;
            S.segments = labkit.biosignal.segmentByEvents(S.filteredSignal, S.events, [-halfWin halfWin]);
            S.template = labkit.biosignal.buildTemplate(S.segments, struct('topN', edtTopN.Value));
            S.measurements = labkit.biosignal.measureSegments(S.segments, S.template);

            addLog(sprintf('Analyzed ROI: %d peaks, %d valid segments.', ...
                numel(S.events.index), size(S.segments.values, 2)));
            updateSummary();
            refreshPlots();
        catch ME
            showError('Analysis failed', ME.message);
        end
    end

    function onAddToComparison(~, ~)
        if isempty(S.measurements) || isempty(S.measurements.perSegment)
            showError('No SNR result', 'Analyze a signal before adding it to class comparison.');
            return;
        end
        label = string(strtrim(edtClass.Value));
        if strlength(label) == 0
            showError('Missing class label', 'Enter a class label before adding SNR values.');
            return;
        end

        T = S.measurements.perSegment;
        rows = table(repmat(label, height(T), 1), T.EventTime, T.SNRdB, ...
            repmat(string(S.filteredSignal.displayName), height(T), 1), ...
            'VariableNames', {'Group','EventTime','SNRdB','Channel'});
        if isempty(S.groupRows)
            S.groupRows = rows;
        else
            S.groupRows = [S.groupRows; rows];
        end
        addLog(sprintf('Added %d SNR values to class "%s".', height(rows), label));
        refreshGroupStats();
    end

    function onClearGroups(~, ~)
        S.groupRows = table();
        refreshGroupStats();
        addLog('Cleared class comparison data.');
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
        writetable(S.measurements.perSegment, fullfile(fp, fn));
        addLog(sprintf('Exported segment SNR CSV: %s', fullfile(fp, fn)));
    end

    function onExportStats(~, ~)
        if isempty(S.groupRows)
            showError('No class comparison', 'Add one or more analyzed classes before exporting stats.');
            return;
        end
        [fn, fp] = uiputfile('ecg_class_snr_stats.csv', 'Export class stats CSV');
        if isequal(fn, 0)
            addLog('Class stats export cancelled.');
            return;
        end
        stats = labkit.biosignal.compareGroups(S.groupRows.SNRdB, S.groupRows.Group);
        writetable(stats.summary, fullfile(fp, fn));
        [stemPath, stemName] = fileparts(fullfile(fp, fn));
        pairPath = fullfile(stemPath, [stemName '_pairwise.csv']);
        writetable(stats.pairwise, pairPath);
        addLog(sprintf('Exported class stats CSV: %s', fullfile(fp, fn)));
    end

    function onExportWaveform(~, ~)
        [fn, fp] = uiputfile('ecg_waveform.png', 'Export waveform PNG');
        if isequal(fn, 0)
            addLog('Waveform export cancelled.');
            return;
        end
        exportgraphics(ui.topAxes, fullfile(fp, fn), 'Resolution', 300);
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

        ax = ui.topAxes;
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

        bottom = ui.bottomAxes;
        if isempty(S.measurements)
            return;
        end

        if strcmp(ddBottomView.Value, 'Template + segments')
            X = S.segments.values;
            t = S.segments.timeOffset;
            if ~isempty(X)
                plot(bottom, t, X, 'Color', [0.78 0.84 0.92], 'LineWidth', 0.5);
                hold(bottom, 'on');
                plot(bottom, S.template.timeOffset, S.template.values, ...
                    'k-', 'LineWidth', 2);
                hold(bottom, 'off');
            end
            title(bottom, 'Template + Segments');
            xlabel(bottom, 'Time from peak (s)');
            ylabel(bottom, char(sig.name));
        else
            T = S.measurements.perSegment;
            plot(bottom, T.EventTime, T.SNRdB, 'o-', ...
                'Color', [0.18 0.55 0.32], 'MarkerFaceColor', [0.18 0.55 0.32]);
            title(bottom, 'SNR Over Time');
            xlabel(bottom, 'Time (s)');
            ylabel(bottom, 'SNR (dB)');
        end
        grid(bottom, 'on');
    end

    function updateSummary()
        summaryTable.Data = buildSummaryRows();
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
            rows = [rows; {'Detected peaks', sprintf('%d', numel(S.events.index))}];
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

    function refreshGroupStats()
        if isempty(S.groupRows)
            classTable.Data = cell(0, 7);
            pairTable.Data = cell(0, 6);
            return;
        end
        stats = labkit.biosignal.compareGroups(S.groupRows.SNRdB, S.groupRows.Group);
        classTable.Data = tableToCell(stats.summary);
        pairTable.Data = tableToCell(stats.pairwise);
    end

    function resetAxes()
        labkit.ui.hardResetAxis(ui.topAxes, 'Waveform + Peaks');
        xlabel(ui.topAxes, 'Time (s)');
        ylabel(ui.topAxes, 'Amplitude');
        labkit.ui.hardResetAxis(ui.bottomAxes, 'SNR Over Time');
        xlabel(ui.bottomAxes, 'Time (s)');
        ylabel(ui.bottomAxes, 'SNR (dB)');
    end

    function addLog(message)
        labkit.ui.appendLog(txtLog, message);
    end

    function showError(titleText, message)
        uialert(fig, char(message), titleText);
        addLog(sprintf('%s: %s', titleText, message));
    end
end

function rows = initialSummaryRows()
    rows = {'Status', 'No signal analyzed'};
end

function C = tableToCell(T)
    C = table2cell(T);
    for k = 1:numel(C)
        if isstring(C{k})
            C{k} = char(C{k});
        end
    end
end
