classdef RoiLibraryStateSpec < matlab.unittest.TestCase
    %ROILIBRARYSTATESPEC Specify grouped ROI copy, placement, naming, and removal.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function sameImagePasteOffsetsGroupAndAvoidsNameConflicts(testCase)
            state = copiedState();

            state = roi_analyzer.roiLibrary.pasteSelected( ...
                state, alertContext("UnexpectedAlert"));

            rois = state.project.annotations.items.rois;
            testCase.verifyEqual(numel(rois), 4);
            testCase.verifyEqual(vertcat(rois(3:4).centerXY), ...
                [30 30; 50 35]);
            testCase.verifyEqual(rois(4).centerXY - rois(3).centerXY, [20 5]);
            testCase.verifyEqual(string({rois(3:4).name}), ...
                ["Sample copy" "Reference copy"]);
            testCase.verifyEqual(numel(unique(string({rois.id}))), 4);
            testCase.verifyEqual(state.session.selection.roiIndices, [3 4]);

            state.project.parameters.ratioDenominatorRoiId = rois(4).id;
            state = roi_analyzer.roiLibrary.remove(state, []);
            testCase.verifyEqual(numel(state.project.annotations.items.rois), 2);
            testCase.verifyEqual(state.project.parameters.ratioDenominatorRoiId, "");
        end

        function crossImagePasteKeepsCompatibleSourceCoordinates(testCase)
            state = selectEmptyTarget(copiedState(), [50 70]);

            state = roi_analyzer.roiLibrary.pasteSelected( ...
                state, alertContext("UnexpectedAlert"));

            rois = state.project.annotations.items(2).rois;
            testCase.verifyEqual(vertcat(rois.centerXY), [20 20; 40 25]);
            testCase.verifyEqual(string({rois.name}), ["Sample" "Reference"]);
        end

        function crossImagePasteCentersGroupWhenSourceCoordinatesDoNotFit(testCase)
            state = selectEmptyTarget(copiedState(), [40 45]);

            state = roi_analyzer.roiLibrary.pasteSelected( ...
                state, alertContext("UnexpectedAlert"));

            rois = state.project.annotations.items(2).rois;
            centers = vertcat(rois.centerXY);
            testCase.verifyEqual(mean(centers, 1), [23 20.5], ...
                AbsTol=1e-12);
            testCase.verifyEqual(centers(2, :) - centers(1, :), [20 5]);
        end

        function crossImagePasteRejectsGroupThatCannotFit(testCase)
            state = selectEmptyTarget(copiedState(), [40 35]);
            context = alertContext("ExpectedAlert");

            testCase.verifyError( ...
                @() roi_analyzer.roiLibrary.pasteSelected(state, context), ...
                "roi_analyzer:test:ExpectedAlert");
        end
    end
end

function state = copiedState()
state = workingState();
state = roi_analyzer.roiLibrary.add(state, []);
state = roi_analyzer.roiLibrary.add(state, []);
state.project.annotations.items.rois(1).name = "Sample";
state.project.annotations.items.rois(1).centerXY = [20 20];
state.project.annotations.items.rois(2).name = "Reference";
state.project.annotations.items.rois(2).centerXY = [40 25];
state = roi_analyzer.roiLibrary.selectOnCanvas(state, [1 2], []);
state = roi_analyzer.roiLibrary.copySelected(state, []);
end

function state = selectEmptyTarget(state, imageSize)
state.project.inputs.sources(2, 1) = labkit.app.source.record( ...
    "image-2", "source-image", "target.png");
state.session.selection.sourceIndex = 2;
state.session.selection.roiIndex = 0;
state.session.selection.roiIndices = zeros(1, 0);
state.session.cache = struct("sourceId", "image-2", "name", "target.png", ...
    "image", zeros(imageSize), "preview", zeros(imageSize), ...
    "previewScale", 1);
end

function state = workingState()
project = roi_analyzer.initialData();
project.inputs.sources = labkit.app.source.record( ...
    "image-1", "source-image", "synthetic.png");
session = struct( ...
    "selection", struct("sourceIndex", 1, "sourceImages", ...
        labkit.app.event.ListSelection(Ids="image-1", Indices=1), ...
        "roiIndex", 0, "roiIndices", zeros(1, 0), "roiCells", ...
        labkit.app.event.TableCellSelection(zeros(0, 2))), ...
    "view", struct("shiftX", 0, "shiftY", 0), ...
    "clipboard", struct("rois", [], "anchor", [NaN NaN], ...
        "sourceId", ""), ...
    "cache", struct("sourceId", "image-1", "name", "synthetic.png", ...
        "image", zeros(50, 70), "preview", zeros(50, 70), ...
        "previewScale", 1));
state = struct("project", project, "session", session);
end

function context = alertContext(identifier)
context = struct("alert", @(message, title) raiseAlert(identifier, message, title));
end

function raiseAlert(identifier, message, title)
error("roi_analyzer:test:" + identifier, "%s: %s", title, message);
end
