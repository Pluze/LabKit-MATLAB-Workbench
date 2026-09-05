classdef VideoMarkerMotionEstimateSpec < matlab.unittest.TestCase
    %VIDEOMARKERMOTIONESTIMATESPEC Guard multiscale point tracking.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function explicitRangePreservesManualAnchorsAndDraftStatus(testCase)
            rng(9);
            first = rand(80, 100);
            images = {first, circshift(first, [0 2]), ...
                circshift(first, [0 4]), circshift(first, [0 6])};
            frames = video_marker.frameAnnotations.emptyAnnotations(4, 1);
            frames = video_marker.frameAnnotations.setFramePoints(frames, 1, [50 40], "confirmed", "manual");
            frames = video_marker.frameAnnotations.setFramePoints(frames, 3, [54 40], "confirmed", "manual");
            [predicted, imageData] = video_marker.motionEstimate.predictForward( ...
                @(index) images{index}, frames, 1, 4, first);
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints(predicted, 3), [54 40]);
            testCase.verifyEqual(predicted.frameStatus(3), video_marker.frameAnnotations.statusCode("confirmed"));
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints(predicted, 4), [56 40], AbsTol=.35);
            testCase.verifyEqual(predicted.frameStatus([2 4]), ...
                repmat(video_marker.frameAnnotations.statusCode("draft"), 2, 1));
            testCase.verifyEqual(imageData, images{4});
        end

        function controlledTranslationIsRecoveredDeterministically(testCase)
            rng(7);
            previous = rand(80, 100);
            current = zeros(size(previous));
            current(1:78, 4:100) = previous(3:80, 1:97);

            [point, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints( ...
                previous, current, [50 40]);

            testCase.verifyEqual(point, [53 38], AbsTol=.35);
            testCase.verifyGreaterThan(confidence, .5);
            testCase.verifyTrue(diagnostics.valid);
        end
    end
end
