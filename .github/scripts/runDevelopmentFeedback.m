function result = runDevelopmentFeedback(changedPathsFile, runName)
%RUNDEVELOPMENTFEEDBACK Run focused evidence for a branch push or pull request.
% The workflow owns range discovery. This adapter passes its exact path list
% to the existing semantic planner so a clean checkout never falls back to
% inspecting only HEAD^..HEAD.
arguments
    changedPathsFile (1, 1) string
    runName (1, 1) string = "development-feedback"
end
if exist(changedPathsFile, "file") ~= 2
    error("LabKit:DevelopmentFeedback:MissingChangedPaths", ...
        "Development feedback changed-path input does not exist.");
end
paths = strip(string(splitlines(fileread(changedPathsFile))));
paths = paths(strlength(paths) > 0).';
if isempty(paths)
    fprintf("Development feedback: no changed paths in the selected range.\n");
    result = [];
    return;
end
repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(repositoryRoot, "tests"));
cleanup = onCleanup(@() rmpath(fullfile(repositoryRoot, "tests")));
result = labkittest.run( ...
    Profile="changed", ChangedPaths=paths, ...
    RunName=runName, ...
    ArtifactsRoot=fullfile(repositoryRoot, "artifacts", "test-results"));
clear cleanup
end
