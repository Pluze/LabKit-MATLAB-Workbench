function varargout = gamrywb_ChronoOverlay_app(varargin)
%GAMRYWB_CHRONOOVERLAY_APP Package-backed chrono overlay/export app entry point.
% Load multiple Gamry .DTA files, overlay voltage/current curves, and
% export aligned curves to CSV.

    if nargin > 0
        error('gamrywb_ChronoOverlay_app:UnsupportedInput', 'gamrywb_ChronoOverlay_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_ChronoOverlay_app:TooManyOutputs', 'gamrywb_ChronoOverlay_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = gamrywb.data.makeSession('chrono_overlay');
    S.items = S.session.items;

    fig = uifigure( ...
        'Name', 'Gamry Multi-DTA Plot Export GUI', ...
        'Position', [80 60 1480 900]);

    main = uigridlayout(fig, [1 2]);
    main.ColumnWidth = {340, '1x'};
    main.RowHeight = {'1x'};
    main.Padding = [10 10 10 10];
    main.ColumnSpacing = 10;

    leftPanel = uipanel(main, 'Title', 'Controls');
    leftPanel.Layout.Row = 1;
    leftPanel.Layout.Column = 1;

    left = uigridlayout(leftPanel, [5 1]);
    left.RowHeight = {'fit', '1x', 'fit', 'fit', '1x'};
    left.ColumnWidth = {'1x'};
    left.Padding = [8 8 8 8];
    left.RowSpacing = 10;

    pButtons = uipanel(left, 'Title', 'Files');
    pButtons.Layout.Row = 1;
    gb = uigridlayout(pButtons, [4 2]);
    gb.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    gb.ColumnWidth = {'1x', '1x'};
    gb.Padding = [8 8 8 8];
    gb.RowSpacing = 8;
    gb.ColumnSpacing = 8;

    btnOpen = uibutton(gb, 'Text', 'Open DTA file(s)', 'ButtonPushedFcn', @onOpenFiles);
    btnOpen.Layout.Row = 1;
    btnOpen.Layout.Column = [1 2];

    btnOpenFolder = uibutton(gb, 'Text', 'Open folder recursively', 'ButtonPushedFcn', @onOpenFolder);
    btnOpenFolder.Layout.Row = 2;
    btnOpenFolder.Layout.Column = [1 2];

    btnRemove = uibutton(gb, 'Text', 'Remove selected', 'ButtonPushedFcn', @onRemoveSelected);
    btnRemove.Layout.Row = 3;
    btnRemove.Layout.Column = 1;

    btnClear = uibutton(gb, 'Text', 'Clear all', 'ButtonPushedFcn', @onClearAll);
    btnClear.Layout.Row = 3;
    btnClear.Layout.Column = 2;

    btnExport = uibutton(gb, 'Text', 'Export curves CSV', 'ButtonPushedFcn', @onExportCSV);
    btnExport.Layout.Row = 4;
    btnExport.Layout.Column = [1 2];

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lbFiles.Layout.Row = 2;

    pPlot = uipanel(left, 'Title', 'Plot Options');
    pPlot.Layout.Row = 3;
    gp = uigridlayout(pPlot, [4 2]);
    gp.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    gp.ColumnWidth = {'fit', '1x'};
    gp.Padding = [8 8 8 8];
    gp.RowSpacing = 8;
    gp.ColumnSpacing = 8;

    [~, ddXAxis] = gamrywb.ui.createLabeledDropdown(gp, 'X axis:', ...
        'Items', {'Time (s)', 'Time (ms)', 'Sample #'}, ...
        'Value', 'Time (s)', ...
        'ValueChangedFcn', @(~,~) refreshPlots());

    [~, edLineWidth] = gamrywb.ui.createLabeledEditField(gp, 'Line width:', 'numeric', ...
        'Value', 1.3, ...
        'Limits', [0.1 10], ...
        'LowerLimitInclusive', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());

    cbLegend = uicheckbox(gp, ...
        'Text', 'Show file-name legend', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    cbLegend.Layout.Row = 3;
    cbLegend.Layout.Column = [1 2];

    cbGrid = uicheckbox(gp, ...
        'Text', 'Show grid', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    cbGrid.Layout.Row = 4;
    cbGrid.Layout.Column = [1 2];

    txtInfo = uitextarea(left, 'Editable', 'off');
    txtInfo.Layout.Row = 4;
    txtInfo.Value = { ...
        'Usage:', ...
        '1. Open multiple .DTA files.', ...
        '2. Curves are aligned to the center of the blank time between cathodic and anodic phases.', ...
        '3. Voltage and current curves will be overlaid.', ...
        '4. Export CSV columns as: TimeGapCenterAligned_s, V_*, I_*.', ...
        '5. If files have different time grids, export uses a merged aligned-time axis with interpolation.' ...
        };

    txtLog = uitextarea(left, 'Editable', 'off');
    txtLog.Layout.Row = 5;
    txtLog.Value = {'GUI started.'};

    rightPanel = uipanel(main, 'Title', 'Overlay Plots');
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 2;

    right = uigridlayout(rightPanel, [2 1]);
    right.RowHeight = {'1x', '1x'};
    right.ColumnWidth = {'1x'};
    right.Padding = [8 8 8 8];
    right.RowSpacing = 10;

    axV = uiaxes(right);
    axV.Layout.Row = 1;
    title(axV, 'Voltage');
    xlabel(axV, 'Time (s)');
    ylabel(axV, 'Vf (V)');

    axI = uiaxes(right);
    axI.Layout.Row = 2;
    title(axI, 'Current');
    xlabel(axI, 'Time (s)');
    ylabel(axI, 'Im (A)');
    if nargout == 1
        varargout{1} = fig;
    end

    function onOpenFiles(~, ~)
        [f, p] = uigetfile( ...
            {'*.DTA;*.dta', 'Gamry DTA (*.DTA)'; '*.*', 'All files'}, ...
            'Select one or more Gamry DTA files', ...
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
        refreshPlots();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function item = loadOneDTA(filepath)
        item = gamrywb.data.makeChronoItem(filepath);
        [item, alignMsg] = gamrywb.analysis.alignChronoByPulseGap(item);
        addLog(alignMsg);

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
        refreshPlots();
    end

    function onClearAll(~, ~)
        S.session = gamrywb.data.makeSession('chrono_overlay');
        S.items = S.session.items;
        refreshFileList();
        refreshPlots();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        gamrywb.ui.refreshFileListbox(lbFiles, S.items);
    end

    function refreshPlots()
        if isempty(S.items)
            gamrywb.plot.plotChronoVTIT(axV, axI, struct([]), plotOptions());
            return;
        end

        items = gamrywb.app.selectItemsByNames(S.items, lbFiles.Value);
        if isempty(items)
            cla(axV);
            cla(axI);
            return;
        end

        gamrywb.plot.plotChronoVTIT(axV, axI, items, plotOptions());
    end

    function onExportCSV(~, ~)
        if isempty(S.items)
            uialert(fig, 'No files loaded.', 'Export');
            return;
        end

        items = gamrywb.app.selectItemsByNames(S.items, lbFiles.Value);
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_overlay_curves.csv', 'Save overlay curves CSV');
        if isequal(f, 0)
            return;
        end

        T = gamrywb.io.buildChronoOverlayExportTable(items);
        out = fullfile(p, f);
        gamrywb.io.exportTableCSV(T, out);
        addLog(sprintf('Exported CSV: %s', out));
    end

    function opts = plotOptions()
        opts = struct();
        opts.xAxis = ddXAxis.Value;
        opts.lineWidth = edLineWidth.Value;
        opts.showGrid = cbGrid.Value;
        opts.showLegend = cbLegend.Value;
    end

    function addLog(msg)
        gamrywb.ui.appendLog(txtLog, msg);
    end
end
