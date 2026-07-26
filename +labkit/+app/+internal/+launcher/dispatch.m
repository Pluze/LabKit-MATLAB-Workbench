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
            varargout = {struct("name", "labkit_launcher", "displayName", "LabKit App Launcher", ...
                "version", "1.6.0", "updated", "2026-07-20")};
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
figArgs = {"Name", "LabKit App Launcher", "Tag", "labkitLauncher", ...
    "Position", [150 130 1120 620], "Color", [0.97 0.98 0.99]};
if launcherGuiTestMode() == "hidden"
    figArgs = [figArgs, {"Visible", "off"}];
end
close(findall(groot, "Type", "figure", "Tag", "labkitLauncher"));
fig = uifigure(figArgs{:});
main = uigridlayout(fig, [1 2]);
main.ColumnWidth = {330, "1x"};
main.Padding = [8 8 8 8];
left = uipanel(main, "Title", "Launcher");
right = uipanel(main, "Title", "Applications");
controls = uigridlayout(left, [10 1]);
controls.RowHeight = {32, 32, 32, 32, 32, 32, 32, 32, 32, "1x"};
setappdata(groot, "labkitFigureStudioLauncher", @(ax) launchFigureStudioFromAxes(root, ax));
openButton = uibutton(controls, "Text", "Open Selected App");
refreshButton = uibutton(controls, "Text", "Refresh App List");
docsButton = uibutton(controls, "Text", "Documentation and History");
repairButton = uibutton(controls, "Text", "Repair / Reinstall");
cleanButton = uibutton(controls, "Text", "Clean Artifacts");
docsToolButton = uibutton(controls, "Text", "Build Documentation");
codeButton = uibutton(controls, "Text", "Code Analyzer");
profileButton = uibutton(controls, "Text", "Profile Selected App");
packageButton = uibutton(controls, "Text", "Package Selected App");
status = uitextarea(controls, "Editable", "off", "Value", "Ready.");
grid = uigridlayout(right, [1 1]);
table = uitable(grid, "ColumnName", {"Family", "App", "Visibility", "Version", "Updated", "Command"}, ...
    "RowName", {}, "ColumnEditable", false(1, 6));
state = struct("apps", discoverApps(root), "selected", 1);
refresh();
openButton.ButtonPushedFcn = @(~, ~) launchSelected();
refreshButton.ButtonPushedFcn = @(~, ~) refresh();
docsButton.ButtonPushedFcn = @(~, ~) openDocumentation();
repairButton.ButtonPushedFcn = @(~, ~) labkit_launcher("repair");
cleanButton.ButtonPushedFcn = @(~, ~) runTool("clean");
docsToolButton.ButtonPushedFcn = @(~, ~) runTool("docs");
codeButton.ButtonPushedFcn = @(~, ~) runTool("codecheck");
profileButton.ButtonPushedFcn = @(~, ~) runTool("profile");
packageButton.ButtonPushedFcn = @(~, ~) runTool("package");
table.CellSelectionCallback = @selectRow;

    function refresh()
        state.apps = discoverApps(root);
        table.Data = displayRows(state.apps);
        state.selected = min(max(state.selected, 1), max(numel(state.apps), 1));
        enabled = matlab.lang.OnOffSwitchState(~isempty(state.apps));
        openButton.Enable = enabled;
        docsButton.Enable = enabled;
        if isempty(state.apps)
            status.Value = "No app entry points found. Repair / Reinstall may restore this installation.";
        else
            status.Value = string(sprintf("%d app entry point(s) available.", numel(state.apps)));
        end
    end

    function selectRow(~, event)
        if ~isempty(event.Indices)
            state.selected = event.Indices(1, 1);
        end
    end

    function launchSelected()
        if isempty(state.apps)
            return;
        end
        app = state.apps(state.selected);
        try
            addpath(app.folder, "-end");
            feval(app.command);
            status.Value = "Opened " + app.command + ".";
        catch cause
            if isStructuralStartupFailure(cause)
                status.Value = ["Could not start " + app.command + ": " + string(cause.message); ...
                    "The installation may be incomplete. Use Repair / Reinstall."];
            else
                status.Value = "App " + app.command + " reported: " + string(cause.message);
            end
        end
    end

    function openDocumentation()
        if isempty(state.apps)
            return;
        end
        try
            page = documentationPage(root, state.apps(state.selected).command);
            if launcherGuiTestMode() ~= "hidden"
                web(page, "-browser");
            end
            status.Value = "Opened documentation for " + state.apps(state.selected).command + ".";
        catch cause
            status.Value = "Documentation unavailable: " + string(cause.message);
        end
    end

    function runTool(kind)
        try
            switch kind
                case "clean"
                    callTool(root, fullfile("tools", "maintenance"), "cleanLabKitArtifacts", root);
                case "docs"
                    callTool(root, fullfile("tools", "docs"), "renderLabKitDocs", ...
                        fullfile(root, "docs"), fullfile(root, "site"));
                case "codecheck"
                    callTool(root, fullfile("tools", "codecheck"), "runCodecheckReport", root);
                case "profile"
                    requireSelectedApp();
                    callTool(root, fullfile("tools", "profiling"), "profileLabKitTarget", ...
                        state.apps(state.selected).command, [], "OpenReport", false, "WaitForGuiClose", false);
                case "package"
                    requireSelectedApp();
                    callTool(root, fullfile("tools", "deployment"), "packageLabKitApp", ...
                        state.apps(state.selected).command, [], "Root", root, "CodeFormat", "source");
            end
            status.Value = "Tool completed.";
        catch cause
            status.Value = "Tool failed: " + string(cause.message);
        end
    end

    function requireSelectedApp()
        if isempty(state.apps)
            error("labkit:app:internal:launcher:NoAppSelected", "Select an app before using this tool.");
        end
    end
end

function callTool(root, relativeFolder, name, varargin)
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
feval(name, varargin{:});
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
