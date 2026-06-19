% Expected caller: rhs_screen.run/buildSpec. Input is app state. Output is
% compact status lines for the detail panel.
function lines = detailLines(S)
%DETAILLINES Build detail-panel text for RHS screening.

    if nargin == 0 || isempty(S)
        lines = {'No RHS folder has been screened.'};
        return;
    end

    statusMessage = char(string(fieldOrDefault(S, "statusMessage", ...
        "No RHS folder has been screened.")));
    lines = {
        statusMessage
        "Minimum duration: " + char(string(fieldOrDefault(S, "minDurationSec", 0))) + " s"
        "Require exact data blocks: " + char(string(fieldOrDefault(S, "requireExactBlocks", true)))
        "Output folder: " + char(displayPath(fieldOrDefault(S, "outputFolder", "")))};

    if isfield(S, "session") && isstruct(S.session) && ...
            isfield(S.session, "recordings") && istable(S.session.recordings)
        recordings = S.session.recordings;
        lines{end+1} = sprintf("Recordings: %d", height(recordings));
        if ismember("keep", recordings.Properties.VariableNames)
            lines{end+1} = sprintf("Kept for analysis: %d", ...
                sum(logical(recordings.keep)));
        end
        if height(recordings) > 0
            flags = unique(recordings.qcFlag, "stable");
            for k = 1:numel(flags)
                lines{end+1} = sprintf("%s: %d", char(flags(k)), ...
                    sum(recordings.qcFlag == flags(k)));
            end
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

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = "Not selected";
        return;
    end
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
    if strlength(text) == 0
        text = string(pathValue);
    end
end
