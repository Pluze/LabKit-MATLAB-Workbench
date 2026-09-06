classdef DicPostprocessWorkflowSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSWORKFLOWSPEC Specify DIC overlay generation and exports.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
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
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("matFile", string(matPath), 1);
            runtime.applyFileSelection("referenceFile", string(referencePath), 1);
            runtime.applyFileSelection("maskFile", string(maskPath), 1);
            runtime.invokeAction("generate");
            runtime.applyControlValue("colorMin", -.10);
            runtime.applyControlValue("colorMax", .20);
            runtime.applyControlValue("oversample", 3);
            runtime.applyControlValue("smoothSigma", .5);
            runtime.applyControlValue("edgeTrim", 0);
            runtime.applyControlValue("alpha", .45);
            runtime.applyControlValue("brightness", .10);
            runtime.applyControlValue("contrast", 1.2);
            runtime.applyControlValue("gamma", .9);
            runtime.applyControlValue("saturation", .8);
            runtime.applyControlValue("redGain", 1.1);
            runtime.applyControlValue("greenGain", .9);
            runtime.applyControlValue("blueGain", 1.05);
            runtime.invokeAction("saveOverlays");
            runtime.invokeAction("exportSummary");

            testCase.verifyGreaterThan(height(runtime.State.project.results.summaryTable), 0);
            parameters = runtime.State.project.parameters;
            testCase.verifyEqual([parameters.colorMin, parameters.colorMax, ...
                parameters.oversample, parameters.smoothSigma, ...
                parameters.edgeTrim], [-.10, .20, 3, .5, 0]);
            testCase.verifyEqual([parameters.contrast, parameters.gamma, ...
                parameters.saturation, parameters.redGain, ...
                parameters.greenGain, parameters.blueGain], ...
                [1.2, .9, .8, 1.1, .9, 1.05]);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "overlayAxes.exx").Children);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "overlayAxes.eyy").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "overlay_exx_unknown_mm.png")));
            testCase.verifyTrue(isfile(fullfile(folder, "overlay_eyy_unknown_mm.png")));
            testCase.verifyTrue(isfile(summaryPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.summaryOutputPath));
            acceptedStrain = runtime.State.session.cache.strain;
            acceptedSummary = runtime.State.project.results.summaryTable;
            acceptedOverlay = runtime.State.session.cache.overlayExx;
            data_dic_save = struct("strains", struct( ...
                "plot_exx_ref_formatted", {{"invalid"}}, ...
                "plot_eyy_ref_formatted", zeros(2)));
            save(matPath, "data_dic_save");
            runtime.invokeAction("generate");
            testCase.verifyEqual(runtime.State.session.cache.strain, acceptedStrain);
            testCase.verifyEqual(runtime.State.project.results.summaryTable, acceptedSummary);
            testCase.verifyEqual(runtime.State.session.cache.overlayExx, acceptedOverlay);
            runtime.applyControlValue("colorMax", -.2);
            testCase.verifyEmpty(runtime.State.project.results.summaryTable);
            testCase.verifyEmpty(runtime.State.session.cache.overlayExx);
            testCase.verifyEmpty(runtime.State.session.cache.overlayEyy);
            runtime.applyControlValue("colorMax", .2);
            testCase.verifyEqual(runtime.State.project.results.summaryTable, acceptedSummary);
            testCase.verifyEqual(runtime.State.session.cache.overlayExx, acceptedOverlay);
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
