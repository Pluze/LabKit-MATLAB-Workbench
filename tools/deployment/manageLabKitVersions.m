function varargout = manageLabKitVersions(root, mode, varargin)
%MANAGELABKITVERSIONS Browse and install selected LabKit GitHub versions.
%
%   MANAGELABKITVERSIONS opens the Version Manager for the LabKit installation
%   that contains this tool.
%
%   MANAGELABKITVERSIONS(ROOT) opens the Version Manager for ROOT. The window
%   lists recent non-draft releases, tags, and main-branch commits. Refresh
%   obtains current candidates. Double-click or Install Selected asks for
%   confirmation before downloading and replacing the installation.
%
%   RESULT = MANAGELABKITVERSIONS(ROOT, "main") installs the GitHub main ZIP.
%   RESULT = MANAGELABKITVERSIONS(ROOT, "stable") installs the latest stable
%   release, falling back to the first strict v<major>.<minor>.<patch> tag.
%   RESULT = MANAGELABKITVERSIONS(ROOT, "install", Source=SOURCE) installs a
%   selected source. SOURCE is a scalar struct with nonempty scalar-text Kind,
%   Label, Url, and Name fields. Url must identify a ZIP in this repository's
%   GitHub archive. Optional Date and Summary scalar-text fields are displayed.
%
%   MANAGELABKITVERSIONS(..., ProgressFcn=FCN) reports best-effort progress by
%   calling FCN(message, fraction), where message is a string scalar and
%   fraction is between 0 and 1. The default [] reports no programmatic
%   progress. Progress callback failures never interrupt discovery or install.
%
%   ROOT is a nonempty scalar path. MODE is "browse" (default), "main",
%   "stable", or "install". Browse returns the Version Manager figure when an
%   output is requested. Install modes return a scalar RESULT struct with root,
%   source, updated, message, backupFolder, backupRetained, and
%   preservedItemCount. Canceling confirmation returns updated=false.
%
%   The installation is replaced through a sibling backup and rollback path.
%   Existing private_apps, artifacts, resources/project, photos, derived,
%   profile_results, and LabKit.prj are copied into the replacement only when
%   the candidate does not contain the same local entry. Such a migration keeps
%   the sibling backup as a recovery location. Git checkouts (.git file or
%   directory), filesystem roots, malformed candidates, nested candidates, and
%   local-data conflicts are rejected. Download, extraction, and file errors
%   throw stable errors; a failed confirmation is not an error.
%
%   Errors:
%     LabKit:Deployment:InvalidMode       MODE is unsupported.
%     LabKit:Deployment:InvalidSource     SOURCE is malformed or untrusted.
%     LabKit:Deployment:UnsafeRoot        ROOT is a filesystem root.
%     LabKit:Deployment:GitCheckout       ROOT is a Git checkout.
%     LabKit:Deployment:InvalidRoot       ROOT is not a LabKit installation.
%     LabKit:Deployment:InvalidCandidate  The ZIP/candidate is not safe.
%     LabKit:Deployment:RollbackFailed    Replacement and rollback both failed.
%
%   Typical Call:
%      addpath(fullfile("tools", "deployment"))
%      manager = manageLabKitVersions(pwd)
%      result = manageLabKitVersions(pwd, "stable")
%      progress = @(message, fraction) fprintf("%s %.0f%%\n", ...
%          message, 100*fraction);
%      result = manageLabKitVersions(pwd, "main", ProgressFcn=progress)
%
%   See also WEBREAD, WEBSAVE, UNZIP.

    if nargin < 1 || isempty(root)
        root = repoRoot();
    end
    if nargin < 2 || isempty(mode)
        mode = "browse";
    end
    opts = parseOptions(varargin{:});
    root = string(normalizedPath(root));
    if ~isTextScalar(mode) || ismissing(string(mode))
        error("LabKit:Deployment:InvalidMode", ...
            "Mode must be browse, main, stable, or install.");
    end
    mode = lower(strtrim(string(mode)));
    if ~ismember(mode, ["browse", "main", "stable", "install"])
        error("LabKit:Deployment:InvalidMode", ...
            "Mode must be browse, main, stable, or install.");
    end
    if mode == "browse"
        fig = openManager(root, opts);
        if nargout > 0, varargout = {fig}; end
        return;
    end
    assertUpdateRoot(root);
    switch mode
        case "main"
            source = mainSource();
        case "stable"
            source = stableSource();
        case "install"
            if isempty(opts.Source)
                error("LabKit:Deployment:InvalidSource", ...
                    "Install mode requires a selected source.");
            end
            source = validateSource(opts.Source);
    end
    result = installSource(root, source, opts);
    if nargout > 0
        varargout = {result};
    end
