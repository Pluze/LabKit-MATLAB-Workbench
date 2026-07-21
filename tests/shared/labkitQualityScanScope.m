function scope = labkitQualityScanScope(root)
%LABKITQUALITYSCANSCOPE Source scope for project style/quality guardrails.
%
% Expected caller: project contract tests that scan source text for repository
% quality rules. Inputs are a LabKit checkout root. Output contains absolute
% file lists for public tracked files plus private app workspaces that opt in
% with .labkit-accept-main-guardrails. LABKIT_GUARD_PRIVATE_APPS remains a
% temporary force-enable override. Side effects: reads git file lists and
% environment variables.

    root = char(string(root));
    tracked = gitTrackedFiles(root);
    trackedFullPaths = fullfile(root, cellstr(tracked));
    trackedFullPaths = string(trackedFullPaths(:));
    trackedFullPaths = trackedFullPaths(isfile(trackedFullPaths));

    privateRoots = acceptedPrivateAppRoots(root);

    privateTextByRoot = cell(numel(privateRoots), 1);
    privateMatlabByRoot = cell(numel(privateRoots), 1);
    for k = 1:numel(privateRoots)
        privateTextByRoot{k} = collectTextFiles(privateRoots(k));
        privateMatlabByRoot{k} = collectFiles(privateRoots(k), "*.m");
    end
    privateTextFiles = vertcatStrings(privateTextByRoot);
    privateMatlabFiles = vertcatStrings(privateMatlabByRoot);

    scope = struct();
    scope.includePrivateApps = ~isempty(privateRoots);
    scope.privateAppRoots = privateRoots;
    scope.trackedFiles = tracked;
    scope.trackedFullPaths = trackedFullPaths;
    scope.matlabFiles = unique([trackedFullPaths(endsWith(trackedFullPaths, ".m")); ...
        privateMatlabFiles], "stable");
    publicTextFiles = publicTrackedTextFiles(root, tracked);
    scope.textFiles = unique([publicTextFiles; ...
        privateTextFiles], "stable");
    scope.appMFiles = unique([collectFiles(fullfile(root, "apps"), "*.m"); ...
        privateMatlabFiles], "stable");
    scope.appEntrypoints = unique([collectFiles(fullfile(root, "apps"), "labkit_*_app.m"); ...
        collectPrivateEntrypoints(privateRoots)], "stable");
    scope.appRunFiles = appRunFiles(scope.appMFiles);
end

function tf = forcePrivateAppGuardsEnabled()
    value = lower(strtrim(string(getenv("LABKIT_GUARD_PRIVATE_APPS"))));
    tf = any(value == ["1", "true", "yes", "on"]);
end

function roots = acceptedPrivateAppRoots(root)
    candidates = configuredPrivateAppRoots(root);
    if forcePrivateAppGuardsEnabled()
        roots = candidates;
        return;
    end

    roots = strings(0, 1);
    for k = 1:numel(candidates)
        if privateRootAcceptsMainGuardrails(candidates(k))
            roots(end+1, 1) = candidates(k);
        end
    end
end

function roots = configuredPrivateAppRoots(root)
    roots = strings(0, 1);
    localRoot = string(fullfile(root, "private_apps", "apps"));
    if isfolder(localRoot)
        roots(end+1, 1) = localRoot;
    end

    envValue = string(getenv("LABKIT_PRIVATE_APP_ROOTS"));
    if strlength(strtrim(envValue)) > 0
        parts = string(strsplit(char(envValue), pathsep));
        parts = strip(parts);
        parts = parts(strlength(parts) > 0);
        for k = 1:numel(parts)
            candidate = privateAppsFolder(parts(k));
            if isfolder(candidate)
                roots(end+1, 1) = candidate;
            end
        end
    end
    roots = unique(roots, "stable");
end

function appRoot = privateAppsFolder(root)
    root = string(root);
    if endsWith(strrep(root, "\", "/"), "/apps")
        appRoot = root;
    else
        appRoot = string(fullfile(root, "apps"));
    end
end

function tf = privateRootAcceptsMainGuardrails(appRoot)
    workspaceRoot = privateWorkspaceRoot(appRoot);
    tf = isfile(fullfile(workspaceRoot, ".labkit-accept-main-guardrails"));
end

function root = privateWorkspaceRoot(appRoot)
    appRoot = string(appRoot);
    if endsWith(strrep(appRoot, "\", "/"), "/apps")
        root = string(fileparts(char(appRoot)));
    else
        root = appRoot;
    end
end

function files = collectPrivateEntrypoints(privateRoots)
    filesByRoot = cell(numel(privateRoots), 1);
    for k = 1:numel(privateRoots)
        filesByRoot{k} = collectFiles(privateRoots(k), "labkit_*_app.m");
    end
    files = vertcatStrings(filesByRoot);
end

function values = vertcatStrings(parts)
    if isempty(parts)
        values = strings(0, 1);
    else
        values = vertcat(parts{:});
    end
end

function files = collectFiles(root, pattern)
    if ~isfolder(root)
        files = strings(0, 1);
        return;
    end
    entries = dir(fullfile(root, "**", pattern));
    entries = entries(~[entries.isdir]);
    files = strings(numel(entries), 1);
    for k = 1:numel(entries)
        files(k) = string(fullfile(entries(k).folder, entries(k).name));
    end
    files = sort(files);
end

function files = collectTextFiles(root)
    allFiles = collectFiles(root, "*");
    files = allFiles(arrayfun(@isTextFile, allFiles));
end

function files = appRunFiles(appMFiles)
    files = strings(0, 1);
    packageMarker = string(filesep) + "+";
    for k = 1:numel(appMFiles)
        [~, name, ext] = fileparts(appMFiles(k));
        if name == "run" && ext == ".m" && contains(appMFiles(k), packageMarker)
            files(end+1, 1) = appMFiles(k);
        end
    end
end

function files = gitTrackedFiles(root)
    command = "git -C " + shellDoubleQuote(root) + " ls-files";
    [status, output] = system(char(command));
    assert(status == 0, "Could not list tracked files with git.");
    files = splitlines(string(output));
    files = files(strlength(files) > 0);
end

function files = publicTrackedTextFiles(root, tracked)
    roots = ["README.md", "AGENTS.md", "docs/", ...
        "tests/", "apps/", "+labkit/", ".github/"];
    keep = false(size(tracked));
    slashTracked = replace(tracked, "\", "/");
    for k = 1:numel(roots)
        keep = keep | slashTracked == roots(k) | startsWith(slashTracked, roots(k));
    end
    scoped = tracked(keep);
    fullPaths = fullfile(root, cellstr(scoped));
    fullPaths = string(fullPaths(:));
    files = fullPaths(isfile(fullPaths) & arrayfun(@isTextFile, fullPaths));
end

function quoted = shellDoubleQuote(value)
    quoted = string(value);
    if contains(quoted, """")
        error("LabKit:QualityScope:InvalidShellValue", ...
            "Shell-quoted values cannot contain double-quote characters.");
    end
    quoted = """" + quoted + """";
end

function tf = isTextFile(filepath)
    [~, ~, ext] = fileparts(filepath);
    tf = any(strcmpi(ext, {'.m', '.md', '.ps1', '.sh', '.yml', '.yaml', ...
        '.json', '.txt', '.csv', '.tsv'}));
end
