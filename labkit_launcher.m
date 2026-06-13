function varargout = labkit_launcher(varargin)
%LABKIT_LAUNCHER Open a GUI selector for LabKit app entry points.
%
% Usage:
%   labkit_launcher
%
% This single-file launcher scans apps/**/labkit_*_app.m entry points,
% initializes the LabKit path, and lets users launch an app without manually
% locating the app folder. Existing app entry points remain independently
% launchable.

    root = fileparts(mfilename('fullpath'));
    mode = parseMode(varargin);

    apps = discoverApps(root);
    if mode == "list"
        varargout = {appTable(apps)};
        return;
    end

    if nargout > 1
        error('labkit_launcher:TooManyOutputs', ...
            'labkit_launcher returns at most the launcher figure handle.');
    end

    initializePath(root);
    fig = createLauncherFigure(root, apps);
    if nargout == 1
        varargout = {fig};
    end
end

function mode = parseMode(args)
    mode = "gui";
    if isempty(args)
        return;
    end
    if numel(args) ~= 1
        error('labkit_launcher:InvalidInput', ...
            'labkit_launcher accepts no inputs or the string "list".');
    end

    value = string(args{1});
    if strlength(value) == 0
        return;
    end
    if ~strcmpi(value, "list")
        error('labkit_launcher:InvalidInput', ...
            'Unsupported labkit_launcher mode: %s', value);
    end
    mode = "list";
end

function initializePath(root)
    startupFile = fullfile(root, 'startup_labkit.m');
    if exist(startupFile, 'file') == 2
        currentFolder = pwd;
        cleanup = onCleanup(@() cd(currentFolder));
        cd(root);
        startup_labkit(false);
        clear cleanup;
    else
        addpath(root);
        appRoot = fullfile(root, 'apps');
        if exist(appRoot, 'dir') == 7
            addpath(appRoot, '-end');
        end
    end
end

