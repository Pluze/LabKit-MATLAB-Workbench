function varargout = labkit_launcher(varargin)
%LABKIT_LAUNCHER Self-contained GUI selector and repair updater for LabKit.
%
% Usage:
%   labkit_launcher
%   apps = labkit_launcher("list")
%
% This launcher intentionally avoids dependencies on other LabKit .m files so
% it can still restore a damaged zip install when packages, apps, or scripts
% have been deleted. App launch still adds the restored app folders to the
% MATLAB path before calling the selected app entry point.

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

    initializePath(root, apps);
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
    if strlength(value) > 0 && ~strcmpi(value, "list")
        error('labkit_launcher:InvalidInput', ...
            'Unsupported labkit_launcher mode: %s', value);
    end
    mode = "list";
end

function initializePath(root, apps)
    addPathIfMissing(root);
    addPathIfMissing(fullfile(root, 'apps'), '-end');
    for k = 1:numel(apps)
        addPathIfMissing(apps(k).folder, '-end');
    end
end

function addPathIfMissing(folder, varargin)
    if exist(folder, 'dir') == 7 && ~pathContains(folder)
        addpath(folder, varargin{:});
    end
end

function fig = runLauncher(root, apps)
    panelFontSize = 15;
    tableFontSize = 15;

    figArgs = {'Name', 'LabKit App Launcher', ...
        'Position', [150 130 1260 620], 'Color', [0.97 0.98 0.99]};
    if launcherGuiTestMode() == "hidden"
        figArgs = [figArgs, {'Visible', 'off'}];
    end
    fig = uifigure(figArgs{:});
    applyLauncherGuiTestMode(fig);
    main = uigridlayout(fig, [1 3]);
    main.ColumnWidth = {360, 5, '1x'};
    main.RowHeight = {'1x'};
    main.Padding = [6 6 6 6];
    main.ColumnSpacing = 0;

    leftPanel = uipanel(main, 'Title', 'Controls', 'FontSize', panelFontSize);
    leftPanel.Layout.Row = 1;
    leftPanel.Layout.Column = 1;
    divider = uipanel(main, 'BorderType', 'none', ...
        'BackgroundColor', [0.78 0.80 0.82]);
    divider.Layout.Row = 1;
    divider.Layout.Column = 2;
    rightPanel = uipanel(main, 'Title', 'Applications', 'FontSize', panelFontSize);
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 3;

    controlsGrid = uigridlayout(leftPanel, [7 1]);
    controlsGrid.RowHeight = {34, 34, 34, 34, 34, 34, '1x'};
    controlsGrid.Padding = [6 6 6 6];
    controlsGrid.RowSpacing = 6;

    updateGrid = uigridlayout(controlsGrid, [1 3]);
    updateGrid.Layout.Row = 1;
    updateGrid.Layout.Column = 1;
    updateGrid.ColumnWidth = {'1x', '1x', '1x'};
    updateGrid.RowHeight = {'1x'};
    updateGrid.Padding = [0 0 0 0];
    updateGrid.ColumnSpacing = 6;

    updateLabel = uilabel(updateGrid, 'Text', 'GitHub download');
    updateLabel.Layout.Row = 1;
    updateLabel.Layout.Column = 1;
    btnUpdate = uibutton(updateGrid, 'Text', 'Latest', ...
        'ButtonPushedFcn', @onUpdateFromMain);
    btnUpdate.Layout.Row = 1;
    btnUpdate.Layout.Column = 2;
    btnRelease = uibutton(updateGrid, 'Text', 'Release', ...
        'ButtonPushedFcn', @onUpdateFromStable);
    btnRelease.Layout.Row = 1;
    btnRelease.Layout.Column = 3;
    if isprop(btnUpdate, 'Tooltip')
        btnUpdate.Tooltip = 'Download and apply the latest main branch zip.';
        btnRelease.Tooltip = 'Download and apply the latest GitHub release or tag zip.';
    end
    btnRefresh = uibutton(controlsGrid, 'Text', 'Refresh App List', ...
        'ButtonPushedFcn', @onRefreshApps);
    btnOpen = uibutton(controlsGrid, 'Text', 'Open Selected App', ...
        'ButtonPushedFcn', @onLaunchSelected);
    btnDebug = uibutton(controlsGrid, 'Text', 'Open Debug', ...
        'ButtonPushedFcn', @onLaunchSelectedDebug);
    btnClean = uibutton(controlsGrid, 'Text', 'Clean Artifacts', ...
        'ButtonPushedFcn', @onCleanArtifacts);
    btnCode = uibutton(controlsGrid, 'Text', 'Run Code Analyzer', ...
        'ButtonPushedFcn', @onRunCodeCheck);
    txtInfo = uitextarea(controlsGrid, 'Editable', 'off', 'Value', {'Ready.'});

    tableGrid = uigridlayout(rightPanel, [1 1]);
    tableGrid.Padding = [4 4 4 4];
    appTable = uitable(tableGrid, 'ColumnName', {'Family', 'App', 'Command'}, ...
        'ColumnEditable', [false false false], 'RowName', {}, ...
        'FontSize', tableFontSize);
    appTable.ColumnWidth = {160, 220, 'auto'};
    configureTable(appTable, @onSelectionChanged, @onTableDoubleClicked);

    ui = struct();
    ui.figure = fig;
    ui.controls = struct();
    ui.controls.selectedDetails = struct('textArea', txtInfo);
    ui.controls.statusLine = struct('textArea', txtInfo);
    ui.controls.appTable = struct('table', appTable);
    setappdata(fig, 'labkitUiRegistry', ui);

    state = struct('apps', apps, 'visibleApps', apps, 'selectedRow', 1, ...
        'status', integrityStatus(root, apps));
    refreshTable();

    function onRefreshApps(varargin)
        state.apps = discoverApps(root);
        state.visibleApps = state.apps;
        state.selectedRow = 1;
        initializePath(root, state.apps);
        refreshTable();
    end

    function onSelectionChanged(~, event)
        row = eventRow(event);
        if ~isnan(row)
            state.selectedRow = row;
            refreshSelection();
        end
    end

    function onTableDoubleClicked(~, event)
        row = eventRow(event);
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

    function onCleanArtifacts(varargin)
        if ~confirmCleanArtifacts(fig)
            setStatus('Clean artifacts canceled.');
            return;
        end
        setStatus(cleanArtifactsStatus(cleanGeneratedArtifacts(root)));
    end

    function onRunCodeCheck(varargin)
        setStatus('Running MATLAB Code Analyzer...');
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'MATLAB Code Analyzer', ...
                'Message', 'Preparing scan...', 'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            report = runCodeAnalyzerReport(root, @onCodeCheckProgress);
            setStatus(codeCheckStatus(report));
        catch err
            setStatus(sprintf('Code Analyzer failed: %s', err.message));
        end
        clear dlgCleanup;

        function onCodeCheckProgress(message, value)
            setStatus(message);
            if ~isempty(dlg) && isvalid(dlg)
                dlg.Message = char(message);
                if isfinite(value)
                    dlg.Indeterminate = 'off';
                    dlg.Value = min(max(value, 0), 1);
                end
            end
            drawnow limitrate;
        end
    end

    function onUpdateFromMain(varargin)
        setStatus('Updating LabKit from GitHub main...');
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Update LabKit', ...
                'Message', 'Preparing update...', 'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            result = launcherUpdateFromMainZip(root, @onUpdateProgress);
            setStatus(result.message);
            onRefreshApps();
        catch err
            setStatus(sprintf('Update failed: %s', err.message));
        end
        clear dlgCleanup;

        function onUpdateProgress(message, value)
            setStatus(message);
            if ~isempty(dlg) && isvalid(dlg)
                dlg.Message = char(message);
                if isfinite(value)
                    dlg.Indeterminate = 'off';
                    dlg.Value = value;
                end
            end
            drawnow limitrate;
        end
    end

    function onUpdateFromStable(varargin)
        setStatus('Updating LabKit from latest release/tag...');
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Update LabKit', ...
                'Message', 'Preparing release update...', 'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            result = launcherUpdateFromStableZip(root, @onUpdateProgress);
            setStatus(result.message);
            onRefreshApps();
        catch err
            setStatus(sprintf('Update failed: %s', err.message));
        end
        clear dlgCleanup;

        function onUpdateProgress(message, value)
            setStatus(message);
            if ~isempty(dlg) && isvalid(dlg)
                dlg.Message = char(message);
                if isfinite(value)
                    dlg.Indeterminate = 'off';
                    dlg.Value = value;
                end
            end
            drawnow limitrate;
        end
    end

    function launchSelectedApp(debugMode)
        if isempty(state.visibleApps)
            setStatus('No app entry points found. Use GitHub Update to repair this install.');
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        app = state.visibleApps(row);
        setStatus(launchStartStatus(app, debugMode));
        drawnow;
        try
            addPathIfMissing(app.folder, '-end');
            if debugMode
                feval(app.command, "debug");
            else
                feval(app.command);
            end
            setStatus(launchSuccessStatus(app, debugMode));
        catch err
            setStatus(sprintf(['Failed to launch %s: %s. If project files are missing ' ...
                'or damaged, use GitHub Update to repair this install.'], ...
                app.command, err.message));
        end
    end

    function refreshTable()
        state.visibleApps = state.apps;
        appTable.Data = appDisplayRows(state.visibleApps);
        state.selectedRow = min(max(state.selectedRow, 1), max(numel(state.visibleApps), 1));
        setLaunchEnabled(~isempty(state.visibleApps));
        refreshSelection();
        if isempty(state.visibleApps)
            setStatus('No app entry points found. Use GitHub Update to repair this install.');
        else
            setStatus(integrityStatus(root, state.apps));
        end
    end

    function refreshSelection()
        if isempty(state.visibleApps)
            updateInfo(noMatchingAppDetails());
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        updateInfo(selectedAppDetails(state.visibleApps(row)));
    end

    function setLaunchEnabled(enabled)
        stateValue = matlab.lang.OnOffSwitchState(enabled);
        btnOpen.Enable = stateValue;
        btnDebug.Enable = stateValue;
    end

    function setStatus(message)
        state.status = string(message);
        refreshSelection();
    end

    function updateInfo(detailRows)
        rows = reshape(cellstr(string(detailRows(:))), [], 1);
        txtInfo.Value = [{['Status: ' char(state.status)]}; {''}; rows];
    end
