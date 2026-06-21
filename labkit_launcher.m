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
        varargout = {appCatalogTable(apps)};
        return;
    end

    if nargout > 1
        error('labkit_launcher:TooManyOutputs', ...
            'labkit_launcher returns at most the launcher figure handle.');
    end

    initializePath(root);
    fig = runLauncher(root, apps);
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

function fig = runLauncher(root, apps)
    callbacks = struct( ...
        'launchSelected', @onLaunchSelected, ...
        'launchSelectedDebug', @onLaunchSelectedDebug, ...
        'openGovernance', @onOpenGovernance, ...
        'cleanArtifacts', @onCleanArtifacts, ...
        'refreshApps', @onRefreshApps);
    ui = labkit.ui.app.create(buildLauncherSpec(apps, callbacks));
    handles = launcherHandles(ui);
    configureTable(handles.table, @onSelectionChanged, @onTableDoubleClicked);

    fig = handles.figure;
    state = struct();
    state.apps = apps;
    state.visibleApps = apps;
    state.selectedRow = 1;
    state.selectedStyle = uistyle('BackgroundColor', [0.86 0.93 1.00]);
    refreshTable();

    function onRefreshApps(~, ~)
        state.apps = discoverApps(root);
        state.visibleApps = state.apps;
        state.selectedRow = 1;
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
        launchSelectedApp(false);
    end

    function onLaunchSelected(varargin)
        launchSelectedApp(false);
    end

    function onLaunchSelectedDebug(varargin)
        launchSelectedApp(true);
    end

    function onOpenGovernance(varargin)
        app = findAppByCommand(state.apps, 'labkit_ProjectGovernance_app');
        if isempty(app)
            setStatus('Project Governance app was not found.');
            return;
        end
        launchApp(app, false);
    end

    function onCleanArtifacts(varargin)
        if ~confirmCleanArtifacts(fig)
            setStatus('Clean artifacts canceled.');
            return;
        end
        result = cleanGeneratedArtifacts(root);
        setStatus(cleanArtifactsStatus(result));
    end

    function launchSelectedApp(debugMode)
        if isempty(state.visibleApps)
            setStatus('No app entry points found.');
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        launchApp(state.visibleApps(row), debugMode);
    end

    function launchApp(app, debugMode)
        setStatus(launchStartStatus(app, debugMode));
        drawnow;

        try
            addpath(app.folder, '-end');
            if debugMode
                feval(app.command, "debug");
            else
                feval(app.command);
            end
            setStatus(launchSuccessStatus(app, debugMode));
        catch err
            setStatus(sprintf('Failed to launch %s: %s', ...
                app.command, err.message));
        end
    end

    function refreshTable()
        state.visibleApps = state.apps;
        handles.table.Data = appDisplayRows(state.visibleApps);
        state.selectedRow = min(max(state.selectedRow, 1), ...
            max(numel(state.visibleApps), 1));
        setLaunchEnabled(~isempty(state.visibleApps));
        refreshSelection();
        setStatus(sprintf('%d of %d apps shown', ...
            numel(state.visibleApps), numel(state.apps)));
    end

    function refreshSelection()
        if isempty(state.visibleApps)
            handles.details.Value = noMatchingAppDetails();
            clearTableStyles();
            return;
        end

        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        handles.details.Value = selectedAppDetails(state.visibleApps(row));
        highlightSelectedRow(row);
    end

    function setLaunchEnabled(enabled)
        stateValue = matlab.lang.OnOffSwitchState(enabled);
        handles.openButton.Enable = stateValue;
        handles.debugButton.Enable = stateValue;
    end

    function clearTableStyles()
        try
            removeStyle(handles.table);
        catch
        end
    end

    function highlightSelectedRow(row)
        clearTableStyles();
        try
            addStyle(handles.table, state.selectedStyle, 'row', row);
        catch
        end
    end

    function setStatus(message)
        handles.status.Value = char(message);
    end

    function row = selectedTableRow()
        row = NaN;
        if isprop(handles.table, 'Selection') && ~isempty(handles.table.Selection)
            row = handles.table.Selection(1, 1);
        end
    end
