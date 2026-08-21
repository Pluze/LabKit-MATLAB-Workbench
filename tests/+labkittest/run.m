function result = run(varargin)
%RUN Execute a compiled LabKit test plan with one runner per environment.
%   RESULT = labkittest.run accepts the same semantic selectors as
%   labkittest.plan, compiles a plan, and runs each exact test identity once.
%   It never accepts suite folders, substring test names, arbitrary tags, or
%   runner options.
%
%   RESULT = labkittest.run(Plan=PLAN) executes an already compiled plan.
%   PLAN must be the value returned by labkittest.plan. RunName and
%   ArtifactsRoot control the run-centered artifact folder; ordinary callers
%   use the defaults.
%
%   Each run writes manifest.json, plan.json, events.jsonl, active-test.json,
%   junit.xml, and summary.json below artifacts/runs/<RunName>.

    [compiledPlan, opts] = parseOptions(varargin{:});
    labkittest.setup();
    artifacts = createArtifacts(opts, compiledPlan);
    artifactEnvironment = exposeArtifactFolder(artifacts.Folder);
    reportPlanScope(compiledPlan);
    reportManualChecks(compiledPlan.ManualChecks);
    results = cell(1, numel(compiledPlan.Groups));
    for k = 1:numel(compiledPlan.Groups)
        group = compiledPlan.Groups(k);
        suite = [group.Descriptors.Test];
        runner = matlab.unittest.TestRunner.withTextOutput("OutputDetail", "terse");
        progress = labkittest.ProgressPlugin(artifacts.Folder);
        cleanup = onCleanup(@() delete(progress));
        runner.addPlugin(matlab.unittest.plugins.DiagnosticsRecordingPlugin);
        runner.addPlugin(progress);
        if opts.Coverage
            runner.addPlugin(coveragePlugin(artifacts.Folder));
        end
        environmentCleanup = applyEnvironment(group.Environment);
        results{k} = runner.run(suite);
        delete(environmentCleanup);
        delete(cleanup);
    end
    failed = cellfun(@hasFailures, results);
    writeJUnit(fullfile(artifacts.Folder, "junit.xml"), results);
    writeJson(fullfile(artifacts.Folder, "summary.json"), ...
        summaryPayload(compiledPlan, results, failed));
    if any(failed)
        error("LabKit:TestRun:Failure", "One or more LabKit specifications failed.");
    end
    result = struct("Plan", compiledPlan, "Results", {results}, ...
        "RunName", opts.RunName, "ArtifactsRoot", opts.ArtifactsRoot, ...
        "Artifacts", artifacts);
    delete(artifactEnvironment);
end

function reportPlanScope(compiledPlan)
if compiledPlan.Scope == "full-profile"
    fprintf("LabKit full profile validation\n");
    fprintf("Selected evidence: %d identities\n", numel(compiledPlan.Descriptors));
    fprintf("Purpose: complete catalog coverage for the selected environment/profile\n");
else
    fprintf("LabKit focused local validation\n");
    fprintf("Selected evidence: %d identities\n", numel(compiledPlan.Descriptors));
    fprintf("Purpose: rapid local feedback\n");
    fprintf("Merge safety: not established; full profiles run in CI\n");
end
for classification = compiledPlan.Classifications
    if classification.Kind == "ignored"
        fprintf("IGNORED PATH: %s (%s)\n", classification.Path, classification.Reason);
    end
end
end

function reportManualChecks(checks)
    for k = 1:numel(checks)
        fprintf("MANUAL CHECK (not automated evidence): %s\n", checks(k));
    end
end

function [compiledPlan, opts] = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkittest.run";
    p.addParameter("Plan", struct(), @isPlanOrEmpty);
    p.addParameter("RunName", "labkittest", @isTextScalar);
    p.addParameter("ArtifactsRoot", defaultArtifactsRoot(), @isTextScalar);
    p.addParameter("Coverage", false, @isLogicalScalar);
    p.KeepUnmatched = true;
    p.parse(varargin{:});
    opts = p.Results;
    if ~isempty(fieldnames(opts.Plan))
        if ~isempty(fieldnames(p.Unmatched))
            error("LabKit:TestRun:PlanWithSelectors", ...
                "A compiled Plan cannot be combined with selectors.");
        end
        compiledPlan = opts.Plan;
    else
        selectorArgs = unmatchedPairs(p.Unmatched);
        compiledPlan = labkittest.plan(selectorArgs{:});
    end
    opts.RunName = string(opts.RunName);
    opts.ArtifactsRoot = absolutePath(opts.ArtifactsRoot);
