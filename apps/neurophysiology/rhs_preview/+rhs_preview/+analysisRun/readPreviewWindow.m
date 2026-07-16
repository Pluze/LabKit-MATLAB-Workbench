function [S, ok, logMessage] = readPreviewWindow(S, selectedChannels, actionLabel, preserveRoi)
%READPREVIEWWINDOW Read the requested RHS preview window from app state.
%
% Usage:
%   [S, ok, logMessage] = rhs_preview.analysisRun.readPreviewWindow( ...
%       S, selectedChannels, actionLabel)
%   [S, ok, logMessage] = rhs_preview.analysisRun.readPreviewWindow( ...
%       S, selectedChannels, actionLabel, preserveRoi)
%
% Description:
%   Reads a bounded time window from the RHS file recorded in S and stores the
%   returned waveform structure in S.preview. The requested start time is
%   clamped to the indexed recording duration before labkit.rhs.readWindow is
%   called. This function updates data and status fields only; it does not
%   create graphics, open dialogs, or write files.
%
% Inputs:
%   S - Scalar RHS Preview state structure. See State Fields for the values
%       read or changed by this function.
%   selectedChannels - Channel identifiers accepted by the channels option of
%       labkit.rhs.readWindow. Supply at least one identifier from S.family.
%   actionLabel - Text stored in S.lastAction after a successful read. This
%       lets the caller distinguish an initial read from a refresh or a move to
%       another part of the recording.
%   preserveRoi - Optional logical scalar. true keeps the previous ROI after
%       clamping it to the new time vector; false resets S.roiSec to [NaN NaN].
%       Default: false.
%
% Outputs:
%   S - Updated state. On success, preview, roiSec, windowStartSec,
%       statusMessage, and lastAction describe the completed read.
%   ok - Logical scalar. true only when labkit.rhs.readWindow returns a status
%       whose ok field is true.
%   logMessage - Text summary for the app log. It reports the sample count on
%       success, describes a read failure, or is empty when no read was
%       attempted because a file or channel selection is missing.
%
% State Fields:
%   rhsFile - Path to the indexed RHS file. Empty text prevents the read.
%   family - RHS channel family passed to labkit.rhs.readWindow, such as
%       "amplifier" or "stim".
%   windowStartSec - Requested start time in seconds. It is replaced by the
%       valid value returned by clampWindowStartSec.
%   windowDurationSec - Requested duration in seconds. The read interval ends
%       at windowStartSec + max(windowDurationSec, eps).
%   index - File index used by clampWindowStartSec to enforce recording bounds.
%   roiSec - Two-element ROI interval in seconds. It is preserved and clamped
%       only when preserveRoi is true and the read contains time samples.
%   preview - Waveform window returned by labkit.rhs.readWindow. A thrown read
%       error clears this field; a returned failure status leaves the returned
%       window here so its diagnostic content remains available.
%   statusMessage - Reader-facing explanation of success, missing input, or a
%       failed read.
%   lastAction - actionLabel after success, or "Preview read failed" after a
%       read error. Missing inputs leave the previous value unchanged.
%
% Failure Behavior:
%   A missing file or empty channel selection returns ok=false without calling
%   the reader. Exceptions from labkit.rhs.readWindow are caught, copied into
%   statusMessage and logMessage, and clear preview. A nonthrowing failed read
%   returns its status message and ok=false. State-shape errors, such as a
%   missing required field, are programming errors and may still throw.
%
% Typical Call:
%   channels = ["A-000", "A-001"];
%   [state, ok, message] = rhs_preview.analysisRun.readPreviewWindow( ...
%       state, channels, "Read preview", true);
%
% See also labkit.rhs.readWindow,
%   rhs_preview.analysisRun.clampWindowStartSec,
%   rhs_preview.analysisRun.clampRoi

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
