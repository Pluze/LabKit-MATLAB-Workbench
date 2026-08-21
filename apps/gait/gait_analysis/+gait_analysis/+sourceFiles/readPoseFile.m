function pose = readPoseFile(filepath)
%READPOSEFILE Read one current Video Marker MAT project for gait analysis.
%
% Usage:
%   pose = gait_analysis.sourceFiles.readPoseFile(filepath)
%
% Inputs:
%   filepath - Scalar path to a MAT file containing one current
%       `videoMarkerArchive` produced by Video Marker payload version 3.
%       The reader loads only that named variable and never reopens the video.
%
% Outputs:
%   pose - Normalized scalar structure. coords is F-by-P-by-2 [x y] image
%       coordinates; pointNames and skeleton preserve the Video Marker order;
%       frameIndex is 1:F; time is derived from embedded frameRate; annotation
%       status/source, calibration, video metadata, and units are preserved.
%
% Errors:
%   labkit_GaitAnalysis_app:PoseFileNotFound - filepath does not exist.
%   labkit_GaitAnalysis_app:UnsupportedPoseFile - filepath is not MAT.
%   labkit_GaitAnalysis_app:InvalidMarkerProject - The file is not a current
%       Video Marker project or its coordinate/skeleton shapes disagree.
%   labkit_GaitAnalysis_app:MissingVideoMetadata - Embedded timing metadata is
%       absent, invalid, or has a nonpositive frame rate.
%
% Description:
%   Video Marker MAT is the sole file-input contract for Gait Analysis. CSV,
%   arbitrary workspace MAT variables, and legacy marker payloads are rejected
%   because they do not jointly own timing, skeleton, calibration, and frame
%   provenance. `computeGait` remains callable with an in-memory normalized pose
%   for deterministic tests and GUI-free calculations.
%
% Typical Call:
%   pose = gait_analysis.sourceFiles.readPoseFile("walk.video_marker.autosave.mat");
%   assert(pose.ok && pose.frameRate > 0)
%
% See also gait_analysis.analysisRun.computeGait,
%   video_marker.videoSource.metadataFromInfo

    filepath = string(filepath);
    if ~isscalar(filepath) || strlength(filepath) == 0 || ~isfile(filepath)
        error('labkit_GaitAnalysis_app:PoseFileNotFound', ...
            'Video Marker project file was not found.');
    end
    [~, ~, extension] = fileparts(filepath);
    if lower(string(extension)) ~= ".mat"
        error('labkit_GaitAnalysis_app:UnsupportedPoseFile', ...
            'Gait Analysis accepts current Video Marker MAT archives only.');
    end
    inventory = string(who('-file', filepath));
    if numel(inventory) ~= 1 || inventory ~= "videoMarkerArchive"
        invalidMarker('MAT file is not a current Video Marker archive.');
    end
    loaded = load(filepath, 'videoMarkerArchive');
    pose = poseFromArchive(loaded.videoMarkerArchive);
    pose.sourcePath = filepath;
    pose.sourceFormat = "mat.videoMarkerArchiveV3";
    pose.ok = true;
end

function pose = poseFromArchive(archive)
    fields = ["format", "formatVersion", "payloadVersion", ...
        "project", "currentFrame"];
    if ~isstruct(archive) || ~isscalar(archive) || ...
            ~isequal(sort(string(fieldnames(archive))), sort(fields(:))) || ...
            ~isTextScalar(archive.format) || ...
            string(archive.format) ~= "video_marker.archive" || ...
            ~isCurrentVersion(archive.formatVersion, 1) || ...
            ~isCurrentVersion(archive.payloadVersion, 3) || ...
            ~isstruct(archive.project) || ~isscalar(archive.project)
        invalidMarker('Gait Analysis requires a current Video Marker archive.');
    end
    project = archive.project;
    if ~all(isfield(project, {'inputs', 'annotations'})) || ...
            ~isfield(project.annotations, 'frames') || ...
            ~isfield(project.annotations, 'skeleton')
        invalidMarker('Video Marker payload annotations are incomplete.');
    end
    frames = project.annotations.frames;
    rawSkeleton = project.annotations.skeleton;
    if ~isstruct(frames) || ~isscalar(frames) || ...
            ~isfield(frames, 'coords') || ~isnumeric(frames.coords)
        invalidMarker('Video Marker frame coordinates are malformed.');
    end
    coords = double(frames.coords);
    if isempty(coords) || ndims(coords) ~= 3 || size(coords, 3) ~= 2
        invalidMarker('Video Marker coordinates must be nonempty F-by-P-by-2 data.');
    end
    skeleton = normalizedSkeleton(rawSkeleton, size(coords, 2));
    metadata = videoMetadata(project.inputs, size(coords, 1));

    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.coords = coords;
    pose.pointNames = skeleton.pointNames;
    pose.skeleton = skeleton;
    pose.frameIndex = (1:size(coords, 1)).';
    pose.videoMetadata = metadata;
    pose.frameRate = metadata.frameRate;
    pose.time = (pose.frameIndex - 1) ./ metadata.frameRate;
    pose.frameStatus = optionalFrameVector( ...
        frames, 'frameStatus', size(coords, 1), 'uint8');
    pose.frameSource = optionalFrameVector( ...
        frames, 'frameSource', size(coords, 1), 'uint8');
    pose.calibration = markerCalibration(project.annotations);
    if pose.calibration.isCalibrated
        pose.pixelsPerUnit = pose.calibration.pixelsPerUnit;
        pose.unitName = pose.calibration.unit;
    end
