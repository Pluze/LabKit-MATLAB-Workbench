classdef GuiLayoutCurvatureTest < matlab.unittest.TestCase
    %GUILAYOUTCURVATURETEST Verify curvature measurement GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function curvature_workflow_fits_curve_and_measures_length(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            imagePath = fullfile(folder, 'curvature.png');
            imwrite(syntheticCurvatureImage(), imagePath);

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            outputs = ["curvature_result.csv", "curvature_overlay.png"];
            outputIndex = 0;
            backend = struct( ...
                "chooseOutputFile", @chooseOutput, ...
                "alert", @(~, ~) []);
            runtime = curvature.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertCurvatureLayout(h, fig);
            runtime.applyFileSelection('imageFile', imagePath, 1);
            runtime.applyInteraction( ...
                'scaleReference', 'interactionChanged', [25 90; 125 90]);
            runtime.applyControlValue('referenceLength', 100);
            runtime.applyControlValue('scaleUnit', 'um');
            runtime.invokeAction('placeScaleBar');
            testCase.verifyTrue( ...
                runtime.State.project.annotations.calibration.isCalibrated);

            curvePoints = [28 70; 48 42; 84 30; 120 42; 140 70];
            runtime.applyInteraction( ...
                'curve', 'interactionChanged', curvePoints);
            runtime.invokeAction('fitCurvature');
            runtime.invokeAction('measureLength');
            testCase.verifyTrue(runtime.State.project.results.fit.ok);
            testCase.verifyTrue(runtime.State.project.results.length.ok);
            previewAxes = findall(fig, 'Tag', 'preview.image');
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.invokeAction('exportCsv');
            runtime.invokeAction('exportOverlay');
            for filepath = fullfile(outputFolder, outputs)
                testCase.verifyTrue(isfile(filepath));
            end

            projectPath = fullfile(outputFolder, 'curvature-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 2);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'image'));
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty(runtime.State.session.cache.image, ...
                'Project reopen should rebuild the decoded image cache.');
            testCase.verifyTrue(runtime.State.project.results.fit.ok, ...
                'Project reopen should retain the durable curvature fit.');
            clear runtimeCleanup outputCleanup;

            function choice = chooseOutput(~, ~)
                outputIndex = outputIndex + 1;
                choice = labkit.app.dialog.Choice( ...
                    fullfile(outputFolder, outputs(outputIndex)));
            end
        end
    end
end

function assertCurvatureLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["imageFile", "undoCurve", "clearCurve", ...
        "fitCurvature", "measureLength", "referenceLength", ...
        "scaleUnit", "placeScaleBar", "exportCsv", ...
        "exportOverlay", "resultTable", "details", "preview.image"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing Curvature semantic target: %s.", id);
    end
end

function img = syntheticCurvatureImage()
    [x, y] = meshgrid(1:168, 1:104);
    background = 0.30 + 0.20 .* sin(x ./ 11) + 0.15 .* cos(y ./ 9);
    curve = exp(-((sqrt((x - 84).^2 + (y - 88).^2) - 58).^2) ./ 12);
    img = uint8(255 .* min(max(background + 0.45 .* curve, 0), 1));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