end

function configureTable(tableHandle, selectionCallback, doubleClickCallback)
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

function row = eventRow(event)
    row = NaN;
    if isprop(event, 'Indices') && ~isempty(event.Indices)
        row = event.Indices(1, 1);
    elseif isprop(event, 'Selection') && ~isempty(event.Selection)
        row = event.Selection(1, 1);
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

function rows = selectedAppDetails(app)
    rows = [{char(app.displayName)}; {['Family: ' char(app.family)]}; ...
        {['Command: ' app.command]}; {['Path: ' app.relativePath]}; ...
        cellstr(wrapDescription(app.description))];
end

function rows = noMatchingAppDetails()
    rows = {'No app entry points found.'; 'Use GitHub Update to repair this install.'};
end

function message = integrityStatus(root, apps)
    missing = missingManagedProjectParts(root);
    if isempty(apps)
        message = "No app entry points found. Use GitHub Update to repair this install.";
    elseif isempty(missing)
        message = sprintf('%d app(s) available. Project structure looks complete.', numel(apps));
    else
        message = sprintf(['%d app(s) available, but managed project parts are ' ...
            'missing: %s. Use GitHub Update to repair this install.'], ...
            numel(apps), strjoin(cellstr(missing), ', '));
    end
end

function missing = missingManagedProjectParts(root)
    required = ["+labkit", "apps", "docs", "tests", "buildfile.m", ...
        "README.md", "AGENTS.md"];
    missing = strings(1, 0);
    for k = 1:numel(required)
        path = fullfile(root, char(required(k)));
        if exist(path, "file") ~= 2 && exist(path, "dir") ~= 7
            missing(end+1) = required(k);
        end
    end
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
        message = sprintf('Cleaned %d generated artifact item(s).', result.removedCount);
    else
        message = sprintf('Cleaned %d item(s); %d item(s) failed.', ...
            result.removedCount, numel(result.errors));
    end
