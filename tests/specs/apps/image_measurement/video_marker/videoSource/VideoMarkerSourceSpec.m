classdef VideoMarkerSourceSpec < matlab.unittest.TestCase
    %VIDEOMARKERSOURCESPEC Specify clearing a selected video source.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function clearingTheVideoRemovesFramesAndDerivedExports(testCase)
            project = video_marker.initialData();
            project.annotations.skeleton = video_marker.skeletonDefinition.fromText( ...
                "hip", "");
            project.annotations.frames = video_marker.frameAnnotations.emptyAnnotations(2, 1);
            project.results.coordinateOutputPath = "coordinates.csv";
            state = struct("project", project);
            context = labkittest.createCallbackContext(struct( ...
                "removeResource", @(~, ~) [], "log", @(varargin) []));

            actual = video_marker.videoSource.selectionChanged(state, [], context);

            testCase.verifyEmpty(actual.project.annotations.frames.coords);
            testCase.verifyEqual(actual.project.parameters.coordinateStartFrame, 1);
            testCase.verifyEqual(actual.project.parameters.coordinateEndFrame, 1);
            testCase.verifyEqual(actual.project.results.coordinateOutputPath, "");
        end
    end
end
