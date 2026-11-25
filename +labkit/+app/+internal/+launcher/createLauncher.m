function fig = createLauncher(root,guideReachable,confirmBuild)
%CREATELAUNCHER Coordinate state and actions for the native Launcher view.
% ROOT is the checkout or installed package root. The figure owns callback
% state; focused package functions own view construction, discovery, dynamic
% App invocation, and source-checkout tool adaptation.

if nargin < 2, guideReachable = @onlineGuideReachable; end
if nargin < 3, confirmBuild = @confirmLocalBuild; end
launchLog = labkit.app.internal.launcher.createLaunchLog(root);
labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
    "launcher.session.started", [], "", "started", "");
stageClock = tic;
view = labkit.app.internal.launcher.createLauncherView();
fig = view.figure;
labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
    "launcher.view.created", toc(stageClock), "", "completed", "");
setappdata(fig, "labkitLauncherLog", launchLog);
state = struct( ...
    "catalog", labkit.app.internal.discovery.emptyApps(), ...
    "apps", labkit.app.internal.discovery.emptyApps(), ...
    "selected", 1, ...
    "catalogLoaded", false, ...
    "checkedCommands", strings(0, 1), ...
    "logLines", strings(0,1), ...
    "reportPath", "", ...
    "busy", false, ...
    "tools", emptyToolAvailability());

configureTable(view.appTable, @selectRow, @doubleClickRow);
view.appTable.CellEditCallback = @changePackageSelection;
view.openButton.ButtonPushedFcn = @(~, ~) launchSelected();
view.refreshButton.ButtonPushedFcn = @(~, ~) refreshApps();
view.appDocsButton.ButtonPushedFcn = @(~, ~) openDocumentation();
view.brandButton.ButtonPushedFcn = @(src,~) openViewer(src,@() openInBrowser( ...
    "https://github.com/Pluze/LabKit-MATLAB-Workbench"));
view.logButton.MenuSelectedFcn = @(src,~) openViewer(src,@() labkit.app.internal.launcher.showLaunchLog(launchLog));
view.reportButton.ButtonPushedFcn = @(src,~) openViewer(src,@openReport);
view.latestButton.MenuSelectedFcn = @(~, ~) manageVersion("latest");
view.versionsButton.MenuSelectedFcn = @(~, ~) manageVersion("browse");
view.cleanButton.MenuSelectedFcn = @(~, ~) runMaintenance("clean");
view.docsToolButton.MenuSelectedFcn = @(~, ~) runMaintenance("docs");
view.codeButton.MenuSelectedFcn = @(~, ~) runMaintenance("codecheck");
view.profileButton.MenuSelectedFcn = @(~, ~) runMaintenance("profile");
view.packageButton.ButtonPushedFcn = @(~, ~) packageChecked();

