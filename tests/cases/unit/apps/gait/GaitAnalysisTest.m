classdef GaitAnalysisTest < matlab.unittest.TestCase
    %GAITANALYSISTEST Verify Gait Analysis app-owned input and metric contracts.

    methods (Test, TestTags = {'Unit'})
        function generic_csv_imports_and_computes_step_metrics(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            csvPath = fullfile(folder, "pose.csv");
            writetable(syntheticPoseTable(), csvPath);

            pose = gait_analysis.sourceFiles.readPoseFile(csvPath);
            testCase.verifyEqual(pose.pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);

            opts = gait_analysis.appState.defaultOptions();
            opts.smoothWindow = 1;
            opts.minStepFrames = 3;
            opts.minStride = 2;
            result = gait_analysis.analysisRun.computeGait(pose, opts);

            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.events.contactFrames, [2; 6; 10]);
            testCase.verifyEqual(height(result.stepTable), 2);
            testCase.verifyEqual(result.stepTable.is_valid, [true; true]);
            testCase.verifyEqual(result.stepTable.stride_length, [7; 7], ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(result.stepTable.step_time_s, [4; 4] ./ 30, ...
                "AbsTol", 1e-12);
            testCase.verifyTrue(any(result.summaryTable.Metric == "Valid steps"));
        end

        function labkit_coordinate_csv_imports_double_underscore_columns(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            T = table();
            T.frame_index = [1; 2];
            T.time_s = [0; 0.1];
            T.coordinate_unit = ["mm"; "mm"];
            T.hip__x = [1; 2];
            T.hip__y = [3; 4];
            T.foot__x = [5; 6];
            T.foot__y = [7; 8];
            csvPath = fullfile(folder, "coordinates.csv");
            writetable(T, csvPath);

            pose = gait_analysis.sourceFiles.readPoseFile(csvPath);

            testCase.verifyEqual(pose.unitName, "mm");
            testCase.verifyEqual(pose.pointNames, ["hip"; "foot"]);
            testCase.verifyEqual(squeeze(pose.coords(:, 1, 1)), [1; 2]);
            testCase.verifyEqual(squeeze(pose.coords(:, 2, 2)), [7; 8]);
        end

        function mat_pose_and_result_csv_set_round_trip(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            pose = tableToPose(syntheticPoseTable());
            matPath = fullfile(folder, "pose.mat");
            coords = pose.coords;
            pointNames = pose.pointNames;
            frameIndex = pose.frameIndex;
            time = pose.time;
            unitName = "px";
            save(matPath, "coords", "pointNames", "frameIndex", "time", "unitName");

            imported = gait_analysis.sourceFiles.readPoseFile(matPath);
            opts = gait_analysis.appState.defaultOptions();
            opts.smoothWindow = 1;
            result = gait_analysis.analysisRun.computeGait(imported, opts);
            outputs = gait_analysis.resultFiles.writeOutputs(folder, "gait", result);

            testCase.verifyTrue(isfile(outputs.frameCsv));
            testCase.verifyTrue(isfile(outputs.coordinateCsv));
            testCase.verifyTrue(isfile(outputs.stepCsv));
            testCase.verifyTrue(isfile(outputs.summaryCsv));
            stepTable = readtable(outputs.stepCsv, "TextType", "string");
            testCase.verifyTrue(any(string(stepTable.Properties.VariableNames) == "hip_rom_deg"));
        end

        function video_marker_project_and_autosave_import_as_pose(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            skeleton = video_marker.skeletonDefinition.fromParts( ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"], ...
                [1 2; 2 3; 3 4; 4 5]);
            frames = video_marker.frameAnnotations.emptyAnnotations(4, 5);
            expected = reshape(1:40, [4 5 2]);
            frames.coords = expected;
            project = video_marker.appLifecycle.createProject();
            project.annotations.skeleton = skeleton;
            project.annotations.frames = frames;
            labkitProject = struct( ...
                "format", "labkit.project", ...
                "formatVersion", struct("major", 1, "minor", 0), ...
                "app", struct("id", "video_marker", "payloadVersion", 1), ...
                "document", struct(), "producer", struct(), ...
                "sources", struct([]), "payload", project);

            projectPath = fullfile(folder, "video-marker-project.mat");
            save(projectPath, "labkitProject");
            pose = gait_analysis.sourceFiles.readPoseFile(projectPath);
            testCase.verifyEqual(pose.sourceFormat, ...
                "mat.labkitMarkerProject");
            testCase.verifyEqual(pose.pointNames, skeleton.pointNames);
            testCase.verifyEqual(pose.coords, expected);
            testCase.verifyEqual(pose.frameIndex, (1:4).');
            testCase.verifyTrue(all(isnan(pose.time)));

            autosavePath = fullfile(folder, "recovery.mat");
            save(autosavePath, "labkitProject");
            autosavePose = gait_analysis.sourceFiles.readPoseFile(autosavePath);
            testCase.verifyEqual(autosavePose.coords, expected);
        end

        function coordinate_export_keeps_pixels_and_scaled_origin_columns(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));

            pose = tableToPose(syntheticPoseTable());
            opts = gait_analysis.appState.defaultOptions();
            opts.smoothWindow = 1;
            opts.pixelsPerUnit = 2;
            opts.unitName = "mm";
            opts.originAtFirstFrameFirstPoint = true;
            result = gait_analysis.analysisRun.computeGait(pose, opts);
            outputs = gait_analysis.resultFiles.writeOutputs(folder, "gait", result);

            coordinates = readtable(outputs.coordinateCsv, ...
                "TextType", "string", "VariableNamingRule", "preserve");
            testCase.verifyEqual(coordinates.coordinate_unit(1), "mm");
            testCase.verifyEqual(coordinates.origin_mode(1), "first_frame_first_point");
            testCase.verifyEqual(coordinates.origin_point(1), "iliac");
            testCase.verifyEqual(coordinates.origin_x_px_value(1), -2);
            testCase.verifyEqual(coordinates.origin_y_px_value(1), 8);
            testCase.verifyEqual(coordinates.("hip__x_px")(1), 0);
            testCase.verifyEqual(coordinates.("hip__y_px")(1), 6);
            testCase.verifyEqual(coordinates.("hip__x")(1), 1);
            testCase.verifyEqual(coordinates.("hip__y")(1), -1);

            reloaded = gait_analysis.sourceFiles.readPoseFile(outputs.coordinateCsv);
            testCase.verifyEqual(reloaded.pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            testCase.verifyEqual(reloaded.unitName, "px");
            testCase.verifyEqual(squeeze(reloaded.coords(1, 2, :)), [0; 6]);
        end
    end
end

function T = syntheticPoseTable()
    frames = (1:12).';
    time = (frames - 1) ./ 30;
    hipX = zeros(size(frames));
    footRel = [-2; -3; -1; 2; 4; -3; -1; 2; 4; -3; -1; 1];
    T = table();
    T.frame_index = frames;
    T.time_s = time;
    T.iliac_x = hipX - 2;
    T.iliac_y = 8 + zeros(size(frames));
    T.hip_x = hipX;
    T.hip_y = 6 + zeros(size(frames));
    T.knee_x = hipX + 1;
    T.knee_y = 4 + 0.2 .* sin(frames);
    T.ankle_x = hipX + 2;
    T.ankle_y = 2 + 0.2 .* cos(frames);
    T.foot_x = hipX + footRel;
    T.foot_y = zeros(size(frames));
end

function pose = tableToPose(T)
    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.sourceFormat = "synthetic";
    pose.pointNames = ["iliac"; "hip"; "knee"; "ankle"; "foot"];
    pose.frameIndex = T.frame_index;
    pose.time = T.time_s;
    pose.unitName = "px";
    coords = NaN(height(T), numel(pose.pointNames), 2);
    for p = 1:numel(pose.pointNames)
        name = char(pose.pointNames(p));
        coords(:, p, 1) = T.([name '_x']);
        coords(:, p, 2) = T.([name '_y']);
    end
    pose.coords = coords;
    pose.ok = true;
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