end

function opts = parseOptions(varargin)
    parser = inputParser;
    parser.FunctionName = "manageLabKitVersions";
    parser.addParameter("ProgressFcn", [], @(value) isempty(value) || isa(value, "function_handle"));
    parser.addParameter("Source", [], @(value) isempty(value) || isstruct(value));
    parser.parse(varargin{:});
    opts = parser.Results;
end

function fig = openManager(root, opts)
    figArgs = {"Name", "LabKit Version Manager", "Position", [210 170 900 520], "Color", [0.97 0.98 0.99]};
    if isappdata(groot, "labkitVersionManagerGuiTestMode") && ...
            string(getappdata(groot, "labkitVersionManagerGuiTestMode")) == "hidden"
        figArgs = [figArgs, {"Visible", "off"}];
    end
    fig = uifigure(figArgs{:});
    layout = uigridlayout(fig, [4 1]);
    layout.RowHeight = {86, "1x", 36, 76};
    layout.Padding = [8 8 8 8];
    layout.RowSpacing = 8;
    current = uitextarea(layout, "Editable", "off", ...
        "Value", currentInstallLines(root));
    current.Layout.Row = 1;
    sourceTable = uitable(layout, ...
        "ColumnName", {"Type", "Version or commit", "Date", "Summary"}, ...
        "RowName", {}, "FontSize", 14);
    sourceTable.ColumnWidth = {100, 170, 170, "auto"};
    sourceTable.Layout.Row = 2;
    buttons = uigridlayout(layout, [1 4]);
    buttons.Layout.Row = 3;
    buttons.ColumnWidth = {"1x", "1x", "1x", "1x"};
    buttons.Padding = [0 0 0 0];
    buttons.ColumnSpacing = 8;
    refresh = uibutton(buttons, "Text", "Refresh");
    refresh.Layout.Column = 1;
    install = uibutton(buttons, "Text", "Install Selected", "Enable", "off");
    install.Layout.Column = 2;
    closeButton = uibutton(buttons, "Text", "Close", ...
        "ButtonPushedFcn", @(~, ~) close(fig));
    closeButton.Layout.Column = 4;
    if isprop(refresh, "Tooltip")
        refresh.Tooltip = "Fetch recent GitHub releases, tags, and main commits.";
        install.Tooltip = "Download and apply the selected LabKit version.";
        closeButton.Tooltip = "Close version manager.";
    end
    status = uitextarea(layout, "Editable", "off", ...
        "Value", "Choose a recent release, tag, or main-branch commit.");
    status.Layout.Row = 4;
    state = struct("sources", emptySources(), "selectedRow", 1, "busy", false);
    refresh.ButtonPushedFcn = @onRefresh;
    install.ButtonPushedFcn = @onInstall;
    configureTable(sourceTable, @onSelect, @onInstall);
    onRefresh();
    function onRefresh(~, ~)
        if state.busy
            return;
        end
        setBusy(true, "Fetching recent LabKit versions from GitHub...");
        notify(opts.ProgressFcn, "Fetching recent LabKit versions from GitHub...", 0.05);
        try
            state.sources = discoverSources();
            state.selectedRow = 1;
            sourceTable.Data = sourceRows(state.sources);
            if isempty(state.sources)
                status.Value = ...
                    "No release, tag, or commit options were returned by GitHub.";
            else
                status.Value = "Loaded " + numel(state.sources) + ...
                    " version option(s).";
            end
        catch cause
            state.sources = emptySources();
            sourceTable.Data = cell(0, 4);
            status.Value = "Version lookup failed: " + failureText(cause);
        end
        notify(opts.ProgressFcn, status.Value, 1.00);
        setBusy(false, status.Value);
    end
    function onSelect(~, event)
        row = eventRow(event);
        if ~isnan(row)
            state.selectedRow = row;
        end
    end
    function onInstall(~, ~)
        if state.busy || isempty(state.sources)
            return;
        end
        setBusy(true, "Preparing selected version...");
        selected = state.sources(min(max(state.selectedRow, 1), numel(state.sources)));
        try
            result = installSource(root, selected, opts);
            status.Value = result.message;
            current.Value = currentInstallLines(root);
        catch cause
            status.Value = "Version install failed: " + failureText(cause);
        end
        setBusy(false, status.Value);
    end
    function setBusy(value, message)
        state.busy = value;
        refresh.Enable = matlab.lang.OnOffSwitchState(~value);
        closeButton.Enable = matlab.lang.OnOffSwitchState(~value);
        install.Enable = matlab.lang.OnOffSwitchState( ...
            ~value && ~isempty(state.sources));
        status.Value = string(message);
        drawnow limitrate;
    end
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
    elseif isstruct(event) && isfield(event, "Indices") && ...
            ~isempty(event.Indices)
        row = event.Indices(1, 1);
    elseif isstruct(event) && isfield(event, "Selection") && ...
            ~isempty(event.Selection)
        row = event.Selection(1, 1);
    end
