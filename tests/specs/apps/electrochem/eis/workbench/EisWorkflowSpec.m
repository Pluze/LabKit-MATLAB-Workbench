classdef EisWorkflowSpec < matlab.unittest.TestCase
    %EISWORKFLOWSPEC Specify EIS file loading, plot materialization, and export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsPlotsExportsAndRestoresAnEisFile(testCase)
            source = testfixtures.dtaFixturePath("eis_potentiostatic_zcurve.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "eis.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                eis.definition(), [], backend);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", source, 1);
            axesValue = findall(figureValue, "Tag", "plot.main");
            runtime.applyControlValue("showMarkers", false);
            runtime.invokeAction("exportPlot");

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNotEmpty(axesValue.Children);
            testCase.verifyTrue(isfile(output));
            testCase.verifyTrue(isfile(fullfile(folder, "labkit_result.json")));
            saved = fullfile(folder, "eis-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.applyFileSelection("files", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(saved);
            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            clear cleanup
        end
    end
end
