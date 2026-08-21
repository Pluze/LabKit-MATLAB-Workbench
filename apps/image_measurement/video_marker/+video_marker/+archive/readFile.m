function applicationState = readFile(filepath, context)
%READFILE Restore one Video Marker snapshot through its App-owned contract.
filepath = string(filepath);
details = whos("-file", char(filepath));
names = string({details.name});
recognized = intersect(names, ...
    ["videoMarkerArchive", "labkitProject", "videoMarkerProject"]);
if numel(recognized) ~= 1
    error("video_marker:UnknownArchiveFormat", ...
        "MAT file must contain exactly one recognized Video Marker archive.");
end
loaded = load(char(filepath), char(recognized));
[project, resume, payloadVersion] = decode( ...
    loaded.(char(recognized)), recognized);
if payloadVersion == 1
    project = migrateProject(project, 1);
end
project.inputs.sources = resolveSources(project.inputs.sources, filepath);
video_marker.archive.validateProject(project);
session = video_marker.createSession(project, context);
session = applyResume(session, resume);
applicationState = struct("project", project, "session", session);
end

function [project, resume, payloadVersion] = decode(value, name)
if name == "videoMarkerArchive"
    requireFields(value, ...
        ["format", "formatVersion", "payloadVersion", "project", "currentFrame"]);
    if string(value.format) ~= "video_marker.archive" || ...
            double(value.formatVersion) ~= 1
        error("video_marker:UnknownArchiveFormat", ...
            "Unsupported Video Marker archive format.");
    end
    project = value.project;
    payloadVersion = positiveVersion(value.payloadVersion);
    resume = struct("currentFrame", double(value.currentFrame));
elseif name == "labkitProject"
    requireFields(value, ["format", "formatVersion", "app", "payload", "resume"]);
    if string(value.format) ~= "labkit.project" || ...
            double(value.formatVersion.major) ~= 1 || ...
            string(value.app.id) ~= "video_marker"
        error("video_marker:UnknownArchiveFormat", ...
            "MAT file is not a compatible Video Marker project.");
    end
    project = value.payload;
    payloadVersion = positiveVersion(value.app.payloadVersion);
    resume = value.resume;
else
    [project, resume] = importLegacyProject(value);
    payloadVersion = 2;
end
if payloadVersion > 3
    error("video_marker:NewerArchiveVersion", ...
        "Video Marker archive is newer than this App.");
end
end

function project = migrateProject(project, fromVersion)
if fromVersion ~= 1
    error("video_marker:UnsupportedProjectMigration", ...
        "Video Marker cannot migrate project version %d.", fromVersion);
end
if ~isfield(project, "inputs") || ~isstruct(project.inputs)
    project.inputs = struct();
end
if ~isfield(project.inputs, "videoMetadata")
    project.inputs.videoMetadata = video_marker.videoSource.emptyMetadata();
end
if isfield(project, "annotations") && ...
        isfield(project.annotations, "frames") && ...
        isfield(project.annotations.frames, "coords") && ...
        ~isempty(project.annotations.frames.coords)
    project.inputs.videoMetadata.frameCount = ...
        size(project.annotations.frames.coords, 1);
end
end

function [project, resume] = importLegacyProject(legacy)
if ~isstruct(legacy) || ~isscalar(legacy) || ...
        ~isfield(legacy, "schemaVersion") || legacy.schemaVersion ~= 1
    error("video_marker:InvalidLegacyProject", ...
        "Unsupported Video Marker legacy project schema.");
end
project = video_marker.initialData();
if isfield(legacy, "videoReference") && isstruct(legacy.videoReference)
    project.inputs.sources = labkit.app.source.record( ...
        "video", "video", legacyReferencePath(legacy.videoReference));
elseif isfield(legacy, "videoPath") && strlength(string(legacy.videoPath)) > 0
    project.inputs.sources = labkit.app.source.record( ...
        "video", "video", string(legacy.videoPath));
end
project.annotations.skeleton = legacy.skeleton;
project.annotations.frames = ...
    video_marker.frameAnnotations.upgradeAnnotationSchema(legacy.annotations);