end

function sources = discoverSources()
    sources = [ ...
        safeSources(@() recentReleases(5)), ...
        safeSources(@() recentTags(5)), ...
        safeSources(@() recentCommits(8)) ...
        ];
end

function sources = safeSources(fetch)
    try
        sources = fetch();
    catch
        sources = emptySources();
    end
end

function sources = recentReleases(limit)
    raw = githubRead("releases?per_page=" + limit);
    template = makeSource("", "", "", "", "", "");
    sources = repmat(template, 1, limit);
    count = 0;
    for index = 1:numel(raw)
        if logicalField(raw(index), "draft") || ...
                logicalField(raw(index), "prerelease")
            continue;
        end
        tag = textField(raw(index), "tag_name");
        if strlength(tag) == 0
            continue;
        end
        name = textField(raw(index), "name");
        if strlength(name) == 0
            name = tag;
        end
        count = count + 1;
        sources(count) = tagSource("Release", tag, ...
            name + " (" + tag + ")", textField(raw(index), "published_at"));
        if count == limit
            break;
        end
    end
    sources = sources(1:count);
end

function sources = recentTags(limit)
    raw = githubRead("tags?per_page=" + limit);
    template = makeSource("", "", "", "", "", "");
    sources = repmat(template, 1, limit);
    count = 0;
    for index = 1:min(numel(raw), limit)
        tag = textField(raw(index), "name");
        if strlength(tag) == 0
            continue;
        end
        count = count + 1;
        sources(count) = tagSource("Tag", tag, "Tag " + tag, "");
    end
    sources = sources(1:count);
end

function sources = recentCommits(limit)
    raw = githubRead("commits?sha=main&per_page=" + limit);
    template = makeSource("", "", "", "", "", "");
    sources = repmat(template, 1, limit);
    count = 0;
    for index = 1:min(numel(raw), limit)
        sha = textField(raw(index), "sha");
        if strlength(sha) < 7
            continue;
        end
        short = extractBefore(sha, 8);
        message = nestedText(raw(index), ["commit", "message"]);
        message = extractBefore(message + newline, newline);
        count = count + 1;
        sources(count) = makeSource("Commit", "main commit " + short, ...
            "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/" + ...
            sha + ".zip", short, ...
            nestedText(raw(index), ["commit", "author", "date"]), message);
    end
    sources = sources(1:count);
end

function source = stableSource()
    try
        latest = githubRead("releases/latest");
        if isstruct(latest) && ~logicalField(latest, "draft") && ...
                ~logicalField(latest, "prerelease")
            tag = textField(latest, "tag_name");
            if strlength(tag) > 0
                name = textField(latest, "name");
                if strlength(name) == 0
                    name = tag;
                end
                source = tagSource("Release", tag, name + " (" + tag + ")", ...
                    textField(latest, "published_at"));
                return;
            end
        end
    catch
    end
    try
        tags = recentTags(20);
    catch
        error("LabKit:Deployment:StableSourceUnavailable", ...
            "Could not find a stable GitHub release or tag.");
    end
    for index = 1:numel(tags)
        if isempty(regexp(char(tags(index).Name), ...
                '^v[0-9]+\.[0-9]+\.[0-9]+$', 'once'))
            continue;
        end
        source = tags(index);
        source.Kind = "Stable";
        source.Label = "GitHub stable tag " + source.Name;
        return;
    end
    error("LabKit:Deployment:StableSourceUnavailable", "Could not find a stable GitHub release or tag.");