end

function pairs = unmatchedPairs(values)
    names = fieldnames(values);
    pairs = cell(1, 2 * numel(names));
    for k = 1:numel(names)
        pairs{2 * k - 1} = names{k};
        pairs{2 * k} = values.(names{k});
    end
end

function tf = isPlanOrEmpty(value)
    requiredFields = {'Descriptors', 'Groups', 'Reasons', 'Fallback', ...
        'Scope', 'Classifications', 'ManualChecks'};
    tf = isstruct(value) && (isempty(fieldnames(value)) || ...
        all(isfield(value, requiredFields)));
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isLogicalScalar(value)
    tf = islogical(value) && isscalar(value);
end

function value = absolutePath(value)
    value = string(value);
    if ispc
        absolute = ~isempty(regexp(char(value), "^[A-Za-z]:[\\\\/]|^[\\\\/]{2}", "once"));
    else
        absolute = startsWith(value, filesep);
    end
    if ~absolute
        value = string(fullfile(pwd, value));
    end
end

function root = defaultArtifactsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "artifacts", "runs");
end

function root = repositoryRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fileparts(fileparts(packageFolder));
end

function plugin = coveragePlugin(folder)
    html = fullfile(folder, "coverage-html");
    if exist(html, "dir") ~= 7
        mkdir(html);
    end
    formats = [ ...
        matlab.unittest.plugins.codecoverage.CoverageReport( ...
            html, "MainFile", "index.html"), ...
        matlab.unittest.plugins.codecoverage.CoberturaFormat( ...
            fullfile(folder, "coverage.xml"))];
    root = repositoryRoot();
    plugin = matlab.unittest.plugins.CodeCoveragePlugin.forFolder( ...
        {char(fullfile(root, "+labkit")), char(fullfile(root, "apps"))}, ...
        "IncludingSubfolders", true, "Producing", formats);
end

function tf = hasFailures(results)
    tf = any([results.Failed]) || any([results.Incomplete]);
end

function artifacts = createArtifacts(opts, compiledPlan)
    folder = fullfile(opts.ArtifactsRoot, sanitizedRunName(opts.RunName));
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
    artifacts = struct("Folder", string(folder));
    writeJson(fullfile(folder, "manifest.json"), struct( ...
        "runName", char(opts.RunName), ...
        "createdAt", char(datetime("now", "TimeZone", "UTC", ...
            "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")), ...
        "framework", "labkittest"));
    writeJson(fullfile(folder, "plan.json"), planPayload(compiledPlan));
end

function cleanup = exposeArtifactFolder(folder)
previous = getenv("LABKIT_TEST_ARTIFACT_FOLDER");
setenv("LABKIT_TEST_ARTIFACT_FOLDER", char(folder));
cleanup = onCleanup(@() setenv("LABKIT_TEST_ARTIFACT_FOLDER", previous));
end

function cleanup = applyEnvironment(environment)
    previous = getenv("LABKIT_GUI_TEST_MODE");
    previousVisible = get(groot, "DefaultFigureVisible");
    if environment == "hidden-gui"
        setenv("LABKIT_GUI_TEST_MODE", "hidden");
        set(groot, "DefaultFigureVisible", "off");
    end
    cleanup = onCleanup(@() restoreEnvironment(previous, previousVisible));
end

function restoreEnvironment(previous, previousVisible)
    setenv("LABKIT_GUI_TEST_MODE", previous);
    set(groot, "DefaultFigureVisible", previousVisible);
end

function payload = planPayload(compiledPlan)
    descriptors = compiledPlan.Descriptors;
    payload = struct( ...
        "reasons", {cellstr(compiledPlan.Reasons)}, ...
        "fallback", compiledPlan.Fallback, ...
        "scope", char(compiledPlan.Scope), ...
        "classifications", {arrayfun(@classificationPayload, compiledPlan.Classifications)}, ...
        "manualChecks", {cellstr(compiledPlan.ManualChecks)}, ...
        "tests", {arrayfun(@descriptorPayload, descriptors)});
end

function payload = classificationPayload(classification)
payload = struct( ...
    "path", char(classification.Path), ...
    "kind", char(classification.Kind), ...
    "role", char(classification.Role), ...
    "owner", char(classification.Owner), ...
    "reason", char(classification.Reason));
