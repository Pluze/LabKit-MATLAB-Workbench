classdef GaitAnalysisTest < matlab.unittest.TestCase
    %GAITANALYSISTEST Verify current Video Marker input and gait metrics.

    methods (Test, TestTags = {'Unit'})
        function current_video_marker_project_imports_source_facts(testCase)
            setupLabKitTestPath();
            folder = makeFolder();
            cleanup = onCleanup(@() cleanupFolder(folder));
            [labkitProject, expected] = consumerMarkerProject();
            projectPath = fullfile(folder, "walk.video_marker.autosave.mat");
            save(projectPath, "labkitProject");

            pose = gait_analysis.sourceFiles.readPoseFile(projectPath);

            testCase.verifyEqual(pose.sourceFormat, ...
                "mat.videoMarkerProjectV2");
            testCase.verifyEqual(pose.coords, expected);
            testCase.verifyEqual(pose.pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            testCase.verifyEqual(pose.frameIndex, (1:12).');
            testCase.verifyEqual(pose.time, (0:11).' ./ 30, "AbsTol", 1e-12);
            testCase.verifyEqual(pose.frameRate, 30);
            testCase.verifyEqual(pose.skeleton.edges, ...
                [1 2; 2 3; 3 4; 4 5]);
            testCase.verifyEqual(pose.pixelsPerUnit, 10);
            testCase.verifyEqual(pose.unitName, "mm");
        end

        function analysis_segments_active_swings_and_reports_metrics(testCase)
            setupLabKitTestPath();
            pose = syntheticPose();
            opts = gait_analysis.analysisRun.defaultOptions();
            opts.smoothWindow = 1;
            opts.detectionProminence = 2;
            opts.minLiftOffIntervalSeconds = 0.1;
            opts.minStepLength = 2;

            result = gait_analysis.analysisRun.computeGait(pose, opts);

            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.events.liftOffFrames, [3; 9]);
            testCase.verifyEqual(result.events.landingFrames, [5; 11]);
            testCase.verifyEqual(height(result.stepTable), 2);
            testCase.verifyEqual(result.stepTable.is_valid, [true; true]);
            testCase.verifyEqual(result.stepTable.step_length, [5; 6], ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(result.stepTable.swing_time_s, [2; 2] ./ 30, ...
                "AbsTol", 1e-12);
            testCase.verifyTrue(all(ismember( ...
                ["hip_min_deg", "hip_max_deg", "hip_rom_deg"], ...
                string(result.stepTable.Properties.VariableNames))));
            testCase.verifyEqual(find(result.frameTable.landing_event), [5; 11]);
        end

        function completed_final_swing_is_not_dropped(testCase)
            setupLabKitTestPath();
            pose = syntheticPose();
            pose.coords = pose.coords(7:end, :, :);
            pose.frameIndex = (1:6).';
            pose.time = (0:5).' ./ 30;
            opts = gait_analysis.analysisRun.defaultOptions();
            opts.smoothWindow = 1;
            opts.detectionProminence = 2;

            result = gait_analysis.analysisRun.computeGait(pose, opts);

            testCase.verifyEqual(result.events.liftOffFrames, 3);
            testCase.verifyEqual(result.events.landingFrames, 5);
            testCase.verifyEqual(height(result.stepTable), 1);
        end

        function rejects_legacy_and_unrelated_mat_files(testCase)
            setupLabKitTestPath();
            folder = makeFolder();
            cleanup = onCleanup(@() cleanupFolder(folder));
            coords = zeros(4, 5, 2);
            legacyPath = fullfile(folder, "legacy.mat");
            save(legacyPath, "coords");

            testCase.verifyError( ...
                @() gait_analysis.sourceFiles.readPoseFile(legacyPath), ...
                'labkit_GaitAnalysis_app:InvalidMarkerProject');
        end

        function rejects_marker_project_without_timing_metadata(testCase)
            setupLabKitTestPath();
            folder = makeFolder();
            cleanup = onCleanup(@() cleanupFolder(folder));
            [labkitProject, ~] = consumerMarkerProject();
            labkitProject.payload.inputs.videoMetadata.frameRate = 0;
            projectPath = fullfile(folder, "missing-rate.mat");
            save(projectPath, "labkitProject");

            testCase.verifyError( ...
                @() gait_analysis.sourceFiles.readPoseFile(projectPath), ...
                'labkit_GaitAnalysis_app:MissingVideoMetadata');
        end

        function source_facts_replace_previous_time_scale_and_roles(testCase)
            setupLabKitTestPath();
            pose = syntheticPose();
            pose.frameRate = 120;
            pose.pointNames(1) = "iliac_crest";
            options = gait_analysis.analysisRun.defaultOptions();
            options.frameRate = 10;
            options.pixelsPerUnit = 22;
            options.unitName = "mm";
            options.iliacPoint = "old_iliac";

            actual = gait_analysis.analysisRun.optionsForPose(pose, options);

            testCase.verifyEqual(actual.frameRate, 120);
            testCase.verifyEqual(actual.pixelsPerUnit, 1);
            testCase.verifyEqual(actual.unitName, "px");
            testCase.verifyEqual(actual.iliacPoint, "iliac_crest");
        end

        function result_csv_set_round_trips(testCase)
            setupLabKitTestPath();
            folder = makeFolder();
            cleanup = onCleanup(@() cleanupFolder(folder));
            result = gait_analysis.analysisRun.computeGait( ...
                syntheticPose(), analysisOptions());

            outputs = gait_analysis.resultFiles.writeOutputs( ...
                folder, "gait", result);

            outputPaths = [outputs.frameCsv; outputs.coordinateCsv; ...
                outputs.stepCsv; outputs.summaryCsv];
            testCase.verifyTrue(all(isfile(outputPaths)));
            steps = readtable(outputs.stepCsv, "TextType", "string");
            testCase.verifyTrue(any(string(steps.Properties.VariableNames) == ...
                "swing_time_s"));
        end

        function project_migration_renames_v1_options(testCase)
            setupLabKitTestPath();
            spec = gait_analysis.projectSpec();
            project = spec.Create();
            project.parameters = rmfield(project.parameters, ...
                {'minLiftOffIntervalSeconds', 'minSwingFrames', ...
                'maxSwingFrames', 'minStepLength', 'maxHipTranslation', ...
                'detectionMinHeightSigma'});
            project.parameters.minStepIntervalSeconds = 0.25;
            project.parameters.minStepFrames = 4;
            project.parameters.maxStepFrames = 40;
            project.parameters.minStride = 3;
            project.parameters.maxBodyDrift = 9;

            migrated = spec.Migrate(project, 1);

            testCase.verifyEqual(migrated.parameters.minLiftOffIntervalSeconds, 0.25);
            testCase.verifyEqual(migrated.parameters.minSwingFrames, 4);
            testCase.verifyEqual(migrated.parameters.maxSwingFrames, 40);
            testCase.verifyEqual(migrated.parameters.minStepLength, 3);
            testCase.verifyEqual(migrated.parameters.maxHipTranslation, 9);
            testCase.verifyEqual(migrated.parameters.detectionMinHeightSigma, 2);
            testCase.verifyFalse(isfield(migrated.parameters, 'minStride'));
        end

        function project_migration_adopts_canonical_source_collection(testCase)
            setupLabKitTestPath();
            spec = gait_analysis.projectSpec();
            project = spec.Create();
            expected = struct("absolutePath", "/tmp/walk.mat");
            project.inputs.source = expected;
            project.inputs = rmfield(project.inputs, "sources");

            migrated = spec.Migrate(project, 2);
            definition = gait_analysis.definition();

            testCase.verifyEqual(migrated.inputs.sources, expected);
            testCase.verifyFalse(isfield(migrated.inputs, "source"));
            testCase.verifyEqual(definition.project.Version, 3);
            testCase.verifyTrue(isa(definition.project.Migrate, ...
                'function_handle'));
        end

        function debug_sample_runs_on_an_isolated_gait_path(testCase)
            [root, appRoot] = gaitRoots();
            previousPath = path;
            pathCleanup = onCleanup(@() path(previousPath));
            restoredefaultpath;
            addpath(root);
            addpath(appRoot);
            rehash path

            pack = gait_analysis.debug.writeSamplePack();
            pose = gait_analysis.sourceFiles.readPoseFile( ...
                pack.representativeFiles);

            testCase.verifyTrue(pose.ok);
            testCase.verifyEqual(pose.frameRate, 30);
            testCase.verifyEmpty(which("video_marker.projectSpec"));

            clear pathCleanup
        end
    end

    methods (Test, TestTags = {'Integration'})
        function current_video_marker_producer_matches_gait_reader(testCase)
            setupLabKitTestPath();
            folder = makeFolder();
            cleanup = onCleanup(@() cleanupFolder(folder));
            [labkitProject, expected] = producerMarkerProject();
            projectPath = fullfile(folder, ...
                "producer.video_marker.autosave.mat");
            save(projectPath, "labkitProject");

            pose = gait_analysis.sourceFiles.readPoseFile(projectPath);

            testCase.verifyEqual(pose.coords, expected);
            testCase.verifyEqual(pose.frameRate, 30);
            testCase.verifyEqual(pose.skeleton.edges, ...
                [1 2; 2 3; 3 4; 4 5]);
            testCase.verifyEqual(pose.unitName, "mm");
        end
    end
end

function [labkitProject, coords] = consumerMarkerProject()
    pose = syntheticPose();
    coords = pose.coords;
    pointNames = pose.pointNames;
    frames = struct( ...
        "schemaVersion", 2, ...
        "coords", coords, ...
        "frameStatus", zeros(12, 1, "uint8"), ...
        "frameSource", zeros(12, 1, "uint8"), ...
        "trackingConfidence", NaN(12, 5), ...
        "anchorRevision", zeros(12, 1, "uint64"));
    project = struct();
    project.inputs = struct( ...
        "sources", labkit.ui.runtime.emptySourceRecords(), ...
        "videoMetadata", markerVideoMetadata());
    project.parameters = struct();
    project.annotations = struct( ...
        "skeleton", struct( ...
        "schemaVersion", 1, ...
        "pointIds", pointNames, ...
        "pointNames", pointNames, ...
        "edges", [1 2; 2 3; 3 4; 4 5]), ...
        "frames", frames, ...
        "calibration", ...
        labkit.ui.interaction.scaleBarCalibration(20, 2, "mm"));
    project.results = struct();
    project.extensions = struct();
    labkitProject = markerEnvelope(project);
end

function [labkitProject, coords] = producerMarkerProject()
    pose = syntheticPose();
    coords = pose.coords;
    spec = video_marker.projectSpec();
    project = spec.Create();
    project.annotations.skeleton = video_marker.skeletonDefinition.fromParts( ...
        pose.pointNames, [1 2; 2 3; 3 4; 4 5]);
    project.annotations.frames = ...
        video_marker.frameAnnotations.emptyAnnotations(12, 5);
    project.annotations.frames.coords = coords;
    project.inputs.videoMetadata = markerVideoMetadata();
    project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration(20, 2, "mm");
    assert(spec.Validate(project));
    labkitProject = markerEnvelope(project);
end

function metadata = markerVideoMetadata()
    metadata = struct( ...
        "frameCount", 12, ...
        "frameRate", 30, ...
        "duration", 12/30, ...
        "height", 100, ...
        "width", 200);
end

function labkitProject = markerEnvelope(project)
    labkitProject = struct( ...
        "format", "labkit.project", ...
        "formatVersion", struct("major", 1, "minor", 0), ...
        "app", struct("id", "video_marker", "payloadVersion", 2), ...
        "document", struct(), "producer", struct(), ...
        "sources", struct([]), "payload", project);
end

function [root, appRoot] = gaitRoots()
    testFile = mfilename("fullpath");
    root = fileparts(fileparts(fileparts(fileparts( ...
        fileparts(fileparts(testFile))))));
    appRoot = fullfile(root, "apps", "gait", "gait_analysis");
end

function pose = syntheticPose()
    frames = (1:12).';
    footX = [0; 1; 5; 3; 0; 1; 0; 1; 6; 4; 0; 1];
    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.sourceFormat = "synthetic";
    pose.pointNames = ["iliac"; "hip"; "knee"; "ankle"; "foot"];
    pose.frameIndex = frames;
    pose.time = (frames - 1) ./ 30;
    pose.frameRate = 30;
    pose.unitName = "px";
    pose.skeleton = struct("pointIds", pose.pointNames, ...
        "pointNames", pose.pointNames, "edges", [1 2; 2 3; 3 4; 4 5]);
    coords = NaN(12, 5, 2);
    coords(:, :, 1) = [-2*ones(12,1), zeros(12,1), ...
        ones(12,1), 2*ones(12,1), footX];
    coords(:, :, 2) = [8*ones(12,1), 6*ones(12,1), ...
        4 + 0.2.*sin(frames), 2 + 0.2.*cos(frames), zeros(12,1)];
    pose.coords = coords;
    pose.ok = true;
end

function opts = analysisOptions()
    opts = gait_analysis.analysisRun.defaultOptions();
    opts.smoothWindow = 1;
    opts.detectionProminence = 2;
end

function folder = makeFolder()
    folder = string(tempname);
    mkdir(folder);
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
