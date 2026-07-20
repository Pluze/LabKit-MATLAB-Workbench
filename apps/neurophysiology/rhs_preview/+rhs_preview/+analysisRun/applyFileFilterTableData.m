% Expected caller: RHS Preview direct callbacks and unit tests. Inputs are current filter
% rows plus GUI table data. Output is updated rows preserving file paths and
% recording ids.
function rows = applyFileFilterTableData(rows, data)
%APPLYFILEFILTERTABLEDATA Apply manual good/bad labels and comments.

    if isempty(rows) || height(rows) == 0 || isempty(data)
        return;
    end

    nRows = min(height(rows), size(data, 1));
    for r = 1:nRows
        filePath = string(data{r, 2});
        target = find(rows.filePath == filePath, 1, "first");
        if isempty(target)
            target = r;
        end
        rows.label(target) = normalizeLabel(data{r, 1});
        rows.comment(target) = string(data{r, 3});
    end
end

function label = normalizeLabel(value)
    value = lower(strtrim(string(value)));
    if any(value == ["bad", "reject", "rejected", "false", "0", "no", "n"])
        label = "bad";
    elseif any(value == ["good", "keep", "kept", "true", "1", "yes", "y"])
        label = "good";
    elseif strlength(value) == 0
        label = "good";
    else
        label = value;
    end
end
