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
            state = video_marker.appLifecycle.createInitialState();
            testCase.verifyEmpty(state.skeleton.pointNames);

            [skeleton, first] = video_marker.skeletonDefinition.addPoint(state.skeleton);
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

        function pyramidal_klt_tracks_translated_point(testCase)
            setupLabKitTestPath();
            testCase.assumeEqual(exist('vision.PointTracker', 'class'), 8, ...
                'Computer Vision Toolbox is unavailable.');
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
            testCase.verifyEqual(diagnostics.engine, "pyramidal_klt");
        end

        function forward_prediction_reuses_cache_until_manual_anchor_changes(testCase)
            setupLabKitTestPath();
            testCase.assumeEqual(exist('vision.PointTracker', 'class'), 8, ...
                'Computer Vision Toolbox is unavailable.');
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

        function project_save_load_excludes_current_frame_image(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            state = video_marker.appLifecycle.createInitialState();
            state.skeleton = video_marker.skeletonDefinition.fromText( ...
                "a, b, c, d, e", "a-b, b-c, c-d, d-e");
            state.videoPath = "synthetic.avi";
            state.videoInfo = struct("path", "synthetic.avi", "frameCount", 1, ...
                "frameRate", 10, "duration", 0.1, "height", 4, "width", 5);
            state.annotations = video_marker.frameAnnotations.emptyAnnotations(1, 5);
            state.currentImage = uint8(ones(4, 5, 3));
            projectPath = fullfile(folder, "project.mat");

            video_marker.projectFiles.saveProject(projectPath, state);
            loaded = video_marker.projectFiles.loadProject(projectPath);

            testCase.verifyEqual(loaded.videoPath, "synthetic.avi");
            testCase.verifyEmpty(loaded.currentImage);
            testCase.verifyEqual(size(loaded.annotations.coords), [1 5 2]);
        end

        function project_video_reference_survives_bundle_move(testCase)
            setupLabKitTestPath();
            sourceRoot = string(tempname);
            movedRoot = string(tempname);
            mkdir(fullfile(sourceRoot, "projects"));
            mkdir(fullfile(sourceRoot, "media"));
            cleanup = onCleanup(@() cleanupTwoFolders(sourceRoot, movedRoot));
            videoPath = fullfile(sourceRoot, "media", "sample.avi");
            fileId = fopen(videoPath, 'w');
            fclose(fileId);

            state = video_marker.appLifecycle.createInitialState();
            state.videoPath = videoPath;
            state.videoInfo.path = videoPath;
            projectPath = fullfile(sourceRoot, "projects", "project.mat");
            state.projectPath = projectPath;
            video_marker.projectFiles.saveProject(projectPath, state);
            movefile(sourceRoot, movedRoot);

            movedProject = fullfile(movedRoot, "projects", "project.mat");
            movedVideo = fullfile(movedRoot, "media", "sample.avi");
            loaded = video_marker.projectFiles.loadProject(movedProject);
            expectedVideo = canonicalExistingPath(movedVideo);
            testCase.verifyEqual(string(loaded.videoPath), expectedVideo);
            testCase.verifyEqual(string(loaded.videoInfo.path), expectedVideo);
        end

        function autosave_round_trip_is_atomic_and_discardable(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));
            videoPath = fullfile(folder, "sample.avi");
            state = video_marker.appLifecycle.createInitialState();
            state.videoPath = videoPath;
            state.skeleton = video_marker.skeletonDefinition.fromParts( ...
                ["hip"; "knee"], [1 2]);
            state.videoInfo = struct("path", videoPath, "frameCount", 2, ...
                "frameRate", 20, "duration", 0.1, "height", 40, "width", 50);
            state.annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
            state.annotations = video_marker.frameAnnotations.setFramePoints( ...
                state.annotations, 1, [10 20; 30 40], "confirmed");
            state.currentImage = ones(40, 50, 'uint8');

            visiblePath = video_marker.autosave.filePath(videoPath);
            testCase.verifyEqual(string(fileparts(visiblePath)), ...
                fullfile(folder, "Video Marker Autosaves"));
            testCase.verifyEqual(string(visiblePath), fullfile(folder, ...
                "Video Marker Autosaves", "sample.video_marker.autosave.mat"));
            autosavePath = video_marker.autosave.write(videoPath, state, folder);
            [loaded, found] = video_marker.autosave.read(videoPath, folder);
            testCase.verifyTrue(found);
            testCase.verifyEqual(loaded.annotations.coords, state.annotations.coords);
            testCase.verifyEmpty(loaded.currentImage);
            testCase.verifyEqual(exist(autosavePath + ".tmp", 'file'), 0);
            video_marker.autosave.discard(videoPath, folder);
            [~, found] = video_marker.autosave.read(videoPath, folder);
            testCase.verifyFalse(found);
        end
    end
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end

function cleanupTwoFolders(first, second)
    cleanupFolder(first);
    cleanupFolder(second);
end

function pathValue = canonicalExistingPath(pathValue)
    [exists, attributes] = fileattrib(char(pathValue));
    assert(exists, 'Expected test file does not exist.');
    pathValue = string(attributes.Name);
end
