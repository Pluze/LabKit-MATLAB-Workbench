function output = runLabKitTests(varargin)
%RUNLABKITTESTS Low-level LabKit runner for MATLAB's official test framework.
%
% Prefer buildtool tasks for human and CI entry points. This runner discovers
% official matlab.unittest tests under tests/cases/unit, tests/cases/contract,
% and tests/cases/gui so buildfile.m can compose stable tasks without
% duplicating test discovery.
%
% Internal name-value options:
%   IncludeGui      Include tests under tests/cases/gui.
%   Suites          Suite targets such as project, labkit/dta, or gui.
%   Tests           Test names or substrings to include.
%   Tags            Required official test tags. Multiple tags are ORed.
%   ExcludeTags     Official test tags to exclude.
%   Plan            Named serial plan: changed, ui, apps, or project.
%   IncludeCoverage Generate Cobertura and HTML coverage artifacts.
%   GuiMode         GUI test window mode: hidden, minimized, or visible.
%   HtmlReport      Generate the official HTML test report. Default true.
%   FailIfNoTests   Error when no official tests match.
%   ArtifactsRoot   Root artifact directory.
%   RunName         Name used in artifact titles and console output.
%   ListOnly        List matched tests without executing or writing artifacts.

    root = fileparts(fileparts(mfilename("fullpath")));
    addpath(fullfile(root, "tests", "runner"));
    setupLabKitTestPath();

    opts = parseOptions(root, varargin{:});
    restoreRunName = setRunNameEnvironment(opts.RunName);
    restoreArtifactsRoot = setArtifactsRootEnvironment(opts.ArtifactsRoot);
    restoreGuiMode = labkitGuiTestMode(opts.GuiMode);

    if strlength(opts.Plan) > 0
        output = runValidationPlan(root, opts);
        clear restoreRunName restoreArtifactsRoot restoreGuiMode
        return;
    end

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
        clear restoreRunName restoreArtifactsRoot restoreGuiMode
        return;
    end

    paths = labkitArtifactPaths( ...
        "Root", opts.ArtifactsRoot, ...
        "RunName", opts.RunName, ...
        "Create", true);
    runner = matlab.unittest.TestRunner.withTextOutput( ...
        "OutputDetail", opts.OutputDetail, ...
        "LoggingLevel", opts.LoggingLevel);
    runner.addPlugin(labkitProgressPlugin);
    runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
        paths.junitXml));
    if opts.HtmlReport
        runner.addPlugin(matlab.unittest.plugins.TestReportPlugin.producingHTML( ...
            paths.testHtml, ...
            "MainFile", "index.html", ...
            "Title", "LabKit MATLAB Tests - " + opts.RunName, ...
            "IncludingCommandWindowText", true));
    end

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
    clear restoreRunName restoreArtifactsRoot restoreGuiMode
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
    p.addParameter("Plan", "", @isTextScalar);
    p.addParameter("IncludeCoverage", false, @isLogicalScalar);
    p.addParameter("GuiMode", labkitDefaultGuiMode(), @isTextScalar);
    p.addParameter("HtmlReport", true, @isLogicalScalar);
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
    opts.GuiMode = labkitNormalizeGuiMode(opts.GuiMode);
    opts.HtmlReport = logical(opts.HtmlReport);
    opts.FailIfNoTests = logical(opts.FailIfNoTests);
    opts.ListOnly = logical(opts.ListOnly);
    opts.Suites = normalizeTextList(opts.Suites);
    opts.Tests = normalizeTextList(opts.Tests);
    opts.Tags = normalizeTextList(opts.Tags);
    opts.ExcludeTags = normalizeTextList(opts.ExcludeTags);
    opts.Plan = lower(string(opts.Plan));
    opts.ArtifactsRoot = char(opts.ArtifactsRoot);
    opts.RunName = string(opts.RunName);
end

