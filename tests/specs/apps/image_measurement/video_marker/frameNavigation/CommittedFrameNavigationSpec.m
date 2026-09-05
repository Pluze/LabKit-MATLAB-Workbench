classdef CommittedFrameNavigationSpec < matlab.unittest.TestCase
    %COMMITTEDFRAMENAVIGATIONSPEC Specify quiet committed frame navigation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function classifiesReviewFramesWithoutInventingConfidence(testCase)
            frames = video_marker.frameAnnotations.emptyAnnotations(5, 1);
            frames = video_marker.frameAnnotations.setFramePoints(frames, 2, [2 2], "draft", "predicted", .2);
            frames = video_marker.frameAnnotations.setFramePoints(frames, 3, [3 3], "draft", "predicted", .8);
            frames = video_marker.frameAnnotations.setFramePoints(frames, 4, [4 4], "draft", "predicted", NaN);
            frames = video_marker.frameAnnotations.setFramePoints(frames, 5, [5 5], "confirmed", "manual");
            testCase.verifyEqual(video_marker.frameNavigation.reviewFrames(frames, "Unreviewed", .5), (1:4)');
            testCase.verifyEqual(video_marker.frameNavigation.reviewFrames(frames, "Unmarked", .5), 1);
            testCase.verifyEqual(video_marker.frameNavigation.reviewFrames(frames, "Predicted", .5), (2:4)');
            testCase.verifyEqual(video_marker.frameNavigation.reviewFrames(frames, "Low/unknown confidence", .5), [2;4]);
            testCase.verifyEqual(video_marker.frameNavigation.reviewFrames(frames, "Low/unknown confidence", 0), 4);
            testCase.verifyError(@() video_marker.frameNavigation.reviewFrames(frames, "Other", .5), "video_marker:InvalidReviewMode");
            testCase.verifyError(@() video_marker.frameNavigation.reviewFrames(frames, "Predicted", NaN), "video_marker:InvalidReviewThreshold");
        end

        function provesCommittedFrameNavigation(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = testfixtures.video_marker.project(string(folder));
            definition = video_marker.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, project, struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyInteraction("framePoints", "interactionChanged", ...
                [24 34; 32 38; 40 42; 48 46; 56 50]);
            firstImage = runtime.State.session.cache.currentImage;
            annotations = runtime.State.project.annotations.frames;

            runtime.applyControlValue("currentFrame", 3);

            testCase.verifyEqual( ...
                runtime.State.session.selection.currentFrame, 3);
            testCase.verifyEqual(runtime.State.session.cache.frameIndex, 3);
            testCase.verifyNotEqual( ...
                runtime.State.session.cache.currentImage, firstImage);
            % Inspection must neither seed drafts nor track intermediate frames.
            testCase.verifyEqual(runtime.State.project.annotations.frames, annotations);
            events = runtime.diagnosticSnapshot().events;
            testCase.verifyFalse(any(startsWith( ...
                string({events.eventName}), ...
                "video_marker.framenavigation.changeframe.")));
            clear cleanup
        end
    end
end
