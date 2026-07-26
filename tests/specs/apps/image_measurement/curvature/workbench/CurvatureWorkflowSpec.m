classdef CurvatureWorkflowSpec < matlab.unittest.TestCase
    %CURVATUREWORKFLOWSPEC Specify traced-fit export through the workbench.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
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
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("imageFile", string(imagePath), 1);
            runtime.applyInteraction("curve", "interactionChanged", arcPoints());
            runtime.applyControlValue("scaleReferencePixels", 40);
            runtime.applyControlValue("scaleReferenceLength", 10);
            runtime.applyControlValue("scaleCalibrationUnit", "mm");
            runtime.invokeAction("fitCurvature");
            runtime.invokeAction("exportCsv");
            runtime.invokeAction("exportOverlay");

            testCase.verifyTrue(runtime.State.project.results.fit.ok);
            testCase.verifyGreaterThan(runtime.State.project.results.fit.R_show, 0);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.image").Children);
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(overlayPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastCsvExport.manifestPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastOverlayExport.manifestPath));
            saved = fullfile(folder, "curvature-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.invokeAction("clearCurve");
            runtime.restoreProject(saved);
            testCase.verifyTrue(runtime.State.project.results.fit.ok);
            testCase.verifySize(runtime.State.project.annotations.curvePoints, [6 2]);
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
