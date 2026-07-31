classdef VideoMarkerMotionEstimateSpec < matlab.unittest.TestCase
    %VIDEOMARKERMOTIONESTIMATESPEC Guard multiscale point tracking.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
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
