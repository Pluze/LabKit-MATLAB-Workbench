classdef GuiLayoutCurvatureTest < matlab.unittest.TestCase
    %GUILAYOUTCURVATURETEST Verify the complete Curvature GUI workflow.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function curvature_workflow_fits_curve_and_measures_length(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            imagePath = fullfile(folder, "curvature.png");
            replacementPath = fullfile(folder, "replacement.png");
            imwrite(syntheticCurvatureImage(), imagePath);
            imwrite(flip(syntheticCurvatureImage(), 2), replacementPath);

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            outputs = ["curvature_result.csv", "curvature_overlay.png"];
            outputIndex = 0;
            backend = struct( ...
                "chooseOutputFile", @chooseOutput, ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                curvature.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertCurvatureLayout(h, fig);

            runtime.applyFileSelection("imageFile", imagePath, 1);
            testCase.verifyEqual(string(component( ...
                fig, "imageFile.status").Value), "Image loaded");
            runtime.invokeAction("measureScaleReference");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.editMode, "reference");
            testCase.verifyEqual(string(component( ...
                fig, "measureScaleReference").Text), ...
                "Finish reference edit");
            runtime.applyInteraction( ...
                "scaleReference", "interactionChanged", ...
                [25 90; 125 90]);
            runtime.invokeAction("measureScaleReference");
            runtime.applyControlValue("scaleReferenceLength", 100);
            runtime.applyControlValue("scaleCalibrationUnit", "um");
            runtime.invokeAction("placeScaleBar");
            testCase.verifyTrue( ...
                runtime.State.project.annotations.calibration.isCalibrated);
            testCase.verifyNotEmpty(runtime.State.session.view.scaleBar);

            curvePoints = [28 70; 48 42; 84 30; 120 42; 140 70];
            runtime.invokeAction("startCurveEdit");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.editMode, "curve");
            testCase.verifyEqual(string(component( ...
                fig, "startCurveEdit").Text), "Finish curve edit");
            runtime.applyInteraction( ...
                "curve", "interactionChanged", curvePoints);
            runtime.invokeAction("startCurveEdit");
            runtime.applyControlValue("densePointCount", 400);
            runtime.invokeAction("fitCurvature");
            runtime.invokeAction("measureCurveLength");
            testCase.verifyTrue(runtime.State.project.results.fit.ok);
            testCase.verifyTrue(runtime.State.project.results.length.ok);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.densePointCount, 400);
            previewAxes = component(fig, "preview.image");
            testCase.verifyNotEmpty(previewAxes.Children);
            testCase.verifyTrue(contains( ...
                string(previewAxes.Title.String), "curvature"));
            resultTable = component(fig, "resultTable");
            testCase.verifyEqual(size(resultTable.Data, 1), 7);
            testCase.verifyNotEqual(string(resultTable.Data{2, 2}), "-");

            runtime.invokeAction("exportCsv");
            runtime.invokeAction("exportOverlay");
            for filepath = fullfile(outputFolder, outputs)
                testCase.verifyTrue(isfile(filepath));
            end
            testCase.verifyTrue(isfile(fullfile( ...
                outputFolder, "curvature_result.labkit.json")));
            testCase.verifyTrue(isfile(fullfile( ...
                outputFolder, "curvature_overlay.labkit.json")));
            testCase.verifyEqual( ...
                runtime.State.project.results.lastCsvExport.csvPath, ...
                fullfile(outputFolder, outputs(1)));
            testCase.verifyEqual( ...
                runtime.State.project.results.lastOverlayExport.pngPath, ...
                fullfile(outputFolder, outputs(2)));

            projectPath = fullfile( ...
                outputFolder, "curvature-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, "labkitProject");
            testCase.verifyEqual( ...
                saved.labkitProject.app.payloadVersion, 2);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload, "image"));

            runtime.applyFileSelection( ...
                "imageFile", replacementPath, 1);
            testCase.verifyFalse( ...
                runtime.State.project.results.fit.ok, ...
                "A replacement image must invalidate the old fit.");
            testCase.verifyFalse( ...
                runtime.State.project.annotations.calibration.isCalibrated, ...
                "A replacement image must invalidate pixel calibration.");
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty(runtime.State.session.cache.image, ...
                "Project reopen should rebuild the decoded image cache.");
            testCase.verifyTrue(runtime.State.project.results.fit.ok, ...
                "Project reopen should retain the durable curvature fit.");
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
ids = [ ...
    "imageFile", "pointCount", "startCurveEdit", ...
    "undoCurvePoint", "clearCurve", ...
    "measureScaleReference", "scaleReferencePixels", ...
    "scaleReferenceLength", "scaleCalibrationUnit", ...
    "scaleBarLength", "scaleBarPosition", "scaleBarColor", ...
    "placeScaleBar", "scaleReferenceReadout", ...
    "pixelsPerUnitReadout", "densify", "densePointCount", ...
    "showDensePoints", "fitCurvature", "measureCurveLength", ...
    "exportCsv", "exportOverlay", "resultTable", ...
    "detailsText", "appLog", "preview.image"];
for id = ids
    assert(numel(findall(fig, "Tag", id)) == 1, ...
        "Missing Curvature semantic target: %s.", id);
end
tabs = findall(fig, "Type", "uitab");
assert(isequal(sort(string({tabs.Title})), ...
    sort(["Files + Analysis", "Summary + Results", "Log"])));
assert(numel(findall(fig, "Title", "Image Preview")) >= 2);
assert(~isempty(findall(fig, "Title", "Workflow Notes")));
assert(~isempty(findall(fig, "Title", "Curvature Results")));
assert(size(component(fig, "resultTable").Data, 1) == 7);
h.assertAxesContract(fig, { ...
    h.axesSpec("Image + Circle Fit", "", "")});
end

function value = component(figureHandle, tag)
value = findall(figureHandle, "Tag", char(tag));
assert(isscalar(value), "Expected one component with Tag %s.", tag);
end

function img = syntheticCurvatureImage()
[x, y] = meshgrid(1:168, 1:104);
background = 0.30 + 0.20 .* sin(x ./ 11) + 0.15 .* cos(y ./ 9);
curve = exp(-((sqrt((x - 84).^2 + (y - 88).^2) - 58).^2) ./ 12);
img = uint8(255 .* min(max(background + 0.45 .* curve, 0), 1));
end

function removeTempFolder(folder)
if exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end
