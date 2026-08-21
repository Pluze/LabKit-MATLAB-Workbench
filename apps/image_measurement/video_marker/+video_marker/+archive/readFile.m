function applicationState = readFile(filepath, context)
%READFILE Restore one Video Marker snapshot through its App-owned contract.
filepath = string(filepath);
details = whos("-file", char(filepath));
names = string({details.name});
if numel(names) ~= 1 || names ~= "videoMarkerArchive"
    error("video_marker:UnknownArchiveFormat", ...
        "MAT file must contain exactly one current Video Marker archive.");
end
loaded = load(char(filepath), "videoMarkerArchive");
archive = loaded.videoMarkerArchive;
requireCurrentArchive(archive);
project = archive.project;
video_marker.archive.validateProject(project);
project.inputs.sources = resolveSources(project.inputs.sources, filepath);
session = video_marker.createSession(project, context);
session = applyResume(session, archive.currentFrame);
applicationState = struct("project", project, "session", session);
end

function requireCurrentArchive(value)
fields = ["format", "formatVersion", "payloadVersion", "project", "currentFrame"];
if ~isstruct(value) || ~isscalar(value) || ...
        ~isequal(sort(string(fieldnames(value))), sort(fields(:))) || ...
        ~isTextScalar(value.format) || ...
        string(value.format) ~= "video_marker.archive" || ...
        ~isCurrentVersion(value.formatVersion, 1) || ...
        ~isCurrentVersion(value.payloadVersion, 3) || ...
        ~isstruct(value.project) || ~isscalar(value.project) || ...
        ~isCurrentFrame(value.currentFrame)
    error("video_marker:UnknownArchiveFormat", ...
        "MAT file is not a current Video Marker archive.");
end
end

function session = applyResume(session, currentFrame)
if session.cache.videoInfo.frameCount <= 0
    return
end
target = min(max(1, round(double(currentFrame))), ...
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

function sources = resolveSources(sources, filepath)
if ~isempty(sources) && ...
        (~isstruct(sources) || ~all(isfield(sources, {'id', 'role', 'path'})))
    error("video_marker:UnknownArchiveFormat", ...
        "Video Marker archive sources are not in the current format.");
end
archiveFolder = string(fileparts(filepath));
resolved = cell(numel(sources), 1);
resolvedCount = 0;
for k = 1:numel(sources)
    candidates = strings(1, 3);
    recorded = string(sources(k).path);
    candidates(1) = recorded;
    [~, name, extension] = fileparts(recorded);
    fileName = string(name) + string(extension);
    if ~isfile(recorded)
        parts = cellstr(split(recorded, "/"));
        candidates(2) = string(fullfile(archiveFolder, parts{:}));
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

function accepted = isTextScalar(value)
accepted = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value));
end

function accepted = isCurrentVersion(value, expected)
accepted = isnumeric(value) && isscalar(value) && isfinite(value) && ...
    double(value) == expected;
end

function accepted = isCurrentFrame(value)
accepted = isnumeric(value) && isscalar(value) && isfinite(value) && ...
    double(value) >= 1 && double(value) == fix(double(value));
end
