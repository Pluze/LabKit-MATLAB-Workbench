function apps = discoverApps(root)
%DISCOVERAPPS Discover normalized public and private launcher entries.
% ROOT supplies the public Apps tree and optional local private roots. The
% returned struct array is sorted and contains no executable handles.
apps = labkit.app.internal.launcher.emptyApps();
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
        filepath = fullfile(entry.folder, entry.name);
        metadata = appVersionInfo(entry.folder);
        family = familyName(appRoot, entry.folder);
        if strlength(metadata.family) > 0
            family = metadata.family;
        end
        name = displayName(command);
        if strlength(metadata.displayName) > 0
            name = metadata.displayName;
        end
        app = struct("command", scalarText(command, "command"), ...
            "folder", scalarText(entry.folder, "folder"), ...
            "relativePath", scalarText(relativePath(root, filepath), "relativePath"), ...
            "family", scalarText(family, "family"), ...
            "name", scalarText(name, "name"), ...
            "description", scalarText(appDescription(filepath, command), "description"), ...
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

function description = appDescription(filepath, command)
description = "";
try
    text = fileread(filepath);
catch
    return;
end
lines = splitlines(string(text));
prefix = "%" + upper(string(command));
for index = 1:min(numel(lines), 20)
    line = strtrim(lines(index));
    if startsWith(line, prefix)
        description = strtrim(erase(extractAfter( ...
            line, strlength(prefix)), "-"));
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

function info = appVersionInfo(folder)
info = struct("version", "", "updated", "", ...
    "displayName", "", "family", "");
definitions = dir(fullfile(folder, "+*", "definition.m"));
if isempty(definitions)
    return;
end
try
    text = fileread(fullfile(definitions(1).folder, definitions(1).name));
    info.version = literalField(text, "AppVersion");
    info.updated = literalField(text, "Updated");
    info.displayName = literalField(text, "DisplayName");
    info.family = literalField(text, "Family");
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
