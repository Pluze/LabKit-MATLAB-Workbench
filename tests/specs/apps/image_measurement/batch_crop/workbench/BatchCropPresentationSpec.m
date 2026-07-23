classdef BatchCropPresentationSpec < matlab.unittest.TestCase
    %BATCHCROPPRESENTATIONSPEC Specify batch crop workflow declarations.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresSourceCropScaleAndExportControls(testCase)
            ids = nodeIds(batch_crop.workbench.buildLayout());

            testCase.verifyTrue(all(ismember( ...
                ["images" "cropWidth" "exportCrops" "resultTable"], ids)));
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
