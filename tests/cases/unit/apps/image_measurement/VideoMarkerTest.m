classdef VideoMarkerTest < matlab.unittest.TestCase
    %VIDEOMARKERTEST Verify Video Marker app-owned model and export contracts.

    methods (Test, TestTags = {'Unit'})
        function first_skeleton_preset_is_legacy_five_point_leg(testCase)
            setupLabKitTestPath();
            presets = video_marker.userInterface.skeletonPresets();
            testCase.verifyEqual(presets(1).label, "Legacy leg (5 points)");
            testCase.verifyEqual(presets(1).pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            testCase.verifyEqual(presets(1).edges, [1 2; 2 3; 3 4; 4 5]);
        end

        function visual_skeleton_setup_starts_empty_and_remaps_connections(testCase)
            setupLabKitTestPath();
            project = video_marker.appLifecycle.createProject();
            testCase.verifyEmpty(project.annotations.skeleton.pointNames);

            [skeleton, first] = video_marker.skeletonDefinition.addPoint( ...
                project.annotations.skeleton);
            [skeleton, second] = video_marker.skeletonDefinition.addPoint(skeleton);
            skeleton = video_marker.skeletonDefinition.renamePoint(skeleton, first, "hip");
            skeleton = video_marker.skeletonDefinition.renamePoint(skeleton, second, "knee");
            skeleton = video_marker.skeletonDefinition.addEdge(skeleton, first, second);
            [skeleton, newIndex] = video_marker.skeletonDefinition.movePoint(skeleton, second, -1);

            testCase.verifyEqual(newIndex, 1);
            testCase.verifyEqual(skeleton.pointNames, ["knee"; "hip"]);
            testCase.verifyEqual(skeleton.edges, [1 2]);
            skeleton = video_marker.skeletonDefinition.removePoint(skeleton, 1);
            testCase.verifyEqual(skeleton.pointNames, "hip");
            testCase.verifyEmpty(skeleton.edges);
        end

        function connect_in_order_preserves_other_connections(testCase)
            setupLabKitTestPath();
            skeleton = video_marker.skeletonDefinition.fromParts( ...
                ["a"; "b"; "c"; "d"], [1 3]);
            skeleton = video_marker.skeletonDefinition.connectInOrder(skeleton);
            testCase.verifyEqual(skeleton.edges, [1 3; 1 2; 2 3; 3 4]);
        end

        function annotations_inherit_confirm_and_export_round_trip(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            skeleton = video_marker.skeletonDefinition.fromText( ...
                "hip, knee, ankle", "hip-knee, knee-ankle");
            annotations = video_marker.frameAnnotations.emptyAnnotations(4, 3);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [10 20; 30 40; 50 60], "confirmed");
            annotations = video_marker.frameAnnotations.inheritDraft(annotations, 2);
            testCase.verifyEqual(video_marker.frameAnnotations.statusName( ...
                annotations.frameStatus(2)), "draft");
            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                annotations.frameSource(1)), "manual");
            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                annotations.frameSource(2)), "predicted");
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints(annotations, 2), ...
                [10 20; 30 40; 50 60]);

            videoInfo = struct("path", "synthetic.avi", "frameCount", 4, ...
                "frameRate", 20, "duration", 0.2, "height", 72, "width", 96);
            calibration = labkit.ui.interaction.scaleBarCalibration(40, 2, "mm");
            csvPath = fullfile(folder, "markers.csv");
            video_marker.markerCsv.writeFile(csvPath, annotations, skeleton, videoInfo, calibration);
            payload = video_marker.markerCsv.readFile(csvPath);

            testCase.verifyEqual(payload.skeleton.pointNames, ["hip"; "knee"; "ankle"]);
            testCase.verifyEqual(payload.skeleton.edges, [1 2; 2 3]);
            testCase.verifyEqual(payload.annotations.coords, annotations.coords);
            testCase.verifyEqual(payload.annotations.frameStatus, annotations.frameStatus);
        end

        function legacy_annotations_upgrade_with_manual_and_predicted_sources(testCase)
            setupLabKitTestPath();
            legacy = struct('schemaVersion', 1, ...
                'coords', NaN(3, 1, 2), ...
                'frameStatus', uint8([2; 1; 0]));
            upgraded = video_marker.frameAnnotations.upgradeAnnotationSchema(legacy);
            testCase.verifyEqual(upgraded.schemaVersion, 2);
            testCase.verifyEqual(upgraded.frameSource, uint8([1; 2; 0]));
            testCase.verifyEqual(upgraded.trackingConfidence(1), 1);
            testCase.verifyTrue(isnan(upgraded.trackingConfidence(2)));
        end

        function multiscale_patch_tracker_tracks_translated_point(testCase)
            setupLabKitTestPath();
            rng(7);
            previous = rand(80, 100);
            current = zeros(size(previous));
            current(1:78, 4:100) = previous(3:80, 1:97);
            [points, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints( ...
                previous, current, [50 40]);
            testCase.verifyEqual(points, [53 38], 'AbsTol', 0.35);
            testCase.verifyGreaterThan(confidence, 0.5);
            testCase.verifyTrue(diagnostics.valid);
            testCase.verifyEqual(diagnostics.engine, "multiscale_patch");
        end

        function multiscale_patch_tracker_refines_subpixel_motion(testCase)
            setupLabKitTestPath();
            rng(17);
            previous = rand(80, 100);
            [x, y] = meshgrid(1:100, 1:80);
            displacement = [2.4 -1.7];
            current = interp2(previous, x - displacement(1), ...
                y - displacement(2), 'linear', 0);
            [point, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints( ...
                previous, current, [50 40]);
            testCase.verifyEqual(point, [50 40] + displacement, 'AbsTol', 0.45);
            testCase.verifyGreaterThan(confidence, 0.5);
            testCase.verifyTrue(diagnostics.valid);
        end

        function multiscale_patch_tracker_is_deterministic(testCase)
            setupLabKitTestPath();
            rng(23);
            previous = rand(64, 72);
            current = circshift(previous, [-2 3]);
            args = {previous, current, [36 32], [2 -1]};
            [firstPoint, firstConfidence, firstDiagnostics] = ...
                video_marker.motionEstimate.trackPoints(args{:});
            [secondPoint, secondConfidence, secondDiagnostics] = ...
                video_marker.motionEstimate.trackPoints(args{:});
            testCase.verifyEqual(secondPoint, firstPoint);
            testCase.verifyEqual(secondConfidence, firstConfidence);
            testCase.verifyEqual(secondDiagnostics, firstDiagnostics);
        end

        function owned_tracker_matches_toolbox_app_coordinates(testCase)
            setupLabKitTestPath();
            testCase.assumeEqual(exist('vision.PointTracker', 'class'), 8, ...
                'Computer Vision Toolbox is unavailable for parity evidence.');
            rng(29);
            previous = rand(80, 100);
            current = zeros(size(previous));
            current(1:78, 4:100) = previous(3:80, 1:97);
            sourcePoint = [50 40];
            [ownedPoint, ownedConfidence, ownedDiagnostics] = ...
                video_marker.motionEstimate.trackPoints( ...
                previous, current, sourcePoint);

            tracker = vision.PointTracker( ...
                'BlockSize', [31 31], ...
                'NumPyramidLevels', 4, ...
                'MaxIterations', 30, ...
                'MaxBidirectionalError', 2.5);
            cleanup = onCleanup(@() release(tracker));
            initialize(tracker, sourcePoint, previous);
            [toolboxPoint, toolboxValid, toolboxConfidence] = tracker(current);

            % The app stores coordinates and uses confidence only as a quality
            % indicator. Subpixel solvers may differ by less than one pixel;
            % that tolerance does not change frame provenance or CSV semantics.
            testCase.verifyTrue(toolboxValid);
            testCase.verifyTrue(ownedDiagnostics.valid);
            testCase.verifyEqual(ownedPoint, toolboxPoint, 'AbsTol', 0.75);
            testCase.verifyGreaterThan(ownedConfidence, 0.5);
            testCase.verifyGreaterThan(toolboxConfidence, 0.5);
            clear cleanup
        end

        function multiscale_patch_tracker_rejects_flat_evidence(testCase)
            setupLabKitTestPath();
            image = zeros(48, 64);
            [points, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints( ...
                image, image, [32 24], [2 -1]);
            testCase.verifyEqual(points, [34 23]);
            testCase.verifyEqual(confidence, 0);
            testCase.verifyFalse(diagnostics.valid);
            testCase.verifyNotEmpty(diagnostics.failureMessage);
        end

        function forward_prediction_reuses_cache_until_manual_anchor_changes(testCase)
            setupLabKitTestPath();
            rng(11);
            frame = rand(60, 80);
            frames = {frame, frame, frame};
            readCount = 0;
            reader = @readCounted;
            annotations = video_marker.frameAnnotations.emptyAnnotations(3, 1);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [40 30], "confirmed");

            [annotations, ~, first] = video_marker.motionEstimate.predictForward( ...
                reader, annotations, 1, 3, frame);
            testCase.verifyEqual(first.predictedFrames, 2);
            testCase.verifyEqual(first.cachedFrames, 0);
            testCase.verifyEqual(readCount, 2);
            revision = annotations.anchorRevision(1);
            testCase.verifyEqual(annotations.anchorRevision(2:3), ...
                repmat(revision, 2, 1));

            [annotations, ~, second] = video_marker.motionEstimate.predictForward( ...
                reader, annotations, 1, 3, frame);
            testCase.verifyEqual(second.predictedFrames, 0);
            testCase.verifyEqual(second.cachedFrames, 2);
            testCase.verifyEqual(readCount, 3, ...
                'A valid prediction chain should decode only its target frame.');

            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [41 30], "confirmed", "manual", 1);
            [annotations, ~, third] = video_marker.motionEstimate.predictForward( ...
                reader, annotations, 1, 3, frame);
            testCase.verifyEqual(third.predictedFrames, 2);
            testCase.verifyEqual(third.cachedFrames, 0);
            testCase.verifyNotEqual(annotations.anchorRevision(2), revision);
            testCase.verifyEqual(readCount, 5);

            function image = readCounted(index)
                readCount = readCount + 1;
                image = frames{index};
            end
        end

        function coordinate_export_applies_scale_origin_and_y_axis(testCase)
            setupLabKitTestPath();
            skeleton = video_marker.skeletonDefinition.fromText("hip, knee", "hip-knee");
            annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, [11 21; 31 41], "confirmed");
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 2, [13 25; 35 45], "confirmed");
            videoInfo = struct("path", "synthetic.avi", "frameCount", 2, ...
                "frameRate", 10, "duration", 0.2, "height", 60, "width", 80);
            calibration = labkit.ui.interaction.scaleBarCalibration(20, 2, "mm");

            opts = video_marker.coordinateExport.options( ...
                "startFrame", 1, "endFrame", 2, ...
                "unitMode", "calibrated_physical", ...
                "originMode", "first_point", ...
                "yAxisMode", "up");
            T = video_marker.coordinateExport.buildTable( ...
                annotations, skeleton, videoInfo, calibration, opts);

            testCase.verifyEqual(T.hip__x, [0; 0.2], "AbsTol", 1e-12);
            testCase.verifyEqual(T.hip__y, [0; -0.4], "AbsTol", 1e-12);
            testCase.verifyEqual(T.knee__x, [2.0; 2.4], "AbsTol", 1e-12);
            testCase.verifyEqual(T.knee__y, [-2.0; -2.4], "AbsTol", 1e-12);
            testCase.verifyEqual(T.coordinate_unit, ["mm"; "mm"]);
            testCase.verifyEqual(T.origin_point_id, ["hip"; "hip"]);
        end

        function runtime_v2_project_presenter_and_resume_contracts(testCase)
            setupLabKitTestPath();
            definition = video_marker.definition();
            testCase.verifyEqual(definition.contractVersion, 2);
            project = definition.project.Create();
            project.annotations.skeleton = video_marker.skeletonDefinition.fromText( ...
                "a, b, c, d, e", "a-b, b-c, c-d, d-e");
            project.annotations.frames = ...
                video_marker.frameAnnotations.emptyAnnotations(0, 5);
            testCase.verifyTrue(definition.project.Validate(project));
            testCase.verifyEmpty(definition.project.Migrations);
            testCase.verifyFalse(isfield(project, 'currentImage'));

            session = video_marker.appLifecycle.createSession(project);
            state = struct('project', project, 'session', session);
            presentation = video_marker.userInterface.presentWorkbench(state);
            testCase.verifyTrue(isscalar(presentation));
            testCase.verifyEqual( ...
                presentation.controls.keypointTable.Data(:, 2), ...
                {'a'; 'b'; 'c'; 'd'; 'e'});
            testCase.verifyEmpty( ...
                presentation.previews.videoAxes.Axes.video.Model.imageData);
            session.selection.currentFrame = 7;
            resume = video_marker.appLifecycle.createResume(session, project);
            testCase.verifyEqual(resume.currentFrame, 7);
        end

        function legacy_project_import_is_read_only_and_complete(testCase)
            setupLabKitTestPath();
            legacy = struct();
            legacy.schemaVersion = 1;
            legacy.videoPath = "/missing/sample.avi";
            legacy.videoReference = struct( ...
                "schemaVersion", 1, "relativePath", "../media/sample.avi", ...
                "originalPath", legacy.videoPath, "fileName", "sample.avi");
            legacy.skeleton = video_marker.skeletonDefinition.fromParts( ...
                ["hip"; "knee"], [1 2]);
            legacy.annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
            legacy.annotations = video_marker.frameAnnotations.setFramePoints( ...
                legacy.annotations, 1, [10 20; 30 40], "confirmed");
            legacy.calibration = ...
                labkit.ui.interaction.scaleBarCalibration(20, 2, "mm");
            legacy.exportPreferences = struct( ...
                "unitMode", "calibrated_physical", ...
                "originMode", "first_point", "yAxisMode", "up", ...
                "startFrame", 1, "endFrame", 2);
            legacy.currentFrame = 2;

            [project, resume] = ...
                video_marker.appLifecycle.importLegacyProject(legacy);
            testCase.verifyTrue(video_marker.appLifecycle.validateProject(project));
            testCase.verifyEqual(project.inputs.sources.reference, ...
                legacy.videoReference);
            testCase.verifyEqual(project.annotations.frames.coords, ...
                legacy.annotations.coords);
            testCase.verifyEqual( ...
                project.parameters.coordinateUnitMode, ...
                "calibrated_physical");
            testCase.verifyEqual(resume.currentFrame, 2);
            testCase.verifyFalse(isfield(project, 'videoPath'));
        end
    end
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
