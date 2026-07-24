classdef ImageEnhancePresentationSpec < matlab.unittest.TestCase
    %IMAGEENHANCEPRESENTATIONSPEC Specify declared editing and export controls.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresSourceHistoryPreviewAndExportWorkflow(testCase)
            ids = nodeIds(image_enhance.workbench.buildLayout());

            testCase.verifyTrue(all(ismember( ...
                ["sourceImages" "applyTool" "historyTable" "exportImages"], ids)));
        end

        function reportsOriginalExportDimensionsInsteadOfPreviewDimensions(testCase)
            item = image_enhance.sourceFiles.emptyItem();
            item.name = "large.png";
            item.image = zeros(240, 320, 3);
            data = image_enhance.imagePreview.presentationData.resultTableData( ...
                item, zeros(150, 200, 3), 0);

            testCase.verifyEqual(string(data(string(data(:, 1)) == "Output size", 2)), ...
                "320 x 240 px");
        end

        function whiteRoiControlsRequirePerImageModeAndASelectedRoi(testCase)
            project = image_enhance.projectSpec().Create();
            session = image_enhance.createSession(project, ...
                labkit.app.internal.CallbackContextFactory.disconnected());
            project.inputs.sources = struct("id", "image-1", "required", true, ...
                "role", "source-image", "reference", struct());
            annotation = image_enhance.enhancementAnnotations.empty();
            annotation.sourceId = "image-1";
            project.annotations.items = annotation;
            session.selection.currentIndex = 1;
            session.cache.item = image_enhance.sourceFiles.emptyItem();
            state = struct("project", project, "session", session);

            shared = image_enhance.imagePreview.presentationData.toolAvailability( ...
                state, "White ROI calibration");
            state.project.parameters.batchMode = false;
            selectable = image_enhance.imagePreview.presentationData.toolAvailability( ...
                state, "White ROI calibration");
            state.project.annotations.items.whiteRoi = [1 1 4 4];
            applicable = image_enhance.imagePreview.presentationData.toolAvailability( ...
                state, "White ROI calibration");

            testCase.verifyFalse(shared.canSetWhiteRoi);
            testCase.verifyTrue(selectable.canSetWhiteRoi);
            testCase.verifyFalse(selectable.canApply);
            testCase.verifyTrue(applicable.canApply);
            testCase.verifyFalse(applicable.canPreviewPending);
        end

        function defaultWhiteRoiStartsAtTheImageCornerAndClampsToSmallImages(testCase)
            position = image_enhance.imagePreview.presentationData.defaultWhiteRoi([100 200 3]);
            small = image_enhance.imagePreview.presentationData.defaultWhiteRoi([6 5 3]);

            testCase.verifyLessThanOrEqual(position(1), 10);
            testCase.verifyLessThanOrEqual(position(2), 10);
            testCase.verifyEqual(position(3:4), [40 20]);
            testCase.verifyEqual(small, [1 1 5 6]);
        end
    end
end

function ids = nodeIds(node)
ids = string(node.Id);
if ~isempty(node.Children)
    childIds = cellfun(@nodeIds, node.Children, UniformOutput=false);
    ids = [ids; vertcat(childIds{:})];
end
end