end

function spec = buildLauncherSpec(apps, callbacks)
    spec = labkit.ui.spec.app('labkitLauncher', 'LabKit App Launcher', ...
        'controlTabs', launcherTabs(callbacks), ...
        'workspace', launcherWorkspace());
end

function tabs = launcherTabs(callbacks)
    tabs = { ...
        labkit.ui.spec.tab('launcher', 'Launcher', { ...
            selectedAppSection(), ...
            actionsSection(callbacks)})};
end

function section = selectedAppSection()
    section = labkit.ui.spec.section('selectedAppSection', 'Selected App', { ...
        labkit.ui.spec.statusPanel('selectedDetails', ...
            'Selected App', ...
            'value', {'No app selected.'})});
end

function section = actionsSection(callbacks)
    section = labkit.ui.spec.section('actionsSection', 'Actions', { ...
        labkit.ui.spec.actionGroup('primaryActions', { ...
            labkit.ui.spec.action('openSelected', ...
                'Open Selected App', callbacks.launchSelected), ...
            labkit.ui.spec.action('openSelectedDebug', ...
                'Open Debug', callbacks.launchSelectedDebug)}), ...
        labkit.ui.spec.actionGroup('projectToolActions', { ...
            labkit.ui.spec.action('openGovernance', ...
                'Project Governance', callbacks.openGovernance), ...
            labkit.ui.spec.action('cleanArtifacts', ...
                'Clean Artifacts', callbacks.cleanArtifacts)}), ...
        labkit.ui.spec.action('refreshApps', ...
            'Refresh App List', callbacks.refreshApps), ...
        labkit.ui.spec.statusPanel('statusLine', 'Action Result', ...
            'value', {'Ready.'})});
end

function workspace = launcherWorkspace()
    workspace = labkit.ui.spec.workspace('applicationsWorkspace', ...
        'Applications', { ...
        labkit.ui.spec.resultTable('appTable', 'Applications', ...
            'columns', {'Family', 'App', 'Command'})});
end

function handles = launcherHandles(ui)
    handles = struct();
    handles.figure = ui.figure;
    handles.figure.Color = [0.97 0.98 0.99];
    handles.details = ui.controls.selectedDetails.textArea;
    handles.openButton = ui.controls.openSelected.button;
    handles.debugButton = ui.controls.openSelectedDebug.button;
    handles.table = ui.controls.appTable.table;
    handles.status = ui.controls.statusLine.textArea;
end

function configureTable(tableHandle, selectionCallback, doubleClickCallback)
    tableHandle.ColumnEditable = [false false false];
    tableHandle.ColumnSortable = [true true true];
    tableHandle.RowName = {};
    tableHandle.ColumnWidth = {'fit', 'fit', 'auto'};
    if isprop(tableHandle, 'SelectionChangedFcn')
        tableHandle.SelectionChangedFcn = selectionCallback;
    else
        tableHandle.CellSelectionCallback = selectionCallback;
    end
    if isprop(tableHandle, 'SelectionType')
        tableHandle.SelectionType = 'row';
    end
    if isprop(tableHandle, 'DoubleClickedFcn')
        tableHandle.DoubleClickedFcn = doubleClickCallback;
    elseif isprop(tableHandle, 'CellDoubleClickedFcn')
        tableHandle.CellDoubleClickedFcn = doubleClickCallback;
    end
end

function rows = selectedAppDetails(app)
    rows = [ ...
        {char(app.displayName)}; ...
        {['Family: ' char(app.family)]}; ...
        {['Command: ' app.command]}; ...
        {['Path: ' app.relativePath]}; ...
        cellstr(wrapDescription(app.description))];
