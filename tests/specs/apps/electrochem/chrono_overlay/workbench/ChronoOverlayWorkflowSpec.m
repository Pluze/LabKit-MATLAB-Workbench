classdef ChronoOverlayWorkflowSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYWORKFLOWSPEC Specify loading, plot materialization, and export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsAlignsExportsAndRestoresAChronoTrace(testCase)
            source = testfixtures.dtaFixturePath( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "overlay.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = chrono_overlay.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, [], backend, labkit.app.diagnostic.Options(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", source, 1);
            voltage = findall(figureValue, "Tag", "overlayPlots.voltage");
            current = findall(figureValue, "Tag", "overlayPlots.current");
            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNotEmpty(voltage.Children);
            testCase.verifyNotEmpty(current.Children);
            runtime.invokeAction("exportCurves");
            testCase.verifyTrue(isfile(output));
            testCase.verifyTrue(isfile(fullfile(folder, "labkit_result.json")));

            saved = fullfile(folder, "overlay-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.applyFileSelection("files", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(saved);
            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            clear cleanup
        end
    end
end
