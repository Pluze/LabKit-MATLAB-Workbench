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

        function keepsTheLegacyPresetAndEditableConnectionLifecycle(testCase)
            preset = video_marker.skeletonSetup.presets();
            project = video_marker.initialData();
            skeleton = project.annotations.skeleton;
            [skeleton, first] = video_marker.skeletonDefinition.addPoint(skeleton);
            [skeleton, second] = video_marker.skeletonDefinition.addPoint(skeleton);
            skeleton = video_marker.skeletonDefinition.renamePoint(skeleton, first, "hip");
            skeleton = video_marker.skeletonDefinition.renamePoint(skeleton, second, "knee");
            skeleton = video_marker.skeletonDefinition.addEdge(skeleton, first, second);
            skeleton = video_marker.skeletonDefinition.removePoint(skeleton, first);

            testCase.verifyEqual(preset(1).label, "Legacy leg (5 points)");
            testCase.verifyEqual(preset(1).pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            testCase.verifyEqual(skeleton.pointNames, "knee");
            testCase.verifyEmpty(skeleton.edges);
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

        function refinesSubpixelMotionDeterministically(testCase)
            rng(17);
            previous = rand(80, 100);
            [x, y] = meshgrid(1:100, 1:80);
            displacement = [2.4 -1.7];
            current = interp2(previous, x - displacement(1), ...
                y - displacement(2), "linear", 0);

            [firstPoint, firstConfidence, firstDiagnostics] = ...
                video_marker.motionEstimate.trackPoints(previous, current, [50 40]);
            [secondPoint, secondConfidence, secondDiagnostics] = ...
                video_marker.motionEstimate.trackPoints(previous, current, [50 40]);

            testCase.verifyEqual(firstPoint, [50 40] + displacement, AbsTol=.45);
            testCase.verifyGreaterThan(firstConfidence, .5);
            testCase.verifyTrue(firstDiagnostics.valid);
            testCase.verifyEqual(secondPoint, firstPoint);
            testCase.verifyEqual(secondConfidence, firstConfidence);
            testCase.verifyEqual(secondDiagnostics, firstDiagnostics);
        end

        function reusesPredictionsUntilTheManualAnchorChanges(testCase)
            rng(11);
            frame = rand(60, 80);
            frames = {frame, frame, frame};
            reads = 0;
            annotations = video_marker.frameAnnotations.emptyAnnotations(3, 1);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [40 30], "confirmed");

            [annotations, ~, first] = video_marker.motionEstimate.predictForward( ...
                @readFrame, annotations, 1, 3, frame);
            revision = annotations.anchorRevision(1);
            [annotations, ~, second] = video_marker.motionEstimate.predictForward( ...
                @readFrame, annotations, 1, 3, frame);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [41 30], "confirmed", "manual", 1);
            [annotations, ~, third] = video_marker.motionEstimate.predictForward( ...
                @readFrame, annotations, 1, 3, frame);

            testCase.verifyEqual([first.predictedFrames first.cachedFrames], [2 0]);
            testCase.verifyEqual([second.predictedFrames second.cachedFrames], [0 2]);
            testCase.verifyEqual([third.predictedFrames third.cachedFrames], [2 0]);
            testCase.verifyNotEqual(annotations.anchorRevision(2), revision);
            testCase.verifyEqual(reads, 5);

            function image = readFrame(index)
                reads = reads + 1;
                image = frames{index};
            end
        end
    end
end