end

function message = codeCheckStatus(report)
    message = sprintf('Code Analyzer wrote %s: %d message(s) across %d file(s), %d scan error(s).', ...
        char(report.outputs.json), report.summary.messageCount, ...
        report.summary.filesWithMessages, report.summary.scanErrorCount);
end

function apps = discoverApps(root)
    appRoot = fullfile(root, 'apps');
    template = emptyAppStruct();
    if exist(appRoot, 'dir') ~= 7
        apps = template;
        return;
    end
    entries = dir(fullfile(appRoot, '**', 'labkit_*_app.m'));
    entries = entries(~[entries.isdir]);
    apps = repmat(template, numel(entries), 1);
    appCount = 0;
    for k = 1:numel(entries)
        filepath = fullfile(entries(k).folder, entries(k).name);
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
    if ~isempty(apps)
        keys = [reshape(string({apps.family}), [], 1), ...
            reshape(string({apps.displayName}), [], 1)];
        [~, order] = sortrows(keys);
        apps = apps(order);
    end
end

function app = emptyAppStruct()
    app = struct('command', {}, 'displayName', {}, 'family', {}, ...
        'folder', {}, 'relativePath', {}, 'description', {});
end

function catalog = appCatalogTable(apps)
    catalog = table(string({apps.command})', string({apps.displayName})', ...
        string({apps.family})', string({apps.folder})', ...
        string({apps.relativePath})', string({apps.description})', ...
        'VariableNames', {'Command', 'DisplayName', 'Family', 'Folder', ...
        'RelativePath', 'Description'});
end

function tf = isHiddenImplementationPath(rel)
    parts = split(string(strrep(rel, filesep, '/')), '/');
    tf = any(startsWith(parts, '+')) || any(parts == "private");
end

function name = displayNameFromCommand(command)
    name = regexprep(command, '^labkit_', '');
    name = regexprep(name, '_app$', '');
    name = regexprep(name, '_', ' ');
    words = split(string(name));
    for k = 1:numel(words)
        words(k) = upper(extractBefore(words(k), 2)) + extractAfter(words(k), 1);
    end
    name = strjoin(cellstr(words), ' ');
end

function family = appFamily(appRoot, folder)
    rel = relativePath(appRoot, folder);
    parts = split(string(strrep(rel, filesep, '/')), '/');
    if isempty(parts) || strlength(parts(1)) == 0
        family = "General";
    else
        family = displayToken(parts(1));
    end
end

function value = displayToken(token)
    words = split(strrep(string(token), '_', ' '));
    for k = 1:numel(words)
        words(k) = upper(extractBefore(words(k), 2)) + extractAfter(words(k), 1);
    end
    value = strjoin(cellstr(words), ' ');
end

