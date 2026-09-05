classdef RoiAnalyzerWorkflowSpec < matlab.unittest.TestCase
    %ROIANALYZERWORKFLOWSPEC Specify the production image-to-result journey.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsShapesReferencesMeasuresReusesAndExports(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            firstPath = fullfile(folder, "first.png");
            secondPath = fullfile(folder, "second.png");
            outputPath = fullfile(folder, "roi-results.csv");
            projectPath = fullfile(folder, "roi-project.mat");
            parameterPath = fullfile(folder, "roi-parameters.json");
            [x, y] = meshgrid(1:40, 1:32);
            first = uint8(cat(3, x + y, 2 .* x + y, x + 2 .* y));
            second = uint8(min(double(first) + 12, 255));
            imwrite(first, firstPath);
            imwrite(second, secondPath);
            backend = struct( ...
                "chooseOutputFile", @(~, startPath) ...
                    outputChoice(startPath, outputPath, projectPath, parameterPath), ...
                "chooseInputFile", @(~, ~) labkit.app.dialog.Choice(projectPath), ...
                "alert", @(message, title) unexpectedAlert(message, title));
            definition = roi_analyzer.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyFileSelection("sourceImages", ...
                [string(firstPath); string(secondPath)], 1);
            runtime.invokeAction("addRoi");
            runtime.applyControlValue("roiName", "Sample");
            runtime.applyControlValue("roiShape", "Circle");
            runtime.applyControlValue("roiWidth", 2);
            runtime.applyControlValue("roiHeight", 2);
            runtime.applyInteraction("roiCenters", ...
                "interactionChanged", struct("points", [9.5 10.5], ...
                    "selectedIndex", 1, "locked", false));
            runtime.invokeAction("addRoi");
            runtime.applyControlValue("roiName", "Temporary");
            runtime.invokeAction("removeRoi");
            testCase.verifyEqual( ...
                numel(runtime.State.project.annotations.items(1).rois), 1);
            runtime.invokeAction("addRoi");
            runtime.applyControlValue("roiName", "Reference");
            runtime.applyInteraction("roiCenters", ...
                "interactionChanged", struct( ...
                    "points", [9.5 10.5; 24.5 12.5], ...
                    "selectedIndex", 2, "locked", false));
            testCase.verifyEqual( ...
                runtime.State.session.selection.roiIndex, 2);
            testCase.verifyEqual( ...
                runtime.State.project.annotations.items(1).rois(2).centerXY, ...
                [24.5 12.5]);
            runtime.applyTableSelection("roiTable", [1 1]);
            testCase.verifyEqual(runtime.State.session.selection.roiIndex, 1);
            runtime.applyInteraction("roiCenters", ...
                "selectionChanged", [1 2]);
            testCase.verifyEqual( ...
                runtime.State.session.selection.roiIndices, [1 2]);
            runtime.applyInteraction("roiCenters", ...
                "selectionChanged", zeros(1, 0));
            testCase.verifyEmpty(runtime.State.session.selection.roiIndices);
            testCase.verifyEqual(runtime.State.session.selection.roiIndex, 0);
            previewAxes = findall( ...
                runtime.figureHandle(), "Tag", "preview.main");
            pointMarkers = findall( ...
                previewAxes, "Type", "Line", "Marker", "o");
            testCase.verifyGreaterThanOrEqual(numel(pointMarkers), 2, ...
                "Clearing ROI selection must keep the canvas editor active.");
            runtime.applyInteraction("roiCenters", ...
                "interactionChanged", struct( ...
                    "points", [10.5 10.5; 24.5 12.5], ...
                    "selectedIndex", 1, "selectedIndices", 1, ...
                    "locked", false));
            testCase.verifyEqual(runtime.State.session.selection.roiIndex, 1);
            testCase.verifyEqual( ...
                runtime.State.project.annotations.items(1).rois(1).centerXY, ...
                [10.5 10.5]);
            runtime.applyInteraction("roiCenters", ...
                "selectionChanged", [1 2]);
            runtime.applyControlValue("roiShape", "Rectangle");
            runtime.applyControlValue("roiWidth", 10);
            runtime.applyControlValue("roiHeight", 8);
            runtime.invokeAction("copyRois");
            runtime.applyFilePanelSelection("sourceImages", 2);
            runtime.invokeAction("pasteRois");
            firstPaste = runtime.State.project.annotations.items(2).rois;
            testCase.verifyEqual(numel(firstPaste), 2);
            testCase.verifyEqual(vertcat(firstPaste.centerXY), ...
                [10.5 10.5; 24.5 12.5]);
            runtime.applyFilePanelSelection("sourceImages", 1);
            runtime.applyInteraction("roiCenters", ...
                "selectionChanged", [1 2]);
            runtime.applyControlValue("shiftX", 2);
            runtime.applyControlValue("shiftY", 1);
            runtime.invokeAction("shiftCurrent");
            runtime.applyControlValue("ratioDenominatorRoi", "Reference");
            runtime.invokeAction("measureRois");
            runtime.invokeAction("exportParameters");
            runtime.invokeAction("saveProject");

            firstResult = runtime.State.project.results.items(1).summary;
            testCase.verifyEqual(height(firstResult), 6);
            testCase.verifyEqual(unique(firstResult.Channel, "stable"), ...
                ["Red"; "Green"; "Blue"]);
            testCase.verifyTrue(all(isfinite(firstResult.Ratio)));
            runtime.invokeAction("applyLayoutToAll");
            beforeShift = vertcat( ...
                runtime.State.project.annotations.items(1).rois.centerXY);
            runtime.applyControlValue("shiftX", 1);
            runtime.applyControlValue("shiftY", 0);
            runtime.invokeAction("shiftAll");
            testCase.verifyEqual(vertcat( ...
                runtime.State.project.annotations.items(1).rois.centerXY), ...
                beforeShift + [1 0]);
            testCase.verifyEqual(vertcat( ...
                runtime.State.project.annotations.items(2).rois.centerXY), ...
                beforeShift + [1 0]);
            runtime.applyFilePanelSelection("sourceImages", 2);
            runtime.invokeAction("pasteRois");
            secondRois = runtime.State.project.annotations.items(2).rois;
            testCase.verifyEqual(numel(secondRois), 4);
            testCase.verifyEqual( ...
                secondRois(4).centerXY - secondRois(3).centerXY, ...
                secondRois(2).centerXY - secondRois(1).centerXY);
            testCase.verifyEqual(string({secondRois(3:4).name}), ...
                ["Sample copy" "Reference copy"]);
            testCase.verifyEqual( ...
                runtime.State.session.selection.roiIndices, [3 4]);
            movedPoints = vertcat(secondRois.centerXY);
            movedPoints(3:4, :) = movedPoints(3:4, :) + [-2 -1];
            runtime.applyInteraction("roiCenters", ...
                "interactionChanged", movedPoints);
            movedRois = runtime.State.project.annotations.items(2).rois;
            testCase.verifyEqual(vertcat(movedRois(3:4).centerXY), ...
                movedPoints(3:4, :));
            testCase.verifyEqual( ...
                movedRois(4).centerXY - movedRois(3).centerXY, ...
                secondRois(4).centerXY - secondRois(3).centerXY);
            runtime.invokeAction("measureRois");
            runtime.invokeAction("exportCsv");

            secondResult = runtime.State.project.results.items(2).summary;
            testCase.verifyEqual(height(secondResult), 12);
            testCase.verifyGreaterThan( ...
                mean(secondResult.Mean(secondResult.Channel == "Red")), ...
                mean(firstResult.Mean(firstResult.Channel == "Red")));
            testCase.verifyTrue(isfile(outputPath));
            testCase.verifyTrue(isfile(projectPath));
            testCase.verifyTrue(isfile(parameterPath));
            exported = readtable(outputPath, TextType="string");
            testCase.verifyEqual(height(exported), 12);
            testCase.verifyTrue(all(exported.Image == "second.png"));
            runtime.invokeAction("previousImage");
            testCase.verifyEqual(runtime.State.session.selection.sourceIndex, 1);
            runtime.invokeAction("nextImage");
            testCase.verifyEqual(runtime.State.session.selection.sourceIndex, 2);
            testCase.verifyNotEmpty(findall( ...
                runtime.figureHandle(), "Tag", "preview.main").Children);
            currentSelection = runtime.State.session.selection;
            currentCache = runtime.State.session.cache;
            runtime.invokeAction("measureAll");
            testCase.verifyEqual(runtime.State.session.selection, currentSelection);
            testCase.verifyEqual(runtime.State.session.cache, currentCache);
            runtime.invokeAction("exportAllCsv");
            batch = readtable(outputPath, TextType="string");
            testCase.verifyEqual(height(batch), 18);
            testCase.verifyEqual(unique(batch.ImageIndex), [1; 2]);
            testCase.verifyTrue(all(batch.Status == "Measured"));
            % Replace the batch after a source disappears; stale successful
            % rows must be removed and the failure must remain exportable.
            delete(secondPath);
            runtime.invokeAction("measureAll");
            testCase.verifyEmpty(runtime.State.project.results.items(2).summary);
            runtime.invokeAction("exportAllCsv");
            failedBatch = readtable(outputPath, TextType="string");
            testCase.verifyEqual(failedBatch.Status(end), "Read failed");
            testCase.verifyTrue(isnan(failedBatch.Mean(end)));
            imwrite(second, secondPath);
            runtime.invokeAction("measureAll");
            tab = findall(runtime.figureHandle(), "Type", "uitab", "Title", "Results + Export");
            tab.Parent.SelectedTab = tab;
            exportapp(runtime.figureHandle(), labkittest.visualEvidencePath("roi-batch", ".png"));
            runtime.invokeAction("openProject");
            testCase.verifyEqual( ...
                numel(runtime.State.project.annotations.items(1).rois), 2);
            testCase.verifyEqual( ...
                runtime.State.session.selection.roiIndices, [1 2]);
            clear cleanup
        end
    end
end

function unexpectedAlert(message, title)
error("roi_analyzer:test:UnexpectedAlert", "%s: %s", title, message);
end

function choice = outputChoice(startPath, csvPath, projectPath, parameterPath)
startPath = string(startPath);
if endsWith(startPath, ".mat")
    path = projectPath;
elseif endsWith(startPath, ".json")
    path = parameterPath;
else
    path = csvPath;
end
choice = labkit.app.dialog.Choice(path);
end
