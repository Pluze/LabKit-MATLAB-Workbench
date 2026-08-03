function fig = createLauncher(root)
%CREATELAUNCHER Build and wire the stateful native launcher window.
% ROOT is the checkout or installed package root. The returned uifigure owns
% all callback state; discovery and documentation remain separate owners.
panelFontSize = 15;
tableFontSize = 12;
version = labkit.app.internal.launcher.launcherVersion();
position = defaultLauncherPosition();
figArgs = { ...
    "Name", version.displayName + " v" + version.version + ...
        " (" + version.updated + ")", ...
    "Tag", "labkitLauncher", ...
    "Position", position, ...
    "AutoResizeChildren", "off", ...
    "Color", [0.97 0.98 0.99]};
if launcherGuiTestMode() == "hidden"
    figArgs = [figArgs, {"Visible", "off"}];
end
close(findall(groot, "Type", "figure", "Tag", "labkitLauncher"));
fig = uifigure(figArgs{:});
rootPanel = uipanel(fig, ...
    "BorderType", "none", ...
    "BackgroundColor", fig.Color, ...
    "Units", "pixels", ...
    "Position", [1 1 position(3:4)]);
main = uigridlayout(rootPanel, [1 3]);
leftWidth = launcherControlWidth(position(3));
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
    "Open the online documentation page for the selected app.";

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
docsToolButton = uibutton(maintenanceGrid, ...
    "Text", "Doc Generation");
codeButton = uibutton(maintenanceGrid, "Text", "Run Code Analyzer");
profileButton = uibutton(maintenanceGrid, "Text", "Profile Selected App");
cleanButton = uibutton(maintenanceGrid, "Text", "Clean Artifacts");
docsToolButton.Tooltip = ...
    "Rebuild the ignored local site from current documentation sources.";
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
        "Package", "Family", "App", "Version", "Access", "Updated"}, ...
    "ColumnEditable", [true false false false false false], ...
    "RowName", {}, ...
    "FontSize", tableFontSize);
if isprop(appTable, "ColumnFormat")
    appTable.ColumnFormat = { ...
        'logical', 'char', 'char', 'char', 'char', 'char'};
end
appTable.ColumnWidth = launcherTableWidths(position(3), leftWidth);
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
    "apps", labkit.app.internal.launcher.emptyApps(), ...
    "selected", 1, ...
    "checkedCommands", strings(0, 1), ...
    "status", "Loading app list...", ...
    "busy", false, ...
    "tools", launcherToolAvailability(root));

openButton.ButtonPushedFcn = @(~, ~) launchSelected();
refreshButton.ButtonPushedFcn = @(~, ~) refreshApps();
appDocsButton.ButtonPushedFcn = @(~, ~) openDocumentation("online");
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
fig.SizeChangedFcn = @(~, ~) resizeLauncher();
resizeLauncher();

    function refreshApps()
        if state.busy
            return;
        end
        selectedCommand = currentSelectedCommand();
        beginAction("Refreshing app list...");
        try
            state.apps = labkit.app.internal.launcher.discoverApps(root);
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

    function resizeLauncher()
        if ~isvalid(fig) || ~isvalid(appTable)
            return;
        end
        figureWidth = fig.Position(3);
        rootPanel.Position = [1 1 fig.Position(3:4)];
        resizedControlWidth = launcherControlWidth(figureWidth);
        main.ColumnWidth = {resizedControlWidth, 5, "1x"};
        appTable.ColumnWidth = launcherTableWidths( ...
            figureWidth, resizedControlWidth);
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
        openButton.Text = "Starting App...";
        beginAction("Starting " + app.name + "...");
        try
            reportLaunchStage(app, 1, "preparing app path");
            addPathIfMissing(app.folder, "-end");
            reportLaunchStage(app, 2, ...
                "initializing app window via " + app.command);
            invokeDiscoveredApp(app);
            setStatus("Finishing startup for " + app.name + "...");
            drawnow;
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
        openButton.Text = "Open Selected App";
        endAction();
    end

    function reportLaunchStage(app, step, message)
        setStatus("Starting " + app.name + " (" + string(step) + ...
            "/2): " + message + "...");
        drawnow;
    end

    function openDocumentation(source)
        if state.busy || isempty(state.apps)
            return;
        end
        app = selectedApp();
        beginAction("Opening " + source + " documentation for " + ...
            app.command + "...");
        try
            page = labkit.app.internal.launcher.documentationPage( ...
                root, app.command, source);
            if launcherGuiTestMode() ~= "hidden"
                browserStatus = web(char(page), "-browser");
                if browserStatus ~= 0
                    error( ...
                        "labkit:app:internal:launcher:BrowserUnavailable", ...
                        "The system browser could not open the documentation.");
                end
            end
            setStatus("Opened " + source + " documentation for " + ...
                app.command + ".");
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
                    setStatus("Local documentation generated from current sources.");
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
        fig.Pointer = "watch";
        setControlsEnabled(false);
        setStatus(message);
        drawnow;
    end

    function endAction()
        state.busy = false;
        if isvalid(fig)
            fig.Pointer = "arrow";
        end
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
        appTable.Enable = char(value);
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

