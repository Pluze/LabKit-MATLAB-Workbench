function varargout = labkit_launcher(varargin)
%LABKIT_LAUNCHER Repair a LabKit installation or delegate to its installed launcher.
%
%   labkit_launcher opens the installed launcher when its private entry is
%   available. If that entry is missing or cannot load, it opens a minimal
%   repair window instead. labkit_launcher("repair") always opens that repair
%   window. Repair is explicit; startup never downloads or replaces files.
%
%   PAGE = labkit_launcher("documentation", APPCOMMAND) returns the selected
%   public App's GitHub Pages URL. PAGE = labkit_launcher("documentation",
%   APPCOMMAND, "local") returns its generated local HTML page and raises
%   labkit:app:internal:launcher:LocalDocumentationMissing when `site/` has
%   not been generated. The programmatic form never opens a browser or prompt.
%   In the visible Launcher, Generate Local Documentation always rebuilds the
%   complete ignored `site/` folder and does not open a documentation page.

    if nargout > 1
        error("labkit_launcher:TooManyOutputs", "labkit_launcher returns at most one output.");
    end
    root = fileparts(mfilename("fullpath"));
    if isRepairRequest(varargin)
        if nargout > 0
            error("labkit_launcher:RepairHasNoOutput", "Repair mode returns no output.");
        end
        openRepairWindow(root, "");
        return;
    end
    entry = installedDispatchFile(root);
    if strlength(entry) == 0
        varargout = handleMissingInstalledEntry(root, varargin, nargout);
        return;
    end
    try
        dispatcher = str2func("labkit.app.internal.launcher.dispatch");
        if ~resolvesInstalledDispatch(dispatcher, entry)
            addpath(root, "-begin");
            rehash;
            clear('labkit.app.internal.launcher.dispatch');
            dispatcher = str2func("labkit.app.internal.launcher.dispatch");
            if ~resolvesInstalledDispatch(dispatcher, entry)
                error("labkit_launcher:InstalledEntryMismatch", ...
                    "The installed launcher entry does not resolve from this LabKit installation.");
            end
        end
        if nargout == 0
            dispatcher(root, varargin{:});
        else
            [varargout{1:nargout}] = dispatcher(root, varargin{:});
        end
    catch cause
        if isempty(varargin) && isStructuralDelegateFailure(cause)
            fig = openRepairWindow(root, repairMessage(cause));
            if nargout == 1, varargout = {fig}; end
            return;
        end
        rethrow(cause);
    end
end

function tf = isRepairRequest(args)
tf = isscalar(args) && isTextScalar(args{1}) && strcmpi(string(args{1}), "repair");
end

function outputs = handleMissingInstalledEntry(root, args, outputCount)
outputs = cell(1, 0);
message = "The installed launcher entry is unavailable. This installation may be incomplete. " + ...
    "Use the install and repair window to choose a target folder and LabKit version.";
if ~isempty(args)
    error("labkit_launcher:InstalledEntryUnavailable", "%s", message);
end
fig = openRepairWindow(root, message);
if outputCount == 1, outputs = {fig}; end
end

function entry = installedDispatchFile(root)
base = fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch");
entry = "";
for extension = [".m", ".p"]
    candidate = base + extension;
    if exist(candidate, "file") == 2
        entry = candidate;
        return;
    end
end
end

function tf = isStructuralDelegateFailure(cause)
identifier = string(cause.identifier);
tf = startsWith(identifier, "MATLAB:UndefinedFunction") || ...
    startsWith(identifier, "MATLAB:undefinedVarOrClass") || ...
    startsWith(identifier, "MATLAB:parse") || startsWith(identifier, "MATLAB:dispatcher");
end

function tf = resolvesInstalledDispatch(dispatcher, entry)
tf = false;
try
    details = functions(dispatcher);
    resolvedFile = "";
    if isfield(details, "file")
        resolvedFile = string(details.file);
    end
    if strlength(resolvedFile) == 0 && isfield(details, "function")
        resolvedFile = string(which(char(details.function)));
    end
    tf = strlength(resolvedFile) > 0 && sameNormalizedPath(resolvedFile, entry);
catch
end
end

function tf = sameNormalizedPath(leftPath, rightPath)
leftPath = normalizedPath(leftPath);
rightPath = normalizedPath(rightPath);
tf = strcmp(leftPath, rightPath);
end

