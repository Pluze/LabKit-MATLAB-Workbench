classdef FlirThermalWorkflowSpec < matlab.unittest.TestCase
    %FLIRTHERMALWORKFLOWSPEC Specify radiometric display, readings, export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function displaysMeasuresExportsAndRestoresSyntheticRadiometricImages(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = flir_thermal.syntheticInputs.writeSamplePack(context);
            backend = struct("chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = flir_thermal.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, pack.InitialProject, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.invokeAction("previousImage");
            runtime.invokeAction("nextImage");
            runtime.applyControlValue("palette", "iron");
            runtime.applyControlValue("colorMapping", "Gamma");
            runtime.applyControlValue("gammaValue", 1.6);
            runtime.invokeAction("groupRange");
            runtime.applyInteraction("temperatureReading", "backgroundPressed", [1 1]);
            runtime.invokeAction("roiHotMode");
            runtime.applyInteraction("temperatureReading", "interactionChanged", [1 1 3 3]);
            runtime.invokeAction("roiMeanMode");
            runtime.applyInteraction("temperatureReading", "interactionChanged", [1 1 3 3]);
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportAll");

            item = runtime.State.session.cache.currentItem;
            testCase.verifyTrue(isfinite(item.manualPoint.temperatureC));
            testCase.verifyTrue(isfinite(item.roiHotSpot.temperatureC));
            testCase.verifyTrue(isfinite(item.roiMean.temperatureC));
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.thermalImage").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "flir_thermal_manifest.csv")));
            testCase.verifyTrue(isfile(runtime.State.project.results.resultManifestPath));
            saved = fullfile(folder, "flir-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.restoreProject(saved);
            testCase.verifyNotEmpty(runtime.State.session.cache.currentItem.temperatureC);
            clear cleanup
        end
    end
end
