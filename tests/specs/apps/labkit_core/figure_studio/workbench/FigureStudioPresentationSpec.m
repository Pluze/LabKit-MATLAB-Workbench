classdef FigureStudioPresentationSpec < matlab.unittest.TestCase
    %FIGURESTUDIOPRESENTATIONSPEC Specify figure import, styling, and export controls.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresFigureSourceStyleAndExportControls(testCase)
            ids = nodeIds(figure_studio.workbench.buildLayout());

            testCase.verifyTrue(all(ismember( ...
                ["preview" "outputFolder" "exportCurrent" "appLog"], ids)));
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
