classdef VideoMarkerPresentationSpec < matlab.unittest.TestCase
    %VIDEOMARKERPRESENTATIONSPEC Specify reader-facing layout semantics.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresTheVideoMarkingAndCoordinateExportWorkflow(testCase)
            plan = labkittest.inspectDefinition(video_marker.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember( ...
                ["skeletonPreset" "videoFile" "currentFrame" ...
                 "exportCoordinateCsv" "exportAnnotatedVideo" ...
                 "summaryTable"], ids)));
        end
    end
end
