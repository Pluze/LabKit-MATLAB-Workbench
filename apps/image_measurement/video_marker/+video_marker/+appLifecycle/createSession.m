% Expected caller: the LabKit V2 runtime. Input is a validated durable Video
% Marker project whose source paths have already been resolved. Output owns
% current-frame navigation, workflow text, and rebuildable decoded image data.
function session = createSession(project)
    currentFrame = 1;
    info = infoFromProject(project);
    imageData = [];
    videoPath = video_marker.sourceFiles.pathForId( ...
        project.inputs.sources, "video");
    if strlength(videoPath) > 0 && isfile(videoPath)
        [reader, info] = video_marker.videoSource.openVideo(videoPath);
        verifyAnnotationShape(project.annotations, info);
        imageData = video_marker.videoSource.readFrame(reader, currentFrame);
    end
    presets = video_marker.userInterface.skeletonPresets();
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
            "scaleReferenceEditing", false, ...
            "logLines", strings(0, 1)), ...
        "view", struct("scaleBar", []), ...
        "cache", struct( ...
            "videoInfo", info, ...
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

function verifyAnnotationShape(annotations, info)
    frames = annotations.frames;
    if isempty(frames.coords)
        return;
    end
    expectedPoints = numel(annotations.skeleton.pointIds);
    if size(frames.coords, 1) ~= info.frameCount || ...
            size(frames.coords, 2) ~= expectedPoints
        error('video_marker:AnnotationShapeMismatch', ...
            ['Saved annotations do not match the current video frame count ' ...
            'and skeleton.']);
    end
end

function value = initialStatus(info)
    if info.frameCount > 0
        value = "Project video restored.";
    else
        value = "Define keypoints and connections before opening a video.";
    end
end
