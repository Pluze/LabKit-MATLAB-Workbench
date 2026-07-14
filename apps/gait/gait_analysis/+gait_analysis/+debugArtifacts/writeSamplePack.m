%WRITESAMPLEPACK Create synthetic debug files for labkit_GaitAnalysis_app.
% Expected caller: debug startup and tests. Files contain synthetic pose data
% only and no lab sample identifiers.
function pack = writeSamplePack(debugLog)
    root = fullfile(tempdir, "labkit_gait_analysis_debug");
    if exist(root, "dir") ~= 7
        mkdir(root);
    end
    posePath = fullfile(root, "synthetic_gait_pose.csv");
    T = syntheticPoseTable();
    writetable(T, posePath);

    pack = struct();
    pack.sampleFolder = string(root);
    pack.representativeFiles = string(posePath);
    if nargin > 0 && ismethod(debugLog, "trace")
        debugLog.trace("Gait analysis debug sample pack written.");
    end
end

function T = syntheticPoseTable()
    frames = (1:12).';
    time = (frames - 1) ./ 30;
    hipX = zeros(size(frames));
    footRel = [-2; -3; -1; 2; 4; -3; -1; 2; 4; -3; -1; 1];
    T = table();
    T.frame_index = frames;
    T.time_s = time;
    T.iliac_x = hipX - 2;
    T.iliac_y = 8 + zeros(size(frames));
    T.hip_x = hipX;
    T.hip_y = 6 + zeros(size(frames));
    T.knee_x = hipX + 1;
    T.knee_y = 4 + 0.2 .* sin(frames);
    T.ankle_x = hipX + 2;
    T.ankle_y = 2 + 0.2 .* cos(frames);
    T.foot_x = hipX + footRel;
    T.foot_y = zeros(size(frames));
end
