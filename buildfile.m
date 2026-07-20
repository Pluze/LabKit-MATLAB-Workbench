function plan = buildfile
%BUILDFILE LabKit build and validation entry points.
%
% User-facing commands:
%   buildtool changed       conservative validation routed from the git diff
%   buildtool changedFast   faster local iteration routed from the git diff
%   buildtool docs          rebuild the tracked static documentation site
%   buildtool docsCheck     verify the tracked site matches its sources
%   buildtool headless      full non-GUI validation
%   buildtool gui           full automated GUI validation with hidden figures
%   buildtool coverage      coverage report for manual or scheduled runs
%   buildtool listTasks     print the public task catalog
%
% The buildfile deliberately stays thin. It exposes stable tasks and passes
% suite/tag choices to tests/runLabKitTests.m. Ownership-specific routing
% lives in the runner and changed-file planner, derived from
% tests/cases/<kind>/<owner>/<area>/ paths.

    root = fileparts(mfilename("fullpath"));
    addpath(fullfile(root, "tests", "runner"));
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

function docsTask(~)
    runDocumentationTask(false);
end

function docsCheckTask(~)
    runDocumentationTask(true);
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
    catalog = labkitBuildTaskCatalog();
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

function runDocumentationTask(checkOnly)
    root = fileparts(mfilename("fullpath"));
    toolFolder = fullfile(root, "tools", "docs");
    addpath(toolFolder);
    cleanup = onCleanup(@() rmpath(toolFolder));
    if checkOnly
        result = checkLabKitDocs(fullfile(root, "docs"), fullfile(root, "site"));
        fprintf("LabKit documentation is current: %d generated file(s).\n", ...
            result.comparedFileCount);
    else
        result = renderLabKitDocs(fullfile(root, "docs"), fullfile(root, "site"));
        fprintf("Generated %d narrative page(s) and %d API reference page(s) in %s.\n", ...
            result.pageCount, result.apiCount, result.outputRoot);
    end
    clear cleanup
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