function fig = createLauncherFigure(root, apps)
    initialFamilyItems = familyFilterItems(apps);
    spec = labkit.ui.spec.app('labkitLauncher', 'LabKit App Launcher', ...
        'position', [100 80 1320 760], ...
        'leftWidth', 390, ...
        'controlTabs', { ...
            labkit.ui.spec.tab('findApp', 'Find App', { ...
                labkit.ui.spec.section('searchSection', '', { ...
                    labkit.ui.spec.field('launcherSummary', ...
                        'LabKit Apps', ...
                        'kind', 'readonly', ...
                        'value', sprintf('%d app entry points found', numel(apps))), ...
                    labkit.ui.spec.field('search', 'Search:', ...
                        'kind', 'text', ...
                        'onChange', @onFilterChanged), ...
                    labkit.ui.spec.field('family', 'Family:', ...
                        'kind', 'dropdown', ...
                        'items', cellstr(initialFamilyItems), ...
                        'value', char(initialFamilyItems(1)), ...
                        'onChange', @onFilterChanged)}, ...
                    'chrome', 'none'), ...
                labkit.ui.spec.section('selectedAppSection', 'Selected App', { ...
                    labkit.ui.spec.statusPanel('selectedDetails', ...
                        'Selected App', ...
                        'value', {'No app selected.'}), ...
                    labkit.ui.spec.action('openSelected', ...
                        'Open Selected App', @onLaunch)}), ...
                labkit.ui.spec.section('actionsSection', 'Actions', { ...
                    labkit.ui.spec.action('refreshApps', ...
                        'Refresh App List', @onRefresh), ...
                    labkit.ui.spec.statusPanel('launcherHint', ...
                        'Hint', ...
                        'value', {'Select a row to inspect it. Double-click a row to open that app.'})}), ...
                labkit.ui.spec.section('statusSection', 'Status', { ...
                    labkit.ui.spec.logPanel('statusLog', 'Status', ...
                        'value', {'Ready.'})})})}, ...
        'workspace', labkit.ui.spec.workspace('applicationsWorkspace', ...
            'Applications', { ...
            labkit.ui.spec.resultTable('appTable', 'Applications', ...
                'columns', {'Family', 'App', 'Command'})}));

    ui = labkit.ui.app.create(spec);
    fig = ui.figure;
    fig.Color = [0.97 0.98 0.99];
    txtFilter = ui.controls.search.valueHandle;
    ddFamily = ui.controls.family.valueHandle;
    summaryText = ui.controls.launcherSummary.valueHandle;
    detailText = ui.controls.selectedDetails.textArea;
    btnDetailLaunch = ui.controls.openSelected.button;
    tblApps = ui.controls.appTable.table;
    tblApps.ColumnEditable = [false false false];
    tblApps.ColumnSortable = [true true true];
    tblApps.RowName = {};
    tblApps.ColumnWidth = {'fit', 'fit', 'auto'};
    if isprop(tblApps, 'SelectionChangedFcn')
        tblApps.SelectionChangedFcn = @onSelectionChanged;
    else
        tblApps.CellSelectionCallback = @onSelectionChanged;
    end
    if isprop(tblApps, 'SelectionType')
        tblApps.SelectionType = 'row';
    end
    if isprop(tblApps, 'DoubleClickedFcn')
        tblApps.DoubleClickedFcn = @onTableDoubleClicked;
    elseif isprop(tblApps, 'CellDoubleClickedFcn')
        tblApps.CellDoubleClickedFcn = @onTableDoubleClicked;
    end
    statusLabel = ui.controls.statusLog.textArea;

    state = struct();
    state.apps = apps;
    state.visibleApps = apps;
    state.selectedRow = 1;
    state.selectedStyle = uistyle('BackgroundColor', [0.86 0.93 1.00]);
    refreshTable();

    function onFilterChanged(~, ~)
        state.selectedRow = 1;
        refreshTable();
    end

    function onRefresh(~, ~)
        state.apps = discoverApps(root);
        ddFamily.Items = cellstr(familyFilterItems(state.apps));
        ddFamily.Value = ddFamily.Items{1};
        state.selectedRow = 1;
        summaryText.Value = sprintf('%d app entry points found', numel(state.apps));
        refreshTable();
    end

    function onSelectionChanged(~, event)
        row = eventRow(event);
        if isnan(row)
            return;
        end
        state.selectedRow = row;
        refreshSelection();
    end

    function onTableDoubleClicked(~, event)
        row = eventRow(event);
        if isnan(row)
            row = selectedTableRow();
        end
        if ~isnan(row)
            state.selectedRow = row;
            refreshSelection();
        end
        onLaunch();
    end

    function onLaunch(~, ~)
        if isempty(state.visibleApps)
            setStatus('No app entry points found.');
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        app = state.visibleApps(row);
        setStatus(sprintf('Launching %s...', app.command));
        drawnow;

        try
            addpath(app.folder, '-end');
            feval(app.command);
            setStatus(sprintf('Launched %s.', app.command));
        catch err
            setStatus(sprintf('Failed to launch %s: %s', ...
                app.command, err.message));
        end
    end

    function refreshTable()
        state.visibleApps = filterApps(state.apps, ...
            string(txtFilter.Value), string(ddFamily.Value));
        tblApps.Data = displayRows(state.visibleApps);
        state.selectedRow = min(max(state.selectedRow, 1), max(numel(state.visibleApps), 1));
        setLaunchEnabled(~isempty(state.visibleApps));
        refreshSelection();
        setStatus(sprintf('%d of %d apps shown', ...
            numel(state.visibleApps), numel(state.apps)));
    end

    function refreshSelection()
        if isempty(state.visibleApps)
            detailText.Value = {'No matching apps'; 'No app matches the current filters.'};
            clearTableStyles();
            return;
        end

        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        app = state.visibleApps(row);
        detailText.Value = [ ...
            {char(app.displayName)}; ...
            {['Family: ' char(app.family)]}; ...
            {['Command: ' app.command]}; ...
            {['Path: ' app.relativePath]}; ...
            cellstr(wrapDescription(app.description))];
        highlightSelectedRow(row);
    end

    function setLaunchEnabled(enabled)
        stateValue = matlab.lang.OnOffSwitchState(enabled);
        btnDetailLaunch.Enable = stateValue;
    end

    function clearTableStyles()
        try
            removeStyle(tblApps);
        catch
        end
    end

    function highlightSelectedRow(row)
        clearTableStyles();
        try
            addStyle(tblApps, state.selectedStyle, 'row', row);
        catch
        end
    end

    function setStatus(message)
        statusLabel.Value = {char(message)};
    end

    function row = selectedTableRow()
        row = NaN;
        if isprop(tblApps, 'Selection') && ~isempty(tblApps.Selection)
            row = tblApps.Selection(1, 1);
        end
    end

end

function row = eventRow(event)
    row = NaN;
    if isobject(event) && isprop(event, 'Selection')
        indices = event.Selection;
    elseif isstruct(event) && isfield(event, 'Selection')
        indices = event.Selection;
    elseif isobject(event) && isprop(event, 'Indices')
        indices = event.Indices;
    elseif isstruct(event) && isfield(event, 'Indices')
        indices = event.Indices;
    else
        indices = [];
    end
    if ~isempty(indices)
        row = indices(1, 1);
    end
end

function lines = wrapDescription(description)
    text = string(description);
    if strlength(text) == 0
        lines = "No description found in the app header.";
        return;
    end

    sentences = splitSentences(text);
    lines = sentences(1:min(numel(sentences), 3));
end

function sentences = splitSentences(text)
    parts = regexp(char(text), '(?<=[.!?])\s+', 'split');
    sentences = strings(numel(parts), 1);
    sentenceCount = 0;
    for k = 1:numel(parts)
        value = strtrim(string(parts{k}));
        if strlength(value) > 0
            sentenceCount = sentenceCount + 1;
            sentences(sentenceCount) = value;
        end
    end
    sentences = sentences(1:sentenceCount);
    if sentenceCount == 0
        sentences = text;
    end
end

