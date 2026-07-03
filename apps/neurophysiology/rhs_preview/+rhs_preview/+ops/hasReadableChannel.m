% Expected caller: rhs_preview.actions.table. Input is app state. Output indicates
% whether the selected RHS, family, and preview rows can read a waveform.
function tf = hasReadableChannel(S)
%HASREADABLECHANNEL True when preview reading has at least one channel.

    selection = rhs_preview.view.channelSelection(S.info, S.family, "");
    tf = strlength(string(S.rhsFile)) > 0 && selection.hasChannels && ...
        isfield(S, "previewChannelRows") && istable(S.previewChannelRows) && ...
        height(S.previewChannelRows) > 0 && any(logical(S.previewChannelRows.preview));
end
