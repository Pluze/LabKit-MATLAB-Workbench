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
    opts.frameRate = 0;
    opts.pixelsPerUnit = 1;
    opts.unitName = "px";
    opts.originAtFirstFrameFirstPoint = false;
    opts.smoothWindow = 5;
    % Legacy treadmill workflow treated a 20 px foot-X excursion as meaningful.
    opts.detectionProminence = 20;
    % Preserve the legacy peak-height floor: mean(signal)-2*std(signal).
    opts.detectionMinHeightSigma = 2;
    % Legacy separation was fps*0.2, corresponding to at most five swings/s.
    opts.minLiftOffIntervalSeconds = 0.2;
    opts.minSwingFrames = 3;
    opts.maxSwingFrames = 300;
    opts.minStepLength = 1;
    % Constant: effectively disables hip-drift rejection until the user tightens QC.
    opts.maxHipTranslation = 1000000;
end
