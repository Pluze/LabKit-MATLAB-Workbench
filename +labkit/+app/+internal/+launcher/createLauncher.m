function fig = createLauncher(root)
%CREATELAUNCHER Coordinate state and actions for the native Launcher view.
% ROOT is the checkout or installed package root. The figure owns callback
% state; focused package functions own view construction, discovery, dynamic
% App invocation, and source-checkout tool adaptation.

view = labkit.app.internal.launcher.createLauncherView();
fig = view.figure;
state = struct( ...
    "apps", labkit.app.internal.launcher.emptyApps(), ...
    "selected", 1, ...
    "checkedCommands", strings(0, 1), ...
    "status", "Loading app list...", ...
    "busy", false, ...
    "tools", labkit.app.internal.launcher.launcherToolAvailability(root));

configureTable(view.appTable, @selectRow, @doubleClickRow);
view.appTable.CellEditCallback = @changePackageSelection;
view.openButton.ButtonPushedFcn = @(~, ~) launchSelected();
view.refreshButton.ButtonPushedFcn = @(~, ~) refreshApps();
view.appDocsButton.ButtonPushedFcn = @(~, ~) openDocumentation();
view.latestButton.ButtonPushedFcn = @(~, ~) manageVersion("latest");
view.versionsButton.ButtonPushedFcn = @(~, ~) manageVersion("browse");
view.cleanButton.ButtonPushedFcn = @(~, ~) runMaintenance("clean");
view.docsToolButton.ButtonPushedFcn = @(~, ~) runMaintenance("docs");
view.codeButton.ButtonPushedFcn = @(~, ~) runMaintenance("codecheck");
view.profileButton.ButtonPushedFcn = @(~, ~) runMaintenance("profile");
view.packageButton.ButtonPushedFcn = @(~, ~) packageChecked();