function description = appDescription(filepath, command)
    description = "";
    try
        text = fileread(filepath);
    catch
        return;
    end
    lines = splitlines(string(text));
    for k = 1:min(numel(lines), 20)
        line = strtrim(lines(k));
        prefix = "%" + upper(command);
        if startsWith(line, prefix, 'IgnoreCase', true)
            description = strtrim(erase(extractAfter(line, strlength(prefix)), "-"));
            return;
        elseif startsWith(line, "%")
            cleaned = strtrim(extractAfter(line, 1));
            if strlength(cleaned) > 0 && ~startsWith(cleaned, "Usage")
                description = cleaned;
                return;
            end
        end
    end
end

function lines = wrapDescription(description)
    text = string(description);
    if strlength(text) == 0
        lines = "No description found in the app header.";
        return;
    end
    parts = regexp(char(text), '(?<=[.!?])\s+', 'split');
    lines = strings(0, 1);
    for k = 1:numel(parts)
        value = strtrim(string(parts{k}));
        if strlength(value) > 0
            lines(end+1, 1) = value;
        end
    end
    lines = lines(1:min(numel(lines), 3));
end

function result = cleanGeneratedArtifacts(root)
    try
        root = validateCleanArtifactsRoot(root);
    catch err
        result = struct('removedCount', 0, 'errors', string(err.message));
        return;
    end

    targets = {
        'artifacts'
        'matlab_code_check.json'
        'matlab_test.log'
    };
    removedCount = 0;
    errors = strings(0, 1);
    for k = 1:numel(targets)
        relativeTarget = targets{k};
        target = fullfile(root, relativeTarget);
        try
            validateCleanArtifactsTarget(root, target, relativeTarget);
            if exist(target, 'dir') == 7
                rmdir(target, 's');
                removedCount = removedCount + 1;
            elseif exist(target, 'file') == 2
                delete(target);
                removedCount = removedCount + 1;
            end
        catch err
            errors(end+1) = string(err.message);
        end
    end
    result = struct('removedCount', removedCount, 'errors', errors);
end

function root = validateCleanArtifactsRoot(root)
    root = canonicalPath(root);
    if isSamePath(root, filesep)
        error('labkit_launcher:UnsafeCleanRoot', ...
            'Clean Artifacts refused to use the filesystem root as the project root.');
    end
    if exist(fullfile(root, 'labkit_launcher.m'), 'file') ~= 2
        error('labkit_launcher:UnsafeCleanRoot', ...
            'Clean Artifacts refused a folder that is not a LabKit launcher root: %s', root);
    end
end

function validateCleanArtifactsTarget(root, target, relativeTarget)
    if exist(target, 'dir') ~= 7 && exist(target, 'file') ~= 2
        return;
    end

    canonicalRoot = canonicalPath(root);
    canonicalTarget = canonicalPath(target);
    expectedTarget = fullfile(canonicalRoot, relativeTarget);
    if ~isSamePath(canonicalTarget, expectedTarget) || ...
            isSamePath(canonicalTarget, canonicalRoot) || ...
            ~startsWith(string(canonicalTarget), string([canonicalRoot filesep]))
        error('labkit_launcher:UnsafeCleanTarget', ...
            'Clean Artifacts refused unsafe target: %s', target);
    end
end

function resolvedPath = canonicalPath(filepath)
    resolvedPath = char(java.io.File(char(filepath)).getCanonicalPath());
end

function tf = isSamePath(left, right)
    if ispc
        tf = strcmpi(char(left), char(right));
    else
        tf = strcmp(char(left), char(right));
    end
end

function tf = confirmCleanArtifacts(fig)
    try
        choice = uiconfirm(fig, ...
            'Remove generated LabKit artifacts and old diagnostic logs?', ...
            'Clean Artifacts', 'Options', {'Clean', 'Cancel'}, ...
            'DefaultOption', 'Cancel', 'CancelOption', 'Cancel');
        tf = strcmp(choice, 'Clean');
    catch
        tf = false;
    end
end