end

function source = mainSource()
    source = makeSource("Main", "GitHub main", ...
        "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/" + ...
        "refs/heads/main.zip", "main", "", "Main branch");
end

function result = installSource(root, source, opts)
    assertUpdateRoot(root);
    source = validateSource(source);
    hook = testHook();
    if ~confirmInstall(root, source.Label, hook)
        result = resultFor(root, source, false, "Update canceled.", ...
            "", false, 0);
        return;
    end
    notify(opts.ProgressFcn, "Preparing update workspace...", .10);
    temporary = string(tempname);
    cleanup = onCleanup(@() removeFolder(temporary));
    mkdir(temporary);
    if strlength(hook.CandidateRoot) > 0
        candidate = hook.CandidateRoot;
    else
        zipPath = fullfile(temporary, "labkit.zip");
        notify(opts.ProgressFcn, "Downloading " + source.Label + "...", .25);
        websave(zipPath, source.Url);
        extractFolder = fullfile(temporary, "candidate");
        unzip(zipPath, extractFolder);
        candidate = findCandidate(extractFolder);
    end
    assertCandidate(candidate);
    assertSeparate(candidate, root);
    notify(opts.ProgressFcn, "Replacing LabKit installation...", .70);
    replacement = replaceInstallation(root, candidate, hook.FailAfterBackup);
    notify(opts.ProgressFcn, "Update complete.", 1);
    message = "Installed " + source.Label + ". Restart LabKit if it was open.";
    if replacement.backupRetained
        if replacement.preservedItemCount > 0
            message = message + " Local data was migrated; recovery backup " + ...
                "retained at " + replacement.backupFolder + ".";
        else
            message = message + " Backup cleanup was incomplete; recovery " + ...
                "files remain at " + replacement.backupFolder + ".";
        end
    end
    result = resultFor(root, source, true, message, ...
        replacement.backupFolder, replacement.backupRetained, ...
        replacement.preservedItemCount);
    delete(cleanup)
end

function replacement = replaceInstallation(root, candidate, failAfterBackup)
    parent = fileparts(root);
    [~, name] = fileparts(root);
    backup = fullfile(parent, name + ".version-backup-" + string(java.util.UUID.randomUUID()));
    original = pwd;
    relative = relativeWithin(root, original);
    inside = samePath(root, original) || descendant(original, root);
    state = capturePath(root);
    if inside
        cd(parent);
    end
    detachPath(state);
    cleanup = onCleanup(@() restoreContext(original, root, parent, relative, inside, state));
    [moved, message] = movefile(root, backup, "f");
    if ~moved
        error("LabKit:Deployment:ReplaceFailed", "Could not preserve current installation: %s", message);
    end
    try
        if failAfterBackup
            error("LabKit:Deployment:InjectedFailure", "Injected failure after backup.");
        end
        [copied, message] = copyfile(candidate, root);
        if ~copied
            error("LabKit:Deployment:ReplaceFailed", "Could not copy candidate: %s", message);
        end
        assertCandidate(root);
        preservation = preserveLocal(backup, root);
    catch cause
        rollback(root, backup, cause);
    end
    replacement = struct( ...
        "backupFolder", "", ...
        "backupRetained", false, ...
        "preservedItemCount", preservation.itemCount);
    if preservation.itemCount > 0
        replacement.backupFolder = string(backup);
        replacement.backupRetained = true;
    else
        [removed, ~] = rmdir(backup, "s");
        if ~removed
            replacement.backupFolder = string(backup);
            replacement.backupRetained = true;
        end
    end
    delete(cleanup)
end

function rollback(root, backup, cause)
    if exist(root, "dir") == 7
        [removed, message] = rmdir(root, "s");
        if ~removed
            rollbackFailure(cause, backup, "Partial replacement could not be removed: " + string(message));
        end
    end
    [restored, message] = copyfile(backup, root);
    if ~restored
        rollbackFailure(cause, backup, "Backup could not be restored: " + string(message));
    end
    try
        assertUpdateRoot(root);
    catch validationCause
        rollbackFailure(cause, backup, "Restored installation failed validation: " + failureText(validationCause));
    end
    [removed, message] = rmdir(backup, "s");
    if ~removed
        rollbackFailure(cause, backup, "Backup cleanup failed: " + string(message));
    end
    rethrow(cause)
end

