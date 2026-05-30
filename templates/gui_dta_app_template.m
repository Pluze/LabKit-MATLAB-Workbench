function varargout = gui_dta_app_template(varargin)
%GUI_DTA_APP_TEMPLATE Minimal app using the GUI and DTA facade surfaces.

    if nargin > 0
        error('gui_dta_app_template:UnsupportedInput', ...
            'gui_dta_app_template does not accept input arguments.');
    end
    if nargout > 1
        error('gui_dta_app_template:TooManyOutputs', ...
            'gui_dta_app_template returns at most the figure handle.');
    end

    S = struct();
    S.session = gamrywb.dta.makeSession('template');

    ui = gamrywb.ui.createTwoPaneShell( ...
        'GUI + DTA Template', [80 80 1200 760], 340, ...
        'Selected File', [1 1], {'1x'}, 8);
    fig = ui.fig;
    left = ui.leftGrid;
    right = ui.rightGrid;

    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onRemoveSelected = @onRemoveSelected;
    fileCallbacks.onClearAll = @onClearAll;
    fileCallbacks.onExport = @onExport;

    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'removeSelected', 'Remove selected', ...
        'clearAll', 'Clear all', ...
        'export', 'Export names CSV');
    gamrywb.ui.createFilePanel(left, fileLabels, fileCallbacks);

    lbFiles = uilistbox(left, ...
        'Items', {}, ...
        'Multiselect', 'on', ...
        'ValueChangedFcn', @(~, ~) refreshView());
    lbFiles.Layout.Row = 2;

    logUi = gamrywb.ui.createLogPanel(left, 5, {'Ready.'});
    ax = gamrywb.ui.createAxes(right, 1, 'Selected File', 'Point', 'Value');

    refreshView();

    if nargout == 1
        varargout{1} = fig;
    end

    function onOpenFiles(~, ~)
        [names, folder] = uigetfile( ...
            {'*.DTA;*.dta', 'Gamry DTA (*.DTA)'; '*.*', 'All files'}, ...
            'Select one or more DTA files', ...
            'MultiSelect', 'on');
        if isequal(names, 0)
            addLog('Open cancelled.');
            return;
        end
        if ischar(names) || isstring(names)
            names = {char(names)};
        end
        filepaths = cellfun(@(name) fullfile(folder, name), names, 'UniformOutput', false);
        addFiles(filepaths);
    end

    function onOpenFolder(~, ~)
        folder = uigetdir(pwd, 'Select a folder to scan for DTA files');
        if isequal(folder, 0)
            addLog('Folder selection cancelled.');
            return;
        end
        addFiles(gamrywb.dta.findFiles(folder));
    end

    function addFiles(filepaths)
        callbacks = struct();
        callbacks.onAdded = @(filepath, ~) addLog(sprintf('Loaded: %s', filepath));
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped duplicate: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));

        [S.session, report] = gamrywb.dta.addFilesToSession( ...
            S.session, filepaths, "auto", callbacks);
        refreshView();

        if report.nFailed > 0
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', ...
                firstError.filepath, firstError.message), 'Load error');
        end
    end

    function onRemoveSelected(~, ~)
        callbacks = struct();
        callbacks.onRemoved = @(name, ~) addLog(sprintf('Removed: %s', name));
        [S.session, ~] = gamrywb.dta.removeSelectedItemsFromSession( ...
            S.session, lbFiles.Value, callbacks);
        refreshView();
    end

    function onClearAll(~, ~)
        S.session = gamrywb.dta.makeSession('template');
        addLog('Cleared all files.');
        refreshView();
    end

    function onExport(~, ~)
        if isempty(S.session.items)
            addLog('No files loaded.');
            return;
        end

        [name, folder] = uiputfile('*.csv', 'Export loaded DTA names', 'dta_items.csv');
        if isequal(name, 0)
            addLog('Export cancelled.');
            return;
        end

        filepath = fullfile(folder, name);
        try
            writetable(localNameTable(S.session.items), filepath);
            addLog(sprintf('Exported: %s', filepath));
        catch ME
            addLog(sprintf('Export failed: %s', ME.message));
            uialert(fig, ME.message, 'Export failed');
        end
    end

    function refreshView()
        if isempty(S.session.items)
            gamrywb.ui.refreshListboxItems(lbFiles, {});
            gamrywb.ui.hardResetAxis(ax, 'Selected File');
            return;
        end

        gamrywb.ui.refreshListboxItems(lbFiles, {S.session.items.name});
        selectedItems = gamrywb.dta.selectSessionItems(S.session, lbFiles.Value);
        if isempty(selectedItems)
            selectedItems = S.session.items(1);
        end
        plotSelectedItem(selectedItems(1));
    end

    function plotSelectedItem(item)
        y = localPreviewValues(item);
        x = 1:numel(y);
        labels = struct('title', item.name, 'x', 'Point', 'y', 'Value');
        opts = struct('lineWidth', 1.2, 'markerSize', 4, 'marker', '.');
        gamrywb.ui.plotXY(ax, x, y, labels, opts);
    end

    function addLog(message)
        gamrywb.ui.appendLog(logUi.textArea, message);
    end
end

function y = localPreviewValues(item)
    if isfield(item, 'Vf') && ~isempty(item.Vf)
        y = item.Vf;
    elseif isfield(item, 'Zreal') && ~isempty(item.Zreal)
        y = item.Zreal;
    elseif isfield(item, 'curves') && ~isempty(item.curves)
        y = item.curves(1).data(:, 1);
    else
        y = NaN;
    end
end

function T = localNameTable(items)
    files = strings(numel(items), 1);
    kinds = strings(numel(items), 1);
    for i = 1:numel(items)
        files(i) = string(items(i).name);
        kinds(i) = string(items(i).type);
    end
    T = table(files, kinds, 'VariableNames', {'File', 'Kind'});
end
