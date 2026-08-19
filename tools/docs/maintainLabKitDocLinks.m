function result = maintainLabKitDocLinks(repoRoot, options)
%MAINTAINLABKITDOCLINKS Check or repair local links after Markdown files move.
%
% Usage:
%   result = maintainLabKitDocLinks
%   result = maintainLabKitDocLinks(repoRoot)
%   result = maintainLabKitDocLinks(repoRoot, "Update", true)
%
% Description:
%   Scans repository Markdown links. Existing relative targets are preserved.
%   A missing Markdown target is rewritten only when its filename and link
%   label identify exactly one current Markdown page. Ambiguous or unresolved
%   links fail instead of being guessed.
%
% Inputs:
%   repoRoot - Repository root folder. Default: current LabKit repository.
%
% Name-Value Arguments:
%   Update - Logical scalar. When false, report repairable moved links without
%       changing files. When true, rewrite repairable links. Default: false.
%
% Outputs:
%   result - Structure with checkedFileCount, repairedLinkCount,
%       updatedFileCount, and unresolved.
%
% Errors:
%   LabKit:Docs:UnresolvedMarkdownLinks - One or more local Markdown links
%       cannot be resolved uniquely.
%
% Side effects:
%   With Update=true, rewrites only Markdown files containing repairable
%   relative links. The default check mode is read-only.
%
% Example:
%   result = maintainLabKitDocLinks(pwd, "Update", false);
%   assert(isempty(result.unresolved));
%
% See also renderLabKitDocs, checkLabKitDocs

    arguments
        repoRoot (1, 1) string = defaultRepositoryRoot()
        options.Update (1, 1) logical = false
    end
    repoRoot = absoluteFolder(repoRoot);
    files = markdownFiles(repoRoot);
    pageInfo = markdownPageInfo(repoRoot, files);
    unresolvedChunks = cell(numel(files), 1);
    repairedLinkCount = 0;
    updatedFileCount = 0;

    for k = 1:numel(files)
        filepath = files(k);
        original = string(fileread(filepath));
        [updated, repairs, failures] = repairFileLinks( ...
            repoRoot, filepath, original, pageInfo);
        repairedLinkCount = repairedLinkCount + repairs;
        unresolvedChunks{k} = failures;
        if options.Update && updated ~= original
            writeText(filepath, updated);
            updatedFileCount = updatedFileCount + 1;
        end
    end
    unresolved = strings(0, 1);
    if ~isempty(unresolvedChunks)
        unresolved = vertcat(unresolvedChunks{:});
    end
    result = struct( ...
        "checkedFileCount", numel(files), ...
        "repairedLinkCount", repairedLinkCount, ...
        "updatedFileCount", updatedFileCount, ...
        "unresolved", unresolved);
    if ~isempty(unresolved)
        error("LabKit:Docs:UnresolvedMarkdownLinks", ...
            "Unresolved Markdown links:%s%s", newline, strjoin(unresolved, newline));
    end
end

function root = defaultRepositoryRoot()
    root = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
end

function folder = absoluteFolder(folder)
    folder = resolveLabKitDocFolder(folder, ...
        "LabKit:Docs:InvalidFolder", ...
        "Repository folder does not exist: %s");
end

function files = markdownFiles(repoRoot)
    entries = dir(fullfile(repoRoot, "**", "*.md"));
    files = strings(numel(entries), 1);
    fileCount = 0;
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        relative = replace(extractAfter(filepath, repoRoot + filesep), ...
            filesep, "/");
        if startsWith(relative, ["site/", "artifacts/", ".git/"])
            continue;
        end
        fileCount = fileCount + 1;
        files(fileCount, 1) = filepath;
    end
    files = sort(files(1:fileCount));
end

