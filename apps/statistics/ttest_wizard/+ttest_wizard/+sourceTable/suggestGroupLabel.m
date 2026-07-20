% App-owned implementation for ttest_wizard.sourceTable.suggestGroupLabel within the ttest_wizard product workflow.
function label = suggestGroupLabel(cells, indices, existingLabels)
%SUGGESTGROUPLABEL Infer a concise group label from layered table headers.
%
% Typical Call:
%   label = ttest_wizard.sourceTable.suggestGroupLabel( ...
%       source.cells, selectedIndices, [groups.label]);
%
% Inputs:
%   cells - Source-table cell matrix.
%   indices - N-by-2 numeric selected row and column indices.
%   existingLabels - Current group labels as text.
%
% Output:
%   label - Unique string scalar. For a single selected column, up to two
%       nearby semantic header levels are joined from broad to specific,
%       such as "ring pedot - ST". Date-like and numeric headers are ignored.
%
% Side effects: none. The caller remains responsible for storing the label.

    existingLabels = string(existingLabels(:));
    label = "";
    if iscell(cells) && isnumeric(indices) && size(indices, 2) == 2 && ...
            ~isempty(indices)
        columns = unique(indices(:, 2), 'stable');
        if isscalar(columns) && columns >= 1 && columns <= size(cells, 2)
            parts = nearbyHeaderParts( ...
                cells, min(indices(:, 1)), columns);
            if ~isempty(parts)
                label = strjoin(flip(parts), " - ");
            end
        end
    end
    if strlength(label) == 0
        label = "Group " + (numel(existingLabels) + 1);
    end
    label = uniqueLabel(label, existingLabels);
end

function parts = nearbyHeaderParts(cells, firstDataRow, column)
    parts = strings(2, 1);
    count = 0;
    firstHeaderRow = min(size(cells, 1), firstDataRow - 1);
    lastHeaderRow = max(1, firstHeaderRow - 7);
    for row = firstHeaderRow:-1:lastHeaderRow
        candidate = nearestHeaderAtOrLeft(cells, row, column);
        if ~isSemanticHeader(candidate) || ...
                any(strcmpi(candidate, parts(1:count)))
            continue;
        end
        count = count + 1;
        parts(count) = strip(string(candidate));
        if count == numel(parts)
            break;
        end
    end
    parts = parts(1:count);
end

function candidate = nearestHeaderAtOrLeft(cells, row, column)
    candidate = "";
    for candidateColumn = column:-1:1
        value = cells{row, candidateColumn};
        if ischar(value) || (isstring(value) && isscalar(value)) || ...
                (isdatetime(value) && isscalar(value))
            value = strip(string(value));
            if strlength(value) > 0
                candidate = value;
                return;
            end
        elseif isnumeric(value) && isscalar(value) && isfinite(value)
            return;
        end
    end
end

function tf = isSemanticHeader(value)
    value = strip(string(value));
    tf = isscalar(value) && strlength(value) > 0 && ...
        ~isfinite(str2double(value)) && ~looksLikeDate(value);
end

function tf = looksLikeDate(value)
    value = lower(string(value));
    monthName = ...
        "(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)";
    tf = ~isempty(regexp(value, monthName, 'once')) || ...
        ~isempty(regexp(value, ...
        "^\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}$", 'once'));
end

function label = uniqueLabel(label, existingLabels)
    base = strip(string(label));
    label = base;
    suffix = 2;
    while any(strcmpi(label, existingLabels))
        label = base + " " + suffix;
        suffix = suffix + 1;
    end
end
