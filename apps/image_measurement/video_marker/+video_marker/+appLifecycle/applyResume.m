% Expected caller: V2 project restore. Inputs are a freshly created session,
% optional resume data, and durable project. Output restores only a valid
% current-frame convenience and its rebuildable image cache.
function session = applyResume(session, resume, project)
    if session.cache.videoInfo.frameCount <= 0 || ...
            ~isstruct(resume) || ~isfield(resume, 'currentFrame')
        return;
    end
    target = min(max(1, round(double(resume.currentFrame))), ...
        session.cache.videoInfo.frameCount);
    videoPath = video_marker.sourceFiles.pathForId( ...
        project.inputs.sources, "video");
    [reader, ~] = video_marker.videoSource.openVideo(videoPath);
    session.selection.currentFrame = target;
    session.cache.currentImage = ...
        video_marker.videoSource.readFrame(reader, target);
    session.cache.frameIndex = target;
end
