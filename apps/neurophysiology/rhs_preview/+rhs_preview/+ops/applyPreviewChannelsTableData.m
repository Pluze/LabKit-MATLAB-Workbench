% Expected caller: rhs_preview.actions.table and unit tests. Inputs are the current
% Preview channel rows plus GUI table cell data. Output is updated channel
% rows preserving RHS-derived family/channel/unit metadata.
function rows = applyPreviewChannelsTableData(rows, data)
%APPLYPREVIEWCHANNELSTABLEDATA Apply channel-selection edits.

    if isempty(rows) || height(rows) == 0 || isempty(data)
        return;
    end

    nRows = min(height(rows), size(data, 1));
    for r = 1:nRows
        channelName = string(data{r, 4});
        target = find(rows.channel == channelName, 1, "first");
        if isempty(target)
            target = r;
        end
        rows.preview(target) = logicalValue(data{r, 1});
        rows.role(target) = string(data{r, 2});
        rows.label(target) = string(data{r, 3});
    end
end

function value = logicalValue(value)
    if islogical(value)
        value = logical(value);
    elseif isnumeric(value)
        value = value ~= 0;
    else
        value = any(strcmpi(string(value), ["true", "yes", "on", "1"]));
    end
end
