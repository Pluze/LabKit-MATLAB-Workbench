function varargout = dispatch(root, varargin)
%DISPATCH Own the installed LabKit launcher composition and entry routing.
% Private capability. The root launcher owns repair only.

    [mode, modeArgs] = parseMode(varargin);
    switch mode
        case "list"
            varargout = {appCatalogTable(discoverApps(root))};
        case "documentation"
            varargout = {documentationPage(root, modeArgs)};
        case "version"
            varargout = {launcherVersion()};
        otherwise
            if nargout > 1
                error("labkit:app:internal:launcher:TooManyOutputs", ...
                    "Launcher dispatch returns at most one figure.");
            end
            fig = createLauncher(root);
            if nargout == 1
                varargout = {fig};
            end
    end
end

function [mode, appCommand] = parseMode(args)
mode = "gui";
appCommand = "";
if isempty(args)
    return;
end
if numel(args) == 2 && isTextScalar(args{1}) && strcmpi(string(args{1}), "documentation")
    appCommand = string(args{2});
    if ~isTextScalar(appCommand) || strlength(strtrim(appCommand)) == 0
        error("labkit:app:internal:launcher:InvalidInput", ...
            "Documentation mode requires one nonempty app command.");
    end
    mode = "documentation";
    return;
end
if numel(args) ~= 1 || ~isTextScalar(args{1})
    error("labkit:app:internal:launcher:InvalidInput", ...
        "Use no input, list, version, or documentation plus one app command.");
end
mode = lower(string(args{1}));
if ~ismember(mode, ["list", "version"])
    error("labkit:app:internal:launcher:InvalidInput", "Unsupported launcher mode: %s", mode);
end
end

function fig = createLauncher(root)
panelFontSize = 15;
tableFontSize = 14;
version = launcherVersion();
position = defaultLauncherPosition();
figArgs = { ...
    "Name", version.displayName + " v" + version.version + ...
        " (" + version.updated + ")", ...
    "Tag", "labkitLauncher", ...
    "Position", position, ...
    "Color", [0.97 0.98 0.99]};
if launcherGuiTestMode() == "hidden"
    figArgs = [figArgs, {"Visible", "off"}];
end
close(findall(groot, "Type", "figure", "Tag", "labkitLauncher"));
fig = uifigure(figArgs{:});
main = uigridlayout(fig, [1 3]);
leftWidth = min(420, max(380, round(position(3) * 0.28)));
main.ColumnWidth = {leftWidth, 5, "1x"};
main.RowHeight = {"1x"};
main.Padding = [6 6 6 6];
main.ColumnSpacing = 0;

left = uipanel(main, "Title", "Launcher", "FontSize", panelFontSize);
left.Layout.Column = 1;
divider = uipanel(main, "BorderType", "none", ...
    "BackgroundColor", [0.78 0.80 0.82]);
divider.Layout.Column = 2;
right = uipanel(main, "Title", "Applications", "FontSize", panelFontSize);
right.Layout.Column = 3;

controls = uigridlayout(left, [5 1]);
controls.RowHeight = {108, 72, 108, 72, "1x"};
controls.Padding = [6 6 6 6];
controls.RowSpacing = 6;

runPanel = uipanel(controls, "Title", "Run Apps");
runPanel.Layout.Row = 1;
runGrid = uigridlayout(runPanel, [2 2]);
runGrid.RowHeight = {"1x", "1x"};
runGrid.ColumnWidth = {"1x", "1x"};
runGrid.Padding = [5 5 5 5];
runGrid.RowSpacing = 5;
runGrid.ColumnSpacing = 6;
openButton = uibutton(runGrid, "Text", "Open Selected App");
openButton.Layout.Row = 1;
openButton.Layout.Column = [1 2];
refreshButton = uibutton(runGrid, "Text", "Refresh App List");
refreshButton.Layout.Row = 2;
refreshButton.Layout.Column = 1;
appDocsButton = uibutton(runGrid, "Text", "Documentation and History");
appDocsButton.Layout.Row = 2;
appDocsButton.Layout.Column = 2;
appDocsButton.Tooltip = ...
    "Open the generated documentation page for the selected app.";