function output = runValidationPlan(root, opts)
    ensurePlanHasNoExplicitSelectors(opts);
    planName = opts.Plan;
    if planName == "changed"
        changedPaths = detectAffectedValidationPaths(root);
        steps = labkitValidationPlanForChangedPaths(root, changedPaths);
    else
        steps = namedValidationPlan(planName);
    end

    if isempty(steps)
        error("LabKit:Tests:NoAffectedValidationTargets", ...
            "No validation targets were detected for plan %s.", planName);
    end

    fprintf("LabKit validation plan: %s\n", planName);
    fprintf("Validation plan steps: %d\n", numel(steps));
    printValidationPlanSteps(steps);

    childOutputs = cell(1, numel(steps));
    totalCount = 0;
    for k = 1:numel(steps)
        step = steps(k);
        stepRunName = opts.RunName + "_" + step.RunNameSuffix;
        fprintf("Validation plan step %d/%d: %s\n", ...
            k, numel(steps), stepRunName);

        childArgs = validationPlanStepArgs(step);
        childOutputs{k} = runLabKitTests(childArgs{:}, ...
            "HtmlReport", opts.HtmlReport, ...
            "FailIfNoTests", opts.FailIfNoTests, ...
            "ArtifactsRoot", opts.ArtifactsRoot, ...
            "RunName", stepRunName, ...
            "GuiMode", opts.GuiMode, ...
            "ListOnly", opts.ListOnly, ...
            "OutputDetail", opts.OutputDetail, ...
            "LoggingLevel", opts.LoggingLevel, ...
            "IncludeCoverage", opts.IncludeCoverage);
        if isfield(childOutputs{k}, "count")
            totalCount = totalCount + childOutputs{k}.count;
        else
            totalCount = totalCount + numel(childOutputs{k}.official);
        end
    end

    output = struct( ...
        "plan", planName, ...
        "steps", steps, ...
        "outputs", {childOutputs}, ...
        "count", totalCount, ...
        "runName", opts.RunName);
end

function ensurePlanHasNoExplicitSelectors(opts)
    if ~isempty(opts.Suites) || ~isempty(opts.Tests) || ~isempty(opts.Tags) || ...
            ~isempty(opts.ExcludeTags)
        error("LabKit:Tests:InvalidValidationPlan", ...
            "Plan cannot be combined with explicit suite, test, or tag selectors.");
    end
end

function args = validationPlanStepArgs(step)
    args = {};
    if ~isempty(step.Suites)
        args = [args, {"Suites", step.Suites}];
    end
    args = [args, {"IncludeGui", step.IncludeGui}];
end

function printValidationPlanSteps(steps)
    for k = 1:numel(steps)
        suites = stepSuitesLabel(steps(k));
        fprintf("  %d. %s includeGui=%d suites=%s\n", ...
            k, steps(k).RunNameSuffix, steps(k).IncludeGui, suites);
    end
end

function label = stepSuitesLabel(step)
    if isempty(step.Suites)
        label = "<all-headless>";
    else
        label = strjoin(step.Suites, ",");
    end
end

function steps = namedValidationPlan(planName)
    switch planName
        case "ui"
            steps = [ ...
                validationPlanStep("labkit_ui", "labkit/ui", true), ...
                validationPlanStep("gui_apps", "gui/apps", true)];
        case {"app", "apps"}
            steps = [ ...
                validationPlanStep("apps", "apps", false), ...
                validationPlanStep("gui_apps", "gui/apps", true)];
        case "project"
            steps = validationPlanStep("project", "project", false);
        otherwise
            error("LabKit:Tests:UnknownValidationPlan", ...
                "Unknown validation plan: %s.", planName);
    end
end

function step = validationPlanStep(runNameSuffix, suites, includeGui)
    step = struct( ...
        "RunNameSuffix", string(runNameSuffix), ...
        "Suites", {normalizeTextList(suites)}, ...
        "IncludeGui", logical(includeGui));
end

function paths = detectAffectedValidationPaths(root)
    assertChangedValidationGitAvailable(root);
    changedPaths = [ ...
        gitChangedPaths(root, "HEAD", strings(1, 0)), ...
        gitUntrackedPaths(root, strings(1, 0))];
    paths = unique(changedPaths, "stable");
    if isempty(paths) && gitRefExists(root, "HEAD^")
        paths = gitChangedPaths(root, "HEAD^", strings(1, 0));
    end
end

function assertChangedValidationGitAvailable(root)
    command = "git -C " + shellDoubleQuote(root) + ...
        " rev-parse --is-inside-work-tree";
    [status, output] = system(char(command));
    if status ~= 0 || strip(string(output)) ~= "true"
        error("LabKit:Tests:ChangedRequiresGit", ...
            "The changed build task requires git and a git checkout. Use buildtool headless when git state is unavailable.");
    end
end

function suite = discoverOfficialSuite(root, opts)
    casesRoot = fullfile(root, "tests", "cases");
    groups = discoverOfficialGroups(casesRoot);
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

