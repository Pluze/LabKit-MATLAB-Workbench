classdef RoiLibraryStateSpec < matlab.unittest.TestCase
    %ROILIBRARYSTATESPEC Specify grouped ROI copy, placement, naming, and removal.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function groupedPastePreservesRelativeCentersAndUniqueNames(testCase)
            state = workingState();
            state = roi_analyzer.roiLibrary.add(state, []);
            state = roi_analyzer.roiLibrary.add(state, []);
            state.project.annotations.items.rois(1).name = "Sample";
            state.project.annotations.items.rois(1).centerXY = [15 20];
            state.project.annotations.items.rois(2).name = "Reference";
            state.project.annotations.items.rois(2).centerXY = [35 25];
            state = roi_analyzer.roiLibrary.selectOnCanvas(state, [1 2], []);

            state = roi_analyzer.roiLibrary.copySelected(state, []);
            state = roi_analyzer.roiLibrary.pasteSelected(state, []);
            testCase.verifyTrue(state.session.clipboard.pastePending);
            state = roi_analyzer.roiLibrary.pasteAtPoint(state, [40 30], []);

            rois = state.project.annotations.items.rois;
            testCase.verifyEqual(numel(rois), 4);
            testCase.verifyEqual(rois(4).centerXY - rois(3).centerXY, [20 5]);
            testCase.verifyEqual(mean(vertcat(rois(3:4).centerXY), 1), [40 30]);
            testCase.verifyEqual(string({rois(3:4).name}), ...
                ["Sample copy" "Reference copy"]);
            testCase.verifyEqual(numel(unique(string({rois.id}))), 4);
            testCase.verifyEqual(state.session.selection.roiIndices, [3 4]);
            testCase.verifyFalse(state.session.clipboard.pastePending);

            state.project.parameters.ratioDenominatorRoiId = rois(4).id;
            state = roi_analyzer.roiLibrary.remove(state, []);
            testCase.verifyEqual(numel(state.project.annotations.items.rois), 2);
            testCase.verifyEqual(state.project.parameters.ratioDenominatorRoiId, "");
        end
    end
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
        "pastePending", false), ...
    "cache", struct("sourceId", "image-1", "name", "synthetic.png", ...
        "image", zeros(50, 70), "preview", zeros(50, 70), ...
        "previewScale", 1));
state = struct("project", project, "session", session);
end