view.search.ValueChangingFcn = @(~,event) filterCatalog(event.Value,currentSelectedCommand());
view.search.ValueChangedFcn = @(src,~) filterCatalog(src.Value,currentSelectedCommand());
view.family.ValueChangedFcn = @(~,~) filterCatalog(view.search.Value,currentSelectedCommand());
view.scope.ValueChangedFcn = view.family.ValueChangedFcn;
refreshApps();

    function filterCatalog(query,command)
        apps = state.catalog;
        mask = true(size(apps));
        for k = 1:numel(apps)
            app = apps(k);
            mask(k) = (view.family.Value == "All families" || view.family.Value == string(app.family)) && ...
                (view.scope.Value == "All apps" || strcmpi(view.scope.Value,app.visibility)) && ...
                (strlength(strip(string(query))) == 0 || contains(join([string(app.name),string(app.family),string(app.description),string(app.command)]), ...
                    strip(string(query)),IgnoreCase=true));
        end
        state.apps = apps(mask);
        state.selected = appRowByCommand(state.apps,command);
        view.appTable.Data = launcherRows(state.apps,state.checkedCommands);
        if ~isempty(state.apps) && isprop(view.appTable,"Selection")
            view.appTable.Selection = state.selected;
        end
        view.count.Text = string(numel(apps));
        if numel(state.apps) ~= numel(apps)
            view.count.Text = compose("%d/%d",numel(state.apps),numel(apps));
        end
        view.count.Tooltip = compose("%d of %d applications",numel(state.apps),numel(apps));
        setControlsEnabled(~state.busy);
        updateInfo();
    end

    function refreshApps()
        if state.busy, return; end
        selectedCommand = currentSelectedCommand();
        previousApps = state.catalog;
        refreshClock = tic;
        labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
            "launcher.catalog.refresh.started", [], "", "started", "");
        statusClock = tic;
        beginAction("Refresh catalog","Discovering installed apps...");
        labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
            "launcher.catalog.status_presented", toc(statusClock), ...
            "", "completed", "");
        try
            discoveryClock = tic;
            state.catalog = labkit.app.internal.discovery.discoverApps(root);
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.catalog.discovered", toc(discoveryClock), ...
                "", "completed", "");
            toolsClock = tic;
            state.tools = ...
                labkit.app.internal.launcher.launcherToolAvailability(root);
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.tools.probed", toc(toolsClock), ...
                "", "completed", "");
            state.checkedCommands = retainedCommands( ...
                state.catalog, state.checkedCommands);
            previousFamily = string(view.family.Value);
            families = ["All families",sort(unique(string({state.catalog.family})))];
            view.family.Items = families;
            if any(families == previousFamily), view.family.Value = previousFamily; end
            filterCatalog(view.search.Value,selectedCommand);
            setStatus(catalogSummary(state.catalog,previousApps,state.catalogLoaded));
            state.catalogLoaded = true;
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.catalog.refresh.completed", toc(refreshClock), ...
                "", "completed", "");
        catch cause
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.catalog.refresh.failed", toc(refreshClock), ...
                "", "failed", cause.identifier);
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
        launchClock = tic;
        labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
            "launcher.app.started", [], app.command, "started", "");
        view.openButton.Text = "Starting App...";
        statusClock = tic;
        beginAction("Open " + app.name, "Starting " + app.name + ...
            " (1/2): preparing app path...");
        labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
            "launcher.app.status_presented", toc(statusClock), ...
            app.command, "completed", "");
        try
            pathClock = tic;
            labkit.app.internal.discovery.addPathIfMissing(app.folder, "-end");
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.app.path_prepared", toc(pathClock), ...
                app.command, "completed", "");
            reportLaunchStage(app, 2, ...
                "initializing app window");
            invocationClock = tic;
            labkit.app.internal.discovery.invokeDiscoveredApp(app);
            invocationDuration = toc(invocationClock);
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.app.invocation_completed", invocationDuration, ...
                app.command, "completed", "");
            totalDuration = toc(launchClock);
            setStatus(compose("Opened %s in %.2f s.", ...
                app.name, totalDuration));
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.app.completed", totalDuration, ...
                app.command, "completed", "");
        catch cause
            labkit.app.internal.launcher.appendLaunchLog(launchLog, ...
                "launcher.app.failed", toc(launchClock), ...
                app.command, "failed", cause.identifier);
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
        beginAction(app.name + " guide","Checking the online guide…");
        try
            page = labkit.app.internal.launcher.documentationPage( ...
                root, app.command, "online");
            source = "Online";
            if ~guideReachable(page)
                source = "Local";
                try
                    page = labkit.app.internal.launcher.documentationPage(root,app.command,"local");
                catch missing
                    if string(missing.identifier) ~= "labkit:app:internal:launcher:LocalDocumentationMissing"
                        rethrow(missing)
                    end
                    if ~state.tools.docs
                        error("labkit:app:internal:launcher:GuideBuildUnavailable", ...
                            "The online guide is unreachable. This installation has no local guide or documentation generator.")
                    end
                    if ~confirmBuild(fig)
                        setStatus("Local guide generation canceled.");
                        endAction();
                        return
                    end
                    setStatus("Generating local documentation…");
                    drawnow;
                    invokeTool(fullfile("tools","docs"),"renderLabKitDocs", ...
                        fullfile(root,"docs"),fullfile(root,"site"));
                    page = labkit.app.internal.launcher.documentationPage(root,app.command,"local");
                end
            end
            if labkit.app.internal.launcher.launcherGuiTestMode() ~= "hidden"
                if web(char(page), "-browser") ~= 0
                    error("labkit:app:internal:launcher:BrowserUnavailable", ...
                        "The system browser could not open the documentation.");
                end
            end
            setStatus([source + " guide for " + app.name; string(page)]);
        catch cause
            setStatus("Documentation unavailable: " + failureText(cause));
        end
        endAction();
    end

    function manageVersion(mode)
        if state.busy, return; end
        if mode == "browse"
            label = "Browse releases";
        else
            label = "Install latest release";
        end
        beginAction(label,"Preparing version tools...");
        try
            if mode == "browse"
                invokeTool(fullfile("tools", "deployment"), ...
                    "manageLabKitVersions", root, mode, ...
                    "ProgressFcn", @reportVersionProgress);
                setStatus(["Opened LabKit Version Manager."; "Choose a release there to read its changes and installation options."]);
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
        switch kind
            case "clean", label = "Clean artifacts";
            case "docs", label = "Generate documentation";
            case "codecheck", label = "Analyze source code";
            case "profile", label = "Profile " + selectedApp().name;
        end
        beginAction(label,label + "…");
        try
            switch kind
                case "clean"
                    result = invokeTool(fullfile("tools", "maintenance"), ...
                        "cleanLabKitArtifacts", root, ...
                        "ProgressFcn", @reportProgress);
                    setStatus([compose("%d removed · %d errors",result.removedCount,numel(result.errors)); ...
                        string(result.removedTargets(:)); string(result.errors(:))]);
                case "docs"
                    result = invokeTool(fullfile("tools", "docs"), ...
                        "renderLabKitDocs", fullfile(root, "docs"), ...
                        fullfile(root, "site"));
                    setStatus(compose("Built %d guide pages and %d API pages.",result.pageCount,result.apiCount), ...
                        fullfile(result.outputRoot,"index.html"));
                case "codecheck"
                    result = invokeTool(fullfile("tools", "codecheck"), ...
                        "runCodecheckReport", root, ...
                        "ProgressFcn", @reportProgress);
                    setStatus([compose("%d files analyzed · %d analyzer issues",result.fileCount,result.issueCount); ...
                        compose("%d runtime violations · %d compatibility recommendations", ...
                        result.runtimeViolationCount,result.compatibilityRecommendationCount); ...
                        compose("%d hygiene findings · %d suppressed issues",result.hygieneViolationCount,result.suppressedIssueCount)],result.htmlFile);
                case "profile"
                    app = selectedApp();
                    [report, artifacts] = invokeTool(fullfile("tools", "profiling"), ...
                        "profileLabKitTarget", app.command, [], ...
                        "OpenReport", false, "WaitForGuiClose", false);
                    setStatus(compose("%s startup · %d functions profiled",app.name,artifacts.functionCount),report);
            end
        catch cause
            setStatus("Tool failed: " + failureText(cause));
        end
        endAction();
    end

    function packageChecked()
        if state.busy, return; end
        apps = checkedApps(state.catalog, state.checkedCommands);
        if isempty(apps)
            setStatus("Check one or more apps in the Package column first.");
            return;
        end
        commands = string({apps.command});
        beginAction("Package " + numel(commands) + " app(s)",["Creating source archive…"; string({apps.name}).']);
        try
            result = invokeTool(fullfile("tools", "deployment"), ...
                "packageLabKitApp", commands, [], "Root", root, ...
                "ProgressFcn", @reportProgress);
            setStatus(["Created source archive"; string(result.zipFile); ""; string({apps.name}).']);
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

    function reportVersionProgress(message,fraction)
        if isvalid(fig)
            setStatus(compose("Updates · %.0f%%  %s",100*fraction,string(message)));
            drawnow limitrate;
        end
    end

    function reportProgress(message, fraction)
        setStatus(compose("%.0f%%  %s",100*fraction,string(message)));
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

    function openViewer(button,open)
        if state.busy, return; end
        state.busy = true;
        label = button.Text;
        cleanup = onCleanup(@() restoreViewerButton(button,label));
        try
            button.Text = "Opening…";
            fig.Pointer = "watch";
            setControlsEnabled(false);
            drawnow nocallbacks;
            open();
        catch cause
            setStatus(string(label) + " failed: " + failureText(cause));
        end
        clear cleanup
    end

    function restoreViewerButton(button,label)
        if ~isvalid(fig), return; end
        button.Text = label;
        endAction();
    end

    function openReport()
        if ~isfile(state.reportPath)
            error("labkit:app:internal:launcher:ReportUnavailable", ...
                "Report file is unavailable: %s",state.reportPath);
        end
        openInBrowser(state.reportPath);
    end

    function openInBrowser(target)
        if labkit.app.internal.launcher.launcherGuiTestMode() ~= "hidden" && web(char(target),"-browser") ~= 0
            error("labkit:app:internal:launcher:BrowserUnavailable","The system browser could not open %s.",target);
        end
    end

    function beginAction(label,message)
        if ~isempty(state.logLines), state.logLines(end+1,1) = ""; end
        state.logLines(end+1,1) = string(datetime("now","Format","HH:mm:ss")) + "   ›   " + label;
        view.reportButton.Visible = "off";
        state.reportPath = "";
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
        view.search.Enable = value;
        view.family.Enable = value;
        view.scope.Enable = value;
        view.logButton.Enable = value;
        view.brandButton.Enable = value;
        view.reportButton.Enable = value;
        view.toolsButton.Enable = value;
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

    function setStatus(message,report)
        message = string(message);
        state.logLines = [state.logLines; message(:)];
        if nargin > 1
            state.logLines(end+1,1) = string(report);
            if isfile(report)
                state.reportPath = string(report);
                view.reportButton.Tooltip = report;
                view.reportButton.Visible = "on";
            end
        end
        state.logLines = state.logLines(max(1,end-999):end);
        view.status.Value = state.logLines;
        scroll(view.status,"bottom");
    end

    function updateInfo()
        if isempty(state.apps)
            view.selectionTitle.Text = "No applications";
            view.selectionTitle.Tooltip = "";
            view.description.Tooltip = "";
            if isempty(state.catalog)
                view.description.Text = "No apps found in this installation.";
            else
                view.description.Text = "Try another search or filter.";
            end
        else
            app = selectedApp();
            view.selectionTitle.Text = app.name;
            view.selectionTitle.Tooltip = app.name;
            view.description.Text = app.description;
            view.description.Tooltip = app.description;
        end
        apps = checkedApps(state.catalog,state.checkedCommands);
        view.packageButton.Visible = switchState(~isempty(apps));
        view.packageButton.Enable = switchState(~state.busy && state.tools.package && ~isempty(apps));
        if isempty(apps)
            view.packageButton.Text = "Package Checked";
            view.packageButton.Tooltip = "Check apps in the Package column to create a source archive.";
        else
            view.packageButton.Text = "Package Checked (" + numel(apps) + ")";
            view.packageButton.Tooltip = join(string({apps.name}),newline);
        end
    end
end

function value = switchState(value)
value = matlab.lang.OnOffSwitchState(value);
end

function tools = emptyToolAvailability()
tools = struct("version", false, "clean", false, "docs", false, ...
    "codecheck", false, "profile", false, "package", false);
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

function message = catalogSummary(apps, previous, hasPrevious)
families = string({apps.family});
message = compose("%d apps across %d families.",numel(apps),numel(unique(families)));
if hasPrevious
    commands = string({apps.command});
    oldCommands = string({previous.command});
    [present, oldIndex] = ismember(commands,oldCommands);
    changes = strings(numel(apps),1);
    for k = 1:numel(apps)
        if ~present(k)
            changes(k) = "Added · " + apps(k).name;
        elseif string(apps(k).version) ~= string(previous(oldIndex(k)).version)
            changes(k) = apps(k).name + " · " + previous(oldIndex(k)).version + " → " + apps(k).version;
        end
    end
    removed = previous(~ismember(oldCommands,commands));
    changes = [changes(changes ~= ""); reshape("Removed · " + string({removed.name}),[],1)];
    if isempty(changes)
        changes = "App list and installed versions are unchanged.";
    end
    message = [message; ""; changes];

end
if isempty(apps)
    message(end+1,1) = "No app entry points found. If the installation is incomplete, run labkit_launcher(""repair"").";
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

function available = onlineGuideReachable(page)
try
    webread(page,weboptions(Timeout=3,ContentType="text"));
    available = true;
catch
    available = false;
end
end

function generate = confirmLocalBuild(fig)
choice = uiconfirm(fig,"The online App guide is unreachable. Generate the local documentation and open this guide?", ...
    "Open offline guide",Options=["Generate and open","Cancel"],DefaultOption=1,CancelOption=2);
generate = string(choice) == "Generate and open";
end
