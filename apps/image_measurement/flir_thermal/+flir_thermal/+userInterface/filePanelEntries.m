% Expected caller: FLIR thermal runner refresh logic and tests. Input is the
% loaded item struct array. Output is filePanel entry structs with per-image
% range-session status labels.
function entries = filePanelEntries(items)

    entries = repmat(struct('path', "", 'status', ""), numel(items), 1);
    for k = 1:numel(items)
        entries(k).path = string(items(k).path);
        if isfield(items(k), 'rangeAdjusted') && logical(items(k).rangeAdjusted)
            entries(k).status = "range set";
        else
            entries(k).status = "needs range";
        end
    end
end