function value = normalizedPath(filepath)
pathValue = java.nio.file.Paths.get(char(filepath), javaArray("java.lang.String", 0));
value = string(pathValue.toAbsolutePath().normalize().toString());
if ispc
    value = lower(value);
end
end

function message = repairMessage(cause)
detail = string(cause.message);
if strlength(string(cause.identifier)) > 0
    detail = string(cause.identifier) + ": " + detail;
end
message = "Installed launcher failed to load: " + detail + newline + ...
    "The installation may be incomplete. The repair window can reinstall a selected LabKit version.";
end

function fig = openRepairWindow(root, initialMessage)
figArgs = {"Name", "LabKit Repair", "Tag", "labkitRepair", ...
    "Position", [280 180 720 500], "Color", [0.97 0.98 0.99]};
if repairGuiTestMode() == "hidden"
    figArgs = [figArgs, {"Visible", "off"}];
end
close(findall(groot, "Type", "figure", "Tag", "labkitRepair"));
fig = uifigure(figArgs{:});
grid = uigridlayout(fig, [5 1]);
grid.RowHeight = {92, 104, 112, 42, "1x"};
grid.Padding = [10 10 10 10];
grid.RowSpacing = 8;

intro = uipanel(grid, "Title", "Install or Repair LabKit", "FontSize", 15);
introGrid = uigridlayout(intro, [1 1]);
introGrid.Padding = [8 6 8 6];
uitextarea(introGrid, "Editable", "off", ...
    "Value", cellstr(defaultRepairMessage(initialMessage)));

targetPanel = uipanel(grid, "Title", "Installation Folder");
targetGrid = uigridlayout(targetPanel, [2 3]);
targetGrid.RowHeight = {30, "1x"};
targetGrid.ColumnWidth = {96, "1x", 92};
targetGrid.Padding = [8 6 8 6];
uilabel(targetGrid, "Text", "Target folder");
targetField = uieditfield(targetGrid, "text", ...
    "Value", char(root), "Tag", "labkitRepairTarget");
targetField.Layout.Column = 2;
browse = uibutton(targetGrid, "Text", "Browse...", ...
    "Tag", "labkitRepairBrowse");
browse.Layout.Column = 3;
targetHint = uilabel(targetGrid, "Text", "", "WordWrap", "on");
targetHint.Layout.Row = 2;
targetHint.Layout.Column = [1 3];

sourcePanel = uipanel(grid, "Title", "Download Source");
sourceGrid = uigridlayout(sourcePanel, [2 4]);
sourceGrid.RowHeight = {30, "1x"};
sourceGrid.ColumnWidth = {96, 235, "1x", 104};
sourceGrid.Padding = [8 6 8 6];
uilabel(sourceGrid, "Text", "Version");
sourceChoice = uidropdown(sourceGrid, ...
    "Items", [ ...
        "Latest stable release (recommended)", ...
        "Choose a released version", ...
        "Current main branch (development)"], ...
    "ItemsData", ["stable", "tag", "main"], ...
    "Value", "stable", "Tag", "labkitRepairSource");
sourceChoice.Layout.Column = 2;
releaseChoice = uidropdown(sourceGrid, ...
    "Items", "Load versions first", "ItemsData", "", ...
    "Enable", "off", "Tag", "labkitRepairRelease");
releaseChoice.Layout.Column = 3;
loadReleases = uibutton(sourceGrid, "Text", "Load versions", ...
    "Enable", "off", "Tag", "labkitRepairLoadReleases");
loadReleases.Layout.Column = 4;
sourceHint = uilabel(sourceGrid, "Text", ...
    "Stable is recommended. Main is for deliberate development installs.", ...
    "WordWrap", "on");
sourceHint.Layout.Row = 2;
sourceHint.Layout.Column = [1 4];

repair = uibutton(grid, "Text", "Install LabKit", ...
    "Tag", "labkitRepairAction", "FontWeight", "bold");

statusPanel = uipanel(grid, "Title", "Installation Status");
statusGrid = uigridlayout(statusPanel, [2 1]);
statusGrid.RowHeight = {28, "1x"};
statusGrid.Padding = [8 6 8 6];
stage = uilabel(statusGrid, "Text", "Ready", "FontWeight", "bold", ...
    "Tag", "labkitRepairStage");
status = uitextarea(statusGrid, "Editable", "off", ...
    "Value", "No files have been changed.", "Tag", "labkitRepairStatus");

