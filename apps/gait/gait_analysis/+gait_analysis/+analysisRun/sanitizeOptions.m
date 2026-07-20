% App-owned implementation for gait_analysis.analysisRun.sanitizeOptions within the gait_analysis product workflow.
function options = sanitizeOptions(options)
%SANITIZEOPTIONS Replace invalid numeric UI values with App defaults.
defaults = gait_analysis.analysisRun.defaultOptions();
numericNames = ["frameRate", "pixelsPerUnit", "smoothWindow", ...
    "detectionProminence", "detectionMinHeightSigma", ...
    "minLiftOffIntervalSeconds", "minSwingFrames", ...
    "maxSwingFrames", "minStepLength", "maxHipTranslation"];
for name = numericNames
    value = double(options.(name));
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        options.(name) = defaults.(name);
    end
end
options.originAtFirstFrameFirstPoint = ...
    logical(options.originAtFirstFrameFirstPoint);
end
