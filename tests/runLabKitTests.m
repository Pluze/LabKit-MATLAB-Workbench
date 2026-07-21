function output = runLabKitTests(varargin)
%RUNLABKITTESTS Low-level LabKit runner for MATLAB's official test framework.
%
% Prefer buildtool tasks for human and CI entry points. This runner discovers
% official matlab.unittest tests under tests/cases/unit, tests/cases/contract,
% and tests/cases/gui so buildfile.m can compose stable tasks without
% duplicating test discovery.
%
% Internal options are parsed below; docs/development/maintain-and-release/testing.md owns build-task entry points.

    root = fileparts(fileparts(mfilename("fullpath")));
    addpath(fullfile(root, "tests", "runner"));
    setupLabKitTestPath();

    opts = labkitParseRunnerOptions(root, varargin{:});
    environmentCleanup = setRunEnvironment(opts);

    if strlength(opts.Plan) > 0
        output = runValidationPlan(root, opts);
        delete(environmentCleanup);
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
        if opts.PrintList
            printSuiteListing(listing);
        end
        output = struct( ...
            "official", matlab.unittest.Test.empty(1, 0), ...
            "artifacts", struct(), ...
            "runName", opts.RunName, ...
            "listOnly", true, ...
            "count", height(listing), ...
            "tests", listing);
        delete(environmentCleanup);
        return;
    end

    paths = labkitArtifactPaths( ...
        "Root", opts.ArtifactsRoot, ...
        "RunName", opts.RunName, ...
        "Create", false);
    ensureDirectory(paths.testResults);
    ensureDirectory(paths.logs);
    runner = matlab.unittest.TestRunner.withTextOutput( ...
        "OutputDetail", opts.OutputDetail, ...
        "LoggingLevel", opts.LoggingLevel);
    runner.addPlugin(labkitProgressPlugin(paths.logs));
    runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
        paths.junitXml));
    if opts.HtmlReport
        ensureDirectory(paths.testHtml);
        runner.addPlugin(matlab.unittest.plugins.TestReportPlugin.producingHTML( ...
            paths.testHtml, ...
            "MainFile", "index.html", ...
            "Title", "LabKit MATLAB Tests - " + opts.RunName, ...
            "IncludingCommandWindowText", true));
    end
    if opts.IncludeCoverage
        ensureDirectory(paths.coverage);
        ensureDirectory(paths.coverageHtml);
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
    if labkitOfficialResultsHaveFailures(officialResults)
        error("LabKit:Tests:OfficialFailure", ...
            "One or more official matlab.unittest tests failed.");
    end

    output = struct( ...
        "official", officialResults, ...
        "artifacts", paths, ...
        "runName", opts.RunName);
    delete(environmentCleanup);
end

function cleanup = setRunEnvironment(opts)
    previousRunName = getenv("LABKIT_RUN_NAME");
    previousArtifactsRoot = getenv("LABKIT_ARTIFACTS");
    setenv("LABKIT_RUN_NAME", char(opts.RunName));
    setenv("LABKIT_ARTIFACTS", char(opts.ArtifactsRoot));
    guiCleanup = labkitGuiTestMode(opts.GuiMode);
    cleanup = onCleanup(@() restoreRunEnvironment( ...
        previousRunName, previousArtifactsRoot, guiCleanup));
end

function restoreRunEnvironment( ...
        previousRunName, previousArtifactsRoot, guiCleanup)
    setenv("LABKIT_RUN_NAME", previousRunName);
    setenv("LABKIT_ARTIFACTS", previousArtifactsRoot);
    delete(guiCleanup);
end

function ensureDirectory(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function output = runValidationPlan(root, opts)
    ensurePlanHasNoExplicitSelectors(opts);
    planName = opts.Plan;
    if planName == "changedfast"
        changedPaths = detectAffectedValidationPaths(root);
        steps = labkitValidationPlanForChangedPaths(root, changedPaths, ...
            "Mode", "fast");
    else
        error("LabKit:Tests:UnknownValidationPlan", ...
            "Plan must be changedFast: %s.", planName);
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
            "PrintList", opts.PrintList, ...
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
    if ~isempty(opts.Suites) || ~isempty(opts.Files) || ...
            ~isempty(opts.Tests) || ~isempty(opts.Tags) || ...
            ~isempty(opts.ExcludeTags)
        error("LabKit:Tests:InvalidValidationPlan", ...
            "Plan cannot be combined with explicit suite, file, test, or tag selectors.");
    end
end

function args = validationPlanStepArgs(step)
    args = {};
    if ~isempty(step.Suites)
        args = [args, {"Suites", step.Suites}];
    end
    if isfield(step, "Files") && ~isempty(step.Files)
        args = [args, {"Files", step.Files}];
    end
    if isfield(step, "Tests") && ~isempty(step.Tests)
        args = [args, {"Tests", step.Tests}];
    end
    args = [args, {"IncludeGui", step.IncludeGui}];
end

function printValidationPlanSteps(steps)
    for k = 1:numel(steps)
        fprintf("  %d. %s includeGui=%d suites=%s files=%s tests=%s reason=%s\n", ...
            k, steps(k).RunNameSuffix, steps(k).IncludeGui, ...
            stepSuitesLabel(steps(k)), stepFilesLabel(steps(k)), ...
            stepTestsLabel(steps(k)), ...
            stepReasonLabel(steps(k)));
    end
end
function label = stepFilesLabel(step)
    if ~isfield(step, "Files") || isempty(step.Files)
        label = "<none>";
    else
        label = strjoin(step.Files, ",");
    end
end

function label = stepSuitesLabel(step)
    if isempty(step.Suites)
        label = "<all-headless>";
    else
        label = strjoin(step.Suites, ",");
    end
end
function label = stepTestsLabel(step)
    if ~isfield(step, "Tests") || isempty(step.Tests)
        label = "<all>";
    else
        label = strjoin(step.Tests, ",");
    end
end

function label = stepReasonLabel(step)
    if ~isfield(step, "Reason") || strlength(string(step.Reason)) == 0
        label = "<unspecified>";
    else
        label = char(step.Reason);
    end
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
            "The changedFast build task requires git and a git checkout. Use buildtool headless when git state is unavailable.");
    end
