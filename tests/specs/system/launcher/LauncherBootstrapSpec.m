classdef LauncherBootstrapSpec < matlab.unittest.TestCase
    % LAUNCHERBOOTSTRAPSPEC Regression: repair bootstrap must remain self-contained while recording a minimal session.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function listsAppsWithoutTheSdkOnPath(testCase)
            root = labkittest.setup();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            copyfile(fullfile(root, "labkit_launcher.m"), folder);
            previousPath = path;
            cleanup = onCleanup(@() restorePath(previousPath));
            addpath(folder, "-begin");
            clear labkit_launcher

            listing = labkit_launcher("list");

            testCase.verifyClass(listing, "table");
            testCase.verifyEqual(string(which("labkit_launcher")), ...
                string(fullfile(folder, "labkit_launcher.m")));
            clear cleanup
        end
    end
end

function restorePath(previousPath)
clear labkit_launcher
path(previousPath);
end
