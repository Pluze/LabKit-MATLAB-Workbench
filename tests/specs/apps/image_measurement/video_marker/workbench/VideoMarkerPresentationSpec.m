classdef VideoMarkerPresentationSpec < matlab.unittest.TestCase
    %VIDEOMARKERPRESENTATIONSPEC Specify reader-facing layout semantics.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresTheVideoMarkingAndCoordinateExportWorkflow(testCase)
            layout = video_marker.workbench.buildLayout();
            ids = nodeIds(layout);

            testCase.verifyTrue(all(ismember( ...
                ["skeletonPreset" "videoFile" "currentFrame" ...
                 "exportCoordinateCsv" "summaryTable"], ids)));
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