versionPanel = uipanel(controls, "Title", "Versions and Install");
versionPanel.Layout.Row = 2;
versionGrid = uigridlayout(versionPanel, [1 3]);
versionGrid.ColumnWidth = {"1x", "1x", "1x"};
versionGrid.Padding = [5 5 5 5];
versionGrid.ColumnSpacing = 6;
latestButton = uibutton(versionGrid, "Text", "Latest");
releaseButton = uibutton(versionGrid, "Text", "Release");
versionsButton = uibutton(versionGrid, "Text", "Versions");
latestButton.Tooltip = "Download and apply the latest main branch ZIP.";
releaseButton.Tooltip = "Download and apply the latest stable release.";
versionsButton.Tooltip = ...
    "Choose a recent release, tag, or main-branch commit.";

maintenancePanel = uipanel(controls, ...
    "Title", "Development and Maintenance");
maintenancePanel.Layout.Row = 3;
maintenanceGrid = uigridlayout(maintenancePanel, [2 2]);
maintenanceGrid.ColumnWidth = {"1x", "1x"};
maintenanceGrid.RowHeight = {"1x", "1x"};
maintenanceGrid.Padding = [5 5 5 5];
maintenanceGrid.RowSpacing = 5;
maintenanceGrid.ColumnSpacing = 6;
docsToolButton = uibutton(maintenanceGrid, "Text", "Update Documentation");
codeButton = uibutton(maintenanceGrid, "Text", "Run Code Analyzer");
profileButton = uibutton(maintenanceGrid, "Text", "Profile Selected App");
cleanButton = uibutton(maintenanceGrid, "Text", "Clean Artifacts");
docsToolButton.Tooltip = ...
    "Rebuild the documentation site from docs and public MATLAB help.";
codeButton.Tooltip = ...
    "Run MATLAB Code Analyzer and write the repository report.";
profileButton.Tooltip = ...
    "Profile the selected app and save its report without opening a browser.";
cleanButton.Tooltip = ...
    "Remove generated artifacts through the maintenance tool.";

packagePanel = uipanel(controls, "Title", "Package and Publish");
packagePanel.Layout.Row = 4;
packageGrid = uigridlayout(packagePanel, [1 2]);
packageGrid.ColumnWidth = {"1x", "1x"};
packageGrid.Padding = [5 5 5 5];
packageGrid.ColumnSpacing = 6;
packageButton = uibutton(packageGrid, "Text", "Package Checked");
pcodeButton = uibutton(packageGrid, "Text", "Checked P-code");
packageButton.Tooltip = ...
    "Create one standalone source package containing every checked app.";
pcodeButton.Tooltip = ...
    "Create the same multi-app package with MATLAB code encoded as P-code.";

status = uitextarea(controls, "Editable", "off", "Value", "Ready.");
status.Layout.Row = 5;
tableGrid = uigridlayout(right, [1 1]);
tableGrid.Padding = [4 4 4 4];
appTable = uitable(tableGrid, ...
    "ColumnName", { ...
        "Package", "Family", "App", "Visibility", ...
        "Version", "Updated", "Command"}, ...
    "ColumnEditable", [true false false false false false false], ...
    "RowName", {}, ...
    "FontSize", tableFontSize);
if isprop(appTable, "ColumnFormat")
    appTable.ColumnFormat = { ...
        'logical', 'char', 'char', 'char', 'char', 'char', 'char'};
end
appTable.ColumnWidth = repmat({"auto"}, 1, 7);
configureTable(appTable, @selectRow, @doubleClickRow);
appTable.CellEditCallback = @changePackageSelection;

setappdata(groot, "labkitFigureStudioLauncher", ...
    @(ax) launchFigureStudioFromAxes(root, ax));
view = struct( ...
    "figure", fig, ...
    "controls", struct( ...
        "selectedDetails", struct("textArea", status), ...
        "statusLine", struct("textArea", status), ...
        "appTable", struct("table", appTable)));
