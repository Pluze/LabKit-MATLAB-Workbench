function plan = buildfile
%BUILDFILE Stable LabKit validation and documentation entry points.
%   buildtool changedFast  local semantic pre-commit evidence
%   buildtool headless     every headless specification
%   buildtool gui          every hidden-GUI specification
%   buildtool isolated     every isolated-process specification
%   buildtool coverage     headless specifications with coverage artifacts
%   buildtool docs         render documentation
%   buildtool docsCheck    verify generated documentation

plan = buildplan(localfunctions);
plan.DefaultTasks = "headless";
end

function changedFastTask(~)
runTests("changed");
end

function headlessTask(~)
runTests("headless");
end

function guiTask(~)
runTests("gui");
end

function isolatedTask(~)
runTests("isolated");
end

function coverageTask(~)
runTests("coverage", Coverage=true);
end

function docsTask(~)
runDocumentationTask(false);
end

function docsCheckTask(~)
runDocumentationTask(true);
end

function listTasksTask(~)
fprintf("LabKit build tasks:\n");
fprintf("  changedFast  local semantic pre-commit evidence\n");
fprintf("  headless     every headless specification\n");
fprintf("  gui          every hidden-GUI specification\n");
fprintf("  isolated     every isolated-process specification\n");
fprintf("  coverage     headless specifications with coverage artifacts\n");
fprintf("  docs         render documentation\n");
fprintf("  docsCheck    verify generated documentation\n");
end

function runTests(profile, options)
arguments
    profile (1,1) string
    options.Coverage (1,1) logical = false
end
root = fileparts(mfilename("fullpath"));
addpath(fullfile(root, "tests"));
labkittest.run(Profile=profile, RunName=profile, ...
    ArtifactsRoot=fullfile(root, "artifacts", "test-results"), ...
    Coverage=options.Coverage);
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