end

function payload = descriptorPayload(descriptor)
    payload = struct( ...
        "id", char(descriptor.Id), ...
        "owner", char(descriptor.Owner), ...
        "contract", char(descriptor.Contracts), ...
        "environment", char(descriptor.Environment));
end

function payload = summaryPayload(compiledPlan, results, failed)
    flattened = [results{:}];
    failedCount = 0;
    incompleteCount = 0;
    if ~isempty(flattened)
        failedCount = sum([flattened.Failed]);
        incompleteCount = sum([flattened.Incomplete]);
    end
    payload = struct( ...
        "tests", numel(flattened), ...
        "failed", failedCount, ...
        "incomplete", incompleteCount, ...
        "passed", ~any(failed), ...
        "fallback", compiledPlan.Fallback, ...
        "scope", char(compiledPlan.Scope));
end

function writeJson(file, payload)
    fid = fopen(file, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:TestRun:ArtifactWrite", ...
            "Could not write test artifact: %s", file);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", jsonencode(payload));
    clear cleanup
end

function writeJUnit(file, results)
    flattened = [results{:}];
    fid = fopen(file, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:TestRun:ArtifactWrite", ...
            "Could not write JUnit artifact: %s", file);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?>\n<testsuites>\n');
    for k = 1:numel(flattened)
        result = flattened(k);
        [className, methodName] = junitNames(result.Name);
        failed = logical(result.Failed);
        incomplete = logical(result.Incomplete);
        fprintf(fid, ['  <testsuite name="%s" tests="1" failures="%d" ' ...
            'errors="%d" time="%.9g">\n'], xmlText(className), failed, ...
            incomplete, resultSeconds(result.Duration));
        fprintf(fid, '    <testcase classname="%s" name="%s" time="%.9g"', ...
            xmlText(className), xmlText(methodName), resultSeconds(result.Duration));
        if ~failed && ~incomplete
            fprintf(fid, '/>\n');
        elseif failed
            [message, detail] = junitDiagnostic(result, "failure");
            fprintf(fid, '><failure message="%s">%s</failure></testcase>\n', ...
                xmlText(message), xmlText(detail));
        else
            [message, detail] = junitDiagnostic(result, "error");
            fprintf(fid, '><error message="%s">%s</error></testcase>\n', ...
                xmlText(message), xmlText(detail));
        end
        fprintf(fid, '  </testsuite>\n');
    end
    fprintf(fid, '</testsuites>\n');
    clear cleanup
end

function [message, detail] = junitDiagnostic(result, kind)
    fallback = "Test failed";
    if kind == "error"
        fallback = "Test incomplete";
    end
    message = fallback;
    detail = fallback;
    if ~isfield(result.Details, "DiagnosticRecord") || ...
            isempty(result.Details.DiagnosticRecord)
        return;
    end
    records = result.Details.DiagnosticRecord;
    if kind == "error"
        records = records.selectIncomplete();
    else
        records = records.selectFailed();
    end
    if isempty(records)
        return;
    end
    reports = string({records.Report});
    reports = reports(strlength(strtrim(reports)) > 0);
    if isempty(reports)
        return;
    end
    separator = string(newline) + string(newline);
    detail = strjoin(reports, separator);
    firstLine = extractBefore(detail + string(newline), string(newline));
    firstLine = regexprep(strtrim(firstLine), "\s+", " ");
    if strlength(firstLine) > 500
        firstLine = extractBefore(firstLine, 501);
    end
    if strlength(firstLine) > 0
        message = firstLine;
    end
end

function [className, methodName] = junitNames(identity)
    parts = split(string(identity), "/");
    className = parts(1);
    methodName = strjoin(parts(2:end), "/");
end

function value = resultSeconds(durationValue)
    if isduration(durationValue)
        value = seconds(durationValue);
    else
        value = double(durationValue);
    end
end

function value = xmlText(value)
    value = string(value);
    value = replace(value, "&", "&amp;");
    value = replace(value, string(char(34)), "&quot;");
    value = replace(value, "<", "&lt;");
    value = char(replace(value, ">", "&gt;"));
end

function name = sanitizedRunName(value)
    name = regexprep(string(value), "[^A-Za-z0-9_.-]+", "_");
    name = regexprep(name, "^_+|_+$", "");
    if strlength(name) == 0
        name = "run";
    end
end
