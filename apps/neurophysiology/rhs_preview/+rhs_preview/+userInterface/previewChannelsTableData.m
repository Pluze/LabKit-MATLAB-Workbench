% Expected caller: rhs_preview.definitionActions/buildSpec. Input is app state. Output is
% an editable cell table for channel preview and protocol-role drafting.
function data = previewChannelsTableData(S)
%PREVIEWCHANNELSTABLEDATA Build display rows for Preview channel selection.

    rows = table();
    if isstruct(S) && isfield(S, "previewChannelRows") && ...
            istable(S.previewChannelRows)
        rows = S.previewChannelRows;
    end
    if height(rows) == 0
        data = cell(0, 4);
        return;
    end

    data = cell(height(rows), 4);
    for r = 1:height(rows)
        data{r, 1} = logical(rows.preview(r));
        data{r, 2} = char(rows.role(r));
        data{r, 3} = char(rows.label(r));
        data{r, 4} = char(rows.channel(r));
    end
end