setappdata(fig, "labkitLauncherView", view);
state = struct( ...
    "apps", emptyApps(), ...
    "selected", 1, ...
    "checkedCommands", strings(0, 1), ...
    "status", "Loading app list...", ...
    "busy", false, ...
    "tools", launcherToolAvailability(root));

openButton.ButtonPushedFcn = @(~, ~) launchSelected();
refreshButton.ButtonPushedFcn = @(~, ~) refreshApps();
appDocsButton.ButtonPushedFcn = @(~, ~) openDocumentation();
latestButton.ButtonPushedFcn = @(~, ~) manageVersion("main");
releaseButton.ButtonPushedFcn = @(~, ~) manageVersion("stable");
versionsButton.ButtonPushedFcn = @(~, ~) manageVersion("browse");
cleanButton.ButtonPushedFcn = @(~, ~) runMaintenance("clean");
docsToolButton.ButtonPushedFcn = @(~, ~) runMaintenance("docs");
codeButton.ButtonPushedFcn = @(~, ~) runMaintenance("codecheck");
profileButton.ButtonPushedFcn = @(~, ~) runMaintenance("profile");
packageButton.ButtonPushedFcn = @(~, ~) packageChecked("source");
pcodeButton.ButtonPushedFcn = @(~, ~) packageChecked("pcode");
refreshApps();

    function refreshApps()
        if state.busy
            return;
        end
        selectedCommand = currentSelectedCommand();
        beginAction("Refreshing app list...");
        try
            state.apps = discoverApps(root);
            state.tools = launcherToolAvailability(root);
            state.checkedCommands = retainedCommands( ...
                state.apps, state.checkedCommands);
            state.selected = appRowByCommand(state.apps, selectedCommand);
            appTable.Data = launcherRows(state.apps, state.checkedCommands);
            setStatus(appAvailabilityStatus(state.apps));
        catch cause
            setStatus("Refresh app list failed: " + failureText(cause));
        end
        endAction();
    end

    function selectRow(~, event)
        row = eventRow(event);
        if ~isnan(row)
            state.selected = row;
            updateInfo();
        end
    end

    function doubleClickRow(~, event)
        row = eventRow(event);
        if ~isnan(row)
            state.selected = row;
        end
        launchSelected();
    end

    function changePackageSelection(~, event)
        if isempty(event.Indices) || isempty(state.apps)
            return;
        end
        row = event.Indices(1, 1);
        if row < 1 || row > numel(state.apps)
            return;
        end
        command = string(state.apps(row).command);
        state.checkedCommands(state.checkedCommands == command) = [];
        if logical(event.NewData)
            state.checkedCommands(end + 1, 1) = command;
        end
        updateInfo();
    end

    function launchSelected()
        if state.busy || isempty(state.apps)
            return;
        end
        app = selectedApp();
        beginAction("Opening " + app.command + "...");
        try
            addPathIfMissing(app.folder, "-end");
            feval(app.command);
            setStatus("Opened " + app.command + ".");
        catch cause
            if isStructuralStartupFailure(cause)
                setStatus([ ...
                    "Could not start " + app.command + ": " + ...
                        failureText(cause)
                    "The installation may be incomplete. Run " + ...
                        "labkit_launcher(""repair"") to reinstall."
                    ]);
            else
                setStatus("App " + app.command + " reported: " + ...
                    failureText(cause));
            end
        end
        endAction();
    end

    function openDocumentation()
        if state.busy || isempty(state.apps)
            return;
        end
        app = selectedApp();
        beginAction("Opening documentation for " + app.command + "...");
        try
            page = documentationPage(root, app.command);
            if launcherGuiTestMode() ~= "hidden"
                web(page, "-browser");
            end
            setStatus("Opened documentation for " + app.command + ".");
        catch cause
            setStatus("Documentation unavailable: " + failureText(cause));
        end
        endAction();
    end

    function manageVersion(mode)
        if state.busy
            return;
        end
        beginAction("Preparing LabKit version tools...");
        try
            if mode == "browse"
                callTool(root, fullfile("tools", "deployment"), ...
                    "manageLabKitVersions", root, mode, ...
                    "ProgressFcn", @reportProgress);
                setStatus("Opened LabKit Version Manager.");
            else
                result = callTool(root, fullfile("tools", "deployment"), ...
                    "manageLabKitVersions", root, mode, ...
                    "ProgressFcn", @reportProgress);
                setStatus(result.message);
            end
        catch cause
            setStatus("Version action failed: " + failureText(cause));
        end
        endAction();
    end

    function runMaintenance(kind)
        if state.busy
            return;
        end
        beginAction("Running " + kind + "...");
        try
            switch kind
                case "clean"
                    result = callTool(root, fullfile("tools", "maintenance"), ...
                        "cleanLabKitArtifacts", root, ...
                        "ProgressFcn", @reportProgress);
                    setStatus("Clean Artifacts complete: " + ...
                        string(result.removedCount) + " target(s) removed.");
                case "docs"
                    callTool(root, fullfile("tools", "docs"), ...
                        "renderLabKitDocs", fullfile(root, "docs"), ...
                        fullfile(root, "site"));
                    setStatus("Documentation site updated.");
                case "codecheck"
                    callTool(root, fullfile("tools", "codecheck"), ...
                        "runCodecheckReport", root, ...
                        "ProgressFcn", @reportProgress);
                    setStatus("Code Analyzer report completed.");
                case "profile"
                    app = selectedApp();
                    callTool(root, fullfile("tools", "profiling"), ...
                        "profileLabKitTarget", app.command, [], ...
                        "OpenReport", false, "WaitForGuiClose", false);
                    setStatus("Performance profile completed for " + ...
                        app.command + ".");
            end
        catch cause
            setStatus("Tool failed: " + failureText(cause));
        end
        endAction();
    end

    function packageChecked(codeFormat)
        if state.busy
            return;
        end
        apps = checkedApps(state.apps, state.checkedCommands);
        if isempty(apps)
            setStatus("Check one or more apps in the Package column first.");
            return;
        end
        commands = string({apps.command});
        beginAction("Packaging " + packageSummary(commands) + "...");
        try
            result = callTool(root, fullfile("tools", "deployment"), ...
                "packageLabKitApp", commands, [], ...
                "Root", root, "CodeFormat", codeFormat, ...
                "ProgressFcn", @reportProgress);
            setStatus("Packaged " + packageSummary(commands) + ...
                " at " + string(result.zipFile) + ".");
        catch cause
            setStatus("Package failed: " + failureText(cause));
        end
        endAction();
    end

    function reportProgress(message, ~)
        setStatus(message);
        drawnow limitrate;
    end

    function app = selectedApp()
        if isempty(state.apps)
            error("labkit:app:internal:launcher:NoAppSelected", ...
                "Select an app before using this action.");
        end
        row = min(max(state.selected, 1), numel(state.apps));
        app = state.apps(row);
    end

    function command = currentSelectedCommand()
        command = "";
        if ~isempty(state.apps)
            command = string(selectedApp().command);
        end
    end

    function beginAction(message)
        state.busy = true;
        setControlsEnabled(false);
        setStatus(message);
    end

    function endAction()
        state.busy = false;
        setControlsEnabled(true);
        updateInfo();
    end

    function setControlsEnabled(enabled)
        value = matlab.lang.OnOffSwitchState(enabled);
        refreshButton.Enable = value;
        latestButton.Enable = matlab.lang.OnOffSwitchState( ...
            enabled && state.tools.version);
        releaseButton.Enable = latestButton.Enable;
        versionsButton.Enable = latestButton.Enable;
        cleanButton.Enable = matlab.lang.OnOffSwitchState( ...
            enabled && state.tools.clean);
        docsToolButton.Enable = matlab.lang.OnOffSwitchState( ...
            enabled && state.tools.docs);
        codeButton.Enable = matlab.lang.OnOffSwitchState( ...
            enabled && state.tools.codecheck);
        hasApps = ~isempty(state.apps);
        openButton.Enable = matlab.lang.OnOffSwitchState(enabled && hasApps);
        appDocsButton.Enable = openButton.Enable;
        profileButton.Enable = matlab.lang.OnOffSwitchState( ...
            enabled && hasApps && state.tools.profile);
        packageButton.Enable = matlab.lang.OnOffSwitchState( ...
            enabled && hasApps && state.tools.package);
        pcodeButton.Enable = packageButton.Enable;
    end

    function setStatus(message)
        state.status = string(message);
        updateInfo();
    end

    function updateInfo()
        details = selectedAppDetails(state.apps, state.selected);
        details(end + 1, 1) = "Checked for package: " + ...
            numel(state.checkedCommands) + " app(s)";
        status.Value = [ ...
            "Status: " + state.status
            ""
            details
            ];
    end
