function plan = buildfile
%BUILDFILE LabKit build and validation entry points.

    plan = buildplan(localfunctions);
    plan.DefaultTasks = "headless";

    catalog = taskCatalog();
    for k = 1:numel(catalog)
        plan(catalog(k).Name).Description = catalog(k).Description;
    end
end

function changedTask(~)
    runCatalogTask("changed");
end

function headlessTask(~)
    runCatalogTask("headless");
end

function guiTask(~)
    runCatalogTask("gui");
end

function coverageTask(~)
    runCatalogTask("coverage");
end

function listTasksTask(~)
    printTaskCatalog(taskCatalog());
end

function catalog = taskCatalog()
    catalog = [ ...
        taskSpec("changed", "Run conservative changed-file validation.", "Plan", "changed", "HtmlReport", false), ...
        taskSpec("headless", "Run the full non-GUI validation set.", "IncludeGui", false), ...
        taskSpec("gui", "Run noninteractive GUI launch, layout, and gesture checks.", "Suites", "gui", "IncludeGui", true), ...
        taskSpec("coverage", "Run official tests with coverage artifacts.", "Tags", ["Unit", "Integration"], "IncludeCoverage", true), ...
        taskSpec("listTasks", "List official LabKit build tasks.", "RunTests", false)];
end

function spec = taskSpec(name, description, varargin)
    p = inputParser;
    p.FunctionName = "taskSpec";
    p.addParameter("RunTests", true, @isLogicalScalar);
    p.addParameter("Suites", strings(1, 0), @isStringLikeList);
    p.addParameter("Plan", "", @isTextScalar);
    p.addParameter("Tags", strings(1, 0), @isStringLikeList);
    p.addParameter("IncludeGui", [], @isEmptyOrLogicalScalar);
    p.addParameter("IncludeCoverage", [], @isEmptyOrLogicalScalar);
    p.addParameter("HtmlReport", [], @isEmptyOrLogicalScalar);
    p.addParameter("Required", true, @isLogicalScalar);
    p.parse(varargin{:});

    runTests = logical(p.Results.RunTests);
    spec = struct( ...
        "Name", string(name), ...
        "Description", string(description), ...
        "RunTests", runTests, ...
        "Suites", normalizeTextList(p.Results.Suites), ...
        "Plan", string(p.Results.Plan), ...
        "Tags", normalizeTextList(p.Results.Tags), ...
        "IncludeGui", normalizeOptionalLogical(p.Results.IncludeGui), ...
        "IncludeCoverage", normalizeOptionalLogical(p.Results.IncludeCoverage), ...
        "HtmlReport", normalizeOptionalLogical(p.Results.HtmlReport), ...
        "Required", runTests && logical(p.Results.Required));
end

function runCatalogTask(runName)
    spec = findTaskSpec(runName);
    if ~spec.RunTests
        error("LabKit:Build:CatalogTaskNotRunnable", ...
            "Build task %s is not a test-runner task.", runName);
    end

    args = taskRunArguments(spec);
    runBuildTests(spec.Name, args{:});
end

function spec = findTaskSpec(runName)
    catalog = taskCatalog();
    matches = [catalog.Name] == string(runName);
    if ~any(matches)
        error("LabKit:Build:UnknownCatalogTask", ...
            "Unknown build task catalog entry: %s.", runName);
    end
    spec = catalog(matches);
end

function args = taskRunArguments(spec)
    args = {};
    if ~isempty(spec.Suites)
        args = [args, {"Suites", spec.Suites}];
    end
    if strlength(spec.Plan) > 0
        args = [args, {"Plan", spec.Plan}];
    end
    if ~isempty(spec.Tags)
        args = [args, {"Tags", spec.Tags}];
    end
    if ~isempty(spec.IncludeGui)
        args = [args, {"IncludeGui", spec.IncludeGui}];
    end
    if ~isempty(spec.IncludeCoverage)
        args = [args, {"IncludeCoverage", spec.IncludeCoverage}];
    end
    if ~isempty(spec.HtmlReport)
        args = [args, {"HtmlReport", spec.HtmlReport}];
    end
end

function runBuildTests(runName, varargin)
    root = fileparts(mfilename("fullpath"));
    addpath(fullfile(root, "tests"));
    runLabKitTests(varargin{:}, ...
        "RunName", runName, ...
        "ArtifactsRoot", fullfile(root, "artifacts"));
end

function printTaskCatalog(catalog)
    fprintf("LabKit build tasks:\n");
    for k = 1:numel(catalog)
        fprintf("  %-30s %s\n", catalog(k).Name, catalog(k).Description);
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

function value = normalizeOptionalLogical(value)
    if isempty(value)
        return;
    end
    value = logical(value);
end

function tf = isStringLikeList(value)
    tf = ischar(value) || isstring(value) || iscellstr(value);
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isEmptyOrLogicalScalar(value)
    tf = isempty(value) || isLogicalScalar(value);
end
