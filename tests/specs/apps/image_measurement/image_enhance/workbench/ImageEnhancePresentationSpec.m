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
    end
end

function ids = nodeIds(node)
ids = string(node.Id);
if ~isempty(node.Children)
    childIds = cellfun(@nodeIds, node.Children, UniformOutput=false);
    ids = [ids; vertcat(childIds{:})];
end
end