end

function info = launcherVersion()
info = struct( ...
    "name", "labkit_launcher", ...
    "displayName", "LabKit App Launcher", ...
    "version", "1.6.0", ...
    "updated", "2026-07-20");
end

function position = defaultLauncherPosition()
screen = double(get(groot, "ScreenSize"));
screenWidth = screen(3);
screenHeight = screen(4);
width = min(screenWidth, max(800, min(1500, screenWidth - 80)));
height = min(screenHeight, max(560, min(780, screenHeight - 120)));
x = screen(1) + max(0, (screenWidth - width) / 2);
y = screen(2) + max(0, (screenHeight - height) / 2);
position = round([x y width height]);
end

function configureTable(tableHandle, selectionCallback, doubleClickCallback)
if isprop(tableHandle, "SelectionChangedFcn")
    tableHandle.SelectionChangedFcn = selectionCallback;
else
    tableHandle.CellSelectionCallback = selectionCallback;
end
if isprop(tableHandle, "SelectionType")
    tableHandle.SelectionType = "row";
end
if isprop(tableHandle, "DoubleClickedFcn")
    tableHandle.DoubleClickedFcn = doubleClickCallback;
elseif isprop(tableHandle, "CellDoubleClickedFcn")
    tableHandle.CellDoubleClickedFcn = doubleClickCallback;
