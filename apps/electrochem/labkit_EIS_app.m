function varargout = labkit_EIS_app(varargin)
%LABKIT_EIS_APP EIS overlay/export app.
% Single-file app that composes +labkit GUI/DTA APIs and owns EIS workflow choices.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_EIS_app', varargin, nargout, eisAppTestHandlers());
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_EIS_app:TooManyOutputs', ...
                'labkit_EIS_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_EIS_app:TooManyOutputs', 'labkit_EIS_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = labkit.dta.makeSession('eis_overlay');
    S.items = S.session.items;

    axisItems = { ...
        'Freq (Hz)', ...
        'log10(Freq)', ...
        'Time (s)', ...
        'Point #', ...
        'Zreal (ohm)', ...
        'Zimag (ohm)', ...
        '-Zimag (ohm)', ...
        'Zmod (ohm)', ...
        'Zphz (deg)', ...
        'Idc (A)', ...
        'Vdc (V)'};

    workbenchOpts = struct();
    workbenchOpts.rightTitle = 'Plot';
    workbenchOpts.rightGridSize = [1 1];
    workbenchOpts.rightRowHeight = {'1x'};
    workbenchOpts.rightRowSpacing = 8;
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Gamry EIS Multi-DTA Plot GUI', ...
        'position', [80 60 1500 900], ...
        'leftWidth', 360, ...
        'options', workbenchOpts));
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    right = ui.rightGrid;

    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onRemoveSelected = @onRemoveSelected;
    fileCallbacks.onClearAll = @onClearAll;
    fileCallbacks.onExport = @onExportCSV;
    fileCallbacks.onSelectFile = @(~,~) refreshPlot();
    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'removeSelected', 'Remove selected', ...
        'clearAll', 'Clear all', ...
        'export', 'Export current plot CSV', ...
        'loadedText', 'No files loaded');
    fileUi = labkit.ui.view.panel(layFA, 'files', fileLabels, fileCallbacks, ...
        struct('showRemoveSelected', true, 'multiselect', 'on'));
    lbFiles = fileUi.listbox;
    txtLoaded = fileUi.loadedText;

    plotOptionsUi = labkit.ui.view.panel(layFA, 'plotOptions', 8, 2);
    gp = plotOptionsUi.grid;

    [~, ddX] = labkit.ui.view.form(gp, 'dropdown', 'X axis:', ...
        'Items', axisItems, ...
        'Value', 'Zreal (ohm)', ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    [~, ddY] = labkit.ui.view.form(gp, 'dropdown', 'Y axis:', ...
        'Items', axisItems, ...
        'Value', '-Zimag (ohm)', ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    [~, edLineWidth] = labkit.ui.view.form(gp, 'spinner', 'Line width:', ...
        'Value', 1.4, ...
        'Limits', [0.1 10], ...
        'Step', 0.1, ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    [~, edMarkerSize] = labkit.ui.view.form(gp, 'spinner', 'Marker size:', ...
        'Value', 6, ...
        'Limits', [1 20], ...
        'Step', 1, ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    cbMarkers = uicheckbox(gp, ...
        'Text', 'Show markers', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbMarkers.Layout.Row = 5;
    cbMarkers.Layout.Column = [1 2];

    cbLogX = uicheckbox(gp, ...
        'Text', 'Log X', ...
        'Value', false, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbLogX.Layout.Row = 6;
    cbLogX.Layout.Column = [1 2];

    cbLogY = uicheckbox(gp, ...
        'Text', 'Log Y', ...
        'Value', false, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbLogY.Layout.Row = 7;
    cbLogY.Layout.Column = [1 2];

    row8 = uigridlayout(gp, [1 2]);
    row8.Layout.Row = 8;
    row8.Layout.Column = [1 2];
    row8.ColumnWidth = {'1x', '1x'};
    row8.RowHeight = {'fit'};
    row8.Padding = [0 0 0 0];
    row8.ColumnSpacing = 8;

    cbLegend = uicheckbox(row8, ...
        'Text', 'Legend', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    cbGrid = uicheckbox(row8, ...
        'Text', 'Grid', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    infoUi = labkit.ui.view.panel(laySR, 'text', 'Usage', 1, { ...
        'Usage:', ...
        '1. Open one or more EIS .DTA files containing ZCURVE.', ...
        '2. Choose any X and Y axis combination.', ...
        '3. Use Zreal vs -Zimag for a Nyquist plot.', ...
        '4. Use Freq vs Zmod or Zphz for Bode-style plots.', ...
        '5. CSV export writes one shared row index with X/Y pairs per file.'});
    txtInfo = infoUi.textArea;

    logUi = labkit.ui.view.panel(layLog, 'log', 1);
    txtLog = logUi.textArea;

    ax = labkit.ui.view.axes(right, 1, 'EIS Overlay', 'Zreal (ohm)', '-Zimag (ohm)');

    txtSummary = uitextarea(laySR, 'Editable', 'off');
    labkit.ui.view.place(txtSummary, laySR, 2);
    txtSummary.Value = {'No files loaded.'};
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('EIS debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    %% App callbacks, session actions, refresh, and export
    function onOpenFiles(~, ~)
        [f, p] = uigetfile( ...
            {'*.DTA;*.dta', 'Gamry DTA (*.DTA)'; '*.*', 'All files'}, ...
            'Select one or more Gamry EIS DTA files', ...
            'MultiSelect', 'on');
        if isequal(f, 0)
            addLog('Open cancelled.');
            return;
        end

        if ischar(f) || isstring(f)
            f = {char(f)};
        end

        filepaths = cellfun(@(name) fullfile(p, name), f, 'UniformOutput', false);
        loadFiles(filepaths);
    end

    function onOpenFolder(~, ~)
        folder = uigetdir(pwd, 'Select a folder to recursively scan for .DTA files');
        if isequal(folder, 0)
            addLog('Folder selection cancelled.');
            return;
        end

        filepaths = labkit.dta.findFiles(folder);
        if isempty(filepaths)
            addLog(sprintf('No DTA files found under: %s', folder));
            uialert(fig, sprintf('No .DTA files found under:\n%s', folder), 'No files found');
            return;
        end

        addLog(sprintf('Found %d DTA file(s) under %s', numel(filepaths), folder));
        loadFiles(filepaths);
    end

    function loadFiles(filepaths)
        if isempty(filepaths)
            return;
        end

        callbacks = struct();
        callbacks.onAdded = @onAddedDTA;
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "eis", callbacks);
        S.items = S.session.items;

        refreshFileList();
        refreshPlot();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function onAddedDTA(filepath, item)
        for ii = 1:numel(item.logmsg)
            addLog(item.logmsg{ii});
        end
        addLog(sprintf('%s: %s', item.name, item.message));
        addLog(sprintf('Loaded: %s', filepath));
    end

    function onRemoveSelected(~, ~)
        if isempty(S.items) || isempty(lbFiles.Value)
            return;
        end
        callbacks = struct();
        callbacks.onRemoved = @(name, ~) addLog(sprintf('Removed: %s', name));
        [S.session, ~] = labkit.dta.removeSelectedItemsFromSession(S.session, lbFiles.Value, callbacks);
        S.items = S.session.items;
        refreshFileList();
        refreshPlot();
    end

    function onClearAll(~, ~)
        S.session = labkit.dta.makeSession('eis_overlay');
        S.items = S.session.items;
        refreshFileList();
        refreshPlot();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        if isempty(S.items)
            labkit.ui.view.update(lbFiles, 'listItems', {});
            txtLoaded.Value = 'No files loaded';
            return;
        end
        labkit.ui.view.update(lbFiles, 'listItems', {S.items.name});
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshPlot()
        cla(ax);
        ax.XScale = ternary(cbLogX.Value, 'log', 'linear');
        ax.YScale = ternary(cbLogY.Value, 'log', 'linear');
        axis(ax, 'normal');

        if isempty(S.items)
            title(ax, 'EIS Overlay');
            xlabel(ax, labelForAxis(ddX.Value));
            ylabel(ax, labelForAxis(ddY.Value));
            txtSummary.Value = {'No files loaded.'};
            return;
        end

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            txtSummary.Value = {'No files selected.'};
            return;
        end

        plotOpts = struct();
        plotOpts.xName = ddX.Value;
        plotOpts.yName = ddY.Value;
        plotOpts.logX = cbLogX.Value;
        plotOpts.logY = cbLogY.Value;
        plotOpts.lineWidth = edLineWidth.Value;
        plotOpts.markerSize = edMarkerSize.Value;
        plotOpts.showMarkers = cbMarkers.Value;
        plotOpts.showLegend = cbLegend.Value;
        plotOpts.showGrid = cbGrid.Value;
        plotOverlay(ax, items, plotOpts);

        txtSummary.Value = buildSummary(items);
    end

    function onExportCSV(~, ~)
        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_eis_plot_export.csv', 'Save current X/Y plot CSV');
        if isequal(f, 0)
            return;
        end

        T = eisWorkflow("buildExportTable", items, ddX.Value, ddY.Value, cbLogX.Value, cbLogY.Value);
        out = fullfile(p, f);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function addLog(msg)
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
    end
end

%% App-local plotting and summary helpers
function handlers = eisAppTestHandlers()
    handlers = struct( ...
        'command', {'buildExportTable', 'valuesForAxis'}, ...
        'minArgs', {5, 2}, ...
        'maxArgs', {5, 2}, ...
        'maxOutputs', {1, 1}, ...
        'run', {@runBuildExportTable, @runValuesForAxis});
end

function outputs = runBuildExportTable(args)
    outputs = {eisWorkflow("buildExportTable", args{1}, args{2}, args{3}, args{4}, args{5})};
end

function outputs = runValuesForAxis(args)
    outputs = {eisWorkflow("valuesForAxis", args{1}, args{2})};
end

function txt = labelForAxis(axisName)
    txt = axisName;
end

function summary = buildSummary(items)
    summary = cell(0, 1);
    summary{end+1} = sprintf('Loaded files: %d', numel(items));
    for i = 1:numel(items)
        fmin = min(items(i).Freq, [], 'omitnan');
        fmax = max(items(i).Freq, [], 'omitnan');
        summary{end+1} = sprintf('%s | N=%d | Freq %.4g to %.4g Hz | order: %s', ...
            items(i).name, items(i).n, fmin, fmax, ternary(items(i).freqDesc, 'high->low', 'low->high/mixed'));
    end
end

function labels = plotOverlay(ax, items, opts)
    if nargin < 3
        opts = struct();
    end
    opts = fillPlotOptions(opts);

    cla(ax);
    ax.XScale = ternary(opts.logX, 'log', 'linear');
    ax.YScale = ternary(opts.logY, 'log', 'linear');
    axis(ax, 'normal');

    cmap = lines(numel(items));
    labels = cell(1, numel(items));
    marker = 'none';
    if opts.showMarkers
        marker = 'o';
    end

    hold(ax, 'on');
    for k = 1:numel(items)
        [x, y] = filteredXY(items(k), opts.xName, opts.yName, opts.logX, opts.logY);
        plot(ax, x, y, ...
            'LineWidth', opts.lineWidth, ...
            'Marker', marker, ...
            'MarkerSize', opts.markerSize, ...
            'Color', cmap(k, :));
        labels{k} = items(k).name;
    end
    hold(ax, 'off');

    xlabel(ax, labelForAxis(opts.xName));
    ylabel(ax, labelForAxis(opts.yName));
    title(ax, sprintf('%s vs %s (%d file%s)', ...
        labelForAxis(opts.yName), labelForAxis(opts.xName), numel(items), pluralS(numel(items))));

    if opts.showGrid
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end

    if opts.showLegend
        legend(ax, labels, 'Interpreter', 'none', 'Location', 'best');
    else
        legend(ax, 'off');
    end

    if isNyquistSelection(opts.xName, opts.yName)
        axis(ax, 'equal');
    end
end

function opts = fillPlotOptions(opts)
    if ~isfield(opts, 'xName')
        opts.xName = 'Zreal (ohm)';
    end
    if ~isfield(opts, 'yName')
        opts.yName = '-Zimag (ohm)';
    end
    if ~isfield(opts, 'logX')
        opts.logX = false;
    end
    if ~isfield(opts, 'logY')
        opts.logY = false;
    end
    if ~isfield(opts, 'lineWidth')
        opts.lineWidth = 1.4;
    end
    if ~isfield(opts, 'markerSize')
        opts.markerSize = 6;
    end
    if ~isfield(opts, 'showMarkers')
        opts.showMarkers = true;
    end
    if ~isfield(opts, 'showLegend')
        opts.showLegend = true;
    end
    if ~isfield(opts, 'showGrid')
        opts.showGrid = true;
    end
end

%% App-local export
function T = buildExportTable(items, xName, yName, useLogX, useLogY)
    if nargin < 4
        useLogX = false;
    end
    if nargin < 5
        useLogY = false;
    end

    maxLen = 0;
    xCell = cell(1, numel(items));
    yCell = cell(1, numel(items));

    for i = 1:numel(items)
        [x, y] = filteredXY(items(i), xName, yName, useLogX, useLogY);
        xCell{i} = x(:);
        yCell{i} = y(:);
        maxLen = max(maxLen, numel(x));
    end

    T = table((1:maxLen).', 'VariableNames', {'RowIndex'});
    for i = 1:numel(items)
        safeName = matlab.lang.makeValidName(items(i).name);
        xVar = matlab.lang.makeValidName(sprintf('X_%s_%s', sanitizeAxisName(xName), safeName));
        yVar = matlab.lang.makeValidName(sprintf('Y_%s_%s', sanitizeAxisName(yName), safeName));
        T.(xVar) = padWithNaN(xCell{i}, maxLen);
        T.(yVar) = padWithNaN(yCell{i}, maxLen);
    end
end

%% Small app-local utilities
function [x, y] = filteredXY(item, xName, yName, useLogX, useLogY)
    x = valuesForAxis(item, xName);
    y = valuesForAxis(item, yName);
    valid = isfinite(x) & isfinite(y);
    x = x(valid);
    y = y(valid);
    if useLogX
        validX = x > 0;
        x = x(validX);
        y = y(validX);
    end
    if useLogY
        validY = y > 0;
        x = x(validY);
        y = y(validY);
    end
end

function values = valuesForAxis(item, axisName)
    switch axisName
        case 'Freq (Hz)'
            values = item.Freq;
        case 'log10(Freq)'
            values = log10(item.Freq);
        case 'Time (s)'
            values = item.Time;
        case 'Point #'
            values = item.Pt;
        case 'Zreal (ohm)'
            values = item.Zreal;
        case 'Zimag (ohm)'
            values = item.Zimag;
        case '-Zimag (ohm)'
            values = item.negZimag;
        case 'Zmod (ohm)'
            values = item.Zmod;
        case 'Zphz (deg)'
            values = item.Zphz;
        case 'Idc (A)'
            values = item.Idc;
        case 'Vdc (V)'
            values = item.Vdc;
        otherwise
            error('Unsupported axis selection: %s', axisName);
    end
end

function padded = padWithNaN(v, n)
    padded = NaN(n, 1);
    if isempty(v)
        return;
    end
    padded(1:numel(v)) = v(:);
end

function out = sanitizeAxisName(txt)
    out = regexprep(lower(txt), '[^a-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
end

function tf = isNyquistSelection(xName, yName)
    tf = strcmp(xName, 'Zreal (ohm)') && ...
        (strcmp(yName, '-Zimag (ohm)') || strcmp(yName, 'Zimag (ohm)'));
end

function txt = pluralS(n)
    if n == 1
        txt = '';
    else
        txt = 's';
    end
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