view = struct( ...
    "targetField", targetField, "targetHint", targetHint, ...
    "sourceChoice", sourceChoice, "releaseChoice", releaseChoice, ...
    "loadReleases", loadReleases, ...
    "sourceHint", sourceHint, "actionButton", repair, ...
    "stage", stage, "status", status);
setappdata(fig, "labkitRepairView", view);
targetField.ValueChangedFcn = @targetChanged;
browse.ButtonPushedFcn = @browseTarget;
sourceChoice.ValueChangedFcn = @sourceChanged;
loadReleases.ButtonPushedFcn = @refreshReleases;
repair.ButtonPushedFcn = @runRepair;
updateTargetSummary();

    function runRepair(~, ~)
        if string(sourceChoice.Value) == "tag" && ...
                strlength(string(releaseChoice.Value)) == 0
            setRepairStatus("Needs attention", ...
                "Load the published versions and choose one before continuing.");
            return;
        end
        target = absolutePath(targetField.Value);
        try
            plan = inspectRepairTarget(target);
        catch cause
            setRepairStatus("Needs attention", ...
                "Target rejected: " + repairFailureMessage(cause));
            return;
        end
        if plan.kind == "repair" && repairGuiTestMode() ~= "hidden"
            choice = uiconfirm(fig, ...
                "Replace the installed LabKit code in " + target + ...
                "? Known local workspace folders are preserved.", ...
                "Confirm LabKit Repair", ...
                "Options", {"Repair", "Cancel"}, ...
                "DefaultOption", 2, "CancelOption", 2);
            if choice ~= "Repair"
                setRepairStatus("Cancelled", ...
                    "Repair cancelled. No files were changed.");
                return;
            end
        end
        repair.Enable = "off";
        targetField.Enable = "off";
        browse.Enable = "off";
        sourceChoice.Enable = "off";
        releaseChoice.Enable = "off";
        loadReleases.Enable = "off";
        setRepairStatus("Step 1 of 4 — Preparing target", ...
            "Preparing " + plan.action + " target...");
        try
            prepareBootstrapTarget(target, root);
            result = repairFromZip(target, string(sourceChoice.Value), ...
                string(releaseChoice.Value), @setRepairStatus);
            setRepairStatus("Complete", result.message);
        catch cause
            setRepairStatus("Failed", "Install / repair failed: " + ...
                repairFailureMessage(cause));
        end
        repair.Enable = "on";
        targetField.Enable = "on";
        browse.Enable = "on";
        sourceChoice.Enable = "on";
        sourceChanged([], []);
        updateTargetSummary();
    end

    function setRepairStatus(stageText, detailText)
        stage.Text = char(stageText);
        status.Value = cellstr(string(detailText));
        drawnow limitrate;
    end

    function targetChanged(~, ~)
        updateTargetSummary();
    end

    function browseTarget(~, ~)
        selected = uigetdir(char(fileparts(absolutePath(targetField.Value))), ...
            "Choose the LabKit installation folder");
        if isequal(selected, 0)
            return;
        end
        targetField.Value = char(selected);
        updateTargetSummary();
    end

    function sourceChanged(~, ~)
        chooseRelease = string(sourceChoice.Value) == "tag";
        controlsEnabled = string(repair.Enable) == "on";
        hasReleases = any(strlength(string(releaseChoice.ItemsData)) > 0);
        releaseChoice.Enable = char(matlab.lang.OnOffSwitchState( ...
            chooseRelease && controlsEnabled && hasReleases));
        loadReleases.Enable = char(matlab.lang.OnOffSwitchState( ...
            chooseRelease && controlsEnabled));
        if chooseRelease
            sourceHint.Text = ...
                "Load the published versions, then choose one from the list.";
        elseif string(sourceChoice.Value) == "main"
            sourceHint.Text = ...
                "Main may contain unreleased changes; use it deliberately.";
        else
            sourceHint.Text = ...
                "Downloads the latest published stable release.";
        end
    end

    function refreshReleases(~, ~)
        loadReleases.Enable = "off";
        releaseChoice.Enable = "off";
        setRepairStatus("Checking GitHub", ...
            "Loading the published stable LabKit versions...");
        try
            tags = publishedStableVersions();
            releaseChoice.Items = cellstr("LabKit " + tags);
            releaseChoice.ItemsData = cellstr(tags);
            releaseChoice.Value = char(tags(1));
            setRepairStatus("Ready", ...
                "Choose a released version, then install or repair LabKit.");
        catch cause
            setRepairStatus("Failed", ...
                "Could not load released versions: " + repairFailureMessage(cause));
        end
        sourceChanged([], []);
    end

    function updateTargetSummary()
        try
            target = absolutePath(targetField.Value);
            targetField.Value = char(target);
            plan = inspectRepairTarget(target);
            targetHint.Text = char(plan.message);
            repair.Text = char(plan.button);
            repair.Enable = "on";
            sourceChanged([], []);
        catch cause
            targetHint.Text = char(repairFailureMessage(cause));
            repair.Text = "Target Folder Is Not Safe";
            repair.Enable = "off";
            releaseChoice.Enable = "off";
            loadReleases.Enable = "off";
        end
    end
