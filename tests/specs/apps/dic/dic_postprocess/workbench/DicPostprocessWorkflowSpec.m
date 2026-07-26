classdef DicPostprocessWorkflowSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSWORKFLOWSPEC Specify DIC overlay generation and exports.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function generatesExportsAndRestoresSyntheticDicOutputs(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            matPath = fullfile(folder, "synthetic_dic.mat");
            referencePath = fullfile(folder, "reference.png");
            maskPath = fullfile(folder, "mask.png");
            summaryPath = fullfile(folder, "strain_summary.csv");
            writeInputs(matPath, referencePath, maskPath);
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(summaryPath), ...
                "alert", @(~, ~) []);
            definition = dic_postprocess.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("matFile", string(matPath), 1);
            runtime.applyFileSelection("referenceFile", string(referencePath), 1);
            runtime.applyFileSelection("maskFile", string(maskPath), 1);
            runtime.invokeAction("generate");
            runtime.applyControlValue("alpha", .45);
            runtime.applyControlValue("brightness", .10);
            runtime.invokeAction("saveOverlays");
            runtime.invokeAction("exportSummary");

            testCase.verifyGreaterThan(height(runtime.State.project.results.summaryTable), 0);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "overlayAxes.exx").Children);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "overlayAxes.eyy").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "overlay_exx_unknown_mm.png")));
            testCase.verifyTrue(isfile(fullfile(folder, "overlay_eyy_unknown_mm.png")));
            testCase.verifyTrue(isfile(fullfile(folder, "dic_overlays_unknown_mm.labkit.json")));
            testCase.verifyTrue(isfile(summaryPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.summaryManifestPath));
            saved = fullfile(folder, "dic-postprocess-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.applyFileSelection("matFile", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(saved);
            testCase.verifyGreaterThan(height(runtime.State.project.results.summaryTable), 0);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayExx);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayEyy);
            clear cleanup
        end
    end
end

function writeInputs(matPath, referencePath, maskPath)
[x, y] = meshgrid(linspace(-1, 1, 48), linspace(-1, 1, 36));
mask = ((x ./ .7).^2 + (y ./ .7).^2) <= 1;
data_dic_save = struct("strains", struct( ...
    "plot_exx_ref_formatted", .05 .* x + .01 .* y, ...
    "plot_eyy_ref_formatted", -.04 .* y + .01 .* x, ...
    "roi_ref_formatted", struct("mask", mask)));
save(matPath, "data_dic_save");
imwrite(uint8(255 .* (.5 + .5 .* x)), referencePath);
imwrite(uint8(255 .* mask), maskPath);
end