function apps = discoverApps(root)
    appRoot = fullfile(root, 'apps');
    template = emptyAppStruct();
    if exist(appRoot, 'dir') ~= 7
        apps = template;
        return;
    end

    entries = dir(fullfile(appRoot, '**', 'labkit_*_app.m'));
    candidates = entries(~[entries.isdir]);
    apps = repmat(template, numel(candidates), 1);
    appCount = 0;

    for k = 1:numel(candidates)
        filepath = fullfile(candidates(k).folder, candidates(k).name);
        rel = relativePath(appRoot, filepath);
        if isHiddenImplementationPath(rel)
            continue;
        end

        [folder, command] = fileparts(filepath);
        family = appFamily(appRoot, folder);
        appCount = appCount + 1;
        apps(appCount).command = command;
        apps(appCount).displayName = displayNameFromCommand(command);
        apps(appCount).family = family;
        apps(appCount).folder = folder;
        apps(appCount).relativePath = relativePath(root, filepath);
        apps(appCount).description = appDescription(filepath, command);
    end

    apps = apps(1:appCount);
    if isempty(apps)
        return;
    end

    [~, order] = sortrows([[apps.family]', [apps.displayName]']);
    apps = apps(order);
end

function app = emptyAppStruct()
    app = struct( ...
        'command', {}, ...
        'displayName', {}, ...
        'family', {}, ...
        'folder', {}, ...
        'relativePath', {}, ...
        'description', {});
end

function tf = isHiddenImplementationPath(rel)
    parts = pathParts(rel);
    tf = any(startsWith(parts, '+')) || ...
        any(startsWith(parts, '@')) || ...
        any(strcmp(parts, 'private'));
end

function family = appFamily(appRoot, folder)
    relFolder = relativePath(appRoot, folder);
    parts = pathParts(relFolder);
    if isempty(parts)
        family = "apps";
    else
        family = string(parts{1});
    end
end

function parts = pathParts(pathValue)
    normalized = strrep(char(pathValue), filesep, '/');
    parts = strsplit(normalized, '/');
    parts = parts(~cellfun('isempty', parts));
end

function name = displayNameFromCommand(command)
    name = string(command);
    name = erase(name, "labkit_");
    name = erase(name, "_app");
    name = regexprep(name, '([A-Z]+)([A-Z][a-z])', '$1 $2');
    name = regexprep(name, '([a-z])([A-Z])', '$1 $2');
    name = strrep(name, '_', ' ');
end

function description = appDescription(filepath, command)
    fid = fopen(filepath, 'r');
    if fid < 0
        description = "App entry point: " + string(command);
        return;
    end
    cleanup = onCleanup(@() fclose(fid));

    lines = strings(2, 1);
    lineCount = 0;
    while lineCount < numel(lines)
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        stripped = strtrim(line);
        if startsWith(stripped, 'function ')
            continue;
        end
        if ~startsWith(stripped, '%')
            if lineCount > 0
                break;
            end
            continue;
        end
        text = strtrim(regexprep(stripped, '^%+', ''));
        if strlength(text) == 0 || strcmpi(text, 'Main features') || strcmpi(text, 'Notes')
            continue;
        end
        lineCount = lineCount + 1;
        lines(lineCount) = string(text);
    end
    lines = lines(1:lineCount);
    if lineCount == 0
        description = "App entry point: " + string(command);
    else
        description = strjoin(lines, " ");
    end
end

function rows = displayRows(apps)
    rows = cell(numel(apps), 3);
    for k = 1:numel(apps)
        rows{k, 1} = char(apps(k).family);
        rows{k, 2} = char(apps(k).displayName);
        rows{k, 3} = apps(k).command;
    end
end

function filtered = filterApps(apps, textFilter, familyFilter)
    if isempty(apps)
        filtered = apps;
        return;
    end

    keep = true(numel(apps), 1);
    if strlength(strtrim(textFilter)) > 0
        q = lower(strtrim(textFilter));
        fields = lower([string({apps.command})', string({apps.displayName})', ...
            string({apps.family})', string({apps.relativePath})']);
        keep = keep & any(contains(fields, q), 2);
    end
    if familyFilter ~= "All"
        keep = keep & (string({apps.family})' == familyFilter);
    end
    filtered = apps(keep);
end

function items = familyFilterItems(apps)
    if isempty(apps)
        items = "All";
        return;
    end
    items = ["All"; unique(string({apps.family})')];
end

function T = appTable(apps)
    command = strings(numel(apps), 1);
    displayName = strings(numel(apps), 1);
    family = strings(numel(apps), 1);
    folder = strings(numel(apps), 1);
    relativePath = strings(numel(apps), 1);
    description = strings(numel(apps), 1);
    for k = 1:numel(apps)
        command(k) = string(apps(k).command);
        displayName(k) = string(apps(k).displayName);
        family(k) = string(apps(k).family);
        folder(k) = string(apps(k).folder);
        relativePath(k) = string(apps(k).relativePath);
        description(k) = string(apps(k).description);
    end
    T = table(command, displayName, family, folder, relativePath, description, ...
        'VariableNames', {'Command', 'DisplayName', 'Family', 'Folder', 'RelativePath', 'Description'});
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [char(root) filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
