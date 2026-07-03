% Expected caller: RHS preview-window ops. Inputs are preview channel rows
% and a maximum channel count. Output is the effective plotted channel count.
function count = selectedChannelCount(channelRows, maxPreviewChannels)
%SELECTEDCHANNELCOUNT Count selected preview channels.

    count = max(1, floor(double(maxPreviewChannels)));
    if istable(channelRows) && height(channelRows) > 0 && ...
            any(strcmp(channelRows.Properties.VariableNames, "preview"))
        count = nnz(logical(channelRows.preview));
        if count == 0
            count = min(height(channelRows), max(1, floor(double(maxPreviewChannels))));
        end
    end
    count = max(1, count);
end