end

function message = defaultRepairMessage(initialMessage)
if strlength(initialMessage) == 0
    message = [
        "This standalone file can create a new LabKit installation or repair an existing one."
        "Nothing is downloaded or replaced until you press the action button."
        ];
else
    message = [
        string(initialMessage)
        "Choose the target folder and download source below. No files change until confirmation."
        ];
end
end

function message = repairFailureMessage(cause)
message = string(cause.message);
if strlength(string(cause.identifier)) > 0
    message = string(cause.identifier) + ": " + message;
end
end

function target = absolutePath(value)
if ~isTextScalar(value) || strlength(strtrim(string(value))) == 0
    error("labkit_launcher:InvalidInstallTarget", ...
        "Choose a nonempty installation folder.");
end
pathValue = java.nio.file.Paths.get( ...
    char(strtrim(string(value))), javaArray("java.lang.String", 0));
target = string(pathValue.toAbsolutePath().normalize().toString());
end

function plan = inspectRepairTarget(target)
target = absolutePath(target);
if isFilesystemRoot(target)
    error("labkit_launcher:UnsafeRoot", ...
        "Installation into a filesystem root is not allowed.");
end
if exist(fullfile(target, ".git"), "file") == 2 || ...
        exist(fullfile(target, ".git"), "dir") == 7
    error("labkit_launcher:GitCheckout", ...
        "This folder is a Git checkout; update it with Git instead.");
end
if exist(target, "file") == 2
    error("labkit_launcher:InvalidInstallTarget", ...
        "The selected installation target is a file, not a folder.");
end
if exist(target, "dir") ~= 7
    parent = fileparts(target);
    if exist(parent, "dir") ~= 7
        error("labkit_launcher:InvalidInstallTarget", ...
            "The parent folder must exist before installing LabKit.");
    end
    plan = struct( ...
        "kind", "new", "action", "new installation", ...
        "button", "Install LabKit", ...
        "message", "New installation. LabKit will create this folder.");
    return;
end
hasLauncher = exist(fullfile(target, "labkit_launcher.m"), "file") == 2;
hasFramework = exist(fullfile(target, "+labkit"), "dir") == 7;
hasApps = exist(fullfile(target, "apps"), "dir") == 7;
hasSupportingContent = exist(fullfile(target, "tools"), "dir") == 7 || ...
    exist(fullfile(target, "docs"), "dir") == 7;
if hasLauncher && (hasFramework || (hasApps && hasSupportingContent))
    plan = struct( ...
        "kind", "repair", "action", "existing installation repair", ...
        "button", "Repair / Reinstall LabKit", ...
        "message", "Existing LabKit installation. Repair replaces code " + ...
            "after confirmation and preserves known local workspace folders.");
elseif hasOnlyBootstrapContent(target)
    plan = struct( ...
        "kind", "new", "action", "new installation", ...
        "button", "Install LabKit", ...
        "message", "New installation. The folder contains no unrelated files.");
else
    error("labkit_launcher:InvalidInstallTarget", ...
        "Choose an empty folder, a folder containing only labkit_launcher.m, " + ...
        "or an existing LabKit installation.");
end
end

function prepareBootstrapTarget(target, sourceRoot)
target = absolutePath(target);
plan = inspectRepairTarget(target);
if plan.kind ~= "new"
    return;
end
if exist(target, "dir") ~= 7
    [created, message] = mkdir(target);
    if ~created
        error("labkit_launcher:InstallTargetCreateFailed", ...
            "Could not create the installation folder: %s", message);
    end
