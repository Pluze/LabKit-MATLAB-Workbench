%EMPTYPOSEDATA Empty normalized pose-coordinate payload.
% Expected caller: app state, import actions, and parser tests.
function pose = emptyPoseData()
    pose = struct();
    pose.ok = false;
    pose.sourcePath = "";
    pose.sourceFormat = "";
    pose.pointNames = strings(0, 1);
    pose.coords = zeros(0, 0, 2);
    pose.frameIndex = zeros(0, 1);
    pose.time = zeros(0, 1);
    pose.unitName = "px";
end