end

function rows = noMatchingAppDetails()
    rows = {'No matching apps'; 'No app matches the current filters.'};
end

function message = launchStartStatus(app, debugMode)
    if debugMode
        message = sprintf('Launching %s in debug mode...', app.command);
    else
        message = sprintf('Launching %s...', app.command);
    end
end

function message = launchSuccessStatus(app, debugMode)
    if debugMode
        message = sprintf('Launched %s in debug mode.', app.command);
    else
        message = sprintf('Launched %s.', app.command);
    end
end

function message = cleanArtifactsStatus(result)
    if isempty(result.errors)
        message = sprintf('Cleaned %d generated artifact item(s).', ...
            result.removedCount);
    else
        message = sprintf('Cleaned %d item(s); %d item(s) failed.', ...
            result.removedCount, numel(result.errors));
    end
end

function rows = appDisplayRows(apps)
    rows = cell(numel(apps), 3);
    for k = 1:numel(apps)
        rows{k, 1} = char(apps(k).family);
        rows{k, 2} = char(apps(k).displayName);
        rows{k, 3} = apps(k).command;
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
        appCount = appCount + 1;
        apps(appCount).command = command;
        apps(appCount).displayName = displayNameFromCommand(command);
        apps(appCount).family = appFamily(appRoot, folder);
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

function app = findAppByCommand(apps, command)
    app = [];
    if isempty(apps)
        return;
    end
    idx = find(string({apps.command}) == string(command), 1);
    if ~isempty(idx)
        app = apps(idx);
    end
end

function result = cleanGeneratedArtifacts(root)
    targets = generatedArtifactTargets(root);
    removedCount = 0;
    errors = strings(0, 1);

    for k = 1:numel(targets)
        target = char(targets(k));
        try
            if exist(target, 'dir') == 7
                rmdir(target, 's');
                removedCount = removedCount + 1;
            elseif exist(target, 'file') == 2
                delete(target);
                removedCount = removedCount + 1;
            end
        catch err
            errors(end + 1, 1) = string(target) + ": " + string(err.message);
        end
    end

    result = struct( ...
        'removedCount', removedCount, ...
        'errors', errors);
end

function targets = generatedArtifactTargets(root)
    targets = string(fullfile(root, 'artifacts'));
    legacyReport = fullfile(root, 'matlab_code_check.json');
    if exist(legacyReport, 'file') == 2
        targets(end + 1) = string(legacyReport);
    end

    legacyLogs = dir(fullfile(root, 'matlab_test*.log'));
    for k = 1:numel(legacyLogs)
        if legacyLogs(k).isdir
            continue;
        end
        targets(end + 1) = string(fullfile(legacyLogs(k).folder, legacyLogs(k).name));
    end
    targets = unique(targets, 'stable');
end

function tf = confirmCleanArtifacts(fig)
    try
        choice = uiconfirm(fig, ...
            ['Remove LabKit-generated artifacts and legacy root diagnostic ' ...
            'files? This does not remove app source, docs, tests, photos, ' ...
            'or derived data folders.'], ...
            'Clean Artifacts', ...
            'Options', {'Clean', 'Cancel'}, ...
            'DefaultOption', 'Cancel', ...
            'CancelOption', 'Cancel', ...
            'Icon', 'warning');
        tf = strcmp(choice, 'Clean');
    catch
        tf = false;
    end
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
        if strlength(text) == 0 || strcmpi(text, 'Main features') || ...
                strcmpi(text, 'Notes')
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

function T = appCatalogTable(apps)
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
        'VariableNames', {'Command', 'DisplayName', 'Family', 'Folder', ...
        'RelativePath', 'Description'});
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

function parts = pathParts(pathValue)
    normalized = strrep(char(pathValue), filesep, '/');
    parts = strsplit(normalized, '/');
    parts = parts(~cellfun('isempty', parts));
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [char(root) filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
