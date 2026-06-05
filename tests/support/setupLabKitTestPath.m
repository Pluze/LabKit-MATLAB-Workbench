function root = setupLabKitTestPath()
%SETUPLABKITTESTPATH Add repo and test support paths for official tests.
%
% Expected caller: tests/runLabKitTests.m and official matlab.unittest tests.
% Side effects: adds the repository root, tests, tests/support, and
% tests/helpers to the MATLAB path, then runs startup_labkit.

    root = labkitRepoRoot();
    addpath(root);
    addpath(fullfile(root, "tests"));
    addpath(fullfile(root, "tests", "support"));
    addpath(fullfile(root, "tests", "helpers"));
    startup_labkit();
end
