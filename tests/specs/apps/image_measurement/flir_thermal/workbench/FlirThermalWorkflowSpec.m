classdef FlirThermalWorkflowSpec < matlab.unittest.TestCase
    %FLIRTHERMALWORKFLOWSPEC Specify radiometric display, readings, export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function displaysMeasuresExportsAndRestoresSyntheticRadiometricImages(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = testfixtures.flir_thermal.project(string(folder));
            sourcePaths = labkit.app.source.paths(project.inputs.sources);
            backend = struct("chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = flir_thermal.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, project, backend, ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("thermalFiles", sourcePaths, 2);
            runtime.invokeAction("previousImage");
            runtime.invokeAction("nextImage");
            runtime.applyControlValue("palette", "iron");
            runtime.applyControlValue("colorMapping", "Gamma");
            runtime.applyControlValue("gammaValue", 1.6);
            presets = string( ...
                flir_thermal.thermalPreview.presentationData.rangePresetItems());
            runtime.applyControlValue("rangePreset", presets(2));
            runtime.invokeAction("perImageRange");
            runtime.invokeAction("autoRange");
            range = runtime.State.session.cache.currentItem.displayRange;
            runtime.applyControlValue("temperatureMin", range(1) + .1);
            runtime.applyControlValue("temperatureMax", range(2) - .1);
            runtime.invokeAction("roundRange");
            runtime.invokeAction("groupRange");
            runtime.applyInteraction("temperatureReading", "backgroundPressed", [1 1]);
            runtime.invokeAction("roiHotMode");
            runtime.applyInteraction("temperatureReading", "interactionChanged", [1 1 3 3]);
            runtime.invokeAction("roiMeanMode");
            runtime.applyInteraction("temperatureReading", "interactionChanged", [1 1 3 3]);
            runtime.invokeAction("roiColdMode");
            runtime.applyInteraction("temperatureReading", "interactionChanged", [1 1 3 3]);
            runtime.applyControlValue("exportFormat", "TIFF");
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportCurrent");
            runtime.invokeAction("exportAll");

            item = runtime.State.session.cache.currentItem;
            testCase.verifyTrue(isfinite(item.manualPoint.temperatureC));
            testCase.verifyTrue(isfinite(item.roiHotSpot.temperatureC));
            testCase.verifyTrue(isfinite(item.roiMean.temperatureC));
            testCase.verifyTrue(isfinite(item.roiColdSpot.temperatureC));
            testCase.verifyEqual(runtime.State.project.parameters.exportFormat, ...
                "TIFF");
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.thermalImage").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "flir_thermal_manifest.csv")));
            testCase.verifyTrue(isfile(runtime.State.project.results.resultManifestPath));
            clear cleanup
        end
    end
end
