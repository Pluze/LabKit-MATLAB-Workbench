function varargout = launchChronoOverlayApp(varargin)
%LAUNCHCHRONOOVERLAYAPP Launch the chrono overlay/export app from apps/private.
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

    ui = gamrywb.ui.createTwoPaneShell( ...
        'Gamry Multi-DTA Plot Export GUI', ...
        [80 60 1480 900], ...
        340, ...
        'Overlay Plots', ...
        [2 1], ...
        {'1x', '1x'}, ...
        10);
    fig = ui.fig;
    left = ui.leftGrid;
    right = ui.rightGrid;

    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onRemoveSelected = @onRemoveSelected;
    fileCallbacks.onClearAll = @onClearAll;
    fileCallbacks.onExport = @onExportCSV;
    gamrywb.ui.createFilePanel(left, 'Export curves CSV', fileCallbacks);

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~,~) refreshPlots());
    lbFiles.Layout.Row = 2;

    plotOptionsUi = gamrywb.ui.createPlotOptionsPanel(left, 4);
    gp = plotOptionsUi.grid;

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

    gamrywb.ui.createInfoArea(left, { ...
        'Usage:', ...
        '1. Open multiple .DTA files.', ...
        '2. Curves are aligned to the center of the blank time between cathodic and anodic phases.', ...
        '3. Voltage and current curves will be overlaid.', ...
        '4. Export CSV columns as: TimeGapCenterAligned_s, V_*, I_*.', ...
        '5. If files have different time grids, export uses a merged aligned-time axis with interpolation.' ...
        });

    txtLog = gamrywb.ui.createLogArea(left);

    axV = gamrywb.ui.createAxes(right, 1, 'Voltage', 'Time (s)', 'Vf (V)');
    axI = gamrywb.ui.createAxes(right, 2, 'Current', 'Time (s)', 'Im (A)');
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
        [item, status] = gamrywb.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('%s', char(status.message));
        end

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
