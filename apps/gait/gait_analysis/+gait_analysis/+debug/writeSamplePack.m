%WRITESAMPLEPACK Create a synthetic current Video Marker project for Gait.
% Expected caller: debug startup and GUI tests. The MAT contains no source
% path, sample identifier, or lab data.
function pack = writeSamplePack(debugLog)
    root = fullfile(tempdir, "labkit_gait_analysis_debug");
    if ~isfolder(root)
        mkdir(root);
    end
    spec = video_marker.projectSpec();
    project = spec.Create();
    project.annotations.skeleton = video_marker.skeletonDefinition.fromParts( ...
        ["iliac"; "hip"; "knee"; "ankle"; "foot"], ...
        [1 2; 2 3; 3 4; 4 5]);
    project.annotations.frames = syntheticAnnotations();
    project.inputs.videoMetadata = struct( ...
        "frameCount", 12, "frameRate", 30, "duration", 12/30, ...
        "height", 16, "width", 128);
    project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration([], [], "px");
    labkitProject = struct( ...
        "format", "labkit.project", ...
        "formatVersion", struct("major", 1, "minor", 0), ...
        "app", struct("id", "video_marker", "payloadVersion", 2), ...
        "document", struct(), "producer", struct(), ...
        "sources", struct([]), "payload", project);
    posePath = fullfile(root, "synthetic.video_marker.autosave.mat");
    save(posePath, 'labkitProject');

    pack = struct("sampleFolder", string(root), ...
        "representativeFiles", string(posePath));
    if nargin > 0 && ismethod(debugLog, "trace")
        debugLog.trace("Gait analysis debug Video Marker project written.");
    end
end

function annotations = syntheticAnnotations()
    frame = (1:12).';
    footX = [0; 2; 100; 30; 0; 2; 0; 2; 110; 35; 0; 2];
    coords = NaN(12, 5, 2);
    coords(:, :, 1) = [-2*ones(12, 1), zeros(12, 1), ...
        ones(12, 1), 2*ones(12, 1), footX];
    coords(:, :, 2) = [8*ones(12, 1), 6*ones(12, 1), ...
        4 + 0.2 .* sin(frame), 2 + 0.2 .* cos(frame), zeros(12, 1)];
    annotations = video_marker.frameAnnotations.emptyAnnotations(12, 5);
    annotations.coords = coords;
    annotations.frameStatus(:) = uint8(2);
    annotations.frameSource(:) = uint8(1);
end
