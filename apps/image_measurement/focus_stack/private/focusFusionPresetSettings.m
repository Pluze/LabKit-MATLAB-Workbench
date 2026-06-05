% App-private image measurement helper. Expected caller: owning app callbacks
% and workflow tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function settings = focusFusionPresetSettings(preset)
%FOCUSFUSIONPRESETSETTINGS Return preset options for labkit_FocusStack_app.
%
% Expected caller:
%   labkit_FocusStack_app preset callback.
%
% Inputs/outputs:
%   String-like preset label. Returns the app-owned focus-window,
%   smooth-radius, and minimum-confidence percent defaults.
%
% Side effects:
%   None.

    preset = string(preset);
    switch preset
        case "Crisp details"
            settings = struct('focusWindow', 21, 'smoothRadius', 1, ...
                'minConfidencePercent', 2);
        case "Smooth transitions"
            settings = struct('focusWindow', 41, 'smoothRadius', 8, ...
                'minConfidencePercent', 8);
        case "Noisy images"
            settings = struct('focusWindow', 35, 'smoothRadius', 10, ...
                'minConfidencePercent', 15);
        otherwise
            settings = struct('focusWindow', 31, 'smoothRadius', 4, ...
                'minConfidencePercent', 5);
    end
end
