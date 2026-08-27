classdef CurvatureWorkflowSpec < matlab.unittest.TestCase
    %CURVATUREWORKFLOWSPEC Specify traced-fit export through the workbench.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function tracesFitsExportsAndRestoresASyntheticCurve(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            imagePath = fullfile(folder, "curve.png");
            csvPath = fullfile(folder, "curvature.csv");
            overlayPath = fullfile(folder, "curvature.png");
            imwrite(uint8(180 .* ones(80, 100)), imagePath);
            backend = struct( ...
                "chooseOutputFile", @(filters, ~) chooseFile( ...
                    filters, csvPath, overlayPath), ...
                "alert", @(~, ~) []);
            definition = curvature.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("imageFile", string(imagePath), 1);
            runtime.invokeAction("startCurveEdit");
            runtime.applyInteraction("curve", "interactionChanged", arcPoints());
            runtime.invokeAction("undoCurvePoint");
            testCase.verifyNumElements( ...
                runtime.State.project.annotations.curvePoints(:, 1), 5);
            runtime.invokeAction("clearCurve");
            testCase.verifyEmpty(runtime.State.project.annotations.curvePoints);
            runtime.applyInteraction("curve", "interactionChanged", arcPoints());
            testCase.verifyEmpty(findobj( ...
                figureValue, DisplayName="curve"));
            runtime.invokeAction("startCurveEdit");
            runtime.invokeAction("measureScaleReference");
            runtime.applyInteraction("scaleReference", ...
                "interactionChanged", [10 10; 50 10]);
            runtime.invokeAction("measureScaleReference");
            runtime.applyControlValue("scaleReferencePixels", 40);
            runtime.applyControlValue("scaleReferenceLength", 10);
            runtime.applyControlValue("scaleCalibrationUnit", "mm");
            runtime.applyControlValue("scaleBarLength", 5);
            runtime.applyControlValue("scaleBarPosition", "Top left");
            runtime.applyControlValue("scaleBarColor", "White");
            runtime.invokeAction("placeScaleBar");
            testCase.verifyEqual( ...
                runtime.State.session.view.scaleBar.color, [1 1 1]);
            runtime.applyControlValue("densify", true);
            runtime.applyControlValue("densePointCount", 120);
            runtime.invokeAction("fitCurvature");
            runtime.applyControlValue("showDensePoints", false);
            runtime.invokeAction("exportCsv");
            runtime.invokeAction("exportOverlay");

            testCase.verifyTrue(runtime.State.project.results.fit.ok);
            testCase.verifyTrue(runtime.State.project.results.length.ok);
            measureButton = findall(figureValue, "Tag", "fitCurvature");
            testCase.verifyEqual(string(measureButton.Text), ...
                "Measure length + curvature");
            testCase.verifyEmpty(findall(figureValue, ...
                "Tag", "measureCurveLength"));
            testCase.verifyGreaterThan(runtime.State.project.results.fit.R_show, 0);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.densePointCount, 120);
            testCase.verifyFalse(runtime.State.project.parameters.showDensePoints);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.image").Children);
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(overlayPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastCsvExport.outputPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastOverlayExport.outputPath));
            clear cleanup
        end
    end
end

function choice = chooseFile(filters, csvPath, overlayPath)
if contains(string(filters(1)), "csv", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(csvPath);
else
    choice = labkit.app.dialog.Choice(overlayPath);
end
end

function points = arcPoints()
theta = linspace(.15 .* pi, .85 .* pi, 6)';
points = [50 + 24 .* cos(theta), 48 + 24 .* sin(theta)];
end
