function pose = pose()
%POSE Return a cross-owner deterministic walking-pose fixture.
%
% Expected callers: Gait Analysis specifications. Output has twelve frames,
% five named points, and two complete synthetic swings. It has no side effects.

    frames = (1:12).';
    footX = [0; 1; 5; 3; 0; 1; 0; 1; 6; 4; 0; 1];
    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.sourceFormat = "synthetic";
    pose.pointNames = ["iliac"; "hip"; "knee"; "ankle"; "foot"];
    pose.frameIndex = frames;
    pose.time = (frames - 1) ./ 30;
    pose.frameRate = 30;
    pose.unitName = "px";
    pose.skeleton = struct("pointIds", pose.pointNames, ...
        "pointNames", pose.pointNames, "edges", [1, 2; 2, 3; 3, 4; 4, 5]);
    pose.coords = NaN(12, 5, 2);
    pose.coords(:, :, 1) = [-2 * ones(12, 1), zeros(12, 1), ...
        ones(12, 1), 2 * ones(12, 1), footX];
    pose.coords(:, :, 2) = [8 * ones(12, 1), 6 * ones(12, 1), ...
        4 + 0.2 * sin(frames), 2 + 0.2 * cos(frames), zeros(12, 1)];
    pose.ok = true;
end