end
end

function row = eventRow(event)
row = NaN;
if isprop(event, "Indices") && ~isempty(event.Indices)
    row = event.Indices(1, 1);
elseif isprop(event, "Selection") && ~isempty(event.Selection)
    row = event.Selection(1, 1);
elseif isstruct(event) && isfield(event, "Indices") && ~isempty(event.Indices)
    row = event.Indices(1, 1);
elseif isstruct(event) && isfield(event, "Selection") && ~isempty(event.Selection)
    row = event.Selection(1, 1);
end
end

function row = appRowByCommand(apps, command)
row = 1;
if isempty(apps) || strlength(string(command)) == 0
    return;
end
match = find(string({apps.command}) == string(command), 1);
if ~isempty(match)
    row = match;
end
end

function rows = launcherRows(apps, checkedCommands)
rows = cell(numel(apps), 7);
checked = ismember(string({apps.command}), string(checkedCommands));
for index = 1:numel(apps)
    rows(index, :) = { ...
        checked(index), ...
        char(apps(index).family), ...
        char(apps(index).name), ...
        char(apps(index).visibility), ...
        char(apps(index).version), ...
        char(apps(index).updated), ...
        char(apps(index).command)};
end
end

function commands = retainedCommands(apps, commands)
available = string({apps.command});
commands = string(commands(:));
commands = commands(ismember(commands, available));
end

function apps = checkedApps(apps, commands)
if isempty(apps)
    return;
end
apps = apps(ismember(string({apps.command}), string(commands)));
end

function summary = packageSummary(commands)
if isscalar(commands)
    summary = string(commands);
else
    summary = string(numel(commands)) + " checked apps";
end
end

function details = selectedAppDetails(apps, selected)
if isempty(apps)
    details = [
        "No app entry points found."
        "Run labkit_launcher(""repair"") if the installation is incomplete."
        ];
    return;