end

function suite = discoverOfficialSuite(root, opts)
    if ~isempty(opts.Files)
        suite = discoverExplicitFileSuite(opts.Files, opts.IncludeGui);
    else
        casesRoot = fullfile(root, "tests", "cases");
        groups = discoverOfficialGroups(casesRoot, opts);
        groups = filterGroupsBySuite(groups, opts);

        if isempty(groups)
            suite = matlab.unittest.Test.empty(1, 0);
        else
            suiteParts = {groups.suite};
            suite = [suiteParts{:}];
        end
    end

    suite = filterSuiteByName(suite, opts.Tests, opts.FailIfNoTests);
    suite = filterSuiteByTags(suite, opts.Tags, opts.ExcludeTags);
end

function suite = discoverExplicitFileSuite(files, includeGui)
    suiteParts = cell(1, numel(files));
    for k = 1:numel(files)
        normalized = replace(string(files(k)), "\", "/");
        if contains(normalized, "/tests/cases/gui/") && ~includeGui
            error("LabKit:Tests:GuiFileRequiresIncludeGui", ...
                "GUI test files require IncludeGui=true: %s", files(k));
        end
        suiteParts{k} = matlab.unittest.TestSuite.fromFile(files(k));
    end
    suite = [suiteParts{:}];
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

function groups = discoverOfficialGroups(casesRoot, opts)
    persistent cachedCasesRoot cachedSignature cachedGroups

    if ~isempty(opts.Tests)
        groups = labkitDiscoverSelectorGroups(casesRoot, opts);
        return;
    end

    signature = testTreeSignature(casesRoot);
    if isequal(cachedCasesRoot, string(casesRoot)) && ...
            isequal(cachedSignature, signature)
        groups = cachedGroups;
        return;
    end

    roots = ["unit", "contract", "gui"];
    folderSets = cell(1, numel(roots));
    for r = 1:numel(roots)
        sectionRoot = fullfile(casesRoot, roots(r));
        if exist(sectionRoot, "dir") ~= 7
            folderSets{r} = strings(1, 0);
            continue;
        end
        folderSets{r} = foldersWithMFiles(sectionRoot);
    end
    folders = [folderSets{:}];
    groups = repmat(struct( ...
        "key", "", ...
        "suite", matlab.unittest.Test.empty(1, 0)), 1, numel(folders));
    groupCount = 0;
    for f = 1:numel(folders)
        suite = matlab.unittest.TestSuite.fromFolder(folders(f), ...
            "IncludingSubfolders", false, ...
            "InvalidFileFoundAction", "warn");
        if isempty(suite)
            continue;
        end
        groupCount = groupCount + 1;
        groups(groupCount) = struct( ...
            "key", relativeTestKey(folders(f), casesRoot), ...
            "suite", suite);
    end
    groups = groups(1:groupCount);

    cachedCasesRoot = string(casesRoot);
    cachedSignature = signature;
    cachedGroups = groups;
end

function signature = testTreeSignature(root)
    files = labkitTestTreeMFiles(root);
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

function folders = foldersWithMFiles(root)
    files = labkitTestTreeMFiles(root);
    folders = strings(1, numel(files));
    for k = 1:numel(files)
        folders(k) = string(fileparts(files(k)));
    end
    folders = unique(folders, "stable");
end

function groups = filterGroupsBySuite(groups, opts)
    if isempty(groups)
        return;
    end

    suiteTargets = lower(labkitNormalizeSuiteTargets(opts.Suites));
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
        " diff --name-only --diff-filter=ACMRTUXB " + shellDoubleQuote(ref);
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
        " rev-parse --verify --quiet " + shellDoubleQuote(ref);
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
    allowedRefChars = './_@{}^-~';
    allowed = isstrprop(chars, "alphanum") | ismember(chars, allowedRefChars);
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

function suite = filterSuiteByName(suite, tests, failIfUnmatched)
    tests = lower(normalizeTextList(tests));
    if isempty(tests) || isempty(suite)
        return;
    end

    keep = false(size(suite));
    names = lower(string({suite.Name}));
    matchCounts = zeros(size(tests));
    for t = 1:numel(tests)
        matched = contains(names, tests(t));
        matchCounts(t) = sum(matched);
        keep = keep | matched;
    end
    if failIfUnmatched && any(matchCounts == 0)
        missing = tests(matchCounts == 0);
        error("LabKit:Tests:UnmatchedTestSelector", ...
            "Requested test selector(s) matched no official tests: %s", ...
            strjoin(missing, ", "));
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
        "gui/" + target]);
    if startsWith(target, "apps/")
        candidates(end+1) = "contract/apps";
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