refreshApps();

    function refreshApps()
        if state.busy, return; end
        selectedCommand = currentSelectedCommand();
        beginAction("Refreshing app list...");
        try
            state.apps = labkit.app.internal.launcher.discoverApps(root);
            state.tools = ...
                labkit.app.internal.launcher.launcherToolAvailability(root);
            state.checkedCommands = retainedCommands( ...
                state.apps, state.checkedCommands);
            state.selected = appRowByCommand(state.apps, selectedCommand);
            view.appTable.Data = launcherRows( ...
                state.apps, state.checkedCommands);
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
        if ~isnan(row), state.selected = row; end
        launchSelected();
    end

    function changePackageSelection(~, event)
        if isempty(event.Indices) || isempty(state.apps), return; end
        row = event.Indices(1, 1);
        if row < 1 || row > numel(state.apps), return; end
        command = string(state.apps(row).command);
        state.checkedCommands(state.checkedCommands == command) = [];
        if logical(event.NewData)
            state.checkedCommands(end + 1, 1) = command;
        end
        updateInfo();
    end

    function launchSelected()
        if state.busy || isempty(state.apps), return; end
        app = selectedApp();
        view.openButton.Text = "Starting App...";
        beginAction("Starting " + app.name + "...");
        try
            reportLaunchStage(app, 1, "preparing app path");
            labkit.app.internal.launcher.addPathIfMissing(app.folder, "-end");
            reportLaunchStage(app, 2, ...
                "initializing app window via " + app.command);
            labkit.app.internal.launcher.invokeDiscoveredApp(app);
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
        view.openButton.Text = "Open Selected App";
        endAction();
    end

    function reportLaunchStage(app, step, message)
        setStatus("Starting " + app.name + " (" + string(step) + ...
            "/2): " + message + "...");
        drawnow;
    end

    function openDocumentation()
        if state.busy || isempty(state.apps), return; end
        app = selectedApp();
        beginAction("Opening online documentation for " + app.command + "...");
        try
            page = labkit.app.internal.launcher.documentationPage( ...
                root, app.command, "online");
            if labkit.app.internal.launcher.launcherGuiTestMode() ~= "hidden"
                if web(char(page), "-browser") ~= 0
                    error("labkit:app:internal:launcher:BrowserUnavailable", ...
                        "The system browser could not open the documentation.");
                end
            end
            setStatus("Opened online documentation for " + app.command + ".");
        catch cause
            setStatus("Documentation unavailable: " + failureText(cause));
        end
        endAction();
    end

    function manageVersion(mode)
        if state.busy, return; end
        beginAction("Preparing LabKit version tools...");
        try
            if mode == "browse"
                invokeTool(fullfile("tools", "deployment"), ...
                    "manageLabKitVersions", root, mode, ...
                    "ProgressFcn", @reportProgress);
                setStatus("Opened LabKit Version Manager.");
            else
                result = invokeTool(fullfile("tools", "deployment"), ...
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
        if state.busy, return; end
        beginAction("Running " + kind + "...");
        try
            switch kind
                case "clean"
                    result = invokeTool(fullfile("tools", "maintenance"), ...
                        "cleanLabKitArtifacts", root, ...
                        "ProgressFcn", @reportProgress);
                    setStatus("Clean Artifacts complete: " + ...
                        string(result.removedCount) + " target(s) removed.");
                case "docs"
                    invokeTool(fullfile("tools", "docs"), ...
                        "renderLabKitDocs", fullfile(root, "docs"), ...
                        fullfile(root, "site"));
                    setStatus( ...
                        "Local documentation generated from current sources.");
                case "codecheck"
                    invokeTool(fullfile("tools", "codecheck"), ...
                        "runCodecheckReport", root, ...
                        "ProgressFcn", @reportProgress);
                    setStatus("Code Analyzer report completed.");
                case "profile"
                    app = selectedApp();
                    invokeTool(fullfile("tools", "profiling"), ...
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

    function packageChecked()
        if state.busy, return; end
        apps = checkedApps(state.apps, state.checkedCommands);
        if isempty(apps)
            setStatus("Check one or more apps in the Package column first.");
            return;
        end
        commands = string({apps.command});
        beginAction("Packaging " + packageSummary(commands) + "...");
        try
            result = invokeTool(fullfile("tools", "deployment"), ...
                "packageLabKitApp", commands, [], "Root", root, ...
                "ProgressFcn", @reportProgress);
            setStatus("Packaged " + packageSummary(commands) + ...
                " at " + string(result.zipFile) + ".");
        catch cause
            setStatus("Package failed: " + failureText(cause));
        end
        endAction();
    end

    function varargout = invokeTool(relativeFolder, name, varargin)
        if nargout > 0
            [varargout{1:nargout}] = ...
                labkit.app.internal.launcher.invokeLauncherTool( ...
                    root, relativeFolder, name, varargin{:});
        else
            labkit.app.internal.launcher.invokeLauncherTool( ...
                root, relativeFolder, name, varargin{:});
        end
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
        app = state.apps(min(max(state.selected, 1), numel(state.apps)));
    end

    function command = currentSelectedCommand()
        command = "";
        if ~isempty(state.apps), command = string(selectedApp().command); end
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
        if isvalid(fig), fig.Pointer = "arrow"; end
        setControlsEnabled(true);
        updateInfo();
    end

    function setControlsEnabled(enabled)
        value = matlab.lang.OnOffSwitchState(enabled);
        view.refreshButton.Enable = value;
        view.latestButton.Enable = switchState(enabled && state.tools.version);
        view.versionsButton.Enable = view.latestButton.Enable;
        view.cleanButton.Enable = switchState(enabled && state.tools.clean);
        view.docsToolButton.Enable = switchState(enabled && state.tools.docs);
        view.codeButton.Enable = switchState(enabled && state.tools.codecheck);
        hasApps = ~isempty(state.apps);
        view.openButton.Enable = switchState(enabled && hasApps);
        view.appDocsButton.Enable = view.openButton.Enable;
        view.profileButton.Enable = ...
            switchState(enabled && hasApps && state.tools.profile);
        view.packageButton.Enable = ...
            switchState(enabled && hasApps && state.tools.package);
        view.appTable.Enable = char(value);
    end

    function setStatus(message)
        state.status = string(message);
        updateInfo();
    end

    function updateInfo()
        details = selectedAppDetails(state.apps, state.selected);
        details(end + 1, 1) = "Checked for package: " + ...
            numel(state.checkedCommands) + " app(s)";
        view.status.Value = ["Status: " + state.status; ""; details];
    end
end

function value = switchState(value)
value = matlab.lang.OnOffSwitchState(value);
end

function configureTable(tableHandle, selectionCallback, doubleClickCallback)
if isprop(tableHandle, "SelectionChangedFcn")
    tableHandle.SelectionChangedFcn = selectionCallback;
else
    tableHandle.CellSelectionCallback = selectionCallback;
end
if isprop(tableHandle, "SelectionType"), tableHandle.SelectionType = "row"; end
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
elseif isstruct(event) && isfield(event, "Selection") && ...
        ~isempty(event.Selection)
    row = event.Selection(1, 1);
end
end

function row = appRowByCommand(apps, command)
row = 1;
if isempty(apps) || strlength(string(command)) == 0, return; end
match = find(string({apps.command}) == string(command), 1);
if ~isempty(match), row = match; end
end

function rows = launcherRows(apps, checkedCommands)
rows = cell(numel(apps), 6);
checked = ismember(string({apps.command}), string(checkedCommands));
for index = 1:numel(apps)
    rows(index, :) = {checked(index), char(apps(index).family), ...
        char(apps(index).name), char(apps(index).version), ...
        char(apps(index).visibility), char(apps(index).updated)};
end
end

function commands = retainedCommands(apps, commands)
commands = string(commands(:));
commands = commands(ismember(commands, string({apps.command})));
end

function apps = checkedApps(apps, commands)
if ~isempty(apps)
    apps = apps(ismember(string({apps.command}), string(commands)));
end
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
    details = ["No app entry points found."; ...
        "Run labkit_launcher(""repair"") if the installation is incomplete."];
    return;
end
app = apps(min(max(selected, 1), numel(apps)));
details = [string(app.name); "Family: " + string(app.family); ...
    "Visibility: " + string(app.visibility); ...
    "Version: " + string(app.version); "Updated: " + string(app.updated); ...
    "Command: " + string(app.command); "Path: " + string(app.folder)];
end

function message = appAvailabilityStatus(apps)
if isempty(apps)
    message = "No app entry points found. Run labkit_launcher(""repair"") " + ...
        "if the installation is incomplete.";
else
    message = string(numel(apps)) + " app entry point(s) available.";
end
end

function text = failureText(cause)
text = string(cause.message);
if strlength(string(cause.identifier)) > 0
    text = string(cause.identifier) + ": " + text;
end
end

function tf = isStructuralStartupFailure(cause)
id = string(cause.identifier);
tf = startsWith(id, "MATLAB:UndefinedFunction") || ...
    startsWith(id, "MATLAB:parse") || startsWith(id, "MATLAB:dispatcher");
end
