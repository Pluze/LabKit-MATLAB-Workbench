% Expected caller: nerve_response_analysis.run/buildSpec. Input is app
% state. Output is a two-column result-table cell array.
function data = summaryTableData(S)
%SUMMARYTABLEDATA Build nerve-response analysis summary rows.

    if nargin == 0 || isempty(S)
        S = struct();
    end
    analysis = fieldOrDefault(S, "analysis", struct());

    data = {
        'Session', displayPath(fieldOrDefault(S, "sessionFile", ""));
        'Protocol', displayPath(fieldOrDefault(S, "protocolFile", ""));
        'Recordings', displayNumber(fieldOrDefault(analysis, "recordingCount", 0));
        'Analyzed', displayNumber(fieldOrDefault(analysis, "analyzedCount", 0));
        'Events', displayNumber(tableHeight(fieldOrDefault(analysis, "events", table())));
        'Trains', displayNumber(tableHeight(fieldOrDefault(analysis, "trains", table())));
        'Metrics', displayNumber(tableHeight(fieldOrDefault(analysis, "metrics", table())));
        'Issues', displayNumber(tableHeight(fieldOrDefault(analysis, "issues", table())));
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