function position = defaultLauncherPosition()
screen = double(get(groot, "ScreenSize"));
screenWidth = screen(3);
screenHeight = screen(4);
width = min(screenWidth, max(800, min(1280, screenWidth - 80)));
height = min(screenHeight, max(560, min(720, screenHeight - 120)));
x = screen(1) + max(0, (screenWidth - width) / 2);
y = screen(2) + max(0, (screenHeight - height) / 2);
position = round([x y width height]);
end

function width = launcherControlWidth(figureWidth)
width = min(390, max(350, round(double(figureWidth) * 0.29)));
end

function widths = launcherTableWidths(figureWidth, controlWidth)
tableWidth = max(640, double(figureWidth) - double(controlWidth) - 36);
minimum = [62 120 180 70 72 90];
preferred = [72 150 240 78 80 100];
if tableWidth <= sum(minimum)
    values = minimum;
elseif tableWidth < sum(preferred)
    fraction = (tableWidth - sum(minimum)) / ...
        (sum(preferred) - sum(minimum));
    values = minimum + fraction .* (preferred - minimum);
else
    extra = tableWidth - sum(preferred);
    values = preferred + extra .* [0 0.25 0.60 0 0 0.15];
end
widths = num2cell(round(values));
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
rows = cell(numel(apps), 6);
checked = ismember(string({apps.command}), string(checkedCommands));
for index = 1:numel(apps)
    rows(index, :) = { ...
        checked(index), ...
        char(apps(index).family), ...
        char(apps(index).name), ...
        char(apps(index).version), ...
        char(apps(index).visibility), ...
        char(apps(index).updated)};
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
switch string(name)
    case "manageLabKitVersions"
        callable = @manageLabKitVersions;
    case "cleanLabKitArtifacts"
        callable = @cleanLabKitArtifacts;
    case "renderLabKitDocs"
        callable = @renderLabKitDocs;
    case "runCodecheckReport"
        callable = @runCodecheckReport;
    case "profileLabKitTarget"
        callable = @profileLabKitTarget;
    case "packageLabKitApp"
        callable = @packageLabKitApp;
    otherwise
        error("labkit:app:internal:launcher:UnknownTool", ...
            "Launcher tool is not allowlisted: %s", name);
end
if nargout > 0
    [varargout{1:nargout}] = callable(varargin{:});
else
    callable(varargin{:});
end
clear cleanup
end

function invokeDiscoveredApp(app)
command = string(app.command);
resolved = string(which(char(command)));
expected = fullfile(string(app.folder), command + [".m", ".p"]);
available = arrayfun(@(candidate) exist(candidate, "file") == 2, expected);
expected = expected(available);
if strlength(resolved) == 0 || isempty(expected) || ...
        ~any(normalizePathEntry(resolved) == normalizePathEntry(expected))
    error("labkit:app:internal:launcher:AppEntryMismatch", ...
        "Discovered App entry does not resolve from its owning folder: %s", command);
end
% Dynamic extension boundary: the command is derived from and revalidated
% against one discovered labkit_*_app.m or .p file before invocation.
feval(char(command));
end

function tf = isStructuralStartupFailure(cause)
id = string(cause.identifier);
tf = startsWith(id, "MATLAB:UndefinedFunction") || ...
    startsWith(id, "MATLAB:parse") || startsWith(id, "MATLAB:dispatcher");
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

function mode = launcherGuiTestMode()
mode = "visible";
if isappdata(groot, "labkitLauncherGuiTestMode")
    mode = string(getappdata(groot, "labkitLauncherGuiTestMode"));
end
end
