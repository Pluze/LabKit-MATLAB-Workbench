function output = runLabKitTests(varargin)
%RUNLABKITTESTS Run LabKit tests through MATLAB's official test framework.
%
% output = runLabKitTests(Name,Value) discovers official matlab.unittest
% tests under tests/unit, tests/smoke, tests/contract, and tests/gui.
%
% Name-value options:
%   IncludeGui      Include tests under tests/gui.
%   Suites          Suite targets such as project, labkit/dta, or gui.
%   Tests           Test names or substrings to include.
%   Tags            Required official test tags. Multiple tags are ORed.
%   ExcludeTags     Official test tags to exclude.
%   IncludeCoverage Generate Cobertura and HTML coverage artifacts.
%   FailIfNoTests   Error when no official tests match.
%   ArtifactsRoot   Root artifact directory.
%   RunName         Name used in artifact titles and console output.
%   ListOnly        List matched tests without executing or writing artifacts.

    root = fileparts(fileparts(mfilename("fullpath")));
    addpath(fullfile(root, "tests", "support"));
    setupLabKitTestPath();

    opts = parseOptions(root, varargin{:});
    restoreRunName = setRunNameEnvironment(opts.RunName);
    restoreArtifactsRoot = setArtifactsRootEnvironment(opts.ArtifactsRoot);
    suite = discoverOfficialSuite(root, opts);

    fprintf("LabKit official test run: %s\n", opts.RunName);
    fprintf("Official tests matched: %d\n", numel(suite));

    if isempty(suite) && opts.FailIfNoTests
        error("LabKit:Tests:NoOfficialTests", ...
            "No official matlab.unittest tests matched the requested selection.");
    end

    if opts.ListOnly
        listing = suiteListingTable(suite);
        printSuiteListing(listing);
        output = struct( ...
            "official", matlab.unittest.Test.empty(1, 0), ...
            "artifacts", struct(), ...
            "runName", opts.RunName, ...
            "listOnly", true, ...
            "count", height(listing), ...
            "tests", listing);
        clear restoreRunName restoreArtifactsRoot
        return;
    end

    paths = labkitArtifactPaths( ...
        "Root", opts.ArtifactsRoot, ...
        "RunName", opts.RunName, ...
        "Create", true);
    runner = matlab.unittest.TestRunner.withTextOutput( ...
        "OutputDetail", opts.OutputDetail, ...
        "LoggingLevel", opts.LoggingLevel);
    runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
        paths.junitXml));
    runner.addPlugin(matlab.unittest.plugins.TestReportPlugin.producingHTML( ...
        paths.testHtml, ...
        "MainFile", "index.html", ...
        "Title", "LabKit MATLAB Tests - " + opts.RunName, ...
        "IncludingCommandWindowText", true));

    if opts.IncludeCoverage
        coverageFormats = [ ...
            matlab.unittest.plugins.codecoverage.CoverageReport( ...
                paths.coverageHtml, "MainFile", "index.html"), ...
            matlab.unittest.plugins.codecoverage.CoberturaFormat(paths.coberturaXml)];
        coverageFolders = { ...
            char(fullfile(root, "+labkit")), ...
            char(fullfile(root, "apps"))};
        runner.addPlugin(matlab.unittest.plugins.CodeCoveragePlugin.forFolder( ...
            coverageFolders, ...
            "IncludingSubfolders", true, ...
            "Producing", coverageFormats));
    end

    officialResults = runner.run(suite);
    if ~isempty(officialResults) && ~all([officialResults.Passed])
        error("LabKit:Tests:OfficialFailure", ...
            "One or more official matlab.unittest tests failed.");
    end

    output = struct( ...
        "official", officialResults, ...
        "artifacts", paths, ...
        "runName", opts.RunName);
    clear restoreRunName restoreArtifactsRoot
end

function cleanup = setRunNameEnvironment(runName)
    previousRunName = getenv("LABKIT_RUN_NAME");
    setenv("LABKIT_RUN_NAME", char(runName));
    cleanup = onCleanup(@() setenv("LABKIT_RUN_NAME", previousRunName));
end

