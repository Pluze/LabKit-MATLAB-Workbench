function varargout = labkit_launcher(varargin)
%LABKIT_LAUNCHER Self-contained GUI selector and repair updater for LabKit.
%
% Usage:
%   labkit_launcher
%   apps = labkit_launcher("list")
%   info = labkit_launcher("version")
%   records = labkit_launcher("history", appCommand)
%
% This launcher intentionally avoids dependencies on other LabKit .m files so
% it can still restore a damaged zip install when packages, apps, or scripts
% have been deleted. App launch still adds the restored app folders to the
% MATLAB path before calling the selected app entry point.
%
% Maintenance map:
%   Section: Public entrypoint and version
%   Section: Path setup
%   Section: Main launcher window
%   Section: App version history window
%   Section: Version manager window
%   Section: Version manager support
%   Section: Table selection and display helpers
%   Section: Launcher status messages
%   Section: App discovery and catalog metadata
%   Section: Clean Artifacts action
%   Section: Code Analyzer action
%   Section: Performance profile action
%   Section: App package action
%   Section: Update entrypoints and install transaction
%   Section: GitHub update source discovery
%   Section: Update validation and launcher window helpers
%   Section: Update install file operations
%   Section: Shared filesystem and path helpers

    [mode, modeArgs] = parseMode(varargin);
    if mode == "version"
        varargout = {launcherVersion()};
        return;
    end

    if mode == "list"
        root = fileparts(mfilename('fullpath'));
        apps = discoverApps(root);
        varargout = {appCatalogTable(apps)};
        return;
    end
    if mode == "history"
        root = fileparts(mfilename('fullpath'));
        varargout = {launcherAppHistory(root, modeArgs(1))};
        return;
    end
    if nargout > 1
        error('labkit_launcher:TooManyOutputs', ...
            'labkit_launcher returns at most the launcher figure handle.');
    end

    root = fileparts(mfilename('fullpath'));
    initializeLauncherPath(root);
    fig = runLauncher(root);
    if nargout == 1
        varargout = {fig};
    end
end

%% Section: Public entrypoint and version

function [mode, modeArgs] = parseMode(args)
    mode = "gui";
    modeArgs = strings(1, 0);
    if isempty(args)
        return;
    end
    first = string(args{1});
    if numel(args) == 2 && isscalar(first) && strcmpi(first, "history")
        command = string(args{2});
        if ~isscalar(command) || strlength(strtrim(command)) == 0
            error('labkit_launcher:InvalidInput', ...
                'History mode requires one nonempty app command.');
        end
        mode = "history";
        modeArgs = command;
        return;
    end
    if numel(args) ~= 1
        error('labkit_launcher:InvalidInput', ...
            ['labkit_launcher accepts no inputs, "list", "version", or ' ...
            '"history" plus one app command.']);
    end
    value = string(args{1});
    if ~isscalar(value)
        error('labkit_launcher:InvalidInput', ...
            'labkit_launcher mode must be a string scalar.');
    end
    if strlength(strtrim(value)) == 0
        error('labkit_launcher:InvalidInput', ...
            'Unsupported labkit_launcher mode: empty string.');
    end
    if strcmpi(value, "list")
        mode = "list";
        return;
    end
    if strcmpi(value, "version")
        mode = "version";
        return;
    end
    error('labkit_launcher:InvalidInput', ...
        'Unsupported labkit_launcher mode: %s', value);
end

function info = launcherVersion()
    info = struct( ...
        "name", "labkit_launcher", ...
        "displayName", "LabKit App Launcher", ...
        "version", "1.4.0", ...
        "updated", "2026-07-13");
end

function titleText = launcherVersionTitle()
    info = launcherVersion();
    titleText = info.displayName + " v" + info.version + " (" + info.updated + ")";
end

%% Section: Path setup

function initializeLauncherPath(root)
    addPathIfMissing(root);
    setappdata(groot, 'labkitFigureStudioLauncher', ...
        @(ax) launchFigureStudioFromAxes(root, ax));
end

function addPathIfMissing(folder, varargin)
    if exist(folder, 'dir') == 7 && ~pathContains(folder)
        addpath(folder, varargin{:});
    end
end

function launchFigureStudioFromAxes(root, ax)
    addPathIfMissing(fullfile(root, 'apps', 'labkit_core', 'figure_studio'));
    labkit_FigureStudio_app("axes", ax);
end

%% Section: Main launcher window

