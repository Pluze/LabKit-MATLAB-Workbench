% Expected caller: response_review_stats.run/buildSpec. Input is app state.
% Output is a two-column result-table cell array.
function data = summaryTableData(S)
%SUMMARYTABLEDATA Build review/stat summary rows.

    if nargin == 0 || isempty(S)
        S = struct();
    end
    data = {
        'Input', displayPath(fieldOrDefault(S, "inputFile", ""));
        'Output folder', displayPath(fieldOrDefault(S, "outputFolder", ""));
        'Metrics', displayNumber(tableHeight(fieldOrDefault(S, "metrics", table())));
        'Summary groups', displayNumber(tableHeight(fieldOrDefault(S, "summary", table())));
        'Aligned samples', displayNumber(alignedSamples(fieldOrDefault(S, "aligned", [])));
        'Last action', char(string(fieldOrDefault(S, "lastAction", "Ready")))};
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function n = tableHeight(value)
    if istable(value)
        n = height(value);
    else
        n = 0;
    end
end

function n = alignedSamples(aligned)
    if isstruct(aligned) && isfield(aligned, "timeSec")
        n = numel(aligned.timeSec);
    else
        n = 0;
    end
end

function text = displayNumber(value)
    text = char(string(double(value)));
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = 'Not selected';
        return;
    end
    [~, base, ext] = fileparts(char(pathValue));
    text = char(string([base ext]));
end
