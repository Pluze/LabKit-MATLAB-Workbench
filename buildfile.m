function plan = buildfile
%BUILDFILE LabKit build and validation entry points.
%
% User-facing commands:
%   buildtool changed       conservative validation routed from the git diff
%   buildtool changedFast   faster local iteration routed from the git diff
%   buildtool baseMatlab    verify source workflows require only base MATLAB
%   buildtool headless      full non-GUI validation
%   buildtool gui           full automated GUI validation with hidden figures
%   buildtool coverage      coverage report for manual or scheduled runs
%   buildtool listTasks     print the public task catalog
%
% The buildfile deliberately stays thin. It exposes stable tasks and passes
% suite/tag choices to tests/runLabKitTests.m. Ownership-specific routing
% lives in the runner and changed-file planner, derived from
% tests/cases/<kind>/<owner>/<area>/ paths.

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

function changedFastTask(~)
    runCatalogTask("changedFast");
end

function baseMatlabTask(~)
    previous = getenv("LABKIT_VERIFY_TOOLBOX_PRODUCTS");
    setenv("LABKIT_VERIFY_TOOLBOX_PRODUCTS", "1");
    cleanup = onCleanup(@() setenv("LABKIT_VERIFY_TOOLBOX_PRODUCTS", previous));
    runCatalogTask("baseMatlab");
    clear cleanup
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
        taskSpec("changedFast", "Run fast changed-file validation for local iteration.", "Plan", "changedFast", "HtmlReport", false), ...
        taskSpec("baseMatlab", "Verify source workflows require only base MATLAB.", "Suites", "project/hygiene", "Tests", "ToolboxDependencyGuardrailTest", "HtmlReport", false), ...
        taskSpec("headless", "Run the full non-GUI validation set.", "IncludeGui", false), ...
        taskSpec("gui", "Run noninteractive GUI launch, layout, and gesture checks.", "Suites", "gui", "IncludeGui", true, "GuiMode", "hidden"), ...
        taskSpec("coverage", "Run official tests with coverage artifacts.", "Tags", ["Unit", "Integration"], "IncludeCoverage", true), ...
        taskSpec("listTasks", "List official LabKit build tasks.", "RunTests", false)];
end

function spec = taskSpec(name, description, varargin)
    p = inputParser;
    p.FunctionName = "taskSpec";
    p.addParameter("RunTests", true, @isLogicalScalar);
    p.addParameter("Suites", strings(1, 0), @isStringLikeList);
    p.addParameter("Tests", strings(1, 0), @isStringLikeList);
    p.addParameter("Plan", "", @isTextScalar);
    p.addParameter("Tags", strings(1, 0), @isStringLikeList);
    p.addParameter("IncludeGui", [], @isEmptyOrLogicalScalar);
    p.addParameter("IncludeCoverage", [], @isEmptyOrLogicalScalar);
    p.addParameter("HtmlReport", [], @isEmptyOrLogicalScalar);
    p.addParameter("GuiMode", "", @isTextScalar);
    p.addParameter("Required", true, @isLogicalScalar);
    p.addParameter("Visibility", "public", @isTextScalar);
    p.parse(varargin{:});

    runTests = logical(p.Results.RunTests);
    spec = struct( ...
        "Name", string(name), ...
        "Description", string(description), ...
        "Visibility", string(p.Results.Visibility), ...
        "RunTests", runTests, ...
        "Suites", normalizeTextList(p.Results.Suites), ...
        "Tests", normalizeTextList(p.Results.Tests), ...
        "Plan", string(p.Results.Plan), ...
        "Tags", normalizeTextList(p.Results.Tags), ...
        "IncludeGui", normalizeOptionalLogical(p.Results.IncludeGui), ...
        "IncludeCoverage", normalizeOptionalLogical(p.Results.IncludeCoverage), ...
        "HtmlReport", normalizeOptionalLogical(p.Results.HtmlReport), ...
        "GuiMode", string(p.Results.GuiMode), ...
        "Required", runTests && logical(p.Results.Required));
end

function runCatalogTask(runName)
    spec = findTaskSpec(runName);
    if ~spec.RunTests
        error("LabKit:Build:CatalogTaskNotRunnable", ...
            "Build task %s is not a test-runner task.", runName);
    end

    args = taskRunArguments(spec);
    if runWithInternalShards(spec, args)
        return;
    end
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
    if ~isempty(spec.Tests)
        args = [args, {"Tests", spec.Tests}];
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
    if strlength(spec.GuiMode) > 0
        args = [args, {"GuiMode", spec.GuiMode}];
    end
end

function runBuildTests(runName, varargin)
    root = fileparts(mfilename("fullpath"));
    addpath(fullfile(root, "tests"));
    runLabKitTests(varargin{:}, ...
        "RunName", runName, ...
        "ArtifactsRoot", fullfile(root, "artifacts"));
end

