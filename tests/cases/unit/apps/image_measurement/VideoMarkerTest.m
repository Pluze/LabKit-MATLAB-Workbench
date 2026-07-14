classdef VideoMarkerTest < matlab.unittest.TestCase
    %VIDEOMARKERTEST Verify Video Marker app-owned model and export contracts.

    methods (Test, TestTags = {'Unit'})
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
    end
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
