function root = setupLabKitTestPath()
%SETUPLABKITTESTPATH Add repo and shared test paths for official tests.
%
% Expected caller: tests/runLabKitTests.m and official matlab.unittest tests.
% Side effects: adds the repository root, tests, tests/runner, and
% tests/shared to the MATLAB path, then runs startup_labkit.

    root = labkitRepoRoot();
    addpath(root);
    addpath(fullfile(root, "tests"));
    addpath(fullfile(root, "tests", "runner"));
    addpath(fullfile(root, "tests", "shared"));
    startup_labkit(false);
end
