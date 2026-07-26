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
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", source, 1);
            axesValue = findall(figureValue, "Tag", "plot.main");
            units = eis.impedanceDisplay.catalog();
            runtime.applyControlValue("impedanceUnit", units.choices(4));
            runtime.applyControlValue("showMarkers", false);
            runtime.invokeAction("exportPlot");

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNotEmpty(axesValue.Children);
            testCase.verifySubstring(string(axesValue.XLabel.String), ...
                units.choices(4));
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
