function varargout = gamrywb_EIS_app(varargin)
%GAMRYWB_EIS_APP Package-backed EIS app entry point.
% Uses +gamrywb parser, data, plotting, and export helpers without delegating to legacy.

    if nargin > 0
        error('gamrywb_EIS_app:UnsupportedInput', 'gamrywb_EIS_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_EIS_app:TooManyOutputs', 'gamrywb_EIS_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = gamrywb.data.makeSession('eis_overlay');
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

    ui = gamrywb.ui.createTwoPaneShell( ...
        'Gamry EIS Multi-DTA Plot GUI', ...
        [80 60 1500 900], ...
        360, ...
        'Plot', ...
        [2 1], ...
        {'1x', 'fit'}, ...
        8);
    fig = ui.fig;
    left = ui.leftGrid;
    right = ui.rightGrid;

    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onRemoveSelected = @onRemoveSelected;
    fileCallbacks.onClearAll = @onClearAll;
    fileCallbacks.onExport = @onExportCSV;
    gamrywb.ui.createFilePanel(left, 'Export current plot CSV', fileCallbacks);

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlot());
    lbFiles.Layout.Row = 2;

    pPlot = uipanel(left, 'Title', 'Plot Options');
    pPlot.Layout.Row = 3;
    gp = uigridlayout(pPlot, [8 2]);
    gp.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    gp.ColumnWidth = {'fit', '1x'};
    gp.Padding = [8 8 8 8];
    gp.RowSpacing = 8;
    gp.ColumnSpacing = 8;

    [~, ddX] = gamrywb.ui.createLabeledDropdown(gp, 'X axis:', ...
        'Items', axisItems, ...
        'Value', 'Zreal (ohm)', ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    [~, ddY] = gamrywb.ui.createLabeledDropdown(gp, 'Y axis:', ...
        'Items', axisItems, ...
        'Value', '-Zimag (ohm)', ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    [~, edLineWidth] = gamrywb.ui.createLabeledEditField(gp, 'Line width:', 'numeric', ...
        'Value', 1.4, ...
        'Limits', [0.1 10], ...
        'ValueChangedFcn', @(~,~) refreshPlot());

    [~, edMarkerSize] = gamrywb.ui.createLabeledEditField(gp, 'Marker size:', 'numeric', ...
        'Value', 6, ...
        'Limits', [1 20], ...
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

    txtInfo = uitextarea(left, 'Editable', 'off');
    txtInfo.Layout.Row = 4;
    txtInfo.Value = { ...
        'Usage:', ...
        '1. Open one or more EIS .DTA files containing ZCURVE.', ...
        '2. Choose any X and Y axis combination.', ...
        '3. Use Zreal vs -Zimag for a Nyquist plot.', ...
        '4. Use Freq vs Zmod or Zphz for Bode-style plots.', ...
        '5. CSV export writes one shared row index with X/Y pairs per file.'};

    txtLog = uitextarea(left, 'Editable', 'off');
    txtLog.Layout.Row = 5;
    txtLog.Value = {'GUI started.'};

    ax = uiaxes(right);
    ax.Layout.Row = 1;
    title(ax, 'EIS Overlay');
    xlabel(ax, 'Zreal (ohm)');
    ylabel(ax, '-Zimag (ohm)');

    txtSummary = uitextarea(right, 'Editable', 'off');
    txtSummary.Layout.Row = 2;
    txtSummary.Value = {'No files loaded.'};
    if nargout == 1
        varargout{1} = fig;
    end

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

        filepaths = gamrywb.io.findDTAFilesRecursive(folder);
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
        callbacks.onAdded = @(filepath, ~) addLog(sprintf('Loaded: %s', filepath));
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = gamrywb.app.loadFilesIntoSession(S.session, filepaths, @loadOneDTA, callbacks);
        S.items = S.session.items;

        refreshFileList();
        refreshPlot();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function item = loadOneDTA(filepath)
        item = gamrywb.data.makeEISItem(filepath);
        for ii = 1:numel(item.logmsg)
            addLog(item.logmsg{ii});
        end
        addLog(sprintf('%s: %s', item.name, item.message));
    end

    function onRemoveSelected(~, ~)
        if isempty(S.items) || isempty(lbFiles.Value)
            return;
        end
        callbacks = struct();
        callbacks.onRemoved = @(name, ~) addLog(sprintf('Removed: %s', name));
        [S.session, ~] = gamrywb.app.removeSelectedItemsFromSession(S.session, lbFiles.Value, callbacks);
        S.items = S.session.items;
        refreshFileList();
        refreshPlot();
    end

    function onClearAll(~, ~)
        S.session = gamrywb.data.makeSession('eis_overlay');
        S.items = S.session.items;
        refreshFileList();
        refreshPlot();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        gamrywb.ui.refreshFileListbox(lbFiles, S.items);
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

        items = gamrywb.app.selectItemsByNames(S.items, lbFiles.Value);
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
        gamrywb.plot.plotEISOverlay(ax, items, plotOpts);

        txtSummary.Value = buildSummary(items);
    end

    function onExportCSV(~, ~)
        items = gamrywb.app.selectItemsByNames(S.items, lbFiles.Value);
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_eis_plot_export.csv', 'Save current X/Y plot CSV');
        if isequal(f, 0)
            return;
        end

        T = gamrywb.io.buildEISExportTable(items, ddX.Value, ddY.Value, cbLogX.Value, cbLogY.Value);
        out = fullfile(p, f);
        writetable(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function addLog(msg)
        gamrywb.ui.appendLog(txtLog, msg);
    end
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

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