function cleanup = setArtifactsRootEnvironment(artifactsRoot)
    previousArtifactsRoot = getenv("LABKIT_ARTIFACTS");
    setenv("LABKIT_ARTIFACTS", char(artifactsRoot));
    cleanup = onCleanup(@() setenv("LABKIT_ARTIFACTS", previousArtifactsRoot));
end

function opts = parseOptions(root, varargin)
    p = inputParser;
    p.FunctionName = "runLabKitTests";
    p.addParameter("IncludeGui", false, @isLogicalScalar);
    p.addParameter("Suites", strings(1, 0), @isStringLikeList);
    p.addParameter("Tests", strings(1, 0), @isStringLikeList);
    p.addParameter("Tags", strings(1, 0), @isStringLikeList);
    p.addParameter("ExcludeTags", strings(1, 0), @isStringLikeList);
    p.addParameter("IncludeCoverage", false, @isLogicalScalar);
    p.addParameter("FailIfNoTests", true, @isLogicalScalar);
    p.addParameter("ArtifactsRoot", fullfile(root, "artifacts"), @isTextScalar);
    p.addParameter("RunName", "local", @isTextScalar);
    p.addParameter("ListOnly", false, @isLogicalScalar);
    p.addParameter("OutputDetail", "Concise", @isTextScalar);
    p.addParameter("LoggingLevel", "Concise", @isTextScalar);
    p.parse(varargin{:});

    opts = p.Results;
    opts.IncludeGui = logical(opts.IncludeGui);
    opts.IncludeCoverage = logical(opts.IncludeCoverage);
    opts.FailIfNoTests = logical(opts.FailIfNoTests);
    opts.ListOnly = logical(opts.ListOnly);
    opts.Suites = normalizeTextList(opts.Suites);
    opts.Tests = normalizeTextList(opts.Tests);
    opts.Tags = normalizeTextList(opts.Tags);
    opts.ExcludeTags = normalizeTextList(opts.ExcludeTags);
    opts.ArtifactsRoot = char(opts.ArtifactsRoot);
    opts.RunName = string(opts.RunName);
end

function suite = discoverOfficialSuite(root, opts)
    testsRoot = fullfile(root, "tests");
    groups = discoverOfficialGroups(testsRoot);
    groups = filterGroupsBySuite(groups, opts);

    suite = matlab.unittest.Test.empty(1, 0);
    for k = 1:numel(groups)
        suite = [suite, groups(k).suite];
    end

    suite = filterSuiteByName(suite, opts.Tests);
    suite = filterSuiteByTags(suite, opts.Tags, opts.ExcludeTags);
end

function listing = suiteListingTable(suite)
    names = strings(numel(suite), 1);
    tags = strings(numel(suite), 1);
    for k = 1:numel(suite)
        names(k) = string(suite(k).Name);
        suiteTags = string(suite(k).Tags);
        if isempty(suiteTags)
            tags(k) = "";
        else
            tags(k) = strjoin(suiteTags, ",");
        end
    end
    listing = table(names, tags, 'VariableNames', {'Name', 'Tags'});
end

function printSuiteListing(listing)
    if isempty(listing)
        fprintf("No tests matched.\n");
        return;
    end

    fprintf("Matched official tests:\n");
    for k = 1:height(listing)
        fprintf("  %s [%s]\n", char(listing.Name(k)), char(listing.Tags(k)));
    end
end

function groups = discoverOfficialGroups(testsRoot)
    groups = struct("key", {}, "suite", {});
    roots = ["unit", "contract", "smoke", "gui"];
    for r = 1:numel(roots)
        sectionRoot = fullfile(testsRoot, roots(r));
        if exist(sectionRoot, "dir") ~= 7
            continue;
        end
        folders = foldersWithMFiles(sectionRoot);
        for f = 1:numel(folders)
            suite = matlab.unittest.TestSuite.fromFolder(folders(f), ...
                "IncludingSubfolders", false, ...
                "InvalidFileFoundAction", "warn");
            if isempty(suite)
                continue;
            end
            key = relativeTestKey(folders(f), testsRoot);
            groups(end+1) = struct("key", key, "suite", suite);
        end
    end
end

