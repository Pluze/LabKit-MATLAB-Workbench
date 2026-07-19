% Rebuild transient Video Marker navigation and decoded-frame state from one
% validated project after the App SDK resolves its video source.
function session = createSession(project, context)
    currentFrame = 1;
    info = infoFromProject(project);
    imageData = [];
    paths = strings(0, 1);
    if ~isempty(project.inputs.sources)
        paths = context.resolveSourcePaths(project.inputs.sources);
    end
    videoPath = "";
    if ~isempty(paths), videoPath = paths(1); end
    if strlength(videoPath) > 0 && isfile(videoPath)
        [reader, info] = video_marker.videoSource.openVideo(videoPath);
        imageData = video_marker.videoSource.readFrame(reader, currentFrame);
    end
    presets = video_marker.skeletonSetup.presets();
    session = struct( ...
        "selection", struct( ...
            "currentFrame", currentFrame, ...
            "selectedPointIndex", 0, ...
            "selectedEdgeIndex", 0, ...
            "skeletonPreset", presets(1).label, ...
            "connectionFrom", "", ...
            "connectionTo", ""), ...
        "workflow", struct( ...
            "statusMessage", initialStatus(info), ...
            "scaleReferenceEditing", false), ...
        "view", struct("scaleBar", []), ...
        "cache", struct( ...
            "videoInfo", info, ...
            "videoPath", videoPath, ...
            "currentImage", imageData, ...
            "frameIndex", currentFrame));
end

function info = infoFromProject(project)
    info = video_marker.videoSource.emptyInfo();
    if isfield(project.inputs, "videoMetadata")
        metadata = project.inputs.videoMetadata;
        names = string(fieldnames(video_marker.videoSource.emptyMetadata()));
        for k = 1:numel(names)
            name = char(names(k));
            if isfield(metadata, name)
                info.(name) = metadata.(name);
            end
        end
    end
end

function value = initialStatus(info)
    if info.frameCount > 0
        value = "Project video restored.";
    else
        value = "Define keypoints and connections before opening a video.";
    end
end
