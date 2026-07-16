% Expected caller: Runtime V2 project loading. Version 1 kept decoded-video
% facts only in session state. Version 2 adds a durable metadata record. Frame
% count is recoverable from annotations; source-dependent facts such as frame
% rate remain zero until the source is opened again by the current app.
function project = migrateProjectV1ToV2(project)
    if ~isfield(project, "inputs") || ~isstruct(project.inputs)
        project.inputs = struct();
    end
    if ~isfield(project.inputs, "videoMetadata")
        project.inputs.videoMetadata = ...
            video_marker.videoSource.emptyMetadata();
    end
    if isfield(project, "annotations") && ...
            isfield(project.annotations, "frames") && ...
            isfield(project.annotations.frames, "coords") && ...
            ~isempty(project.annotations.frames.coords)
        project.inputs.videoMetadata.frameCount = ...
            size(project.annotations.frames.coords, 1);
    end
end