end
row = min(max(selected, 1), numel(apps));
app = apps(row);
details = [
    string(app.name)
    "Family: " + string(app.family)
    "Visibility: " + string(app.visibility)
    "Version: " + string(app.version)
    "Updated: " + string(app.updated)
    "Command: " + string(app.command)
    "Path: " + string(app.folder)
    ];
end

function message = appAvailabilityStatus(apps)
if isempty(apps)
    message = "No app entry points found. Run labkit_launcher(""repair"") " + ...
        "if the installation is incomplete.";
else
    message = string(numel(apps)) + " app entry point(s) available.";
end
end

function tools = launcherToolAvailability(root)
tools = struct( ...
    "version", toolExists(root, "deployment", "manageLabKitVersions"), ...
    "clean", toolExists(root, "maintenance", "cleanLabKitArtifacts"), ...
    "docs", toolExists(root, "docs", "renderLabKitDocs"), ...
    "codecheck", toolExists(root, "codecheck", "runCodecheckReport"), ...
    "profile", toolExists(root, "profiling", "profileLabKitTarget"), ...
    "package", toolExists(root, "deployment", "packageLabKitApp"));
end

function tf = toolExists(root, area, name)
base = fullfile(root, "tools", area, name);
tf = exist(base + ".m", "file") == 2 || exist(base + ".p", "file") == 2;
end

function addPathIfMissing(folder, varargin)
if exist(folder, "dir") == 7 && ~pathContains(folder)
    addpath(folder, varargin{:});
end
end

function text = failureText(cause)
text = string(cause.message);
if strlength(string(cause.identifier)) > 0
    text = string(cause.identifier) + ": " + text;
end
end

function varargout = callTool(root, relativeFolder, name, varargin)
folder = fullfile(root, relativeFolder);
if exist(fullfile(folder, name + ".m"), "file") ~= 2 && ...
        exist(fullfile(folder, name + ".p"), "file") ~= 2
    error("labkit:app:internal:launcher:ToolUnavailable", "Tool is unavailable: %s", name);
end
added = ~pathContains(folder);
if added
    addpath(folder, "-begin");
    cleanup = onCleanup(@() rmpath(folder));
end
if nargout > 0
    [varargout{1:nargout}] = feval(name, varargin{:});
else
    feval(name, varargin{:});
end
clear cleanup
end

function apps = discoverApps(root)
apps = emptyApps();
roots = [string(fullfile(root, "apps")); privateAppRoots(root)];
entrySets = cell(numel(roots), 1);
entryCount = 0;
for rootIndex = 1:numel(roots)
    entrySets{rootIndex} = appEntryFiles(roots(rootIndex));
    entryCount = entryCount + numel(entrySets{rootIndex});
end
records = cell(entryCount, 1);
recordCount = 0;
for rootIndex = 1:numel(roots)
    appRoot = roots(rootIndex);
    if exist(appRoot, "dir") ~= 7
        continue;
    end
    entries = entrySets{rootIndex};
    for entryIndex = 1:numel(entries)
        entry = entries(entryIndex);
        if isHiddenImplementationPath(relativePath(appRoot, entry.folder))
            continue;
        end
        [~, command] = fileparts(entry.name);
        metadata = appVersionInfo(entry.folder);
        app = struct("command", scalarText(command, "command"), ...
            "folder", scalarText(entry.folder, "folder"), ...
            "family", scalarText(familyName(appRoot, entry.folder), "family"), ...
            "name", scalarText(displayName(command), "name"), ...
            "visibility", scalarText(visibilityFor(root, entry.folder), "visibility"), ...
            "version", scalarText(metadata.version, "version"), ...
            "updated", scalarText(metadata.updated, "updated"));
        recordCount = recordCount + 1;
        records{recordCount} = app;
    end
end
if recordCount > 0
    apps = [records{1:recordCount}];
end
if ~isempty(apps)
    keys = [reshape(string({apps.visibility}) == "private", [], 1), ...
        reshape(string({apps.family}), [], 1), reshape(string({apps.name}), [], 1)];
    [~, order] = sortrows(keys);
    apps = apps(order);