function handled = runWithInternalShards(spec, args)
    handled = false;
    if ~any(spec.Name == ["headless", "gui"]) || isInternalShardWorker() || ...
            isGitHubActions() || ispc
        return;
    end

    root = fileparts(mfilename("fullpath"));
    addpath(fullfile(root, "tests"));
    try
        probe = runLabKitTests(args{:}, ...
            "ListOnly", true, ...
            "FailIfNoTests", false, ...
            "RunName", spec.Name + "_probe", ...
            "ArtifactsRoot", fullfile(root, "artifacts"));
    catch
        return;
    end

    shardPlan = labkitInternalShardPlan(spec.Name, probe.count);
    if shardPlan.Count <= 1
        return;
    end

    fprintf(['LabKit shard probe: %d test(s) matched; running %d ' ...
        'internal %s shard(s).\n'], probe.count, shardPlan.Count, ...
        shardPlan.ExecutionLabel);
    runInternalShardWorkers(root, spec.Name, args, shardPlan.Count, ...
        shardPlan.RunInParallel);
    handled = true;
end

function tf = isInternalShardWorker()
    tf = string(getenv("LABKIT_INTERNAL_SHARD_WORKER")) == "1";
end

function tf = isGitHubActions()
    tf = string(getenv("GITHUB_ACTIONS")) == "true";
end

function runInternalShardWorkers(root, runName, args, shardCount, runInParallel)
    logsRoot = fullfile(root, "artifacts", "logs", runName + "-orchestrator");
    ensureFolder(logsRoot);
    scriptPath = fullfile(logsRoot, "run_shards.sh");
    fid = fopen(scriptPath, "w");
    if fid < 0
        error("LabKit:Build:ShardScript", "Could not create shard script.");
    end
    cleanup = onCleanup(@() fclose(fid));

    fprintf(fid, "#!/bin/sh\n");
    fprintf(fid, "status=0\n");
    matlabExe = fullfile(matlabroot, "bin", "matlab");
    for k = 0:(shardCount - 1)
        shardName = sprintf("%s-shard-%d", runName, k);
        workerLog = fullfile(logsRoot, shardName + ".log");
        batch = shardBatchCommand(root, args, shardName, shardCount, k);
        if runInParallel
            fprintf(fid, "LABKIT_INTERNAL_SHARD_WORKER=1 %s -batch %s > %s 2>&1 &\n", ...
                shellQuote(matlabExe), shellQuote(batch), shellQuote(workerLog));
            fprintf(fid, "pids_%d=$!\n", k + 1);
        else
            fprintf(fid, "LABKIT_INTERNAL_SHARD_WORKER=1 %s -batch %s > %s 2>&1 || status=1\n", ...
                shellQuote(matlabExe), shellQuote(batch), shellQuote(workerLog));
        end
    end
    if runInParallel
        for k = 1:shardCount
            fprintf(fid, "wait $pids_%d || status=1\n", k);
        end
    end
    fprintf(fid, 'if [ "$status" -ne 0 ]; then\n');
    fprintf(fid, "  cat %s/*.log\n", shellQuote(logsRoot));
    fprintf(fid, "fi\n");
    fprintf(fid, "exit $status\n");
    clear cleanup;
    fileattrib(scriptPath, "+x");

    [status, output] = system(shellQuote(scriptPath));
    if strlength(string(output)) > 0
        fprintf("%s", output);
    end
    if status ~= 0
        error("LabKit:Build:ShardFailure", ...
            "One or more internal test shards failed. Logs: %s", logsRoot);
    end
end

function batch = shardBatchCommand(root, args, runName, shardCount, shardIndex)
    shardArgs = [args, { ...
        "ShardCount", shardCount, ...
        "ShardIndex", shardIndex, ...
        "RunName", string(runName), ...
        "ArtifactsRoot", fullfile(root, "artifacts")}];
    batch = "addpath(" + matlabLiteral(fullfile(root, "tests")) + "); " + ...
        "runLabKitTests(" + matlabArgumentList(shardArgs) + ");";
end

function text = matlabArgumentList(args)
    parts = strings(1, numel(args));
    for k = 1:numel(args)
        parts(k) = matlabLiteral(args{k});
    end
    text = strjoin(parts, ", ");
end

function text = matlabLiteral(value)
    if islogical(value)
        if value
            text = "true";
        else
            text = "false";
        end
    elseif isnumeric(value)
        text = string(value);
    else
        value = string(value);
        if isscalar(value)
            text = """" + replace(value, """", """""") + """";
        else
            quoted = """" + replace(value, """", """""") + """";
            text = "[" + strjoin(quoted, ", ") + "]";
        end
    end
end

function text = shellQuote(value)
    text = "'" + replace(string(value), "'", "'\''") + "'";
end

function ensureFolder(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function printTaskCatalog(catalog)
    fprintf("LabKit build tasks:\n");
    for k = 1:numel(catalog)
        if catalog(k).Visibility ~= "public"
            continue;
        end
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
