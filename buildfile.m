function plan = buildfile
%BUILDFILE Stable LabKit validation and documentation entry points.
%   buildtool changedFast  final local pre-PR review evidence
%   buildtool headless     every headless specification
%   buildtool gui          every hidden-GUI specification
%   buildtool journeys     every App-owned native user workflow
%   buildtool isolated     every path-isolated specification
%   buildtool coverage     headless and App-journey coverage artifacts
%   buildtool codecheck    require zero analysis and runtime-boundary findings
%   buildtool docs         render documentation
%   buildtool docsCheck    verify generated documentation

plan = buildplan(localfunctions);
plan.DefaultTasks = "headless";
plan("changedFast").Description = "Run focused final pre-PR specifications selected from the local diff";
plan("headless").Description = "Run all non-GUI product, SDK, persistence, and export specifications";
plan("gui").Description = "Run hidden native-App, callback, graphics, and export workflows";
plan("journeys").Description = "Run every App-owned native user workflow";
plan("isolated").Description = "Start every public App from a reset path to detect undeclared dependencies";
plan("coverage").Description = "Measure headless logic and native App-journey source coverage separately";
plan("codecheck").Description = "Require zero code, compatibility, suppression, and runtime findings";
plan("docs").Description = "Regenerate the path-owned documentation site";
plan("docsCheck").Description = "Verify generated documentation matches its source contracts";
plan("listTasks").Description = "List the stable LabKit build entry points";
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

function journeysTask(~)
runTests("journeys");
end

function isolatedTask(~)
runTests("isolated");
end

function coverageTask(~)
runTests("coverage", Coverage=true);
end

function codecheckTask(~)
root = fileparts(mfilename("fullpath"));
toolFolder = fullfile(root, "tools", "codecheck");
addpath(toolFolder);
cleanup = onCleanup(@() rmpath(toolFolder));
runCodecheckReport(root, "OpenReport", false, ...
    "WriteArtifacts", false, "RequireClean", true);
delete(cleanup);
end

function docsTask(~)
runDocumentationTask(false);
end

function docsCheckTask(~)
runDocumentationTask(true);
end

function listTasksTask(~)
fprintf("LabKit build tasks:\n");
fprintf("  changedFast  final local pre-PR review evidence\n");
fprintf("  headless     every headless specification\n");
fprintf("  gui          every hidden-GUI specification\n");
fprintf("  journeys     every App-owned native user workflow\n");
fprintf("  isolated     every path-isolated specification\n");
fprintf("  coverage     separate headless and native App-journey coverage artifacts\n");
fprintf("  codecheck    require zero analysis and runtime-boundary findings\n");
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
    result = checkLabKitDocs(fullfile(root, "docs"));
    fprintf("LabKit documentation is deterministic: %d generated file(s).\n", ...
        result.comparedFileCount);
else
    result = renderLabKitDocs(fullfile(root, "docs"), fullfile(root, "site"));
    fprintf("Generated %d narrative page(s) and %d API reference page(s) in %s.\n", ...
        result.pageCount, result.apiCount, result.outputRoot);
end
clear cleanup
end