end
end

function apps = emptyApps()
apps = struct("command", {}, "folder", {}, "family", {}, "name", {}, ...
    "visibility", {}, "version", {}, "updated", {});
end

function entries = appEntryFiles(appRoot)
entries = [dir(fullfile(char(appRoot), "**", "labkit_*_app.m")); ...
    dir(fullfile(char(appRoot), "**", "labkit_*_app.p"))];
entries = entries(~[entries.isdir]);
if isempty(entries), return; end
count = numel(entries);
paths = strings(count, 1); commands = strings(count, 1); isSource = false(count, 1);
for index = 1:count
    paths(index) = string(fullfile(entries(index).folder, entries(index).name));
    [~, commands(index), extension] = fileparts(paths(index));
    isSource(index) = string(extension) == ".m";
end
[~, order] = sortrows([commands, string(~isSource), paths]);
entries = entries(order); commands = string(commands(order));
[~, keep] = unique(commands, "stable");
entries = entries(keep);
end

function roots = privateAppRoots(root)
parts = split(string(getenv("LABKIT_PRIVATE_APP_ROOTS")), pathsep);
localCandidates = strings(numel(parts) + 1, 1);
candidateCount = 0;
localRoot = fullfile(root, "private_apps", "apps");
if exist(localRoot, "dir") == 7
    candidateCount = candidateCount + 1; localCandidates(candidateCount) = localRoot;
end
environmentRoots = string(getenv("LABKIT_PRIVATE_APP_ROOTS"));
if strlength(environmentRoots) == 0
    roots = unique(localCandidates(1:candidateCount), "stable");
    return;
end
for part = split(environmentRoots, pathsep).'
    candidate = string(part);
    if ~endsWith(replace(candidate, "\\", "/"), "/apps")
        candidate = fullfile(candidate, "apps");
    end
    if exist(candidate, "dir") == 7
        candidateCount = candidateCount + 1;
        localCandidates(candidateCount) = candidate;
    end
end
roots = unique(localCandidates(1:candidateCount), "stable");
end

function value = visibilityFor(root, folder)
if isDescendantPath(folder, fullfile(root, "apps"))
    value = "public";
else
    value = "private";
end
end

function value = familyName(appRoot, folder)
parts = split(relativePath(appRoot, folder), "/");
if isempty(parts) || strlength(parts(1)) == 0
    value = "Other";
else
    value = displayToken(parts(1));
end
end

function tf = isHiddenImplementationPath(relative)
parts = split(string(relative), "/");
tf = any(parts == "private" | startsWith(parts, "+"));
end

function relative = relativePath(root, folder)
root = string(root); folder = string(folder);
prefix = root + filesep;
if startsWith(folder, prefix, "IgnoreCase", ispc)
    relative = extractAfter(folder, strlength(prefix));
else
    relative = folder;
end
relative = replace(relative, string(filesep), "/");
end

function tf = isDescendantPath(folder, ancestor)
folder = lower(replace(string(folder), string(filesep), "/"));
ancestor = lower(replace(string(ancestor), string(filesep), "/"));
tf = folder == ancestor || startsWith(folder, ancestor + "/");
end

function value = displayName(command)
value = erase(string(command), "labkit_");
value = erase(value, "_app");
value = displayToken(value);
end

function value = displayToken(value)
words = split(replace(string(value), "_", " "));
for index = 1:numel(words)
    if lower(words(index)) == "labkit"
        words(index) = "LabKit";
    else
        words(index) = upper(extractBefore(words(index), 2)) + extractAfter(words(index), 1);
    end
end
value = strjoin(cellstr(words), " ");
end

function catalog = appCatalogTable(apps)
count = numel(apps);
familyColumn = strings(count, 1); appColumn = strings(count, 1); visibilityColumn = strings(count, 1);
versionColumn = strings(count, 1); updatedColumn = strings(count, 1); commandColumn = strings(count, 1);
for index = 1:count
    familyColumn(index) = apps(index).family; appColumn(index) = apps(index).name;
    visibilityColumn(index) = apps(index).visibility; versionColumn(index) = apps(index).version;
    updatedColumn(index) = apps(index).updated; commandColumn(index) = apps(index).command;