function fig = runLauncher(root)
    panelFontSize = 15;
    tableFontSize = 15;

    closeExistingLauncherFigures();
    figArgs = {'Name', 'LabKit App Launcher', ...
        'Tag', launcherFigureTag(), ...
        'Position', [150 130 1260 620], 'Color', [0.97 0.98 0.99]};
    if launcherGuiTestMode() == "hidden"
        figArgs = [figArgs, {'Visible', 'off'}];
    end
    fig = uifigure(figArgs{:});
    fig.Name = char(launcherVersionTitle());
    applyLauncherGuiTestMode(fig);
    paintVisibleLauncherFigure();
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

    controlsGrid = uigridlayout(leftPanel, [9 1]);
    controlsGrid.RowHeight = {34, 34, 34, 34, 34, 34, 34, 34, '1x'};
    controlsGrid.Padding = [6 6 6 6];
    controlsGrid.RowSpacing = 6;

    updateGrid = uigridlayout(controlsGrid, [1 4]);
    updateGrid.Layout.Row = 1;
    updateGrid.Layout.Column = 1;
    updateGrid.ColumnWidth = {'1.5x', '1x', '1x', '1x'};
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
    btnVersions = uibutton(updateGrid, 'Text', 'Versions', ...
        'ButtonPushedFcn', @onOpenVersionManager);
    btnVersions.Layout.Row = 1;
    btnVersions.Layout.Column = 4;
    if isprop(btnUpdate, 'Tooltip')
        btnUpdate.Tooltip = 'Download and apply the latest main branch zip.';
        btnRelease.Tooltip = 'Download and apply the latest GitHub release or tag zip.';
        btnVersions.Tooltip = 'Choose a recent release, tag, or main-branch commit.';
    end
    btnRefresh = uibutton(controlsGrid, 'Text', 'Refresh App List', ...
        'ButtonPushedFcn', @onRefreshApps);
    btnOpen = uibutton(controlsGrid, 'Text', 'Open Selected App', ...
        'ButtonPushedFcn', @onLaunchSelected);
    btnDebug = uibutton(controlsGrid, 'Text', 'Open Debug', ...
        'ButtonPushedFcn', @onLaunchSelectedDebug);
    btnHistory = uibutton(controlsGrid, 'Text', 'Version History', ...
        'ButtonPushedFcn', @onOpenSelectedHistory);
    if isprop(btnHistory, 'Tooltip')
        btnHistory.Tooltip = 'Show structured changelog records for the selected app.';
    end
    packageGrid = uigridlayout(controlsGrid, [1 2]);
    packageGrid.Layout.Row = 6;
    packageGrid.Layout.Column = 1;
    packageGrid.ColumnWidth = {'1x', '1x'};
    packageGrid.RowHeight = {'1x'};
    packageGrid.Padding = [0 0 0 0];
    packageGrid.ColumnSpacing = 6;
    btnPackage = uibutton(packageGrid, 'Text', 'Package Checked', ...
        'ButtonPushedFcn', @(~, ~) onPackageCheckedApps(false));
    btnPackage.Layout.Row = 1;
    btnPackage.Layout.Column = 1;
    btnPackagePcode = uibutton(packageGrid, 'Text', 'Checked P-code', ...
        'ButtonPushedFcn', @(~, ~) onPackageCheckedApps(true));
    btnPackagePcode.Layout.Row = 1;
    btnPackagePcode.Layout.Column = 2;
    btnClean = uibutton(controlsGrid, 'Text', 'Clean Artifacts', ...
        'ButtonPushedFcn', @onCleanArtifacts);
    maintenanceGrid = uigridlayout(controlsGrid, [1 2]);
    maintenanceGrid.Layout.Row = 8;
    maintenanceGrid.Layout.Column = 1;
    maintenanceGrid.ColumnWidth = {'1x', '1x'};
    maintenanceGrid.RowHeight = {'1x'};
    maintenanceGrid.Padding = [0 0 0 0];
    maintenanceGrid.ColumnSpacing = 6;

    btnCode = uibutton(maintenanceGrid, 'Text', 'Run Code Analyzer', ...
        'ButtonPushedFcn', @onRunCodeCheck);
    btnCode.Layout.Row = 1;
    btnCode.Layout.Column = 1;
    btnProfile = uibutton(maintenanceGrid, 'Text', 'Profile Selected App', ...
        'ButtonPushedFcn', @onProfileSelectedApp);
    btnProfile.Layout.Row = 1;
    btnProfile.Layout.Column = 2;
    if isprop(btnProfile, 'Tooltip')
        btnProfile.Tooltip = ['Launch and profile the selected app ' ...
            'until that app window closes. Saves the report without opening a browser.'];
    end
    if isprop(btnPackage, 'Tooltip')
        btnPackage.Tooltip = ['Create one standalone zip containing every checked app, ' ...
            'their assets, the shared +labkit library, the launcher, and deployment tools.'];
        btnPackagePcode.Tooltip = ['Create the same multi-app zip with MATLAB code ' ...
            'encoded as .p files instead of source .m files.'];
    end
    txtInfo = uitextarea(controlsGrid, 'Editable', 'off', 'Value', {'Ready.'});

    tableGrid = uigridlayout(rightPanel, [1 1]);
    tableGrid.Padding = [4 4 4 4];
    appTable = uitable(tableGrid, ...
        'ColumnName', {'Package', 'Family', 'App', 'Visibility', 'Version', 'Updated', 'Command'}, ...
        'ColumnEditable', [true false false false false false false], 'RowName', {}, ...
        'FontSize', tableFontSize);
    if isprop(appTable, 'ColumnFormat')
        appTable.ColumnFormat = {'logical', 'char', 'char', 'char', 'char', 'char', 'char'};
    end
    appTable.ColumnWidth = {72, 140, 190, 90, 90, 110, 'auto'};
    configureTable(appTable, @onSelectionChanged, @onTableDoubleClicked);
    appTable.CellEditCallback = @onPackageCheckChanged;

    ui = struct();
    ui.figure = fig;
    ui.controls = struct();
    ui.controls.selectedDetails = struct('textArea', txtInfo);
    ui.controls.statusLine = struct('textArea', txtInfo);
    ui.controls.appTable = struct('table', appTable);
    setappdata(fig, 'labkitUiRegistry', ui);

    state = struct('apps', emptyAppStruct(), 'visibleApps', emptyAppStruct(), ...
        'selectedRow', 1, 'status', "Loading app list...", ...
        'packageCommands', strings(0, 1), ...
        'actionBusy', false, ...
        'tools', launcherToolAvailability(root));
    applyToolButtonTooltips();
    appTable.Data = cell(0, 7);
    setLaunchEnabled(false);
    updateInfo("Loading app list...");
    drawnow limitrate;

    state.apps = discoverApps(root);
    state.visibleApps = state.apps;
    state.status = integrityStatus(root, state.apps);
    refreshTable();

    function onRefreshApps(varargin)
        beginLauncherAction("Refreshing app list...");
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Refresh App List', ...
                'Message', 'Scanning app entry points...', ...
                'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            selectedCommand = currentSelectedAppCommand();
            state.tools = launcherToolAvailability(root);
            applyToolButtonTooltips();
            state.apps = discoverApps(root);
            state.visibleApps = state.apps;
            state.selectedRow = appRowByCommand(state.visibleApps, selectedCommand);
            initializeLauncherPath(root);
            refreshTable();
        catch err
            setStatus(sprintf('Refresh app list failed: %s', err.message));
        end
        clear dlgCleanup;
        endLauncherAction();
    end

    function onSelectionChanged(~, event)
        row = eventRow(event);
        if ~isnan(row)
            state.selectedRow = row;
            refreshSelection();
        end
    end

    function onPackageCheckChanged(~, event)
        if isempty(event.Indices) || isempty(state.visibleApps)
            return;
        end
        row = event.Indices(1, 1);
        if row < 1 || row > numel(state.visibleApps)
            return;
        end
        command = string(state.visibleApps(row).command);
        state.packageCommands(state.packageCommands == command) = [];
        if logical(event.NewData)
            state.packageCommands(end+1, 1) = command;
        end
        refreshSelection();
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

    function onOpenSelectedHistory(varargin)
        if isempty(state.visibleApps)
            setStatus('No app is available for version history.');
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        app = state.visibleApps(row);
        try
            records = launcherAppHistory(root, app.command);
            if isempty(records)
                setStatus(sprintf('No structured version history found for %s.', ...
                    app.command));
                return;
            end
            openAppHistoryViewer(fig, app, records);
            setStatus(sprintf('Opened %d version history record(s) for %s.', ...
                numel(records), app.command));
        catch err
            setStatus(sprintf('Version history unavailable for %s: %s', ...
                app.command, err.message));
        end
    end

    function onProfileSelectedApp(varargin)
        if state.actionBusy
            return;
        end
        if isempty(state.visibleApps)
            setStatus('No app entry points found. Use GitHub Update to repair this install.');
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        app = state.visibleApps(row);
        beginLauncherAction(profileStartStatus(app, false));
        profileSelectedApp(app, false);
        endLauncherAction();
    end

    function onPackageCheckedApps(usePcode)
        if state.actionBusy
            return;
        end
        apps = checkedPackageApps(state.visibleApps, state.packageCommands);
        if isempty(apps)
            setStatus('Check one or more apps in the Package column first.');
            return;
        end
        summary = packageAppSummary(apps);
        beginLauncherAction(sprintf('Packaging %s...', summary));
        setStatus(sprintf('Packaging %s...', summary));
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Package LabKit App', ...
                'Message', 'Preparing package...', 'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            result = packageSelectedLabKitApps(root, apps, logical(usePcode), @onPackageProgress);
            setStatus(packageSuccessStatus(apps, result));
        catch err
            setStatus(sprintf('Package failed for %s: %s', summary, err.message));
        end
        clear dlgCleanup;
        endLauncherAction();

        function onPackageProgress(message, value)
            setStatus(message);
            updateProgressDialog(dlg, message, value);
            drawnow limitrate;
        end
    end

    function onCleanArtifacts(varargin)
        if state.actionBusy
            return;
        end
        if ~confirmCleanArtifacts(fig)
            setStatus('Clean artifacts canceled.');
            return;
        end
        beginLauncherAction("Cleaning generated artifacts...");
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Clean Artifacts', ...
                'Message', 'Preparing cleanup...', 'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            result = cleanGeneratedArtifacts(root, @onCleanProgress);
            setStatus(cleanArtifactsStatus(result));
        catch err
            setStatus(sprintf('Clean artifacts failed: %s', err.message));
        end
        clear dlgCleanup;
        endLauncherAction();

        function onCleanProgress(message, value)
            setStatus(message);
            updateProgressDialog(dlg, message, value);
            drawnow limitrate;
        end
    end

    function onRunCodeCheck(varargin)
        if state.actionBusy
            return;
        end
        beginLauncherAction("Running MATLAB Code Analyzer...");
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
        endLauncherAction();

        function onCodeCheckProgress(message, value)
            setStatus(message);
            updateProgressDialog(dlg, message, value);
            drawnow limitrate;
        end
    end

    function onUpdateFromMain(varargin)
        if state.actionBusy
            return;
        end
        beginLauncherAction("Updating LabKit from GitHub main...");
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
        endLauncherAction();

        function onUpdateProgress(message, value)
            setStatus(message);
            updateProgressDialog(dlg, message, value);
            drawnow limitrate;
        end
    end

    function onUpdateFromStable(varargin)
        if state.actionBusy
            return;
        end
        beginLauncherAction("Updating LabKit from latest release/tag...");
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
        endLauncherAction();

        function onUpdateProgress(message, value)
            setStatus(message);
            updateProgressDialog(dlg, message, value);
            drawnow limitrate;
        end
    end

    function onOpenVersionManager(varargin)
        if state.actionBusy
            return;
        end
        openVersionManager(fig, root, @onVersionManagerUpdated, @setStatus);
    end

    function onVersionManagerUpdated()
        onRefreshApps();
    end

    function launchSelectedApp(debugMode)
        if isempty(state.visibleApps)
            setStatus('No app entry points found. Use GitHub Update to repair this install.');
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        app = state.visibleApps(row);
        beginLauncherAction(launchStartStatus(app, debugMode));
        setStatus(launchStartStatus(app, debugMode));
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Open LabKit App', ...
                'Message', char(launchStartStatus(app, debugMode)), ...
                'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            updateProgressDialog(dlg, sprintf('Adding %s to MATLAB path...', app.command), NaN);
            drawnow limitrate;
            initializeAppPath(app);
            updateProgressDialog(dlg, sprintf('Opening %s...', app.command), NaN);
            drawnow limitrate;
            clear dlgCleanup;
            endLauncherAction();
            setStatus(launchHandOffStatus(app, debugMode));
            drawnow limitrate;
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
        clear dlgCleanup;
        endLauncherAction();
    end

    function profileSelectedApp(app, debugMode)
        setStatus(profileStartStatus(app, debugMode));
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(fig, 'Title', 'Profile LabKit App', ...
                'Message', char(profileStartStatus(app, debugMode)), ...
                'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            result = runLauncherAppProfile(root, app, debugMode);
            setStatus(profileSuccessStatus(app, result));
        catch err
            setStatus(sprintf('Performance profile failed for %s: %s', ...
                app.command, err.message));
        end
        clear dlgCleanup;
    end

    function refreshTable()
        state.visibleApps = state.apps;
        state.packageCommands = retainedPackageCommands( ...
            state.visibleApps, state.packageCommands);
        appTable.Data = appDisplayRows(state.visibleApps, state.packageCommands);
        adjustLauncherWidthForAppTable();
        adjustAppTableColumns();
        state.selectedRow = min(max(state.selectedRow, 1), max(numel(state.visibleApps), 1));
        selectTableRow(appTable, state.selectedRow, state.visibleApps);
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
        details = selectedAppDetails(state.visibleApps(row));
        details{end+1, 1} = sprintf('Checked for package: %d app(s)', ...
            numel(state.packageCommands));
        updateInfo(details);
    end

    function command = currentSelectedAppCommand()
        command = "";
        if isempty(state.visibleApps)
            return;
        end
        row = min(max(state.selectedRow, 1), numel(state.visibleApps));
        command = string(state.visibleApps(row).command);
    end

    function setLaunchEnabled(enabled)
        stateValue = matlab.lang.OnOffSwitchState(enabled);
        btnOpen.Enable = stateValue;
        btnDebug.Enable = stateValue;
        btnHistory.Enable = stateValue;
        btnProfile.Enable = matlab.lang.OnOffSwitchState(enabled && state.tools.profile);
        btnPackage.Enable = matlab.lang.OnOffSwitchState(enabled && state.tools.package);
        btnPackagePcode.Enable = matlab.lang.OnOffSwitchState(enabled && state.tools.package);
        btnCode.Enable = matlab.lang.OnOffSwitchState(state.tools.codecheck);
    end

    function beginLauncherAction(message)
        state.actionBusy = true;
        setLauncherControlsEnabled(false);
        setStatus(message);
    end

    function endLauncherAction()
        state.actionBusy = false;
        setLauncherControlsEnabled(true);
    end

    function setLauncherControlsEnabled(enabled)
        stateValue = matlab.lang.OnOffSwitchState(enabled);
        btnUpdate.Enable = stateValue;
        btnRelease.Enable = stateValue;
        btnVersions.Enable = stateValue;
        btnRefresh.Enable = stateValue;
        btnClean.Enable = stateValue;
        btnHistory.Enable = stateValue;
        if enabled
            setLaunchEnabled(~isempty(state.visibleApps));
        else
            setLaunchEnabled(false);
            btnCode.Enable = 'off';
        end
    end

    function applyToolButtonTooltips()
        if ~isprop(btnCode, 'Tooltip')
            return;
        end
        if state.tools.codecheck
            btnCode.Tooltip = ['Run MATLAB Code Analyzer, write the JSON report, ' ...
                'then open the HTML viewer from tools/codecheck.'];
        else
            btnCode.Tooltip = missingToolTooltip('tools/codecheck/runCodecheckReport.m or .p');
        end
        if state.tools.profile
            btnProfile.Tooltip = ['Launch and profile the selected app ' ...
                'until that app window closes. Saves the report without opening a browser.'];
        else
            btnProfile.Tooltip = missingToolTooltip('tools/profiling/profileLabKitTarget.m or .p');
        end
        if state.tools.package
            btnPackage.Tooltip = ['Create one standalone zip containing every checked app, ' ...
                'their assets, the shared +labkit library, the launcher, and deployment tools.'];
            btnPackagePcode.Tooltip = ['Create the same multi-app zip with MATLAB code ' ...
                'encoded as .p files instead of source .m files.'];
        else
            tooltip = missingToolTooltip('tools/deployment/packageLabKitApp.m or .p');
            btnPackage.Tooltip = tooltip;
            btnPackagePcode.Tooltip = tooltip;
        end
    end

    function setStatus(message)
        state.status = string(message);
        refreshSelection();
    end

    function updateInfo(detailRows)
        rows = reshape(cellstr(string(detailRows(:))), [], 1);
        txtInfo.Value = [{['Status: ' char(state.status)]}; {''}; rows];
    end

    function adjustLauncherWidthForAppTable()
        preferredTableWidth = launcherTablePreferredWidth(appTable.Data);
        requiredWidth = 360 + 5 + preferredTableWidth + 34;
        if fig.Position(3) >= requiredWidth
            return;
        end
        fig.Position(3) = min(max(requiredWidth, 1260), 1700);
    end

    function adjustAppTableColumns()
        if ~isvalid(appTable)
            return;
        end
        tableWidth = max(700, fig.Position(3) - 360 - 5 - 34);
        appTable.ColumnWidth = launcherTableColumnWidths(appTable.Data, tableWidth);
    end
end

function initializeAppPath(app)
    addPathIfMissing(app.folder, '-end');
end

%% Section: App version history window

function records = launcherAppHistory(root, appCommand)
    changelogFile = fullfile(root, 'CHANGELOG.md');
    if exist(changelogFile, 'file') ~= 2
        error('labkit_launcher:ChangelogUnavailable', ...
            'CHANGELOG.md is missing. Update or repair the LabKit install.');
    end
    parserFile = matlabCodeFile(fullfile(root, 'tools', 'release', ...
        'parseLabKitChangelog'));
    if strlength(string(parserFile)) == 0
        error('labkit_launcher:ChangelogParserUnavailable', ...
            ['Changelog parser is missing. Restore tools/release or update ' ...
            'the LabKit install.']);
    end
    parserFolder = fileparts(parserFile);
    addedParserPath = ~pathContains(parserFolder);
    addPathIfMissing(parserFolder);
    if addedParserPath
        parserPathCleanup = onCleanup(@() rmpath(parserFolder));
    end

    records = parseLabKitChangelog(changelogFile);
    command = string(appCommand);
    keep = false(1, numel(records));
    for k = 1:numel(records)
        components = records(k).components;
        if ~isempty(components)
            keep(k) = any(string({components.name}) == command);
        end
    end
    records = records(keep);
    clear parserPathCleanup;
end

function viewer = openAppHistoryViewer(parentFig, app, records)
    % A stable desktop-sized surface keeps five table columns and narrative
    % details readable without resizing when records change.
    viewerArgs = {'Name', sprintf('%s Version History', app.displayName), ...
        'Position', centeredChildPosition(parentFig, [980 640]), ...
        'Color', [0.97 0.98 0.99]};
    if launcherGuiTestMode() == "hidden"
        viewerArgs = [viewerArgs, {'Visible', 'off'}];
    end
    viewer = uifigure(viewerArgs{:});
    applyLauncherGuiTestMode(viewer);
    grid = uigridlayout(viewer, [4 1]);
    % Fixed header, table, and command rows leave remaining height to details.
    grid.RowHeight = {32, 230, '1x', 34};
    grid.Padding = [8 8 8 8];
    grid.RowSpacing = 6;

    uilabel(grid, 'Text', sprintf('%s | current version %s | %d record(s)', ...
        app.displayName, app.version, numel(records)), ...
        'FontWeight', 'bold', 'FontSize', 14);
    historyTable = uitable(grid, ...
        'ColumnName', {'Date', 'Version change', 'Type', 'Compatibility', 'Change'}, ...
        'ColumnEditable', false(1, 5), 'RowName', {}, ...
        'Data', appHistoryRows(records, app.command));
    historyTable.ColumnWidth = {100, 150, 90, 110, '1x'};
    details = uitextarea(grid, 'Editable', 'off');
    uibutton(grid, 'Text', 'Close', ...
        'ButtonPushedFcn', @(~, ~) close(viewer));
    configureTable(historyTable, @onHistorySelection, @onHistorySelection);
    selectTableRow(historyTable, 1, records);
    showRecord(1);

    function onHistorySelection(~, event)
        row = eventRow(event);
        if ~isnan(row)
            showRecord(row);
        end
    end

    function showRecord(row)
        row = min(max(round(row), 1), numel(records));
        details.Value = cellstr(historyRecordDetails(records(row), app.command));
    end
end

function rows = appHistoryRows(records, appCommand)
    rows = cell(numel(records), 5);
    for k = 1:numel(records)
        rows{k, 1} = char(records(k).date);
        rows{k, 2} = char(appHistoryTransition(records(k), appCommand));
        rows{k, 3} = char(records(k).type);
        rows{k, 4} = char(records(k).compatibility);
        rows{k, 5} = char(records(k).title);
    end
end

function transition = appHistoryTransition(record, appCommand)
    transition = "";
    components = record.components;
    if isempty(components)
        return;
    end
    indices = find(string({components.name}) == string(appCommand));
    values = strings(1, numel(indices));
    for k = 1:numel(indices)
        component = components(indices(k));
        if component.kind == "introduced"
            values(k) = "Introduced at " + component.toVersion;
        else
            values(k) = component.fromVersion + " -> " + component.toVersion;
        end
    end
    transition = strjoin(values, ", ");
end

function lines = historyRecordDetails(record, appCommand)
    transition = appHistoryTransition(record, appCommand);
    sections = record.sections;
    lines = [ ...
        record.title
        "Change ID: " + record.id
        "Date: " + record.date
        "Version: " + transition
        "Type: " + record.type + " | Compatibility: " + record.compatibility
        ""
        "Context"
        string(sections.context)
        ""
        "Decision and rationale"
        string(sections.decisionAndRationale)
        ""
        "Changes"
        string(sections.changes)
        ""
        "User and data impact"
        string(sections.userAndDataImpact)
        ""
        "Compatibility and migration"
        string(sections.compatibilityAndMigration)
        ""
        "Validation"
        string(sections.validation)
        ""
        "Evidence"
        string(sections.evidence)
        ""
        "Known limitations and follow-up"
        string(sections.knownLimitationsAndFollowUp)];
    lines = splitlines(strjoin(lines, newline));
end

function position = centeredChildPosition(parentFig, childSize)
    parentPosition = parentFig.Position;
    position = [ ...
        parentPosition(1) + max(20, (parentPosition(3) - childSize(1)) / 2), ...
        parentPosition(2) + max(20, (parentPosition(4) - childSize(2)) / 2), ...
        childSize];
end

%% Section: Version manager window

function manager = openVersionManager(parentFig, root, refreshCallback, statusCallback)
    if nargin < 3
        refreshCallback = [];
    end
    if nargin < 4
        statusCallback = [];
    end

    managerArgs = {'Name', 'LabKit Version Manager', ...
        'Position', [210 170 900 520], 'Color', [0.97 0.98 0.99]};
    if launcherGuiTestMode() == "hidden"
        managerArgs = [managerArgs, {'Visible', 'off'}];
    end
    manager = uifigure(managerArgs{:});
    applyLauncherGuiTestMode(manager);

    layout = uigridlayout(manager, [4 1]);
    layout.RowHeight = {86, '1x', 36, 76};
    layout.Padding = [8 8 8 8];
    layout.RowSpacing = 8;

    currentInfo = uitextarea(layout, 'Editable', 'off', ...
        'Value', cellstr(currentInstallVersionLines(root)));
    currentInfo.Layout.Row = 1;

    sourceTable = uitable(layout, ...
        'ColumnName', {'Type', 'Version or commit', 'Date', 'Summary'}, ...
        'ColumnEditable', [false false false false], 'RowName', {}, ...
        'FontSize', 14);
    sourceTable.ColumnWidth = {100, 170, 170, 'auto'};
    sourceTable.Layout.Row = 2;

    buttonGrid = uigridlayout(layout, [1 4]);
    buttonGrid.Layout.Row = 3;
    buttonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
    buttonGrid.RowHeight = {'1x'};
    buttonGrid.Padding = [0 0 0 0];
    buttonGrid.ColumnSpacing = 8;

    btnRefresh = uibutton(buttonGrid, 'Text', 'Refresh', ...
        'ButtonPushedFcn', @onRefreshSources);
    btnRefresh.Layout.Column = 1;
    btnInstall = uibutton(buttonGrid, 'Text', 'Install Selected', ...
        'ButtonPushedFcn', @onInstallSelected);
    btnInstall.Layout.Column = 2;
    btnClose = uibutton(buttonGrid, 'Text', 'Close', ...
        'ButtonPushedFcn', @(~, ~) close(manager));
    btnClose.Layout.Column = 4;
    if isprop(btnRefresh, 'Tooltip')
        btnRefresh.Tooltip = 'Fetch recent GitHub releases, tags, and main commits.';
        btnInstall.Tooltip = 'Download and apply the selected LabKit version.';
        btnClose.Tooltip = 'Close version manager.';
    end

    statusText = uitextarea(layout, 'Editable', 'off', ...
        'Value', {'Choose a recent release, tag, or main-branch commit.'});
    statusText.Layout.Row = 4;

    sourceState = struct('sources', emptyVersionSources(), ...
        'selectedRow', 1, 'actionBusy', false);
    configureTable(sourceTable, @onSourceSelection, @onSourceDoubleClicked);
    onRefreshSources();

    function onRefreshSources(varargin)
        if sourceState.actionBusy
            return;
        end
        beginVersionManagerAction('Fetching recent LabKit versions from GitHub...');
        setManagerStatus('Fetching recent LabKit versions from GitHub...');
        notifyStatus(statusCallback, 'Fetching recent LabKit versions from GitHub...');
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(manager, 'Title', 'Refresh LabKit Versions', ...
                'Message', 'Fetching recent releases, tags, and commits...', ...
                'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            sourceState.sources = recentVersionSources();
            sourceState.selectedRow = 1;
            sourceTable.Data = versionSourceRows(sourceState.sources);
            btnInstall.Enable = matlab.lang.OnOffSwitchState(~isempty(sourceState.sources));
            if isempty(sourceState.sources)
                setManagerStatus('No release, tag, or commit options were returned by GitHub.');
                notifyStatus(statusCallback, 'No release, tag, or commit options were returned by GitHub.');
            else
                message = sprintf('Loaded %d version option(s). Select one to install or roll back.', ...
                    numel(sourceState.sources));
                setManagerStatus(message);
                notifyStatus(statusCallback, message);
            end
        catch err
            sourceState.sources = emptyVersionSources();
            sourceTable.Data = cell(0, 4);
            btnInstall.Enable = 'off';
            message = sprintf('Version lookup failed: %s', err.message);
            setManagerStatus(message);
            notifyStatus(statusCallback, message);
        end
        clear dlgCleanup;
        endVersionManagerAction();
    end

    function onSourceSelection(~, event)
        row = eventRow(event);
        if ~isnan(row)
            sourceState.selectedRow = row;
        end
    end

    function onSourceDoubleClicked(varargin)
        onInstallSelected();
    end

    function onInstallSelected(varargin)
        if sourceState.actionBusy
            return;
        end
        if isempty(sourceState.sources)
            setManagerStatus('No version option is available to install.');
            return;
        end
        row = min(max(sourceState.selectedRow, 1), numel(sourceState.sources));
        source = sourceState.sources(row);
        beginVersionManagerAction(sprintf('Preparing %s...', char(source.label)));
        setManagerStatus(sprintf('Preparing %s...', char(source.label)));
        notifyStatus(statusCallback, sprintf('Updating LabKit from %s...', char(source.label)));
        drawnow;
        dlg = [];
        try
            dlg = uiprogressdlg(manager, 'Title', 'Install LabKit Version', ...
                'Message', 'Preparing update...', 'Indeterminate', 'on');
        catch
        end
        if ~isempty(dlg)
            dlgCleanup = onCleanup(@() close(dlg));
        end
        try
            result = launcherUpdateFromZipSource(root, source, @onVersionUpdateProgress);
            setManagerStatus(result.message);
            notifyStatus(statusCallback, result.message);
            currentInfo.Value = cellstr(currentInstallVersionLines(root));
            if ~isempty(refreshCallback)
                refreshCallback();
            end
        catch err
            message = sprintf('Version install failed: %s', err.message);
            setManagerStatus(message);
            notifyStatus(statusCallback, message);
        end
        clear dlgCleanup;
        endVersionManagerAction();

        function onVersionUpdateProgress(message, value)
            setManagerStatus(message);
            notifyStatus(statusCallback, message);
            updateProgressDialog(dlg, message, value);
            drawnow limitrate;
        end
    end

    function beginVersionManagerAction(message)
        sourceState.actionBusy = true;
        setVersionManagerControlsEnabled(false);
        setManagerStatus(message);
    end

    function endVersionManagerAction()
        sourceState.actionBusy = false;
        setVersionManagerControlsEnabled(true);
    end

    function setVersionManagerControlsEnabled(enabled)
        stateValue = matlab.lang.OnOffSwitchState(enabled);
        btnRefresh.Enable = stateValue;
        btnClose.Enable = stateValue;
        if enabled
            btnInstall.Enable = matlab.lang.OnOffSwitchState(~isempty(sourceState.sources));
        else
            btnInstall.Enable = 'off';
        end
    end

    function setManagerStatus(message)
        statusText.Value = cellstr(wrapDescription(string(message)));
    end
end

%% Section: Version manager support

function notifyStatus(statusCallback, message)
    if isempty(statusCallback)
        return;
    end
    try
        statusCallback(string(message));
    catch
    end
end

function lines = currentInstallVersionLines(root)
    info = launcherVersion();
    lines = [
        string(sprintf("Current launcher: %s v%s (%s)", ...
            info.displayName, info.version, info.updated))
        "Install folder: " + string(root)
        installFolderPolicyLine(root)
    ];
end

function line = installFolderPolicyLine(root)
    if exist(fullfile(root, ".git"), "dir") == 7
        line = "Git checkout detected: launcher zip updates are disabled; use git for this tree.";
        return;
    end
    line = "Update policy: the current runtime folder is moved into a dated LabKit-previous-* snapshot before replacement.";
end

function rows = versionSourceRows(sources)
    rows = cell(numel(sources), 4);
    for k = 1:numel(sources)
        rows{k, 1} = char(sources(k).kind);
        rows{k, 2} = char(sources(k).name);
        rows{k, 3} = char(sources(k).date);
        rows{k, 4} = char(sources(k).summary);
    end
end

%% Section: Table selection and display helpers

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
    elseif isstruct(event) && isfield(event, 'Indices') && ~isempty(event.Indices)
        row = event.Indices(1, 1);
    elseif isstruct(event) && isfield(event, 'Selection') && ~isempty(event.Selection)
        row = event.Selection(1, 1);
    end
end

function row = appRowByCommand(apps, selectedCommand)
    row = 1;
    if isempty(apps) || strlength(string(selectedCommand)) == 0
        return;
    end
    commands = string({apps.command});
    match = find(commands == string(selectedCommand), 1, 'first');
    if ~isempty(match)
        row = match;
    end
end

function selectTableRow(tableHandle, row, apps)
    if isempty(apps) || ~isprop(tableHandle, 'Selection')
        return;
    end
    try
        tableHandle.Selection = row;
    catch
        try
            tableHandle.Selection = [row 1];
        catch
        end
    end
end

function rows = appDisplayRows(apps, packageCommands)
    rows = cell(numel(apps), 7);
    checked = ismember(string({apps.command}), string(packageCommands));
    for k = 1:numel(apps)
        rows{k, 1} = checked(k);
        rows{k, 2} = char(apps(k).family);
        rows{k, 3} = char(apps(k).displayName);
        rows{k, 4} = char(apps(k).visibility);
        rows{k, 5} = char(apps(k).version);
        rows{k, 6} = char(apps(k).updated);
        rows{k, 7} = apps(k).command;
    end
end

function commands = retainedPackageCommands(apps, commands)
    available = string({apps.command});
    commands = string(commands(:));
    commands = commands(ismember(commands, available));
end

function apps = checkedPackageApps(visibleApps, commands)
    if isempty(visibleApps)
        apps = visibleApps;
        return;
    end
    selected = ismember(string({visibleApps.command}), string(commands));
    apps = visibleApps(selected);
end

function summary = packageAppSummary(apps)
    if numel(apps) == 1
        summary = string(apps.command);
    else
        summary = string(numel(apps)) + " checked apps";
    end
end

function width = launcherTablePreferredWidth(rows)
    columns = launcherTableColumnWidths(rows, inf);
    width = sum(cell2mat(columns)) + 24;
end

function widths = launcherTableColumnWidths(rows, tableWidth)
    desired = [ ...
        72, ...
        textColumnWidth(rows, 2, 130, 220), ...
        textColumnWidth(rows, 3, 220, 380), ...
        96, ...
        96, ...
        122, ...
        textColumnWidth(rows, 7, 320, 580)];

    if isfinite(tableWidth)
        spare = tableWidth - sum(desired);
        if spare > 0
            desired(3) = desired(3) + round(spare * 0.35);
            desired(7) = desired(7) + round(spare * 0.65);
        elseif spare < 0
            deficit = abs(spare);
            shrink = min(deficit, max(0, desired(7) - 320));
            desired(7) = desired(7) - shrink;
            deficit = deficit - shrink;
            shrink = min(deficit, max(0, desired(3) - 220));
            desired(3) = desired(3) - shrink;
        end
    end

    widths = num2cell(max(round(desired), [64 120 190 90 90 110 260]));
end

function width = textColumnWidth(rows, columnIndex, minWidth, maxWidth)
    values = strings(0, 1);
    if ~isempty(rows)
        values = string(rows(:, columnIndex));
    end
    maxChars = max(strlength([""; values]));
    width = min(maxWidth, max(minWidth, double(maxChars) * 10 + 34));
end

function rows = selectedAppDetails(app)
    rows = [{char(app.displayName)}; {['Family: ' char(app.family)]}; ...
        {['Visibility: ' char(app.visibility)]}; ...
        {['Version: ' char(app.version)]}; {['Updated: ' char(app.updated)]}; ...
        {['Command: ' app.command]}; {['Path: ' app.relativePath]}; ...
        cellstr(wrapDescription(app.description))];
end

function rows = noMatchingAppDetails()
    rows = {'No app entry points found.'; 'Use GitHub Update to repair this install.'};
end

%% Section: Launcher status messages

function message = integrityStatus(root, apps)
    missing = missingManagedProjectParts(root);
    packageInfo = singleAppPackageInfo(root);
    if packageInfo.isPackage && isempty(apps)
        message = "App package is missing its app entry point.";
    elseif packageInfo.isPackage && isempty(missing)
        message = sprintf('App package ready: %d app(s) available.', numel(apps));
    elseif packageInfo.isPackage
        message = sprintf(['App package has %d app(s), but package parts are ' ...
            'missing: %s. Recreate the package from a complete LabKit checkout.'], ...
            numel(apps), strjoin(cellstr(missing), ', '));
    elseif isempty(apps)
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
    packageInfo = singleAppPackageInfo(root);
    if packageInfo.isPackage
        required = [packageInfo.launcherFile, "+labkit", packageInfo.appFolders, ...
            "tools/deployment", "tools/profiling", "packaged_app_manifest.json"];
    else
        required = ["+labkit", "apps", "docs", "tests", "buildfile.m", ...
            "README.md", "AGENTS.md"];
    end
    missing = strings(1, 0);
    for k = 1:numel(required)
        path = fullfile(root, char(required(k)));
        if exist(path, "file") ~= 2 && exist(path, "dir") ~= 7
            missing(end+1) = required(k);
        end
    end
end

function info = singleAppPackageInfo(root)
    info = struct('isPackage', false, 'appCommand', "", ...
        'appFolder', "apps", 'appFolders', "apps", ...
        'codeFormat', "source", 'launcherFile', "labkit_launcher.m");
    manifestFile = fullfile(root, "packaged_app_manifest.json");
    if exist(manifestFile, "file") ~= 2
        return;
    end
    try
        raw = jsondecode(fileread(manifestFile));
    catch
        return;
    end
    if isfield(raw, "type") && any(string(raw.type) == ...
            ["labkit.single_app_package", "labkit.multi_app_package"])
        info.isPackage = true;
        if isfield(raw, "appCommand")
            info.appCommand = string(raw.appCommand);
        end
        if isfield(raw, "appFolder")
            info.appFolder = string(raw.appFolder);
            info.appFolders = info.appFolder;
        elseif isfield(raw, "appFolders")
            info.appFolders = string(raw.appFolders(:)).';
            if ~isempty(info.appFolders)
                info.appFolder = info.appFolders(1);
            end
        end
        if isfield(raw, "codeFormat")
            info.codeFormat = string(raw.codeFormat);
        end
        if info.codeFormat == "pcode"
            info.launcherFile = "labkit_launcher.p";
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

function message = launchHandOffStatus(app, debugMode)
    if debugMode
        message = sprintf('Opening %s in debug mode. The app will report startup progress in its own window.', app.command);
    else
        message = sprintf('Opening %s. The app will report startup progress in its own window.', app.command);
    end
end

function message = profileStartStatus(app, debugMode)
    if debugMode
        message = sprintf(['Profiling %s in debug mode. Close the app window ' ...
            'to finish the report...'], app.command);
    else
        message = sprintf(['Profiling %s. Close the app window to finish ' ...
            'the report...'], app.command);
    end
end

function message = profileSuccessStatus(app, result)
    message = sprintf('Profile complete for %s: %s', app.command, ...
        char(result.relativeHtmlFile));
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
    message = sprintf(['codeIssues report complete: %d issue(s), ' ...
        '%d suppressed issue(s), %d file(s): %s; HTML: %s'], ...
        report.issueCount, report.suppressedIssueCount, ...
        report.fileCount, char(report.relativeJsonFile), ...
        char(report.relativeHtmlFile));
end

%% Section: App discovery and catalog metadata

function apps = discoverApps(root)
    template = emptyAppStruct();
    appRoots = appDiscoveryRoots(root);
    apps = template;
    appCount = 0;
    for rootIndex = 1:numel(appRoots)
        appRoot = char(appRoots(rootIndex).appRoot);
        if exist(appRoot, 'dir') ~= 7
            continue;
        end
        entries = appEntryFiles(appRoot);
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
            apps(appCount).visibility = char(appRoots(rootIndex).visibility);
            apps(appCount).folder = folder;
            apps(appCount).relativePath = relativePath(root, filepath);
            apps(appCount).description = appDescription(filepath, command);
            versionInfo = appVersionInfo(folder);
            apps(appCount).version = versionInfo.version;
            apps(appCount).updated = versionInfo.updated;
        end
    end
    if ~isempty(apps)
        keys = [reshape(string({apps.visibility}) == "private", [], 1), ...
            reshape(string({apps.family}), [], 1), ...
            reshape(string({apps.displayName}), [], 1)];
        [~, order] = sortrows(keys);
        apps = apps(order);
    end
end

function app = emptyAppStruct()
    app = struct('command', {}, 'displayName', {}, 'family', {}, ...
        'visibility', {}, ...
        'folder', {}, 'relativePath', {}, 'description', {}, ...
        'version', {}, 'updated', {});
end

function entries = appEntryFiles(appRoot)
    entries = [dir(fullfile(appRoot, '**', 'labkit_*_app.m')); ...
        dir(fullfile(appRoot, '**', 'labkit_*_app.p'))];
    entries = entries(~[entries.isdir]);
    if isempty(entries)
        return;
    end
    paths = strings(numel(entries), 1);
    commands = strings(numel(entries), 1);
    isSource = false(numel(entries), 1);
    for k = 1:numel(entries)
        paths(k) = string(fullfile(entries(k).folder, entries(k).name));
        [~, commands(k), ext] = fileparts(paths(k));
        isSource(k) = string(ext) == ".m";
    end
    [~, order] = sortrows([commands, string(~isSource), paths]);
    entries = entries(order);
    commands = commands(order);
    [~, keep] = unique(commands, "stable");
    entries = entries(keep);
end

function catalog = appCatalogTable(apps)
    catalog = table(string({apps.command})', string({apps.displayName})', ...
        string({apps.family})', string({apps.visibility})', string({apps.folder})', ...
        string({apps.relativePath})', string({apps.description})', ...
        string({apps.version})', string({apps.updated})', ...
        'VariableNames', {'Command', 'DisplayName', 'Family', 'Visibility', 'Folder', ...
        'RelativePath', 'Description', 'Version', 'Updated'});
end

function appRoots = appDiscoveryRoots(root)
    roots = struct('appRoot', string(fullfile(root, 'apps')), ...
        'visibility', "public");
    privateRoots = privateAppRoots(root);
    for k = 1:numel(privateRoots)
        roots(end+1) = struct('appRoot', privateRoots(k), ...
            'visibility', "private");
    end
    appRoots = roots;
end

function roots = privateAppRoots(root)
    roots = strings(1, 0);
    localRoot = string(fullfile(root, 'private_apps', 'apps'));
    if exist(localRoot, 'dir') == 7
        roots(end+1) = localRoot;
    end

    envValue = string(getenv('LABKIT_PRIVATE_APP_ROOTS'));
    if strlength(strtrim(envValue)) > 0
        parts = string(strsplit(char(envValue), pathsep));
        parts = strip(parts);
        parts = parts(strlength(parts) > 0);
        for k = 1:numel(parts)
            candidate = privateAppRootAppsFolder(parts(k));
            if exist(candidate, 'dir') == 7
                roots(end+1) = candidate;
            end
        end
    end
    roots = unique(roots, 'stable');
end

function appRoot = privateAppRootAppsFolder(root)
    root = string(root);
    if endsWith(strrep(root, "\", "/"), "/apps")
        appRoot = root;
    else
        appRoot = string(fullfile(root, 'apps'));
    end
end

function info = appVersionInfo(folder)
    info = struct('version', "", 'updated', "");
    entries = dir(fullfile(folder, '+*', 'version.m'));
    if isempty(entries)
        return;
    end
    filepath = fullfile(entries(1).folder, entries(1).name);
    try
        text = fileread(filepath);
    catch
        return;
    end
    info.version = stringLiteralField(text, "version");
    info.updated = stringLiteralField(text, "updated");
end

function value = stringLiteralField(text, fieldName)
    value = "";
    pattern = ['"' char(fieldName) '"\s*,\s*"([^"]+)"'];
    tokens = regexp(char(text), pattern, 'tokens', 'once');
    if ~isempty(tokens)
        value = string(tokens{1});
    end
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
        words(k) = displayWord(words(k));
    end
    value = strjoin(cellstr(words), ' ');
end

function word = displayWord(word)
    word = string(word);
    switch lower(word)
        case "labkit"
            word = "LabKit";
        otherwise
            word = upper(extractBefore(word, 2)) + extractAfter(word, 1);
    end
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

%% Section: Clean Artifacts action

function result = cleanGeneratedArtifacts(root, progressFcn)
    if nargin < 2
        progressFcn = [];
    end
    notifyProgress(progressFcn, "Checking cleanup root...", 0.05);
    try
        root = validateCleanArtifactsRoot(root);
    catch err
        result = struct('removedCount', 0, 'errors', string(err.message));
        return;
    end

    targets = {'artifacts'};
    notifyProgress(progressFcn, "Finding generated artifact targets...", 0.20);
    removedCount = 0;
    errors = strings(0, 1);
    for k = 1:numel(targets)
        relativeTarget = targets{k};
        target = fullfile(root, relativeTarget);
        try
            notifyProgress(progressFcn, ...
                sprintf("Checking %s...", relativeTarget), 0.25);
            validateCleanArtifactsTarget(root, target, relativeTarget);
            if exist(target, 'dir') == 7
                notifyProgress(progressFcn, ...
                    sprintf("Removing %s...", relativeTarget), 0.55);
                rmdir(target, 's');
                removedCount = removedCount + 1;
            elseif exist(target, 'file') == 2
                notifyProgress(progressFcn, ...
                    sprintf("Removing %s...", relativeTarget), 0.55);
                delete(target);
                removedCount = removedCount + 1;
            else
                notifyProgress(progressFcn, ...
                    sprintf("%s is already clean.", relativeTarget), 0.85);
            end
        catch err
            errors(end+1) = string(err.message);
        end
    end
    result = struct('removedCount', removedCount, 'errors', errors);
    notifyProgress(progressFcn, "Clean Artifacts complete.", 1.00);
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
            'Remove generated LabKit artifacts?', ...
            'Clean Artifacts', 'Options', {'Clean', 'Cancel'}, ...
            'DefaultOption', 'Cancel', 'CancelOption', 'Cancel');
        tf = strcmp(choice, 'Clean');
    catch
        tf = false;
    end
end

%% Section: Code Analyzer action

function report = runCodeAnalyzerReport(root, progressFcn)
    codecheckTool = codecheckToolFile(root);
    if strlength(string(codecheckTool)) == 0
        error('labkit_launcher:CodecheckToolUnavailable', ...
            ['Code Analyzer tools are missing. Restore tools/codecheck ' ...
            'or update the LabKit install.']);
    end
    codecheckFolder = fileparts(codecheckTool);
    addedCodecheckPath = ~pathContains(codecheckFolder);
    addPathIfMissing(codecheckFolder);
    if addedCodecheckPath
        codecheckPathCleanup = onCleanup(@() rmpath(codecheckFolder));
    end

    report = runCodecheckReport(root, ...
        'ProgressFcn', progressFcn, ...
        'OpenReport', launcherGuiTestMode() ~= "hidden");
    report.relativeJsonFile = string(relativePath(root, report.jsonFile));
    report.relativeHtmlFile = string(relativePath(root, report.htmlFile));
    clear codecheckPathCleanup;
end

function toolFile = codecheckToolFile(root)
    toolFile = matlabCodeFile(fullfile(root, 'tools', 'codecheck', 'runCodecheckReport'));
end

%% Section: Performance profile action

function result = runLauncherAppProfile(root, app, debugMode)
    profileTool = profileToolFile(root);
    if strlength(string(profileTool)) == 0
        error('labkit_launcher:ProfilerUnavailable', ...
            ['Performance profiler tools are missing. Restore tools/profiling ' ...
            'or update the LabKit install.']);
    end
    profileFolder = fileparts(profileTool);
    addedProfilePath = ~pathContains(profileFolder);
    addPathIfMissing(profileFolder);
    if addedProfilePath
        profilePathCleanup = onCleanup(@() rmpath(profileFolder));
    end
    initializeAppPath(app);

    outputRoot = fullfile(root, 'artifacts', 'profile', 'launcher-app-session');
    ensureFolder(outputRoot);
    htmlFile = fullfile(outputRoot, sprintf('profile_%s_%s.html', ...
        safeFilename(app.command), datestr(now, 'yyyymmdd_HHMMSS')));
    targetFile = fullfile(root, char(app.relativePath));
    target = @() launchProfileTarget(app, debugMode);
    [htmlFile, artifacts] = profileLabKitTarget(target, htmlFile, ...
        'OpenReport', launcherGuiTestMode() ~= "hidden", ...
        'WaitForGuiClose', true, ...
        'CloseFiguresAfterRun', false, ...
        'ProjectRoot', root, ...
        'TargetFile', targetFile, ...
        'PrintSummary', false, ...
        'RethrowError', true);

    result = struct();
    result.htmlFile = string(htmlFile);
    result.jsonFile = string(artifacts.jsonFile);
    result.relativeHtmlFile = string(relativePath(root, htmlFile));
    result.relativeJsonFile = string(relativePath(root, artifacts.jsonFile));
end

function toolFile = profileToolFile(root)
    toolFile = matlabCodeFile(fullfile(root, 'tools', 'profiling', 'profileLabKitTarget'));
end

function launchProfileTarget(app, debugMode)
    if debugMode
        feval(app.command, "debug");
    else
        feval(app.command);
    end
end

function name = safeFilename(value)
    name = regexprep(char(string(value)), '[^A-Za-z0-9_.-]+', '_');
    if isempty(name)
        name = 'app';
    end
end

function value = stringField(raw, name)
    if isfield(raw, name) && ~isempty(raw.(name))
        value = string(raw.(name));
    else
        value = "";
    end
end

function value = nestedStringField(raw, names)
    value = "";
    current = raw;
    for k = 1:numel(names)
        name = names(k);
        if ~isstruct(current) || ~isfield(current, name) || isempty(current.(name))
            return;
        end
        current = current.(name);
    end
    if ischar(current) || isstring(current)
        value = string(current);
    end
end

function line = firstTextLine(text)
    parts = splitlines(string(text));
    parts = strip(parts);
    parts = parts(strlength(parts) > 0);
    if isempty(parts)
        line = "";
    else
        line = parts(1);
    end
end

%% Section: App package action

function result = packageSelectedLabKitApps(root, apps, usePcode, progressFcn)
    packageTool = packageToolFile(root);
    if strlength(string(packageTool)) == 0
        error('labkit_launcher:PackageToolUnavailable', ...
            ['Deployment package tools are missing. Restore tools/deployment ' ...
            'or update the LabKit install.']);
    end
    packageFolder = fileparts(packageTool);
    addedPackagePath = ~pathContains(packageFolder);
    addPathIfMissing(packageFolder);
    if addedPackagePath
        packagePathCleanup = onCleanup(@() rmpath(packageFolder));
    end

    outputRoot = fullfile(root, 'artifacts', 'deployment');
    ensureFolder(outputRoot);
    result = packageLabKitApp(apps, [], ...
        'Root', root, ...
        'OutputRoot', outputRoot, ...
        'CodeFormat', packageCodeFormat(usePcode), ...
        'ProgressFcn', progressFcn);
    result.relativeZipFile = string(relativePath(root, result.zipFile));
    clear packagePathCleanup;
end

function toolFile = packageToolFile(root)
    toolFile = matlabCodeFile(fullfile(root, 'tools', 'deployment', 'packageLabKitApp'));
end

function file = matlabCodeFile(baseFile)
    candidates = string(baseFile) + [".m", ".p"];
    file = "";
    for k = 1:numel(candidates)
        if exist(candidates(k), 'file') == 2
            file = char(candidates(k));
            return;
        end
    end
end

function codeFormat = packageCodeFormat(usePcode)
    if usePcode
        codeFormat = "pcode";
    else
        codeFormat = "source";
    end
end

function tools = launcherToolAvailability(root)
    tools = struct();
    tools.codecheck = strlength(string(codecheckToolFile(root))) > 0;
    tools.profile = strlength(string(profileToolFile(root))) > 0;
    tools.package = strlength(string(packageToolFile(root))) > 0;
end

function tooltip = missingToolTooltip(relativeToolPath)
    tooltip = sprintf('Disabled because the optional tool is missing: %s', ...
        char(relativeToolPath));
end

function message = packageSuccessStatus(apps, result)
    if numel(apps) == 1
        message = sprintf('Packaged %s as %s. Run %s after unzipping.', ...
            apps.command, char(result.relativeZipFile), char(result.entryFile));
    else
        message = sprintf('Packaged %d apps as %s. Direct entries: %s.', ...
            numel(apps), char(result.relativeZipFile), ...
            strjoin(cellstr(result.entryFiles), ', '));
    end
end

%% Section: Update entrypoints and install transaction

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
    end
    if ~confirmUpdate(root, source.label)
        result = summaryStruct(root, 0, 0, "", "Update canceled.");
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
        result = summaryStruct(root, 0, 0, "", ...
            "Update canceled because the candidate removes app entrypoints.");
        return;
    end
    notifyProgress(progressFcn, "Moving current LabKit folder into a dated snapshot...", 0.55);
    [snapshotFolder, movedCount] = moveCurrentInstallToSnapshot(root, progressFcn);
    notifyProgress(progressFcn, "Copying replacement LabKit folder...", 0.75);
    copiedCount = copyReplacementTree(sourceRoot, root, progressFcn);
    notifyProgress(progressFcn, "Update complete.", 1.00);
    result = summaryStruct(root, copiedCount, movedCount, snapshotFolder, ...
        sprintf(['Updated from %s. Moved %d old top-level item(s) to %s and ' ...
        'copied %d replacement top-level item(s). Restart labkit_launcher.'], ...
        char(source.label), movedCount, char(snapshotFolder), copiedCount));
    clear cleanup;
    removeFolderIfPresent(tempRoot);
end

%% Section: GitHub update source discovery

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

function sources = recentVersionSources()
    sources = emptyVersionSources();
    sources = [sources, safeVersionSources(@() recentReleaseSources(5))];
    sources = [sources, safeVersionSources(@() recentTagSources(5))];
    sources = [sources, safeVersionSources(@() recentCommitSources(8))];
end

function sources = safeVersionSources(fetchFcn)
    try
        sources = fetchFcn();
    catch
        sources = emptyVersionSources();
    end
end

function sources = recentReleaseSources(limit)
    sources = emptyVersionSources();
    raw = githubApiRead("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/releases");
    if ~isstruct(raw)
        return;
    end
    for k = 1:numel(raw)
        item = raw(k);
        if logicalField(item, "draft") || logicalField(item, "prerelease")
            continue;
        end
        tag = stringField(item, "tag_name");
        if strlength(tag) == 0
            continue;
        end
        name = stringField(item, "name");
        if strlength(name) == 0
            name = tag;
        end
        date = stringField(item, "published_at");
        summary = "GitHub release " + tag;
        source = sourceFromTag("Release", tag, "GitHub release " + tag, ...
            tag, date, name + " (" + tag + ")");
        source.summary = summary;
        sources(end+1) = source;
        if numel(sources) >= limit
            return;
        end
    end
end

function sources = recentTagSources(limit)
    sources = emptyVersionSources();
    raw = githubApiRead("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/tags?per_page=" + string(limit));
    if ~isstruct(raw)
        return;
    end
    for k = 1:min(numel(raw), limit)
        tag = stringField(raw(k), "name");
        if strlength(tag) == 0
            continue;
        end
        sources(end+1) = sourceFromTag("Tag", tag, "GitHub tag " + tag, ...
            tag, "", "Tag " + tag);
    end
end

function sources = recentCommitSources(limit)
    sources = emptyVersionSources();
    raw = githubApiRead("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/commits?sha=main&per_page=" + string(limit));
    if ~isstruct(raw)
        return;
    end
    for k = 1:min(numel(raw), limit)
        sha = stringField(raw(k), "sha");
        if strlength(sha) < 7
            continue;
        end
        short = extractBefore(sha, 8);
        message = firstTextLine(nestedStringField(raw(k), ["commit", "message"]));
        date = nestedStringField(raw(k), ["commit", "author", "date"]);
        label = "main commit " + short;
        sources(end+1) = createVersionSource("Commit", label, ...
            "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/" + sha + ".zip", ...
            "commit-" + short + ".zip", short, date, message);
    end
end

function raw = githubApiRead(url)
    options = weboptions("Timeout", 20, "UserAgent", "MATLAB LabKit Launcher");
    raw = webread(char(url), options);
end

function release = latestStableRelease()
    release = struct("tagName", "");
    try
        raw = githubApiRead("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/releases");
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
        raw = githubApiRead("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/tags");
    catch
        return;
    end
    if isstruct(raw) && ~isempty(raw)
        tagName = stringField(raw(1), "name");
    end
end

function source = stableSourceFromTag(tagName, label)
    source = sourceFromTag("Stable", tagName, label, tagName, "", ...
        "Stable tag " + string(tagName));
end

function source = sourceFromTag(kind, tagName, label, name, date, summary)
    safeTag = encodeUrlPathSegment(tagName);
    source = createVersionSource(kind, label, ...
        "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/tags/" + string(safeTag) + ".zip", ...
        "stable-" + sanitizeFilename(tagName) + ".zip", ...
        name, date, summary);
end

function source = createVersionSource(kind, label, zipUrl, zipName, name, date, summary)
    source = struct( ...
        "kind", string(kind), ...
        "label", string(label), ...
        "zipUrl", string(zipUrl), ...
        "zipName", string(zipName), ...
        "name", string(name), ...
        "date", string(date), ...
        "summary", string(summary));
end

function sources = emptyVersionSources()
    sources = struct("kind", {}, "label", {}, "zipUrl", {}, "zipName", {}, ...
        "name", {}, "date", {}, "summary", {});
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

%% Section: Update validation and launcher window helpers

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

function closeExistingLauncherFigures()
    figures = findall(groot, 'Type', 'figure', 'Tag', launcherFigureTag());
    for k = 1:numel(figures)
        if isvalid(figures(k))
            close(figures(k));
        end
    end
end

function tag = launcherFigureTag()
    tag = 'labkit_launcher_main';
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

function paintVisibleLauncherFigure()
    if launcherGuiTestMode() ~= "visible"
        return;
    end
    drawnow limitrate;
end

function tf = confirmUpdate(root, sourceLabel)
    message = sprintf(['Download %s zip and replace the LabKit runtime in:\n\n%s\n\n' ...
        'The LabKit folder should contain only LabKit runtime files. Before ' ...
        'installing, the launcher will move the current folder contents into a ' ...
        'dated LabKit-previous-* subfolder, then copy the selected zip into place. ' ...
        'Keep lab data and exports outside the LabKit folder.'], ...
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

%% Section: Update install file operations

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

function removed = removedAppEntrypoints(currentRoot, sourceRoot)
    currentApps = collectAppEntrypoints(currentRoot);
    sourceApps = collectAppEntrypoints(sourceRoot);
    removed = setdiff(currentApps, sourceApps);
end

function apps = collectAppEntrypoints(root)
    entries = appEntryFiles(fullfile(root, "apps"));
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

function [snapshotFolder, movedCount] = moveCurrentInstallToSnapshot(root, progressFcn)
    snapshotFolder = uniqueInstallSnapshotFolder(root);
    ensureFolder(snapshotFolder);
    entries = installRootEntries(root);
    [~, snapshotName, snapshotExt] = fileparts(snapshotFolder);
    snapshotLeaf = string(snapshotName) + string(snapshotExt);
    entries = entries(string({entries.name}) ~= snapshotLeaf);
    movedCount = 0;
    entryCount = numel(entries);
    for k = 1:entryCount
        name = string(entries(k).name);
        source = fullfile(root, char(name));
        target = fullfile(snapshotFolder, char(name));
        notifyTopLevelProgress(progressFcn, "Moving old runtime", ...
            k, entryCount, name, 0.55, 0.18);
        movefile(source, target, "f");
        movedCount = movedCount + 1;
    end
end

function snapshotFolder = uniqueInstallSnapshotFolder(root)
    stamp = datestr(now, 'yyyymmdd_HHMMSS');
    baseName = "LabKit-previous-" + string(stamp);
    snapshotFolder = fullfile(root, char(baseName));
    suffix = 1;
    while exist(snapshotFolder, "file") ~= 0 || exist(snapshotFolder, "dir") ~= 0
        snapshotFolder = fullfile(root, char(baseName + "-" + string(suffix)));
        suffix = suffix + 1;
    end
end

function copiedCount = copyReplacementTree(sourceRoot, root, progressFcn)
    entries = installRootEntries(sourceRoot);
    copiedCount = 0;
    entryCount = numel(entries);
    for k = 1:entryCount
        name = string(entries(k).name);
        source = fullfile(sourceRoot, char(name));
        target = fullfile(root, char(name));
        notifyTopLevelProgress(progressFcn, "Copying replacement", ...
            k, entryCount, name, 0.75, 0.24);
        copyfile(source, target, "f");
        copiedCount = copiedCount + 1;
    end
end

function entries = installRootEntries(root)
    entries = [dir(fullfile(root, "*")); dir(fullfile(root, ".*"))];
    names = string({entries.name});
    keep = ~ismember(names, [".", ".."]);
    entries = entries(keep);
    names = string({entries.name});
    [~, uniqueOrder] = unique(names, "stable");
    entries = entries(uniqueOrder);
    [~, order] = sort(lower(string({entries.name})));
    entries = entries(order);
end

function notifyTopLevelProgress(progressFcn, action, index, count, name, startValue, span)
    if count == 0
        notifyProgress(progressFcn, action + ": no top-level items.", startValue + span);
        return;
    end
    value = startValue + span * min(1, max(0, index / count));
    message = sprintf("%s %d/%d: %s", char(action), index, count, char(name));
    notifyProgress(progressFcn, message, value);
end

function result = summaryStruct(root, copiedCount, movedCount, snapshotFolder, message)
    result = struct("updated", copiedCount > 0, ...
        "root", string(root), ...
        "copiedCount", copiedCount, "deletedCount", 0, ...
        "movedCount", movedCount, ...
        "snapshotFolder", string(snapshotFolder), ...
        "message", string(message));
end

%% Section: Shared filesystem and path helpers

function notifyProgress(progressFcn, message, value)
    try
        progressFcn(string(message), value);
    catch
    end
end

function updateProgressDialog(dlg, message, value)
    if isempty(dlg) || ~isvalid(dlg)
        return;
    end
    dlg.Message = char(message);
    if isfinite(value)
        dlg.Indeterminate = 'off';
        dlg.Value = min(max(value, 0), 1);
    else
        dlg.Indeterminate = 'on';
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
