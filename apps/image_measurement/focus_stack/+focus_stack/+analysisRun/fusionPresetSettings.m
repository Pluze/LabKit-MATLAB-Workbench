% App-owned mapping from a named Focus Stack workflow preset to numerical
% fusion parameters. Expected callers are actions and package tests.
function settings = fusionPresetSettings(preset)
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

    items = focus_stack.userInterface.fusionPresetItems();
    index = find(items == string(preset), 1);
    if isempty(index)
        index = 1;
    end
    switch index
        case 2
            settings = struct('focusWindow', 21, 'smoothRadius', 1, ...
                'minConfidencePercent', 2);
        case 3
            settings = struct('focusWindow', 41, 'smoothRadius', 8, ...
                'minConfidencePercent', 8);
        case 4
            settings = struct('focusWindow', 35, 'smoothRadius', 10, ...
                'minConfidencePercent', 15);
        otherwise
            settings = struct('focusWindow', 31, 'smoothRadius', 4, ...
                'minConfidencePercent', 5);
    end
end
