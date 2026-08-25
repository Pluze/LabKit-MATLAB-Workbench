classdef StyleFileCallbacksSpec < matlab.unittest.TestCase
    % STYLEFILECALLBACKSSPEC Regression: reusable style files must round-trip through validated callback state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesStyleFileCallbacks(testCase)
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, "s"));
            path = fullfile(folder, "style.mat");
            state = stateFixture();
            state.project.parameters.style.tickFontSize = 18.5;
            exportContext = labkittest.createCallbackContext(struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(path), ...
                "log", @ignoreLog));

            state = figure_studio.styleLibrary.exportStyle( ...
                state, exportContext);
            state.project.parameters.style.tickFontSize = 9;
            importContext = labkittest.createCallbackContext(struct( ...
                "chooseInputFile", @(~, ~) labkit.app.dialog.Choice(path), ...
                "alert", @ignoreAlert, "log", @ignoreLog));
            state = figure_studio.styleLibrary.importStyle( ...
                state, importContext);

            testCase.verifyTrue(isfile(path));
            testCase.verifyEqual(state.project.parameters.preset, ...
                "Custom imported");
            testCase.verifyEqual( ...
                state.project.parameters.style.tickFontSize, 18.5);
            testCase.verifyEqual(state.session.cache.viewRevision, 2);
            clear cleanup
        end
    end
end

function state = stateFixture()
project = figure_studio.initialData();
state = struct("project", project, "session", struct( ...
    "workflow", struct("status", ""), ...
    "cache", struct("viewRevision", 1)));
end

function ignoreLog(varargin)
end

function ignoreAlert(varargin)
end