function report = runCodeAnalyzerReport(root, progressFcn)
    if nargin < 2
        progressFcn = [];
    end
    excludedFolders = [".git", ".github", ".vscode", ".codes", ...
        "artifacts", "node_modules", "photos"];
    notifyProgress(progressFcn, "Finding MATLAB files...", 0.02);
    files = sort(collectFiles(root, "*.m", excludedFolders));
    fileReports = emptyCodeCheckFileReport();
    scanErrors = emptyCodeCheckScanError();
    totalFiles = max(numel(files), 1);
    for k = 1:numel(files)
        filepath = char(files(k));
        rel = string(relativePath(root, filepath));
        notifyProgress(progressFcn, ...
            sprintf("Scanning %d/%d: %s", k, numel(files), char(rel)), ...
            0.05 + 0.90 * (k - 1) / totalFiles);
        try
            rawMessages = checkcode(filepath, '-id');
        catch err
            scanErrors(end+1) = struct("path", rel, ...
                "absolutePath", string(filepath), ...
                "identifier", string(err.identifier), ...
                "message", string(err.message));
            rawMessages = struct([]);
        end
        messages = normalizeCodeCheckMessages(rel, filepath, rawMessages);
        if ~isempty(messages)
            fileReports(end+1) = struct("path", rel, ...
                "absolutePath", string(filepath), ...
                "messageCount", numel(messages), ...
                "messages", messages);
        end
    end
    output = fullfile(root, 'artifacts', 'code-check', 'matlab_code_check.json');
    notifyProgress(progressFcn, "Writing Code Analyzer report...", 0.96);
    ensureFolder(fileparts(output));
    messageCount = sum(arrayfun(@(item) item.messageCount, fileReports));
    report = struct();
    report.schemaVersion = "1.1";
    report.generatedAt = string(datetime("now", "TimeZone", "local", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ssXXX"));
    report.generator = "labkit_launcher";
    report.root = string(root);
    report.outputs = struct("json", string(relativePath(root, output)));
    report.scope = struct("description", ...
        "All .m files under the repository except generated, hidden, photo, and dependency folders.", ...
        "excludedFolders", excludedFolders);
    report.summary = struct('filesScanned', numel(files), ...
        'filesWithMessages', numel(fileReports), ...
        'messageCount', messageCount, ...
        'scanErrorCount', numel(scanErrors));
    report.files = fileReports;
    report.scanErrors = scanErrors;
    writeText(output, jsonencode(report, PrettyPrint=true));
    notifyProgress(progressFcn, "Code Analyzer report complete.", 1.00);
end

function messages = normalizeCodeCheckMessages(rel, filepath, rawMessages)
    messages = emptyCodeCheckMessage();
    lineText = readFileLines(filepath);
    for k = 1:numel(rawMessages)
        raw = rawMessages(k);
        line = numericVectorField(raw, "line");
        column = numericVectorField(raw, "column");
        message = stringField(raw, "message");
        primaryLine = firstNumeric(line);
        if primaryLine >= 1 && primaryLine <= numel(lineText)
            sourceLine = string(strtrim(lineText(primaryLine)));
        else
            sourceLine = "";
        end
        messages(end+1) = struct("path", rel, ...
            "absolutePath", string(filepath), ...
            "line", line, ...
            "column", column, ...
            "id", analyzerId(raw, message), ...
            "message", message, ...
            "fix", fixText(raw), ...
            "sourceLine", sourceLine);
    end
end

function lines = readFileLines(filepath)
    try
        lines = readlines(filepath);
    catch
        lines = splitlines(string(fileread(filepath)));
    end
end

function id = analyzerId(raw, message)
    id = stringField(raw, "id");
    if strlength(id) > 0
        return;
    end
    tokens = regexp(char(message), "\(([^()]+)\)\s*$", "tokens", "once");
    if ~isempty(tokens)
        id = string(tokens{1});
    end
end

function value = numericVectorField(raw, name)
    if isfield(raw, name) && ~isempty(raw.(name))
        value = double(raw.(name));
    else
        value = NaN;
    end
end

function value = firstNumeric(values)
    values = values(~isnan(values));
    if isempty(values)
        value = NaN;
    else
        value = values(1);
    end
end

function value = stringField(raw, name)
    if isfield(raw, name) && ~isempty(raw.(name))
        value = string(raw.(name));
    else
        value = "";
    end
end

function value = fixText(raw)
    value = "";
    if isfield(raw, "fix") && ~isempty(raw.fix) && ...
            (ischar(raw.fix) || isstring(raw.fix))
        value = string(raw.fix);
    end
end

function value = emptyCodeCheckFileReport()
    value = repmat(struct("path", "", "absolutePath", "", ...
        "messageCount", 0, "messages", emptyCodeCheckMessage()), 1, 0);
end

function value = emptyCodeCheckMessage()
    value = repmat(struct("path", "", "absolutePath", "", ...
        "line", NaN, "column", NaN, "id", "", "message", "", ...
        "fix", "", "sourceLine", ""), 1, 0);
end

function value = emptyCodeCheckScanError()
    value = repmat(struct("path", "", "absolutePath", "", ...
        "identifier", "", "message", ""), 1, 0);
end

function result = launcherUpdateFromMainZip(root, progressFcn)
    source = struct( ...
        "kind", "main", ...
        "label", "GitHub main", ...
        "zipUrl", "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/heads/main.zip", ...
        "zipName", "main.zip");
    result = launcherUpdateFromZipSource(root, source, progressFcn);
end

function result = launcherUpdateFromStableZip(root, progressFcn)
    notifyProgress(progressFcn, "Checking LabKit folder...", 0.05);
    assertUpdateTargetRoot(root);
    notifyProgress(progressFcn, "Checking update mode...", 0.10);
    assertNotGitCheckout(root);
    notifyProgress(progressFcn, "Checking install folder hygiene...", 0.11);
    assertNoUnmanagedInstallFiles(root);
    notifyProgress(progressFcn, "Resolving latest GitHub release or tag...", 0.12);
    source = resolveStableZipSource();
    result = launcherUpdateFromZipSource(root, source, progressFcn, true);
end

function result = launcherUpdateFromZipSource(root, source, progressFcn, preflightDone)
    if nargin < 4
        preflightDone = false;
    end
    tempRoot = tempname;
    cleanup = onCleanup(@() removeFolderIfPresent(tempRoot));
    if ~preflightDone
        notifyProgress(progressFcn, "Checking LabKit folder...", 0.05);
        assertUpdateTargetRoot(root);
        notifyProgress(progressFcn, "Checking update mode...", 0.10);
        assertNotGitCheckout(root);
        notifyProgress(progressFcn, "Checking install folder hygiene...", 0.11);
        assertNoUnmanagedInstallFiles(root);
    end
    if ~confirmUpdate(root, source.label)
        result = summaryStruct(root, "", 0, 0, "Update canceled.");
        return;
    end
    notifyProgress(progressFcn, "Preparing update workspace...", 0.15);
    ensureFolder(tempRoot);
    zipPath = fullfile(tempRoot, char(source.zipName));
    extractRoot = fullfile(tempRoot, "extracted");
    notifyProgress(progressFcn, sprintf("Downloading %s zip...", char(source.label)), 0.25);
    fetchZip(source.zipUrl, zipPath);
    notifyProgress(progressFcn, "Extracting update zip...", 0.40);
    unzip(char(zipPath), char(extractRoot));
    sourceRoot = findExtractedProjectRoot(extractRoot);
    assertInstallRoot(sourceRoot);
    removedApps = removedAppEntrypoints(root, sourceRoot);
    if ~isempty(removedApps) && ~confirmDestructiveUpdate(source.label, removedApps)
        result = summaryStruct(root, "", 0, 0, ...
            "Update canceled because the candidate removes app entrypoints.");
        return;
    end
    notifyProgress(progressFcn, "Reading managed file list...", 0.55);
    newFiles = collectManagedFiles(sourceRoot);
    oldFiles = readManifest(root);
    notifyProgress(progressFcn, "Copying LabKit-managed files...", 0.75);
    copiedCount = overlayManagedFiles(sourceRoot, root, newFiles);
    notifyProgress(progressFcn, "Removing retired managed files...", 0.90);
    deletedCount = deleteStaleManagedFiles(root, oldFiles, newFiles);
    notifyProgress(progressFcn, "Writing update manifest...", 0.96);
    writeManifest(root, newFiles);
    notifyProgress(progressFcn, "Update complete.", 1.00);
    result = summaryStruct(root, "", copiedCount, deletedCount, ...
        sprintf(['Updated from %s. Copied %d file(s), removed %d ' ...
        'retired managed file(s). Restart labkit_launcher.'], ...
        char(source.label), copiedCount, deletedCount));
    clear cleanup;
    removeFolderIfPresent(tempRoot);
end

function source = resolveStableZipSource()
    release = latestStableRelease();
    if strlength(release.tagName) > 0
        source = stableSourceFromTag(release.tagName, ...
            sprintf("GitHub release %s", release.tagName));
        return;
    end
    tagName = latestGitHubTag();
    if strlength(tagName) > 0
        source = stableSourceFromTag(tagName, sprintf("GitHub tag %s", tagName));
        return;
    end
    error("labkit_launcher:NoStableRelease", ...
        "Could not find a GitHub release or tag to download.");
end

function release = latestStableRelease()
    release = struct("tagName", "");
    try
        options = weboptions("Timeout", 20, "UserAgent", "MATLAB LabKit Launcher");
        raw = webread("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/releases", options);
    catch
        return;
    end
    if ~isstruct(raw)
        return;
    end
    for k = 1:numel(raw)
        item = raw(k);
        if logicalField(item, "draft") || logicalField(item, "prerelease")
            continue;
        end
        tag = stringField(item, "tag_name");
        if strlength(tag) > 0
            release.tagName = tag;
            return;
        end
    end
end

function tagName = latestGitHubTag()
    tagName = "";
    try
        options = weboptions("Timeout", 20, "UserAgent", "MATLAB LabKit Launcher");
        raw = webread("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/tags", options);
    catch
        return;
    end
    if isstruct(raw) && ~isempty(raw)
        tagName = stringField(raw(1), "name");
    end
end

function source = stableSourceFromTag(tagName, label)
    safeTag = encodeUrlPathSegment(tagName);
    source = struct( ...
        "kind", "stable", ...
        "label", string(label), ...
        "zipUrl", "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/tags/" + string(safeTag) + ".zip", ...
        "zipName", "stable-" + sanitizeFilename(tagName) + ".zip");
end

function encoded = encodeUrlPathSegment(value)
    encoded = char(string(value));
    encoded = strrep(encoded, '%', '%25');
    encoded = strrep(encoded, ' ', '%20');
    encoded = strrep(encoded, '#', '%23');
    encoded = strrep(encoded, '?', '%3F');
    encoded = strrep(encoded, '/', '%2F');
end

function value = logicalField(raw, name)
    value = false;
    if isfield(raw, name) && ~isempty(raw.(name))
        value = logical(raw.(name));
    end
end

function assertUpdateTargetRoot(root)
    hasLauncher = exist(fullfile(root, "labkit_launcher.m"), "file") == 2;
    hasLabkit = exist(fullfile(root, "+labkit"), "dir") == 7;
    if ~hasLauncher && ~hasLabkit
        error("labkit_launcher:InvalidRoot", ...
            "Run from a folder containing labkit_launcher.m or +labkit: %s", root);
    end
end

function assertInstallRoot(root)
    if exist(fullfile(root, "labkit_launcher.m"), "file") ~= 2 || ...
            exist(fullfile(root, "+labkit"), "dir") ~= 7 || ...
            exist(fullfile(root, "apps"), "dir") ~= 7
        error("labkit_launcher:InvalidRoot", ...
            "Downloaded zip did not contain a complete LabKit install root.");
    end
end

function assertNotGitCheckout(root)
    if exist(fullfile(root, ".git"), "dir") == 7
        error("labkit_launcher:GitCheckout", ...
            "Update from GitHub zip is disabled for git checkouts. Use git to sync this working tree.");
    end
end

function mode = launcherGuiTestMode()
    mode = lower(strtrim(string(getenv('LABKIT_GUI_TEST_MODE'))));
    if ~any(mode == ["hidden", "minimized"])
        mode = "visible";
    end
end

function applyLauncherGuiTestMode(fig)
    if launcherGuiTestMode() == "minimized" && isprop(fig, 'WindowState')
        try
            fig.WindowState = 'minimized';
        catch
        end
    end
end

function assertNoUnmanagedInstallFiles(root)
    files = collectRelativeFiles(root);
    unmanaged = strings(1, 0);
    for k = 1:numel(files)
        rel = files(k);
        if isManagedRelativePath(rel) || isLauncherRuntimePath(rel)
            continue;
        end
        unmanaged(end+1) = rel;
    end
    unmanaged = sort(unique(unmanaged));
    if isempty(unmanaged)
        return;
    end
    preview = unmanaged(1:min(20, numel(unmanaged)));
    suffix = '';
    if numel(unmanaged) > numel(preview)
        suffix = sprintf('\n... and %d more file(s)', numel(unmanaged) - numel(preview));
    end
    error("labkit_launcher:UnmanagedInstallFiles", ...
        ['LabKit update refused because this folder contains files that are ' ...
        'not part of LabKit-managed artifacts. Keep lab data and exports outside ' ...
        'the LabKit install folder, then remove or move these files before updating:\n\n%s%s'], ...
        strjoin(cellstr(preview), newline), suffix);
end

function tf = confirmUpdate(root, sourceLabel)
    message = sprintf(['Download %s zip and overwrite ' ...
        'LabKit-managed files in:\n\n%s\n\nLabKit install folders should not ' ...
        'contain personal data, lab files, or exports. This update has already ' ...
        'refused unmanaged files and will fully replace managed LabKit files.'], ...
        char(sourceLabel), root);
    try
        choice = questdlg(message, "Update LabKit", "Update", "Cancel", "Cancel");
        tf = strcmp(choice, "Update");
    catch
        tf = false;
    end
end

function tf = confirmDestructiveUpdate(sourceLabel, removedApps)
    appList = strjoin(cellstr(removedApps(:)), newline);
    message = sprintf(['The %s update removes or merges these app entrypoints:\n\n%s\n\n' ...
        'This is a destructive LabKit update. Continue only if you do not need ' ...
        'those old entrypoints, or cancel and manually choose an older release tag.'], ...
        char(sourceLabel), appList);
    try
        choice = questdlg(message, "Destructive LabKit Update", ...
            "Continue update", "Cancel", "Cancel");
        tf = strcmp(choice, "Continue update");
    catch
        tf = false;
    end
end

function fetchZip(sourceUrl, zipPath)
    websave(zipPath, sourceUrl);
end

function sourceRoot = findExtractedProjectRoot(extractRoot)
    entries = dir(extractRoot);
    entries = entries([entries.isdir]);
    entries = entries(~ismember(string({entries.name}), [".", ".."]));
    for k = 1:numel(entries)
        candidate = fullfile(entries(k).folder, entries(k).name);
        if exist(fullfile(candidate, "labkit_launcher.m"), "file") == 2
            sourceRoot = candidate;
            return;
        end
    end
    error("labkit_launcher:InvalidZip", "Downloaded zip did not contain a LabKit project root.");
end

function files = collectManagedFiles(root)
    entries = dir(fullfile(root, "**", "*"));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        rel = relativePath(root, fullfile(entries(k).folder, entries(k).name));
        if isManagedRelativePath(rel)
            files(end+1) = string(rel);
        end
    end
    files = sort(unique(files));
end

function tf = isManagedRelativePath(rel)
    parts = split(string(strrep(rel, filesep, "/")), "/");
    rootFiles = ["AGENTS.md", "LICENSE", "README.md", "buildfile.m", ...
        "labkit_launcher.m", ".gitignore"];
    managedRoots = ["+labkit", "apps", "docs", "scripts", "tests", ".agents", ".github"];
    tf = ismember(string(rel), rootFiles) || ismember(parts(1), managedRoots);
end

function tf = isLauncherRuntimePath(rel)
    rel = string(strrep(rel, filesep, "/"));
    parts = split(rel, "/");
    name = parts(end);
    tf = rel == ".labkit-managed-files.txt" || ...
        parts(1) == "artifacts" || ...
        startsWith(name, "LabKit-backup-") && endsWith(name, ".zip");
end

function removed = removedAppEntrypoints(currentRoot, sourceRoot)
    currentApps = collectAppEntrypoints(currentRoot);
    sourceApps = collectAppEntrypoints(sourceRoot);
    removed = setdiff(currentApps, sourceApps);
end

function apps = collectAppEntrypoints(root)
    entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    apps = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        apps(end+1) = string(relativePath(root, ...
            fullfile(entries(k).folder, entries(k).name)));
    end
    apps = sort(unique(apps));
end

function backupPath = createBackup(root, tempRoot, newFiles, oldFiles)
    backupFiles = filesToBackup(root, newFiles, oldFiles);
    backupPath = fullfile(root, sprintf("LabKit-backup-%s.zip", ...
        char(datetime("now", "Format", "yyyyMMdd-HHmmss"))));
    staging = fullfile(tempRoot, "backup-staging");
    ensureFolder(staging);
    writeText(fullfile(staging, "README_RESTORE.txt"), ...
        ["This zip contains LabKit-managed files overwritten or removed during an update." newline ...
        "To restore, unzip it over the LabKit install folder." newline]);
    for k = 1:numel(backupFiles)
        source = fullfile(root, char(backupFiles(k)));
        if exist(source, "file") ~= 2
            continue;
        end
        target = fullfile(staging, char(backupFiles(k)));
        ensureFolder(fileparts(target));
        copyfile(source, target);
    end
    zipFiles = collectRelativeFiles(staging);
    zip(char(backupPath), cellstr(zipFiles), char(staging));
end

function files = filesToBackup(root, newFiles, oldFiles)
    manifest = manifestPath(root);
    changed = newFiles(arrayfun(@(f) exist(fullfile(root, char(f)), "file") == 2, newFiles));
    stale = setdiff(oldFiles, newFiles);
    files = unique([changed(:); stale(:)]);
    if exist(manifest, "file") == 2
        files(end+1) = string(relativePath(root, manifest));
    end
    files = sort(unique(files));
end

function copiedCount = overlayManagedFiles(sourceRoot, root, files)
    copiedCount = 0;
    for k = 1:numel(files)
        source = fullfile(sourceRoot, char(files(k)));
        target = fullfile(root, char(files(k)));
        ensureFolder(fileparts(target));
        copyfile(source, target, "f");
        copiedCount = copiedCount + 1;
    end
end

function deletedCount = deleteStaleManagedFiles(root, oldFiles, newFiles)
    stale = setdiff(oldFiles, newFiles);
    deletedCount = 0;
    for k = 1:numel(stale)
        target = fullfile(root, char(stale(k)));
        if exist(target, "file") == 2 && isManagedRelativePath(stale(k))
            delete(target);
            deletedCount = deletedCount + 1;
        end
    end
end

function writeManifest(root, files)
    writeText(manifestPath(root), strjoin(cellstr(files), newline) + newline);
end

function files = readManifest(root)
    path = manifestPath(root);
    if exist(path, "file") ~= 2
        files = strings(1, 0);
        return;
    end
    files = string(splitlines(strtrim(fileread(path)))).';
    files = files(strlength(files) > 0);
end

function path = manifestPath(root)
    path = fullfile(root, ".labkit-managed-files.txt");
end

function result = summaryStruct(root, backupPath, copiedCount, deletedCount, message)
    result = struct("updated", copiedCount > 0 || deletedCount > 0, ...
        "root", string(root), "backupZip", string(backupPath), ...
        "copiedCount", copiedCount, "deletedCount", deletedCount, ...
        "message", string(message));
end

function notifyProgress(progressFcn, message, value)
    try
        progressFcn(string(message), value);
    catch
    end
end

function files = collectFiles(root, pattern, excludedFolders)
    entries = dir(fullfile(root, "**", pattern));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        rel = string(relativePath(root, filepath));
        parts = split(strrep(rel, filesep, "/"), "/");
        if any(ismember(parts, excludedFolders))
            continue;
        end
        files(end+1) = filepath;
    end
end

function files = collectRelativeFiles(root)
    entries = dir(fullfile(root, "**", "*"));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if ~entries(k).isdir
            files(end+1) = string(relativePath(root, fullfile(entries(k).folder, entries(k).name)));
        end
    end
    files = sort(unique(files));
end

function ensureFolder(folder)
    if strlength(string(folder)) > 0 && exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function writeText(filepath, text)
    ensureFolder(fileparts(filepath));
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write file: %s", filepath);
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleaner;
end

function name = sanitizeFilename(value)
    name = regexprep(char(string(value)), '[^A-Za-z0-9._-]', '-');
    if isempty(name)
        name = 'release';
    end
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [char(root) filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