end
catalog = table(familyColumn, appColumn, visibilityColumn, versionColumn, updatedColumn, commandColumn, ...
    'VariableNames', {'Family', 'App', 'Visibility', 'Version', 'Updated', 'Command'});
end

function rows = displayRows(apps)
rows = cell(numel(apps), 6);
for index = 1:numel(apps)
    rows(index, :) = {char(apps(index).family), char(apps(index).name), ...
        char(apps(index).visibility), char(apps(index).version), ...
        char(apps(index).updated), char(apps(index).command)};
end
end

function page = documentationPage(root, command)
apps = discoverApps(root);
match = find(string({apps.command}) == string(command), 1);
if isempty(match) || apps(match).visibility ~= "public"
    error("labkit:app:internal:launcher:DocumentationUnavailable", ...
        "No public documentation page is available for %s.", command);
end
[~, appId] = fileparts(apps(match).folder);
appId = replace(string(appId), "_", "-");
manuals = dir(fullfile(root, "docs", "apps", "*", appId, "README.md"));
if numel(manuals) ~= 1
    error("labkit:app:internal:launcher:DocumentationUnavailable", ...
        "No generated documentation page is available for %s.", command);
end
[~, family] = fileparts(fileparts(manuals(1).folder));
page = fullfile(root, "site", "apps", family, appId + ".html");
if exist(page, "file") ~= 2
    error("labkit:app:internal:launcher:DocumentationUnavailable", "Generated documentation is missing for %s.", command);
end
end

function tf = isStructuralStartupFailure(cause)
id = string(cause.identifier);
tf = startsWith(id, "MATLAB:UndefinedFunction") || ...
    startsWith(id, "MATLAB:parse") || startsWith(id, "MATLAB:dispatcher");
end

function info = appVersionInfo(folder)
info = struct("version", "", "updated", "");
definitions = dir(fullfile(folder, "+*", "definition.m"));
if isempty(definitions)
    return;
end
try
    text = fileread(fullfile(definitions(1).folder, definitions(1).name));
    info.version = literalField(text, "AppVersion");
    info.updated = literalField(text, "Updated");
catch
end
end

function value = literalField(text, field)
value = "";
patterns = {[char(field) '\s*=\s*"([^"]+)"'], ...
    ['"' char(field) '"\s*,\s*"([^"]+)"']};
for index = 1:numel(patterns)
    tokens = regexp(text, patterns{index}, "tokens", "once");
    if ~isempty(tokens)
        value = string(tokens{1});
        return;
    end
end
end

function value = scalarText(value, field)
value = string(value);
if ~isscalar(value)
    error("labkit:app:internal:launcher:InvalidMetadataShape", ...
        "App metadata field %s must be scalar.", field);
end
end

function tf = pathContains(folder)
entries = string(strsplit(path, pathsep));
target = normalizePathEntry(folder);
tf = any(normalizePathEntry(entries) == target);
end

function value = normalizePathEntry(value)
values = string(value);
for index = 1:numel(values)
    pathValue = java.nio.file.Paths.get(char(values(index)), javaArray("java.lang.String", 0));
    values(index) = string(pathValue.toAbsolutePath().normalize().toString());
end
value = values;
if ispc, value = lower(value); end
end

function launchFigureStudioFromAxes(root, ax)
folder = fullfile(root, "apps", "labkit_core", "figure_studio");
if exist(folder, "dir") ~= 7
    error("labkit:app:internal:launcher:FigureStudioUnavailable", "Figure Studio is unavailable.");
end
if ~pathContains(folder)
    addpath(folder, "-end");
end
labkit_FigureStudio_app("axes", ax);
end

function tf = isTextScalar(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end

function mode = launcherGuiTestMode()
mode = "visible";
if isappdata(groot, "labkitLauncherGuiTestMode")
    mode = string(getappdata(groot, "labkitLauncherGuiTestMode"));
end
end