end
targetLauncher = fullfile(target, "labkit_launcher.m");
if exist(targetLauncher, "file") ~= 2
    sourceLauncher = fullfile(sourceRoot, "labkit_launcher.m");
    [copied, message] = copyfile(sourceLauncher, targetLauncher);
    if ~copied
        error("labkit_launcher:BootstrapCopyFailed", ...
            "Could not place labkit_launcher.m in the installation folder: %s", ...
            message);
    end
end
end

function tf = hasOnlyBootstrapContent(folder)
entries = dir(folder);
names = string({entries(~ismember(string({entries.name}), [".", ".."])).name});
allowed = ["labkit_launcher.m", ".DS_Store", "Thumbs.db", "desktop.ini"];
tf = all(ismember(names, allowed));
end

function result = repairFromZip(root, sourceMode, requestedTag, progressFcn)
hook = repairTestHook();
assertRepairRoot(root);
source = struct("label", "the supplied repair candidate");
workspace = "";
cleanup = onCleanup(@() removeFolderIfPresent(workspace));
if strlength(hook.CandidateRoot) > 0
    candidate = hook.CandidateRoot;
else
    source = resolveZipSource(sourceMode, requestedTag);
    notifyProgress(progressFcn, "Step 2 of 4 — Downloading source", ...
        "Downloading " + source.label + "...");
    workspace = tempname;
    mkdir(workspace);
    zipPath = fullfile(workspace, "labkit.zip");
    websave(zipPath, source.url);
    notifyProgress(progressFcn, "Step 3 of 4 — Validating package", ...
        "Extracting and validating the downloaded LabKit package...");
    extractRoot = fullfile(workspace, "candidate");
    unzip(zipPath, extractRoot);
    candidate = findCandidateRoot(extractRoot);
end
assertCandidateRoot(candidate);
assertCandidateOutsideRepairRoot(candidate, root);
notifyProgress(progressFcn, "Step 4 of 4 — Installing files", ...
    "Replacing the incomplete installation...");
replacement = replaceInstall(root, candidate, hook.FailAfterBackup);
notifyProgress(progressFcn, "Complete", "Installation completed.");
message = "Installed " + source.label + " into " + string(root) + ...
    ". Restart LabKit from that folder.";
if replacement.backupRetained
    if replacement.preservedItemCount > 0
        message = message + " Migrated " + replacement.preservedItemCount + ...
            " local data item(s). Recovery backup retained at " + ...
            replacement.backupFolder + ".";
    else
        message = message + " Backup cleanup was incomplete; recovery files remain at " + ...
            replacement.backupFolder + ".";
    end
end

function source = resolveZipSource(mode, requestedTag)
switch string(mode)
    case "stable"
        source = resolveStableZipSource();
    case "main"
        source = struct( ...
            "label", "the current GitHub main branch", ...
            "url", "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/heads/main.zip");
    case "tag"
        tag = string(strtrim(requestedTag));
        if ~isStableReleaseTag(tag)
            error("labkit_launcher:InvalidReleaseSelection", ...
                "Load the published stable versions and choose one from the list.");
        end
        source = struct( ...
            "label", "GitHub release tag " + tag, ...
            "url", "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/tags/" + tag + ".zip");
    otherwise
        error("labkit_launcher:InvalidDownloadSource", ...
            "Choose latest stable, current main, or a specific stable release tag.");
end
end
result = summaryStruct(root, message);
delete(cleanup)
end

function hook = repairTestHook()
hook = struct("CandidateRoot", "", "FailAfterBackup", false);
key = "labkitLauncherRepairTestHook";
if isappdata(groot, key)
    value = getappdata(groot, key);
    if isstruct(value)
        if isfield(value, "CandidateRoot") && isTextScalar(value.CandidateRoot)
            hook.CandidateRoot = string(value.CandidateRoot);
        end
        if isfield(value, "FailAfterBackup") && islogical(value.FailAfterBackup) && ...
                isscalar(value.FailAfterBackup)
            hook.FailAfterBackup = value.FailAfterBackup;
        end
    end
end
end

function source = resolveStableZipSource()
release = latestStableRelease();
if strlength(release.tag) > 0
    source = struct("label", "GitHub release " + release.tag, "url", release.zipUrl);
    return;
end
tag = latestGitHubTag();
if strlength(tag) == 0
    error("labkit_launcher:StableSourceUnavailable", ...
        "Could not find a stable GitHub release or tag to repair LabKit.");
end
source = struct("label", "GitHub tag " + tag, ...
    "url", "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/refs/tags/" + tag + ".zip");