end

function skeleton = normalizedSkeleton(raw, pointCount)
    if ~isstruct(raw) || ~isscalar(raw) || ...
            ~all(isfield(raw, {'pointIds', 'pointNames', 'edges'}))
        invalidMarker('Video Marker skeleton is incomplete.');
    end
    ids = string(raw.pointIds(:));
    names = string(raw.pointNames(:));
    edges = double(raw.edges);
    validEdges = isempty(edges) || ...
        (ismatrix(edges) && size(edges, 2) == 2 && ...
        all(isfinite(edges), 'all') && all(edges == fix(edges), 'all') && ...
        all(edges >= 1, 'all') && all(edges <= pointCount, 'all'));
    if numel(ids) ~= pointCount || numel(names) ~= pointCount || ...
            any(strlength(ids) == 0) || any(strlength(names) == 0) || ...
            ~validEdges
        invalidMarker('Video Marker skeleton does not match coordinate columns.');
    end
    skeleton = struct('pointIds', ids, 'pointNames', names, 'edges', edges);
end

function metadata = videoMetadata(inputs, frameCount)
    required = ["frameCount", "frameRate", "duration", "height", "width"];
    if ~isstruct(inputs) || ~isscalar(inputs) || ...
            ~isfield(inputs, 'videoMetadata')
        missingMetadata('Video Marker project has no embedded video metadata.');
    end
    raw = inputs.videoMetadata;
    if ~isstruct(raw) || ~isscalar(raw) || ...
            ~all(isfield(raw, cellstr(required)))
        missingMetadata('Video Marker video metadata are incomplete.');
    end
    metadata = struct();
    for field = required
        value = double(raw.(field));
        if ~isscalar(value) || ~isfinite(value) || value < 0
            missingMetadata('Video Marker video metadata contain invalid values.');
        end
        metadata.(field) = value;
    end
    if metadata.frameCount ~= frameCount
        invalidMarker('Embedded frame count does not match coordinate rows.');
    end
    if metadata.frameRate <= 0
        missingMetadata(['Embedded frame rate is missing. Reopen the source ' ...
            'in the current Video Marker and press Save MAT.']);
    end
end

function values = optionalFrameVector(source, field, count, typeName)
    values = zeros(0, 1, typeName);
    if ~isfield(source, field)
        return;
    end
    values = source.(field)(:);
    if numel(values) ~= count
        invalidMarker('Video Marker frame provenance does not match frame count.');
    end
    values = cast(values, typeName);
end

function calibration = markerCalibration(annotations)
    calibration = gait_analysis.sourceFiles.emptyPoseData().calibration;
    if ~isfield(annotations, 'calibration') || ...
            ~isstruct(annotations.calibration)
        return;
    end
    raw = annotations.calibration;
    for field = ["referencePixels", "referenceLength", "pixelsPerUnit"]
        if isfield(raw, field)
            value = double(raw.(field));
            if isscalar(value)
                calibration.(field) = value;
            end
        end
    end
    if isfield(raw, 'unit')
        calibration.unit = string(raw.unit);
    end
    calibration.isCalibrated = isfinite(calibration.pixelsPerUnit) && ...
        calibration.pixelsPerUnit > 0 && isscalar(calibration.unit) && ...
        strlength(calibration.unit) > 0;
end

function invalidMarker(message)
    error('labkit_GaitAnalysis_app:InvalidMarkerProject', '%s', message);
end

function missingMetadata(message)
    error('labkit_GaitAnalysis_app:MissingVideoMetadata', '%s', message);
end

function accepted = isTextScalar(value)
    accepted = (ischar(value) && isrow(value)) || ...
        (isstring(value) && isscalar(value));
end

function accepted = isCurrentVersion(value, expected)
    accepted = isnumeric(value) && isscalar(value) && isfinite(value) && ...
        double(value) == expected;
end
