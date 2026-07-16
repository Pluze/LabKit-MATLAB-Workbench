function groups = labkitDiscoverSelectorGroups(casesRoot, opts)
%LABKITDISCOVERSELECTORGROUPS Discover only test folders matching selectors.
% Expected caller: runLabKitTests. Inputs are the tests/cases root and parsed
% runner options with Suites and Tests. Output is a struct array matching the
% runner's group shape. Side effects: reads test source files.

    groups = struct("key", {}, "suite", {});
    folders = selectorCandidateFolders(casesRoot, opts);
    for f = 1:numel(folders)
        suite = matlab.unittest.TestSuite.fromFolder(folders(f), ...
            "IncludingSubfolders", false, ...
            "InvalidFileFoundAction", "warn");
        if isempty(suite)
            continue;
        end
        key = relativeTestKey(folders(f), casesRoot);
        groups(end+1) = struct("key", key, "suite", suite);
    end
end

function folders = selectorCandidateFolders(casesRoot, opts)
    selectors = lower(normalizeTextList(opts.Tests));
    roots = selectorSearchRoots(casesRoot, opts);
    folders = strings(1, 0);
    for r = 1:numel(roots)
        files = labkitTestTreeMFiles(roots(r));
        for k = 1:numel(files)
            if fileMayContainSelector(files(k), selectors)
                folders(end+1) = string(fileparts(char(files(k))));
            end
        end
    end
    folders = unique(folders, "stable");
end

function roots = selectorSearchRoots(casesRoot, opts)
    targets = lower(labkitNormalizeSuiteTargets(opts.Suites));
    if isempty(targets)
        roots = string(casesRoot);
        return;
    end

    roots = strings(1, 0);
    for k = 1:numel(targets)
        target = targets(k);
        if target == "gui"
            roots(end+1) = string(fullfile(casesRoot, "gui"));
        elseif startsWith(target, "gui/")
            roots(end+1) = string(fullfile(casesRoot, target));
        else
            roots(end+1) = string(fullfile(casesRoot, "unit", target));
            roots(end+1) = string(fullfile(casesRoot, "contract", target));
        end
    end
    roots = roots(arrayfun(@(p) exist(p, "dir") == 7, roots));
    roots = unique(roots, "stable");
end

function tf = fileMayContainSelector(file, selectors)
    haystack = lower(string(file));
    if any(contains(haystack, selectors))
        tf = true;
        return;
    end
    haystack = lower(string(fileread(file)));
    tf = any(contains(haystack, selectors));
end

function key = relativeTestKey(folder, testsRoot)
    key = extractAfter(string(folder), strlength(string(testsRoot)) + 1);
    key = replace(key, filesep, "/");
    while startsWith(key, "/")
        key = extractAfter(key, 1);
    end
end

function values = normalizeTextList(values)
    if isempty(values)
        values = strings(1, 0);
    elseif ischar(values)
        values = string({values});
    elseif iscell(values)
        values = string(values);
    else
        values = string(values);
    end
    values = values(:).';
    values = values(strlength(values) > 0);
end
