% Expected caller: rhs_preview.definitionActions. Inputs are app state, selected channels,
% action label, and ROI behavior. Output is updated state plus read status
% and one optional log line. No UI handles are touched.
function [S, ok, logMessage] = readPreviewWindow(S, selectedChannels, ...
        actionLabel, preserveRoi)
%READPREVIEWWINDOW Read the requested RHS preview window from app state.
%   [S, ok, logMessage] = rhs_preview.analysisRun.readPreviewWindow(S,
%   selectedChannels, actionLabel, preserveRoi) consumes the RHS Preview state
%   fields rhsFile, family, windowStartSec, windowDurationSec, roiSec, preview,
%   statusMessage, and lastAction. selectedChannels are RHS channel ids.
%   preserveRoi defaults false.
%
%   The function clamps the window start, calls labkit.rhs.readWindow, updates
%   preview/workflow fields, and optionally clamps the previous ROI to the new
%   time range. ok reports a successful read; logMessage is empty or one
%   app-facing line. Exceptions are converted into failed state instead of
%   escaping. Scripts needing only waveform data should call
%   labkit.rhs.readWindow directly.

    if nargin < 4
        preserveRoi = false;
    end
    ok = false;
    logMessage = "";
    if strlength(S.rhsFile) == 0
        S.statusMessage = "Select an RHS file first.";
        return;
    end
    if isempty(selectedChannels)
        S.statusMessage = "Select at least one preview channel first.";
        return;
    end

    previousRoiSec = S.roiSec;
    opts = struct();
    opts.family = S.family;
    S.windowStartSec = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
    opts.timeRangeSec = [S.windowStartSec, ...
        S.windowStartSec + max(S.windowDurationSec, eps)];
    opts.channels = selectedChannels;

    try
        [window, status] = labkit.rhs.readWindow(S.rhsFile, opts);
    catch ME
        S.preview = [];
        S.statusMessage = string(ME.message);
        S.lastAction = "Preview read failed";
        logMessage = "Preview read failed: " + S.statusMessage;
        return;
    end

    S.preview = window;
    if preserveRoi && ~isempty(window.timeSec)
        S.roiSec = rhs_preview.analysisRun.clampRoi(previousRoiSec, window.timeSec);
    else
        S.roiSec = [NaN NaN];
    end
    if status.ok
        S.statusMessage = "Preview window read.";
        S.lastAction = string(actionLabel);
        logMessage = sprintf("Read %d sample(s) from %s.", ...
            numel(window.timeSec), char(window.family));
        ok = true;
    else
        S.statusMessage = status.message;
        S.lastAction = "Preview read failed";
        logMessage = "Preview read failed: " + status.message;
    end
end