end

function release = latestStableRelease()
release = struct("tag", "", "zipUrl", "");
try
    raw = webread("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/releases/latest");
    if isfield(raw, "tag_name") && isfield(raw, "zipball_url")
        release.tag = string(raw.tag_name);
        release.zipUrl = string(raw.zipball_url);
    end
catch
end
end

function versions = publishedStableVersions()
try
    raw = webread("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/releases?per_page=50");
catch cause
    error("labkit_launcher:ReleaseListUnavailable", ...
        "GitHub did not return the published LabKit versions: %s", cause.message);
end
if ~isstruct(raw) || isempty(raw) || ~isfield(raw, "tag_name")
    error("labkit_launcher:ReleaseListUnavailable", ...
        "GitHub did not return any published LabKit versions.");
end
versions = strings(numel(raw), 1);
versionCount = 0;
for index = 1:numel(raw)
    if isfield(raw, "draft") && logical(raw(index).draft)
        continue;
    end
    if isfield(raw, "prerelease") && logical(raw(index).prerelease)
        continue;
    end
    tag = string(raw(index).tag_name);
    if isStableReleaseTag(tag)
        versionCount = versionCount + 1;
        versions(versionCount) = tag;
    end
end
versions = versions(1:versionCount);
versions = unique(versions, "stable");
if isempty(versions)
    error("labkit_launcher:ReleaseListUnavailable", ...
        "GitHub did not return any published stable LabKit versions.");
end
end

function tag = latestGitHubTag()
tag = "";
try
    stableTagPageSize = 20;
    raw = webread("https://api.github.com/repos/Pluze/LabKit-MATLAB-Workbench/tags?per_page=" + stableTagPageSize);
    if ~isempty(raw) && isfield(raw, "name")
        for index = 1:numel(raw)
            candidate = string(raw(index).name);
            if isStableReleaseTag(candidate)
                tag = candidate;
                return;
            end
        end
    end
catch
end
end

function tf = isStableReleaseTag(tag)
tf = isTextScalar(tag) && ~ismissing(string(tag)) && ...
    ~isempty(regexp(char(string(tag)), '^v[0-9]+\.[0-9]+\.[0-9]+$', 'once'));
end

function candidate = findCandidateRoot(extractRoot)
entries = dir(extractRoot);
for index = 1:numel(entries)
    if ~entries(index).isdir || startsWith(entries(index).name, ".")
        continue;
    end
    folder = fullfile(entries(index).folder, entries(index).name);
    if hasCandidateShape(folder)
        candidate = folder;
        return;
    end
end
error("labkit_launcher:InvalidCandidate", "Downloaded zip does not contain a LabKit root.");
end

function assertCandidateRoot(candidate)
if ~hasCandidateShape(candidate)
    error("labkit_launcher:InvalidCandidate", ...
        "Repair candidate must contain labkit_launcher.m, +labkit, apps, and the installed launcher entry.");
end
end

function assertCandidateOutsideRepairRoot(candidate, root)
if sameNormalizedPath(candidate, root) || isDescendantPath(candidate, root) || ...
        isDescendantPath(root, candidate)
    error("labkit_launcher:InvalidCandidate", ...
        "Repair candidate and installation root must be separate, non-nested directories.");
end
end

function tf = hasCandidateShape(candidate)
tf = exist(candidate, "dir") == 7 && ...
    exist(fullfile(candidate, "labkit_launcher.m"), "file") == 2 && ...
    exist(fullfile(candidate, "+labkit"), "dir") == 7 && ...
    exist(fullfile(candidate, "apps"), "dir") == 7 && ...
    strlength(installedDispatchFile(candidate)) > 0;
end

function assertRepairRoot(root)
if isFilesystemRoot(root)
    error("labkit_launcher:UnsafeRoot", ...
        "Repair refuses filesystem roots to avoid overwriting a non-LabKit directory.");
end
if exist(fullfile(root, ".git"), "file") == 2 || exist(fullfile(root, ".git"), "dir") == 7
    error("labkit_launcher:GitCheckout", "Repair from a Git checkout is disabled; use git to update it.");
end
hasLauncher = exist(fullfile(root, "labkit_launcher.m"), "file") == 2;
hasFramework = exist(fullfile(root, "+labkit"), "dir") == 7;
hasApps = exist(fullfile(root, "apps"), "dir") == 7;
hasSupportingContent = exist(fullfile(root, "tools"), "dir") == 7 || ...
    exist(fullfile(root, "docs"), "dir") == 7;