function preservation = preserveLocal(backup, root)
    entries = [
        "private_apps"
        "artifacts"
        string(fullfile("resources", "project"))
        "photos"
        "derived"
        "profile_results"
        "LabKit.prj"
        ];
    present = false(size(entries));
    for index = 1:numel(entries)
        source = fullfile(backup, entries(index));
        if entryExists(source)
            present(index) = true;
            if entryExists(fullfile(root, entries(index)))
                error("LabKit:Deployment:LocalDataConflict", ...
                    "Candidate conflicts with local data: %s", entries(index));
            end
        end
    end
    for index = find(present)'
        target = fullfile(root, entries(index));
        if exist(fileparts(target), "dir") ~= 7
            [created, createMessage] = mkdir(fileparts(target));
            if ~created
                error("LabKit:Deployment:LocalDataCopyFailed", ...
                    "Could not prepare %s: %s", entries(index), createMessage);
            end
        end
        [copied, message] = copyfile(fullfile(backup, entries(index)), target);
        if ~copied
            error("LabKit:Deployment:LocalDataCopyFailed", ...
                "Could not preserve %s: %s", entries(index), message);
        end
    end
    preservation = struct("itemCount", sum(present));
end

function assertUpdateRoot(root)
    if samePath(root, fileparts(root))
        error("LabKit:Deployment:UnsafeRoot", "Refusing to replace a filesystem root.");
    end
    if exist(fullfile(root, ".git"), "file") == 2 || exist(fullfile(root, ".git"), "dir") == 7
        error("LabKit:Deployment:GitCheckout", "Git checkouts must be updated with git.");
    end
    validRoot = exist(fullfile(root, "labkit_launcher.m"), "file") == 2 && ...
        exist(fullfile(root, "+labkit"), "dir") == 7 && ...
        exist(fullfile(root, "apps"), "dir") == 7;
    if ~validRoot
        error("LabKit:Deployment:InvalidRoot", "Root is not a LabKit installation safe to replace.");
    end
end

