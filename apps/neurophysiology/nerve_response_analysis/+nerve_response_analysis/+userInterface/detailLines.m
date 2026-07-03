% Expected caller: nerve_response_analysis.userInterface.updateWorkbenchFromState
% or buildWorkbenchSpec. Input is app
% state. Output is compact status-panel text.
function lines = detailLines(S)
%DETAILLINES Build nerve-response analysis detail lines.

    if nargin == 0 || isempty(S)
        lines = {'No filter record has been analyzed.'};
        return;
    end

    lines = {
        char(string(fieldOrDefault(S, "statusMessage", ...
        "No filter record has been analyzed.")))
        "Max recordings: " + char(maxText(fieldOrDefault(S, "maxRecordings", 0)))
        "Max duration: " + char(maxText(fieldOrDefault(S, "maxDurationSec", 0))) + " s"
        "Output folder: " + char(displayPath(fieldOrDefault(S, "outputFolder", "")))};

    analysis = fieldOrDefault(S, "analysis", struct());
    if isstruct(analysis)
        lines{end+1} = sprintf("Events: %d", ...
            tableHeight(fieldOrDefault(analysis, "events", table())));
        lines{end+1} = sprintf("Metrics: %d", ...
            tableHeight(fieldOrDefault(analysis, "metrics", table())));
        issues = fieldOrDefault(analysis, "issues", table());
        if istable(issues) && height(issues) > 0
            lines{end+1} = sprintf("First issue: %s", char(issues.message(1)));
        end
    end
    lines = cellstr(string(lines));
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

function text = maxText(value)
    value = double(value);
    if value <= 0 || ~isfinite(value)
        text = "all";
    else
        text = string(value);
    end
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
