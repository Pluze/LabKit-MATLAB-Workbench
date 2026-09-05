classdef ReviewSessionSpec < matlab.unittest.TestCase
    %REVIEWSESSIONSPEC Regression: review defaults cannot confirm saved predictions.
    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function rebuildsReviewControlsForEmptyAndAnnotatedProjects(testCase)
            project = video_marker.initialData();
            empty = video_marker.createSession(project, []);
            testCase.verifyEmpty(empty.cache.currentImage);
            testCase.verifyEqual(empty.selection.predictionEndFrame, 1);
            project.inputs.videoMetadata.frameCount = 4;
            project.annotations.frames = video_marker.frameAnnotations.emptyAnnotations(4, 1);
            project.annotations.frames = video_marker.frameAnnotations.setFramePoints( ...
                project.annotations.frames, 1, [10 10], "confirmed", "manual");
            project.annotations.frames = video_marker.frameAnnotations.setFramePoints( ...
                project.annotations.frames, 2, [11 10], "draft", "predicted", NaN);
            session = video_marker.createSession(project, []);
            testCase.verifyEqual(session.view.reviewMode, "Unreviewed");
            testCase.verifyEqual(session.view.reviewThreshold, .5);
            testCase.verifyEqual(session.selection.predictionEndFrame, 2);
            testCase.verifyEqual(video_marker.frameNavigation.reviewFrames( ...
                project.annotations.frames, session.view.reviewMode, session.view.reviewThreshold), [2;3;4]);
            project.inputs.videoMetadata.frameCount = 1;
            oneFrame = video_marker.createSession(project, []);
            testCase.verifyEqual(oneFrame.selection.predictionEndFrame, 1);
        end
    end
end
