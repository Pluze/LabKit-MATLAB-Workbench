function plan = buildfile
%BUILDFILE Stable LabKit validation and documentation entry points.
%   buildtool changedFast  final local pre-PR review evidence
%   buildtool headless     every headless specification
%   buildtool apps         hidden-GUI and path-isolated App evidence
%   buildtool codecheck    require zero analysis and runtime-boundary findings
%   buildtool docs         render documentation
%   buildtool docsCheck    verify generated documentation

plan = buildplan(localfunctions);
plan.DefaultTasks = "changedFast";
plan("changedFast").Dependencies = ["codecheck", "docsCheck"];
plan("changedFast").Description = "Run the complete local pre-PR gate with focused tests, codecheck, and docsCheck";
plan("headless").Description = "Run all non-GUI product, SDK, persistence, and export specifications";
plan("apps").Description = "Run hidden native-App workflows and reset-path App isolation evidence";
plan("codecheck").Description = "Require zero code, compatibility, suppression, and runtime findings";
plan("docs").Description = "Regenerate the path-owned documentation site";
plan("docsCheck").Description = "Verify generated documentation matches its source contracts";
end

function changedFastTask(~)
runTests("changed");
end

function headlessTask(~)
runTests("headless");
end

function appsTask(~)
runTests("apps");
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
executeDocumentation(false);
end

function docsCheckTask(~)
executeDocumentation(true);
end

function runTests(profile)
root = fileparts(mfilename("fullpath"));
addpath(fullfile(root, "tests"));
labkittest.run(Profile=profile, RunName=profile, ...
    ArtifactsRoot=fullfile(root, "artifacts", "test-results"));
end

function executeDocumentation(checkOnly)
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
