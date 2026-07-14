%DEFAULTOPTIONS Default gait analysis options.
% Expected caller: initial state, UI option collection, and tests. Defaults
% are conservative and app-owned because they define gait workflow behavior.
function opts = defaultOptions()
    opts = struct();
    opts.iliacPoint = "iliac";
    opts.hipPoint = "hip";
    opts.kneePoint = "knee";
    opts.anklePoint = "ankle";
    opts.footPoint = "foot";
    % Constant: 30 Hz is the common fallback video rate when no time column is present.
    opts.frameRate = 30;
    opts.pixelsPerUnit = 1;
    opts.unitName = "px";
    opts.originAtFirstFrameFirstPoint = false;
    opts.smoothWindow = 5;
    opts.minStepFrames = 3;
    opts.maxStepFrames = 300;
    opts.minStride = 1;
    % Constant: effectively disables hip-drift rejection until the user tightens QC.
    opts.maxBodyDrift = 1000000;
end
