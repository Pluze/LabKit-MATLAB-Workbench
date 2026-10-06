function [session, ok, logMessage] = readCurrentPreview( ...
        session, parameters, actionLabel, preserveRoi)
%READCURRENTPREVIEW Read selected channels from the current transient window.
if nargin < 4
    preserveRoi = false;
end
context = rhs_preview.analysisRun.previewContext(session, parameters);
selected = selectedChannels( ...
    context.previewChannelRows, context.maxPreviewChannels);
[context, ok, logMessage] = ...
    rhs_preview.analysisRun.readPreviewWindow( ...
        context, selected, actionLabel, preserveRoi);
session = rhs_preview.analysisRun.applyPreviewContext(session, context);
end

function selected = selectedChannels(rows, limit)
selected = strings(0, 1);
if ~istable(rows) || height(rows) == 0
    return;
end
selected = string(rows.channel(logical(rows.preview)));
count = min(numel(selected), max(1, floor(double(limit))));
selected = selected(1:count);
end
