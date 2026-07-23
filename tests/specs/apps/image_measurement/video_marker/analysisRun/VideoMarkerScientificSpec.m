classdef VideoMarkerScientificSpec < matlab.unittest.TestCase
    %VIDEOMARKERSCIENTIFICSPEC Specify skeleton and motion-estimation behavior.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function preservesConnectionsWhenTheEditableSkeletonIsReordered(testCase)
            skeleton = video_marker.skeletonDefinition.fromParts( ...
                ["hip"; "knee"; "ankle"], [1 3]);
            [skeleton, index] = video_marker.skeletonDefinition.movePoint( ...
                skeleton, 3, -2);
            skeleton = video_marker.skeletonDefinition.connectInOrder(skeleton);

            testCase.verifyEqual(index, 2);
            testCase.verifyEqual(skeleton.pointNames, ["hip"; "ankle"; "knee"]);
            testCase.verifyEqual(skeleton.edges, [1 2; 2 3]);
        end

        function tracksAControlledTranslationWithHighConfidence(testCase)
            rng(7);
            previous = rand(80, 100);
            current = zeros(size(previous));
            current(1:78, 4:100) = previous(3:80, 1:97);

            [point, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints(previous, current, [50 40]);

            testCase.verifyEqual(point, [53 38], AbsTol=.35);
            testCase.verifyGreaterThan(confidence, .5);
            testCase.verifyTrue(diagnostics.valid);
            testCase.verifyEqual(diagnostics.engine, "multiscale_patch");
        end

        function rejectsTrackingWithoutImageEvidence(testCase)
            image = zeros(48, 64);

            [point, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints(image, image, [32 24], [2 -1]);

            testCase.verifyEqual(point, [34 23]);
            testCase.verifyEqual(confidence, 0);
            testCase.verifyFalse(diagnostics.valid);
            testCase.verifyNotEmpty(diagnostics.failureMessage);
        end
    end
end
