%EMPTYPOSEDATA Empty normalized pose-coordinate payload.
% Expected caller: app state, import actions, and parser tests.
function pose = emptyPoseData()
    pose = struct();
    pose.ok = false;
    pose.sourcePath = "";
    pose.sourceFormat = "";
    pose.pointNames = strings(0, 1);
    pose.skeleton = struct("pointIds", strings(0, 1), ...
        "pointNames", strings(0, 1), "edges", zeros(0, 2));
    pose.coords = zeros(0, 0, 2);
    pose.frameIndex = zeros(0, 1);
    pose.time = zeros(0, 1);
    pose.frameRate = 0;
    pose.videoMetadata = struct("frameCount", 0, "frameRate", 0, ...
        "duration", 0, "height", 0, "width", 0);
    pose.frameStatus = zeros(0, 1, "uint8");
    pose.frameSource = zeros(0, 1, "uint8");
    pose.calibration = struct("referencePixels", NaN, ...
        "referenceLength", 0, "unit", "px", ...
        "pixelsPerUnit", 0, "isCalibrated", false);
    pose.pixelsPerUnit = 1;
    pose.unitName = "px";
end
