function varargout = labkit_launcher(varargin)
%LABKIT_LAUNCHER Repair a LabKit installation or delegate to its installed launcher.
%
%   labkit_launcher opens the installed launcher when its private entry is
%   available. If that entry is missing or cannot load, it opens a minimal
%   repair window instead. labkit_launcher("repair") always opens that repair
%   window. Repair is explicit; startup never downloads or replaces files.

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
        addpath(root, "-begin");
        rehash;
        dispatcher = str2func("labkit.app.internal.launcher.dispatch");
        if ~resolvesInstalledDispatch(dispatcher, entry)
            error("labkit_launcher:InstalledEntryMismatch", ...
                "The installed launcher entry does not resolve from this LabKit installation.");
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
    "Use Repair / Reinstall to download the latest stable LabKit release.";
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
    "The installation may be incomplete. Repair / Reinstall can restore the latest stable release.";
end

function fig = openRepairWindow(root, initialMessage)
figArgs = {"Name", "LabKit Repair", "Tag", "labkitRepair", ...
    "Position", [300 250 560 250], "Color", [0.97 0.98 0.99]};
if repairGuiTestMode() == "hidden"
    figArgs = [figArgs, {"Visible", "off"}];
end
close(findall(groot, "Type", "figure", "Tag", "labkitRepair"));
fig = uifigure(figArgs{:});
grid = uigridlayout(fig, [3 1]);
grid.RowHeight = {"1x", 34, 28};
uitextarea(grid, "Editable", "off", "Value", cellstr(defaultRepairMessage(initialMessage)));
repair = uibutton(grid, "Text", "Repair / Reinstall Latest Stable Release");
status = uilabel(grid, "Text", "Repair does not start until this button is pressed.");
repair.ButtonPushedFcn = @runRepair;

    function runRepair(~, ~)
        repair.Enable = "off";
        status.Text = "Downloading the latest stable LabKit release...";
        drawnow;
        try
            result = repairFromStableZip(root, @setRepairProgress);
            status.Text = char(result.message);
        catch cause
            status.Text = char("Repair failed: " + repairFailureMessage(cause));
        end
        repair.Enable = "on";
    end

    function setRepairProgress(text, ~)
        status.Text = char(text);
        drawnow limitrate;
    end
end

function message = defaultRepairMessage(initialMessage)
if strlength(initialMessage) == 0
    message = "LabKit repair is available if the installed launcher or its dependencies are missing.";
else
    message = initialMessage;
end
end

function message = repairFailureMessage(cause)
message = string(cause.message);
if strlength(string(cause.identifier)) > 0
    message = string(cause.identifier) + ": " + message;
end
end

function result = repairFromStableZip(root, progressFcn)
hook = repairTestHook();
assertRepairRoot(root);
source = struct("label", "the supplied repair candidate");
workspace = "";
cleanup = onCleanup(@() removeFolderIfPresent(workspace));
if strlength(hook.CandidateRoot) > 0
    candidate = hook.CandidateRoot;
else
    source = resolveStableZipSource();
    notifyProgress(progressFcn, "Downloading " + source.label + "...", 0.15);
    workspace = tempname;
    mkdir(workspace);
    zipPath = fullfile(workspace, "labkit.zip");
    websave(zipPath, source.url);
    notifyProgress(progressFcn, "Extracting repair candidate...", 0.40);
    extractRoot = fullfile(workspace, "candidate");
    unzip(zipPath, extractRoot);
    candidate = findCandidateRoot(extractRoot);
end
assertCandidateRoot(candidate);
assertCandidateOutsideRepairRoot(candidate, root);
notifyProgress(progressFcn, "Replacing the incomplete installation...", 0.65);
replacement = replaceInstall(root, candidate, hook.FailAfterBackup);
notifyProgress(progressFcn, "Repair completed.", 1.00);
message = "Reinstalled " + source.label + ". Restart LabKit if it was open.";
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
if ~hasLauncher || ~(hasFramework || (hasApps && hasSupportingContent))
    error("labkit_launcher:InvalidRepairRoot", ...
        "Repair refuses this directory to avoid overwriting a non-LabKit installation.");
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

function notifyProgress(progressFcn, message, value)
if ~isempty(progressFcn)
    progressFcn(char(message), value);
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