hasBootstrapOnly = hasLauncher && hasOnlyBootstrapContent(root);
if ~hasLauncher || ...
        ~(hasBootstrapOnly || hasFramework || (hasApps && hasSupportingContent))
    error("labkit_launcher:InvalidRepairRoot", ...
        "Install / repair refuses this directory to avoid overwriting unrelated files.");
end
end

function replacement = replaceInstall(root, candidate, failAfterBackup)
parent = fileparts(root);
[~, name] = fileparts(root);
backup = fullfile(parent, name + ".repair-backup-" + string(java.util.UUID.randomUUID()));
workingDirectory = pwd;
workingRelativePath = relativePathWithin(root, workingDirectory);
wasInsideRepairRoot = sameNormalizedPath(root, workingDirectory) || ...
    isDescendantPath(workingDirectory, root);
pathState = captureRepairPathState(root);
if wasInsideRepairRoot
    cd(parent);
end
removeRepairPathEntries(pathState);
cleanup = onCleanup(@() restoreWorkingDirectory( ...
    workingDirectory, root, parent, workingRelativePath, wasInsideRepairRoot, pathState));
[moved, moveMessage] = movefile(root, backup, "f");
if ~moved
    error("labkit_launcher:ReplaceFailed", "Could not preserve the current installation: %s", moveMessage);
end
try
    if failAfterBackup
        error("labkit_launcher:InjectedFailure", "Injected failure after preserving the current installation.");
    end
    [copied, copyMessage] = copyfile(candidate, root);
    if ~copied
        error("labkit_launcher:ReplaceFailed", "Could not install the repair candidate: %s", copyMessage);
    end
    assertCandidateRoot(root);
    preservation = copyPreservedLocalContent(backup, root);
catch cause
    rollbackInstall(root, backup, cause);
end
replacement = struct("backupFolder", "", "backupRetained", false, ...
    "preservedItemCount", preservation.itemCount, "backupFailureReason", "");
if preservation.itemCount > 0
    replacement.backupFolder = string(backup);
    replacement.backupRetained = true;
else
    [removed, removeMessage] = rmdir(backup, "s");
    if ~removed
        replacement.backupFolder = string(backup);
        replacement.backupRetained = true;
        replacement.backupFailureReason = string(removeMessage);
    end
end
delete(cleanup)
end

function preservation = copyPreservedLocalContent(backup, root)
relativePaths = preservedLocalPaths();
present = false(size(relativePaths));
for index = 1:numel(relativePaths)
    source = fullfile(backup, relativePaths(index));
    if ~filesystemEntryExists(source)
        continue;
    end
    present(index) = true;
    target = fullfile(root, relativePaths(index));
    if filesystemEntryExists(target)
        error("labkit_launcher:LocalDataConflict", ...
            "Repair candidate conflicts with preserved local data: %s.", relativePaths(index));
    end
end
for index = find(present)'
    source = fullfile(backup, relativePaths(index));
    target = fullfile(root, relativePaths(index));
    targetParent = fileparts(target);
    if exist(targetParent, "dir") ~= 7
        [created, createMessage] = mkdir(targetParent);
        if ~created
            error("labkit_launcher:LocalDataCopyFailed", ...
                "Could not prepare preserved local data target %s: %s", ...
                relativePaths(index), createMessage);
        end
    end
    [copied, copyMessage] = copyfile(source, target);
    if ~copied
        error("labkit_launcher:LocalDataCopyFailed", ...
            "Could not preserve local data %s: %s", relativePaths(index), copyMessage);
    end
end
preservation = struct("itemCount", sum(present));
end

function paths = preservedLocalPaths()
paths = [
    "private_apps"
    "artifacts"
    string(fullfile("resources", "project"))
    "photos"
    "derived"
    "profile_results"
    "LabKit.prj"
    ];
end

function tf = filesystemEntryExists(filepath)
tf = exist(filepath, "file") == 2 || exist(filepath, "dir") == 7;
end

function rollbackInstall(root, backup, cause)
[partialRemoved, removeMessage] = removePartialInstallRoot(root);
if ~partialRemoved
    throwRollbackFailed(cause, backup, ...
        "Partial replacement could not be removed: " + string(removeMessage));