function folders = foldersWithMFiles(root)
    folders = strings(1, 0);
    entries = dir(root);
    [~, order] = sort({entries.name});
    entries = entries(order);
    hasMFile = false;
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if strcmp(entry.name, ".") || strcmp(entry.name, "..")
                continue;
            end
            folders = [folders, foldersWithMFiles(fullfile(entry.folder, entry.name))];
        elseif endsWith(entry.name, ".m")
            hasMFile = true;
        end
    end
    if hasMFile
        folders = [string(root), folders];
    end
end

function groups = filterGroupsBySuite(groups, opts)
    if isempty(groups)
        return;
    end

    suiteTargets = lower(normalizeSuiteTargets(opts.Suites));
    guiOnly = any(suiteTargets == "gui");
    suiteTargets(suiteTargets == "gui") = [];

    keep = true(size(groups));
    guiKeys = startsWith([groups.key], "gui/") | startsWith([groups.key], "smoke/");
    if ~opts.IncludeGui && ~guiOnly
        keep = keep & ~guiKeys;
    elseif guiOnly
        keep = keep & guiKeys;
    end

    if ~isempty(suiteTargets)
        targetKeep = false(size(groups));
        for g = 1:numel(groups)
            for t = 1:numel(suiteTargets)
                targetKeep(g) = targetKeep(g) || groupMatchesSuite(groups(g).key, suiteTargets(t));
            end
        end
        keep = keep & targetKeep;
    end

    groups = groups(keep);
end

function suite = filterSuiteByName(suite, tests)
    tests = lower(normalizeTextList(tests));
    if isempty(tests) || isempty(suite)
        return;
    end

    keep = false(size(suite));
    names = lower(string({suite.Name}));
    for t = 1:numel(tests)
        keep = keep | contains(names, tests(t));
    end
    suite = suite(keep);
end

function suite = filterSuiteByTags(suite, includeTags, excludeTags)
    if isempty(suite)
        return;
    end

    includeTags = lower(normalizeTextList(includeTags));
    excludeTags = lower(normalizeTextList(excludeTags));

    keep = true(size(suite));
    if ~isempty(includeTags)
        keep = false(size(suite));
        for k = 1:numel(suite)
            tags = lower(string(suite(k).Tags));
            keep(k) = any(ismember(tags, includeTags));
        end
    end

    if ~isempty(excludeTags)
        for k = 1:numel(suite)
            tags = lower(string(suite(k).Tags));
            keep(k) = keep(k) && ~any(ismember(tags, excludeTags));
        end
    end

    suite = suite(keep);
end

function tf = groupMatchesSuite(groupKey, target)
    candidates = unique([ ...
        target, ...
        "unit/" + target, ...
        "contract/" + target, ...
        "smoke/" + target, ...
        "gui/structural/" + target, ...
        "gui/gesture/" + target]);
    if target == "project"
        candidates(end+1) = "contract";
    end
    if target == "apps/smoke"
        candidates(end+1) = "smoke/apps";
    elseif startsWith(target, "apps/")
        family = eraseBetween(target, 1, strlength("apps/"));
        candidates(end+1) = "smoke/" + target;
        candidates(end+1) = "contract/app_workflows/" + family;
    end

    tf = false;
    for k = 1:numel(candidates)
        candidate = candidates(k);
        tf = tf || groupKey == candidate || startsWith(groupKey, candidate + "/");
    end
end

function key = relativeTestKey(folder, testsRoot)
    key = extractAfter(string(folder), strlength(string(testsRoot)) + 1);
    key = replace(key, filesep, "/");
    while startsWith(key, "/")
        key = extractAfter(key, 1);
    end
end

function targets = normalizeSuiteTargets(targets)
    targets = normalizeTextList(targets);
    for k = 1:numel(targets)
        target = replace(targets(k), "\", "/");
        target = erase(target, "tests/unit/");
        target = erase(target, "tests/contract/");
        target = erase(target, "tests/smoke/");
        target = erase(target, "tests/gui/");
        while startsWith(target, "/")
            target = extractAfter(target, 1);
        end
        while endsWith(target, "/")
            target = extractBefore(target, strlength(target));
        end
        targets(k) = target;
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

function tf = isStringLikeList(value)
    tf = ischar(value) || isstring(value) || iscellstr(value);
end

function tf = isTextScalar(value)
    tf = (ischar(value) || (isstring(value) && isscalar(value)));
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end