function assertCandidate(root)
    valid = exist(fullfile(root, "labkit_launcher.m"), "file") == 2 && ...
        exist(fullfile(root, "+labkit"), "dir") == 7 && ...
        exist(fullfile(root, "apps"), "dir") == 7 && ...
        exist(fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch.m"), "file") == 2;
    if ~valid
        error("LabKit:Deployment:InvalidCandidate", "Candidate is not a minimal LabKit root.");
    end
end

function assertSeparate(candidate, root)
    if samePath(candidate, root) || descendant(candidate, root) || descendant(root, candidate)
        error("LabKit:Deployment:InvalidCandidate", "Candidate and root must be separate, non-nested folders.");
    end
end

function sources = emptySources()
    sources = struct( ...
        "Kind", {}, ...
        "Label", {}, ...
        "Url", {}, ...
        "Name", {}, ...
        "Date", {}, ...
        "Summary", {});
end

function value = makeSource(kind, label, url, name, date, summary)
    value = struct( ...
        "Kind", string(kind), ...
        "Label", string(label), ...
        "Url", string(url), ...
        "Name", string(name), ...
        "Date", string(date), ...
        "Summary", string(summary));
end

function value = tagSource(kind, tag, summary, date)
    value = makeSource(kind, ...
        "GitHub " + lower(string(kind)) + " " + tag, ...
        "https://github.com/Pluze/LabKit-MATLAB-Workbench/archive/" + ...
        "refs/tags/" + tag + ".zip", tag, date, summary);
end
function value = validateSource(value)
    required = ["Kind", "Label", "Url", "Name"];
    if ~isstruct(value) || ~isscalar(value) || ~all(isfield(value, required))
        error("LabKit:Deployment:InvalidSource", "Selected source is malformed.");
    end
    for field = required
        candidate = value.(field);
        if ~(ischar(candidate) || (isstring(candidate) && isscalar(candidate))) || ...
                ismissing(string(candidate)) || strlength(strtrim(string(candidate))) == 0
            error("LabKit:Deployment:InvalidSource", "Selected source field %s must be nonempty scalar text.", field);
        end
    end
    url = string(value.Url);
    if ~startsWith(url, repositoryArchivePrefix()) || ~endsWith(url, ".zip")
        error("LabKit:Deployment:InvalidSource", ...
            "Selected source URL must be a LabKit GitHub archive ZIP.");
    end
    value = makeSource(value.Kind, value.Label, value.Url, value.Name, ...
        textField(value, "Date"), textField(value, "Summary"));
end
function rows = sourceRows(sources)
    rows = cell(numel(sources), 4);
    for index = 1:numel(sources)
        rows(index, :) = cellstr([ ...
            sources(index).Kind
            sources(index).Name
            sources(index).Date
            sources(index).Summary
            ]');
    end
end
function lines = currentInstallLines(root)
    info = currentLauncherInfo(root);
    lines = [ ...
        "Current launcher: " + info.displayName + " v" + info.version + " (" + info.updated + ")"
        "Install folder: " + root
        "Selected ZIP updates keep a sibling backup when local data is migrated."
        ];
end

function info = currentLauncherInfo(root)
    info = struct( ...
        "displayName", "LabKit App Launcher", ...
        "version", "unavailable", ...
        "updated", "unavailable");
    filepath = fullfile(root, "+labkit", "+app", "+internal", "+launcher", "dispatch.m");
    if exist(filepath, "file") ~= 2
        return;
    end
    try
        source = string(fileread(filepath));
        displayName = regexp(source, 'displayName", "([^"]+)"', 'tokens', 'once');
        version = regexp(source, 'version", "([^"]+)"', 'tokens', 'once');
        updated = regexp(source, 'updated", "([^"]+)"', 'tokens', 'once');
        if ~isempty(displayName)
            info.displayName = string(displayName{1});
        end
        if ~isempty(version)
            info.version = string(version{1});
        end
        if ~isempty(updated)
            info.updated = string(updated{1});
        end
    catch
    end
end

function raw = githubRead(suffix)
    url = "https://api.github.com/repos/Pluze/" + ...
        "LabKit-MATLAB-Workbench/" + suffix;
    options = weboptions( ...
        "Timeout", 20, ...
        "UserAgent", "MATLAB LabKit Deployment");
    raw = webread(char(url), options);
end
function value = textField(item, field)
    value = "";
    if ~isstruct(item) || ~isfield(item, field)
        return;
    end
    candidate = item.(field);
    if ischar(candidate) || (isstring(candidate) && isscalar(candidate))
        value = string(candidate);
    end
end

function value = nestedText(item, fields)
    value = "";
    for field = fields
        if ~isstruct(item) || ~isfield(item, field)
            return;
        end
        item = item.(field);
    end
    if ischar(item) || (isstring(item) && isscalar(item))
        value = string(item);
    end
end

function value = logicalField(item, field)
    value = false;
    if isstruct(item) && isfield(item, field) && isscalar(item.(field))
        value = logical(item.(field));
    end
end
function candidate = findCandidate(folder)
    entries = dir(folder);
    for index = 1:numel(entries)
        if ~entries(index).isdir || startsWith(entries(index).name, ".")
            continue;
        end
        candidate = fullfile(entries(index).folder, entries(index).name);
        if exist(fullfile(candidate, "labkit_launcher.m"), "file") == 2
            return;
        end
    end
    error("LabKit:Deployment:InvalidCandidate", ...
        "ZIP does not contain a LabKit root.");
end

function hook = testHook()
    hook = struct( ...
        "CandidateRoot", "", ...
        "FailAfterBackup", false, ...
        "Confirm", []);
    if ~isappdata(groot, "labkitVersionManagerTestHook")
        return;
    end
    value = getappdata(groot, "labkitVersionManagerTestHook");
    if ~isstruct(value)
        return;
    end
    if isfield(value, "CandidateRoot")
        hook.CandidateRoot = string(value.CandidateRoot);
    end
    if isfield(value, "FailAfterBackup")
        hook.FailAfterBackup = logical(value.FailAfterBackup);
    end
    if isfield(value, "Confirm") && ...
            islogical(value.Confirm) && isscalar(value.Confirm)
        hook.Confirm = logical(value.Confirm);
    end
end
function tf = confirmInstall(root, label, hook)
    if ~isempty(hook.Confirm)
        tf = hook.Confirm;
        return;
    end
    try
        answer = questdlg("Install " + label + " into " + root + "?", ...
            "Install LabKit Version", "Install", "Cancel", "Cancel");
        tf = strcmp(answer, "Install");
    catch
        tf = false;
    end
end
function state = capturePath(root)
    entries = string(strsplit(path, pathsep));
    matches = false(size(entries));
    relative = strings(size(entries));
    for index = 1:numel(entries)
        if samePath(entries(index), root)
            matches(index) = true;
        elseif descendant(entries(index), root)
            matches(index) = true;
            relative(index) = relativeWithin(root, entries(index));
        end
    end
    state = struct("entries", entries, "matches", matches, "relative", relative);
end

function detachPath(state)
    entries = state.entries(~state.matches);
    path(char(strjoin(entries(strlength(entries) > 0), pathsep)));
    rehash;
end

function restoreContext(original, root, parent, relative, inside, state)
    entries = state.entries;
    valid = true;
    try
        assertUpdateRoot(root);
    catch
        valid = false;
    end
    for index = find(state.matches)
        candidate = "";
        if valid
            if strlength(state.relative(index)) == 0
                candidate = root;
            else
                candidate = fullfile(root, state.relative(index));
            end
        end
        if strlength(candidate) > 0 && exist(candidate, "dir") == 7
            entries(index) = candidate;
        else
            entries(index) = "";
        end
    end
    path(char(strjoin(entries(strlength(entries) > 0), pathsep)));
    rehash;
    if ~inside && exist(original, "dir") == 7
        cd(original);
    elseif strlength(relative) > 0 && exist(fullfile(root, relative), "dir") == 7
        cd(fullfile(root, relative));
    elseif exist(root, "dir") == 7
        cd(root);
    elseif exist(parent, "dir") == 7
        cd(parent);
    end
end
function value = normalizedPath(value)
    if ~isTextScalar(value) || ismissing(string(value)) || ...
            strlength(string(value)) == 0
        error("LabKit:Deployment:InvalidPath", ...
            "Filesystem paths must be nonempty scalar text.");
    end
    emptyStrings = javaArray("java.lang.String", 0);
    pathObject = java.nio.file.Paths.get(char(value), emptyStrings);
    value = string(pathObject.toAbsolutePath().normalize().toString());
    if ispc
        value = lower(value);
    end
end

function tf = samePath(left, right)
    if ~isTextScalar(left) || ~isTextScalar(right) || ...
            strlength(string(left)) == 0 || strlength(string(right)) == 0
        tf = false;
        return;
    end
    tf = strcmp(normalizedPath(left), normalizedPath(right));
end

function tf = descendant(candidate, root)
    if ~isTextScalar(candidate) || ~isTextScalar(root) || ...
            strlength(string(candidate)) == 0 || strlength(string(root)) == 0
        tf = false;
        return;
    end
    candidate = normalizedPath(candidate);
    root = normalizedPath(root);
    tf = startsWith(candidate, root + string(filesep));
end

function value = relativeWithin(root, folder)
    value = "";
    if descendant(folder, root)
        value = extractAfter( ...
            normalizedPath(folder), strlength(normalizedPath(root)) + 1);
    end
end

function tf = entryExists(value)
    tf = isTextScalar(value) && strlength(string(value)) > 0 && ...
        (exist(value, "file") == 2 || exist(value, "dir") == 7);
end

function rollbackFailure(cause, backup, detail)
    error("LabKit:Deployment:RollbackFailed", ...
        "Update failed (%s). %s Recovery backup remains at %s.", ...
        failureText(cause), detail, backup);
end

function value = failureText(cause)
    value = string(cause.message);
    if strlength(string(cause.identifier)) > 0
        value = string(cause.identifier) + ": " + value;
    end
end

function notify(callback, message, fraction)
    if isempty(callback)
        return;
    end
    try
        callback(string(message), fraction);
    catch
    end
end
function result = resultFor(root, source, updated, message, backup, retained, preserved)
    result = struct( ...
        "root", string(root), ...
        "source", source, ...
        "updated", logical(updated), ...
        "message", string(message), ...
        "backupFolder", string(backup), ...
        "backupRetained", logical(retained), ...
        "preservedItemCount", preserved);
end

function removeFolder(folder)
    if isTextScalar(folder) && strlength(string(folder)) > 0 && ...
            exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end

function root = repoRoot()
    root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end

function prefix = repositoryArchivePrefix()
    prefix = "https://github.com/Pluze/" + ...
        "LabKit-MATLAB-Workbench/archive/";
end

function tf = isTextScalar(value)
    tf = (ischar(value) && isrow(value)) || ...
        (isstring(value) && isscalar(value));
end
