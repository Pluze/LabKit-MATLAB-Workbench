function writeFile(applicationState, filepath)
%WRITEFILE Save one App-owned Video Marker snapshot to MAT.
filepath = string(filepath);
if ~isscalar(filepath) || strlength(filepath) == 0
    error("video_marker:InvalidArchivePath", ...
        "Video Marker archive path must be nonempty scalar text.");
end
project = applicationState.project;
project.inputs.sources = rebaseSources(project.inputs.sources, filepath);
project.inputs.videoMetadata = video_marker.videoSource.metadataFromInfo( ...
    applicationState.session.cache.videoInfo);
project.results = struct( ...
    "markerOutputPath", "", ...
    "coordinateOutputPath", "");
video_marker.archive.validateProject(project);
videoMarkerArchive = struct( ...
    "format", "video_marker.archive", ...
    "formatVersion", 1, ...
    "payloadVersion", 3, ...
    "project", project, ...
    "currentFrame", double(applicationState.session.selection.currentFrame));
save(char(filepath), "videoMarkerArchive", "-mat");
end

function sources = rebaseSources(sources, filepath)
archiveFolder = string(fileparts(filepath));
for k = 1:numel(sources)
    sourcePath = string(sources(k).path);
    [sourceFolder, name, extension] = fileparts(sourcePath);
    sources(k).path = sourcePath;
    if string(sourceFolder) == archiveFolder
        sources(k).path = string(name) + string(extension);
    end
end
end
