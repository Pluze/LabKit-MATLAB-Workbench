% App-owned runner extracted from labkit_ChronoOverlay_app.m. Expected caller: labkit_ChronoOverlay_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = runChronoOverlayApp(debugLog)
%RUNCHRONOOVERLAYAPP Build and run the app body.

    S = struct();
    S.session = labkit.dta.makeSession('chrono_overlay');
    S.items = S.session.items;

    workbenchOpts = struct();
    workbenchOpts.rightTitle = 'Overlay Plots';
    workbenchOpts.rightGridSize = [2 1];
    workbenchOpts.rightRowHeight = {'1x', '1x'};
    workbenchOpts.rightRowSpacing = 10;
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Gamry Multi-DTA Plot Export GUI', ...
        'position', [80 60 1480 900], ...
        'leftWidth', 340, ...
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
    fileCallbacks.onSelectFile = @(~,~) refreshPlots();
    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'removeSelected', 'Remove selected', ...
        'clearAll', 'Clear all', ...
        'export', 'Export curves CSV', ...
        'loadedText', 'No files loaded');
    fileUi = labkit.ui.view.panel(layFA, 'files', fileLabels, fileCallbacks, ...
        struct('showRemoveSelected', true, 'multiselect', 'on'));
    lbFiles = fileUi.listbox;
    txtLoaded = fileUi.loadedText;

    plotOptionsUi = labkit.ui.view.panel(layFA, 'plotOptions', 4, 2);
    gp = plotOptionsUi.grid;

    [~, ddXAxis] = labkit.ui.view.form(gp, 'dropdown', 'X axis:', ...
        'Items', {'Time (s)', 'Time (ms)', 'Sample #'}, ...
        'Value', 'Time (s)', ...
        'ValueChangedFcn', @(~,~) refreshPlots());

    [~, edLineWidth] = labkit.ui.view.form(gp, 'spinner', 'Line width:', ...
        'Value', 1.3, ...
        'Limits', [0.1 10], ...
        'Step', 0.1, ...
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

    infoUi = labkit.ui.view.panel(laySR, 'text', 'Usage', 1, { ...
        'Usage:', ...
        '1. Open multiple .DTA files.', ...
        '2. Curves are aligned to the center of the blank time between cathodic and anodic phases.', ...
        '3. Voltage and current curves will be overlaid.', ...
        '4. Export CSV columns as: TimeGapCenterAligned_s, V_*, I_*.', ...
        '5. If files have different time grids, export uses a merged aligned-time axis with interpolation.' ...
        });
    txtInfo = infoUi.textArea;

    logUi = labkit.ui.view.panel(layLog, 'log', 1);
    txtLog = logUi.textArea;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('Chrono overlay debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    axV = labkit.ui.view.axes(right, 1, 'Voltage', 'Time (s)', 'Vf (V)');
    axI = labkit.ui.view.axes(right, 2, 'Current', 'Time (s)', 'Im (A)');
    %% App callbacks, session actions, refresh, and export
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
        callbacks.onAdded = @(~, ~) [];
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "chrono", callbacks);
        postProcessAddedItems(report.added);
        S.items = S.session.items;

        refreshFileList();
        refreshPlots();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function postProcessAddedItems(filepaths)
        for iFile = 1:numel(filepaths)
            idx = find(strcmp(string({S.session.items.filepath}), string(filepaths{iFile})), 1, 'first');
            if isempty(idx)
                continue;
            end

            item = S.session.items(idx);
            [item, alignMsg] = chronoOverlayWorkflow("alignByPulseGap", item);
            S.session.items(idx) = item;
            addLog(alignMsg);

            for ii = 1:numel(item.logmsg)
                addLog(item.logmsg{ii});
            end
            addLog(sprintf('%s: %s', item.name, item.message));
            addLog(sprintf('Loaded: %s', filepaths{iFile}));
        end
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
        refreshPlots();
    end

    function onClearAll(~, ~)
        S.session = labkit.dta.makeSession('chrono_overlay');
        S.items = S.session.items;
        refreshFileList();
        refreshPlots();
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

    function refreshPlots()
        if isempty(S.items)
            chronoOverlayWorkflow("plotVTIT", axV, axI, struct([]), plotOptions());
            return;
        end

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            cla(axV);
            cla(axI);
            return;
        end

        chronoOverlayWorkflow("plotVTIT", axV, axI, items, plotOptions());
    end

    function onExportCSV(~, ~)
        if isempty(S.items)
            uialert(fig, 'No files loaded.', 'Export');
            return;
        end

        items = labkit.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(items)
            uialert(fig, 'No files selected for export.', 'Export');
            return;
        end

        [f, p] = uiputfile('gamry_overlay_curves.csv', 'Save overlay curves CSV');
        if isequal(f, 0)
            return;
        end

        T = chronoOverlayWorkflow("buildOverlayExportTable", items);
        out = fullfile(p, f);
        writetable(T, out);
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
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
    end
end
