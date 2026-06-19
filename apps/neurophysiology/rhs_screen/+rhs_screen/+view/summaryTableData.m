% Expected caller: rhs_screen.run/buildSpec. Input is app state. Output is a
% two-column cell array for a result table.
function data = summaryTableData(S)
%SUMMARYTABLEDATA Build screening summary rows.

    if nargin == 0 || isempty(S)
        S = struct();
    end

    report = fieldOrDefault(S, "report", struct());
    data = {
        'RHS folder', displayPath(fieldOrDefault(S, "rootFolder", ""));
        'Protocol', displayPath(fieldOrDefault(S, "protocolFile", ""));
        'Files', displayNumber(fieldOrDefault(report, "fileCount", 0));
        'Kept', displayNumber(fieldOrDefault(report, "keptCount", ...
        fieldOrDefault(report, "acceptedCount", 0)));
        'Needs review', displayNumber(fieldOrDefault(report, "needsReviewCount", 0));
        'Failed', displayNumber(fieldOrDefault(report, "failedCount", 0));
        'Groups', displayNumber(fieldOrDefault(report, "groupCount", 0));
        'Last action', char(string(fieldOrDefault(S, "lastAction", "Ready")))};
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = 'Not selected';
        return;
    end
    [~, base, ext] = fileparts(char(pathValue));
    if strlength(string(ext)) == 0
        text = char(string(base));
    else
        text = char(string([base ext]));
    end
end

function text = displayNumber(value)
    if isempty(value) || ~isnumeric(value)
        text = '0';
    else
        text = char(string(value));
    end
end