function info = markdownPageInfo(repoRoot, files)
    template = struct("path", "", "relative", "", "name", "", "title", "");
    info = repmat(template, numel(files), 1);
    for k = 1:numel(files)
        filepath = files(k);
        text = string(fileread(filepath));
        lines = splitlines(text);
        heading = lines(startsWith(lines, "# "));
        title = "";
        if ~isempty(heading)
            title = strip(extractAfter(heading(1), "# "));
        end
        [~, name, extension] = fileparts(filepath);
        info(k) = struct( ...
            "path", char(filepath), ...
            "relative", char(replace(extractAfter( ...
                filepath, repoRoot + filesep), filesep, "/")), ...
            "name", char(string(name) + string(extension)), ...
            "title", char(title));
    end
end

function [updated, repaired, failures] = repairFileLinks( ...
        repoRoot, filepath, text, pageInfo)
    pattern = '\[([^\]]+)\]\(([^)]+)\)';
    [starts, finishes, tokens] = regexp(char(text), pattern, ...
        "start", "end", "tokens");
    updated = text;
    repaired = 0;
    failures = strings(numel(starts), 1);
    failureCount = 0;
    for k = numel(tokens):-1:1
        label = string(tokens{k}{1});
        rawTarget = string(tokens{k}{2});
        [pathPart, suffix] = splitTarget(rawTarget);
        if ~isLocalMarkdownTarget(pathPart)
            continue;
        end
        currentFolder = string(fileparts(filepath));
        resolved = normalizedAbsolutePath(currentFolder, pathPart);
        if isfile(resolved)
            continue;
        end
        candidate = movedTargetCandidate(pathPart, label, pageInfo);
        if strlength(candidate) == 0
            relativeSource = replace(extractAfter( ...
                filepath, repoRoot + filesep), filesep, "/");
            failureCount = failureCount + 1;
            failures(failureCount, 1) = relativeSource + " -> " + rawTarget;
            continue;
        end
        newTarget = relativeMarkdownPath(currentFolder, candidate) + suffix;
        replacement = "[" + label + "](" + newTarget + ")";
        updated = extractBefore(updated, starts(k)) + replacement + ...
            extractAfter(updated, finishes(k));
        repaired = repaired + 1;
    end
    failures = failures(1:failureCount);
end

function [pathPart, suffix] = splitTarget(target)
    pieces = split(target, "#");
    pathPart = pieces(1);
    suffix = "";
    if numel(pieces) > 1
        suffix = "#" + strjoin(pieces(2:end), "#");
    end
end

function tf = isLocalMarkdownTarget(path)
    path = lower(string(path));
    tf = endsWith(path, ".md") && ...
        ~startsWith(path, ["http://", "https://", "mailto:", "/"]);
end

function path = normalizedAbsolutePath(folder, relative)
    path = string(fullfile(folder, replace(relative, "/", filesep)));
end

function candidate = movedTargetCandidate(oldTarget, label, pageInfo)
    [~, name, extension] = fileparts(oldTarget);
    filename = string(name) + string(extension);
    matches = find(string({pageInfo.name}) == filename);
    if numel(matches) > 1
        normalizedLabel = normalizedWords(label);
        titles = arrayfun(@(item) normalizedWords(item.title), pageInfo(matches));
        exact = matches(titles == normalizedLabel);
        if isscalar(exact)
            matches = exact;
        end
    end
    if isscalar(matches)
        candidate = string(pageInfo(matches).path);
    else
        candidate = "";
    end
end

function value = normalizedWords(value)
    value = lower(regexprep(string(value), '<[^>]+>|[`*_]', ''));
    value = strip(regexprep(value, '[^a-z0-9]+', ' '));
end

function relative = relativeMarkdownPath(fromFolder, target)
    fromParts = split(replace(string(fromFolder), "\", "/"), "/");
    targetParts = split(replace(string(target), "\", "/"), "/");
    shared = 0;
    while shared < min(numel(fromParts), numel(targetParts)) && ...
            lower(fromParts(shared + 1)) == lower(targetParts(shared + 1))
        shared = shared + 1;
    end
    relative = strjoin([ ...
        repmat("..", numel(fromParts) - shared, 1); ...
        targetParts(shared + 1:end)], "/");
end

function writeText(filepath, text)
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Docs:WriteFailed", ...
            "Could not update Markdown links in %s.", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, char(text), "char");
    clear cleanup
end
