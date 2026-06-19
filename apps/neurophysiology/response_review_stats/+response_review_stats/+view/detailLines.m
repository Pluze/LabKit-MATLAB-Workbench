% Expected caller: response_review_stats.run/buildSpec. Input is app state.
% Output is compact status-panel text.
function lines = detailLines(S)
%DETAILLINES Build review/stat detail lines.

    if nargin == 0 || isempty(S)
        lines = {'No metrics have been loaded.'};
        return;
    end

    lines = {
        char(string(fieldOrDefault(S, "statusMessage", ...
        "No metrics have been loaded.")))
        "Baseline: " + char(rangeText(fieldOrDefault(S, "baselineWindowSec", [0.007 0.009])))
        "Noise: " + char(rangeText(fieldOrDefault(S, "noiseWindowSec", [0.007 0.009])))
        "Output folder: " + char(displayPath(fieldOrDefault(S, "outputFolder", "")))};

    summary = fieldOrDefault(S, "summary", table());
    if istable(summary) && height(summary) > 0
        lines{end+1} = sprintf("Groups: %d", height(summary));
        lines{end+1} = sprintf("First group count: %d", summary.Count(1));
    end
    lines = cellstr(string(lines));
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function text = rangeText(value)
    value = double(value);
    text = sprintf("%.4g to %.4g s", value(1), value(2));
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = "Not selected";
        return;
    end
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
end