project.annotations.calibration = normalizeCalibration(legacy.calibration);
if isfield(legacy, "exportPreferences")
    preferences = legacy.exportPreferences;
    project.parameters.coordinateUnitMode = string(preferences.unitMode);
    project.parameters.coordinateOriginMode = string(preferences.originMode);
    project.parameters.coordinateYAxisMode = string(preferences.yAxisMode);
    project.parameters.coordinateStartFrame = double(preferences.startFrame);
    project.parameters.coordinateEndFrame = double(preferences.endFrame);
end
currentFrame = 1;
if isfield(legacy, "currentFrame")
    currentFrame = double(legacy.currentFrame);
end
resume = struct("currentFrame", currentFrame);
end

function session = applyResume(session, resume)
if session.cache.videoInfo.frameCount <= 0 || ...
        ~isstruct(resume) || ~isfield(resume, "currentFrame")
    return
end
target = min(max(1, round(double(resume.currentFrame))), ...
    session.cache.videoInfo.frameCount);
videoPath = session.cache.videoPath;
if strlength(videoPath) == 0 || ~isfile(videoPath)
    return
end
[reader, ~] = video_marker.videoSource.openVideo(videoPath);
cleanup = onCleanup(@() delete(reader));
session.selection.currentFrame = target;
session.cache.currentImage = video_marker.videoSource.readFrame(reader, target);
session.cache.frameIndex = target;
clear cleanup
end

function calibration = normalizeCalibration(value)
line = zeros(0, 2);
if isstruct(value) && isfield(value, "referenceLine")
    line = value.referenceLine;
end
calibration = labkit.app.interaction.scaleCalibration( ...
    fieldValue(value, "referencePixels", NaN), ...
    fieldValue(value, "referenceLength", 0), ...
    fieldValue(value, "unit", "px"), ...
    struct("referenceLine", line));
end

function value = fieldValue(source, name, fallback)
value = fallback;
if isstruct(source) && isfield(source, name)
    value = source.(name);
end
end

function sources = resolveSources(sources, filepath)
archiveFolder = string(fileparts(filepath));
resolved = cell(numel(sources), 1);
resolvedCount = 0;
for k = 1:numel(sources)
    candidates = strings(1, 3);
    fileName = "";
    if isfield(sources, "path")
        recorded = string(sources(k).path);
        candidates(1) = recorded;
        [~, name, extension] = fileparts(recorded);
        fileName = string(name) + string(extension);
        if ~isfile(recorded)
            parts = cellstr(split(recorded, "/"));
            candidates(2) = string(fullfile(archiveFolder, parts{:}));
        end
    elseif isfield(sources, "reference")
        reference = sources(k).reference;
        candidates(1) = string(reference.originalPath);
        if strlength(string(reference.relativePath)) > 0
            parts = cellstr(split(string(reference.relativePath), "/"));
            candidates(2) = string(fullfile(archiveFolder, parts{:}));
        end
        fileName = string(reference.fileName);
    end
    candidates(3) = string(fullfile(archiveFolder, fileName));
    candidates = candidates(strlength(candidates) > 0);
    match = find(arrayfun(@isfile, candidates), 1, "first");
    if isempty(match)
        error("video_marker:MissingArchiveSource", ...
            "Video Marker source file is missing: %s", fileName);
    end
    resolvedCount = resolvedCount + 1;
    resolved{resolvedCount} = labkit.app.source.record( ...
        sources(k).id, sources(k).role, candidates(match));
end
if resolvedCount == 0
    sources = labkit.app.source.emptyRecords();
else
    sources = vertcat(resolved{1:resolvedCount});
end
end

function path = legacyReferencePath(reference)
path = string(reference.originalPath);
if strlength(path) == 0
    path = string(reference.relativePath);
end
if strlength(path) == 0
    path = string(reference.fileName);
end
end

function version = positiveVersion(value)
version = double(value);
if ~isscalar(version) || ~isfinite(version) || ...
        version < 1 || version ~= fix(version)
    error("video_marker:InvalidArchive", ...
        "Video Marker payload version must be a positive integer.");
end
end

function requireFields(value, names)
if ~isstruct(value) || ~isscalar(value) || ...
        ~all(isfield(value, cellstr(names)))
    error("video_marker:InvalidArchive", ...
        "Video Marker archive is incomplete.");
end
end
