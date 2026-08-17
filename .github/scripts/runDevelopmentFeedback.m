function result = runDevelopmentFeedback(changedPathsFile)
%RUNDEVELOPMENTFEEDBACK Run focused evidence for one complete pushed range.
% The workflow owns range discovery. This adapter passes its exact path list
% to the existing semantic planner so a clean checkout never falls back to
% inspecting only HEAD^..HEAD.
arguments
    changedPathsFile (1, 1) string
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
    RunName="development-feedback", ...
    ArtifactsRoot=fullfile(repositoryRoot, "artifacts", "test-results"));
clear cleanup
end
