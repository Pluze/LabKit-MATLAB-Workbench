%CREATEINITIALSTATE Initial state factory for Video Marker.
% Expected caller: labkit_VideoMarker_app runtime and project reset helpers.
% Output is a serializable struct without UI handles or VideoReader objects.
function state = createInitialState()
    state = struct();
    state.schemaVersion = 1;
    state.videoPath = "";
    state.videoInfo = video_marker.videoSource.emptyInfo();
    state.currentFrame = 1;
    state.currentImage = [];
    state.skeleton = video_marker.skeletonDefinition.defaultSkeleton();
    state.selectedPointIndex = 0;
    state.selectedEdgeIndex = 0;
    state.annotations = video_marker.frameAnnotations.emptyAnnotations(0, 0);
    state.calibration = labkit.ui.interaction.scaleBarCalibration([], [], "px");
    state.exportPreferences = struct( ...
        "unitMode", "pixels", ...
        "originMode", "top_left_pixel_center", ...
        "yAxisMode", "up", ...
        "startFrame", 1, ...
        "endFrame", 1);
    state.projectPath = "";
    state.outputFolder = "";
    state.statusMessage = "Define keypoints and connections before opening a video.";
end