end
[restored, restoreMessage] = copyfile(backup, root);
if ~restored
    throwRollbackFailed(cause, backup, ...
        "Backup could not be restored: " + string(restoreMessage));
end
try
    assertRepairRoot(root);
catch validationCause
    throwRollbackFailed(cause, backup, ...
        "Restored installation failed validation: " + string(validationCause.message));
end
[removed, removeMessage] = rmdir(backup, "s");
if ~removed
    throwRollbackFailed(cause, backup, ...
        "Restored installation is valid but backup cleanup failed: " + string(removeMessage));
end
rethrow(cause);
end

function [removed, message] = removePartialInstallRoot(root)
removed = true;
message = "";
if exist(root, "dir") == 7
    [removed, message] = rmdir(root, "s");
elseif exist(root, "file") == 2
    try
        delete(root);
    catch cause
        removed = false;
        message = string(cause.message);
    end
end
end

function throwRollbackFailed(cause, backup, detail)
error("labkit_launcher:RollbackFailed", ...
    "Repair failed (%s). %s Recovery backup remains at %s.", ...
    repairFailureMessage(cause), detail, backup);
end

function tf = isFilesystemRoot(folder)
folder = normalizedPath(folder);
tf = sameNormalizedPath(folder, fileparts(folder));
end

function tf = isDescendantPath(candidate, root)
candidate = normalizedPath(candidate);
root = normalizedPath(root);
separator = string(filesep);
tf = startsWith(candidate, root + separator);
end

function relative = relativePathWithin(root, folder)
relative = "";
if sameNormalizedPath(root, folder)
    return;
end
if isDescendantPath(folder, root)
    root = normalizedPath(root);
    folder = normalizedPath(folder);
    relative = extractAfter(folder, strlength(root) + 1);
end
end

function state = captureRepairPathState(root)
entries = string(strsplit(path, pathsep));
isRepairEntry = false(size(entries));
relativePaths = strings(size(entries));
for index = 1:numel(entries)
    if strlength(entries(index)) == 0
        continue;
    end
    if sameNormalizedPath(entries(index), root)
        isRepairEntry(index) = true;
    elseif isDescendantPath(entries(index), root)
        isRepairEntry(index) = true;
        relativePaths(index) = relativePathWithin(root, entries(index));
    end
end
state = struct("entries", entries, "isRepairEntry", isRepairEntry, ...
    "relativePaths", relativePaths);
end

function removeRepairPathEntries(state)
entries = state.entries(~state.isRepairEntry);
entries = entries(strlength(entries) > 0);
path(char(strjoin(entries, pathsep)));
rehash;
end

function restoreRepairPathEntries(root, state)
entries = state.entries;
rootAvailable = false;
try
    assertRepairRoot(root);
    rootAvailable = true;
catch
end
for index = find(state.isRepairEntry)
    if ~rootAvailable
        candidate = "";
    elseif strlength(state.relativePaths(index)) == 0
        candidate = string(root);
    else
        candidate = string(fullfile(root, state.relativePaths(index)));
    end
    if strlength(candidate) > 0 && exist(candidate, "dir") == 7
        entries(index) = candidate;
    else
        entries(index) = "";
    end
end
entries = entries(strlength(entries) > 0);
path(char(strjoin(entries, pathsep)));
rehash;
end

function restoreWorkingDirectory(originalFolder, root, parent, relative, wasInsideRepairRoot, pathState)
restoreRepairPathEntries(root, pathState);
if ~wasInsideRepairRoot && exist(originalFolder, "dir") == 7
    cd(originalFolder);
elseif strlength(relative) > 0 && exist(fullfile(root, relative), "dir") == 7
    cd(fullfile(root, relative));
elseif exist(root, "dir") == 7
    cd(root);
elseif exist(parent, "dir") == 7
    cd(parent);
elseif exist(originalFolder, "dir") == 7
    cd(originalFolder);
end
end

function result = summaryStruct(root, message)
result = struct("root", string(root), "message", string(message));
end

function notifyProgress(progressFcn, stage, message)
if ~isempty(progressFcn)
    progressFcn(char(stage), char(message));
end
end

function removeFolderIfPresent(folder)
if strlength(string(folder)) > 0 && exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end

function mode = repairGuiTestMode()
mode = "visible";
if isappdata(groot, "labkitLauncherGuiTestMode")
    mode = string(getappdata(groot, "labkitLauncherGuiTestMode"));
end
end

function tf = isTextScalar(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end