function groups = discoverOfficialGroups(casesRoot)
    persistent cachedCasesRoot cachedSignature cachedGroups

    signature = testTreeSignature(casesRoot);
    if isequal(cachedCasesRoot, string(casesRoot)) && ...
            isequal(cachedSignature, signature)
        groups = cachedGroups;
        return;
    end

    groups = struct("key", {}, "suite", {});
    roots = ["unit", "contract", "gui"];
    for r = 1:numel(roots)
        sectionRoot = fullfile(casesRoot, roots(r));
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
            key = relativeTestKey(folders(f), casesRoot);
            groups(end+1) = struct("key", key, "suite", suite);
        end
    end

    cachedCasesRoot = string(casesRoot);
    cachedSignature = signature;
    cachedGroups = groups;
end

function signature = testTreeSignature(root)
    files = testTreeMFiles(root);
    if isempty(files)
        signature = strings(1, 0);
        return;
    end

    parts = strings(1, numel(files));
    for k = 1:numel(files)
        info = dir(files(k));
        if isempty(info)
            parts(k) = string(files(k)) + "|missing";
        else
            parts(k) = string(files(k)) + "|" + string(info.datenum) + ...
                "|" + string(info.bytes);
        end
    end
    signature = strjoin(parts, newline);
end

function files = testTreeMFiles(root)
    files = strings(1, 0);
    entries = dir(root);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if strcmp(entry.name, ".") || strcmp(entry.name, "..")
                continue;
            end
            files = [files, testTreeMFiles(fullfile(entry.folder, entry.name))];
        elseif endsWith(entry.name, ".m")
            files(end+1) = string(fullfile(entry.folder, entry.name));
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
    guiKeys = startsWith([groups.key], "gui/");
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

function paths = gitChangedPaths(root, baseRef, pathspecs)
    ref = validateGitRef(baseRef);
    command = "git -C " + shellDoubleQuote(root) + ...
        " diff --name-only --diff-filter=ACMRTUXB " + ref;
    if ~isempty(pathspecs)
        command = command + " -- " + strjoin(pathspecs, " ");
    end
    paths = runGitPathCommand(command);
end

function paths = gitUntrackedPaths(root, pathspecs)
    command = "git -C " + shellDoubleQuote(root) + ...
        " ls-files --others --exclude-standard";
    if ~isempty(pathspecs)
        command = command + " -- " + strjoin(pathspecs, " ");
    end
    paths = runGitPathCommand(command);
end

function tf = gitRefExists(root, ref)
    ref = validateGitRef(ref);
    command = "git -C " + shellDoubleQuote(root) + ...
        " rev-parse --verify --quiet " + ref;
    [status, ~] = system(char(command));
    tf = status == 0;
end

function paths = runGitPathCommand(command)
    [status, output] = system(char(command));
    if status ~= 0
        error("LabKit:Tests:GitSelectionFailed", ...
            "Could not inspect changed test targets with git: %s", strtrim(output));
    end

    paths = splitlines(string(output));
    paths = strip(replace(paths, "\", "/"));
    paths = paths(strlength(paths) > 0).';
end

function ref = validateGitRef(baseRef)
    ref = string(baseRef);
    if ~isscalar(ref) || strlength(ref) == 0
        error("LabKit:Tests:InvalidGitRef", ...
            "Changed-file validation requires a nonempty git ref.");
    end

    chars = char(ref);
    allowed = isstrprop(chars, "alphanum") | ismember(chars, "./_@{}^-~");
    if ~all(allowed)
        error("LabKit:Tests:InvalidGitRef", ...
            "Changed-file validation git ref contains unsupported shell characters.");
    end
end

function quoted = shellDoubleQuote(value)
    quoted = string(value);
    if contains(quoted, """")
        error("LabKit:Tests:InvalidShellValue", ...
            "Shell-quoted values cannot contain double-quote characters.");
    end
    quoted = """" + quoted + """";
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
        "gui/" + target, ...
        "gui/gesture/" + target]);
    if target == "project"
        candidates(end+1) = "contract";
    end
    if startsWith(target, "apps/")
        family = eraseBetween(target, 1, strlength("apps/"));
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
        target = erase(target, "tests/cases/unit/");
        target = erase(target, "tests/cases/contract/");
        target = erase(target, "tests/cases/gui/");
        target = erase(target, "tests/cases/");
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
