% Expected caller: rhs_screen.export.writeSessionJson and tests. Input is a
% rhs_screen session struct. Output is a jsonencode-compatible struct.
function payload = sessionJsonStruct(session)
%SESSIONJSONSTRUCT Convert a screening session to JSON-safe data.

    payload = session;
    if isfield(payload, "recordings") && istable(payload.recordings)
        payload.recordings = tableToStructArray(payload.recordings);
    end
    if isfield(payload, "groups") && istable(payload.groups)
        payload.groups = tableToStructArray(payload.groups);
    end
    if isfield(payload, "acceptedRecordingIds")
        payload.acceptedRecordingIds = cellstr(string(payload.acceptedRecordingIds(:)));
    end
    payload.exportedBy = "labkit_RHSScreen_app";
end

function rows = tableToStructArray(T)
    rows = struct([]);
    if height(T) == 0
        return;
    end
    names = T.Properties.VariableNames;
    rowCells = cell(height(T), 1);
    for r = 1:height(T)
        item = struct();
        for c = 1:numel(names)
            value = T{r, c};
            item.(names{c}) = jsonValue(value);
        end
        rowCells{r} = item;
    end
    rows = [rowCells{:}];
end

function value = jsonValue(value)
    if isstring(value)
        if isscalar(value)
            value = char(value);
        else
            value = cellstr(value(:));
        end
    elseif iscell(value)
        value = cellfun(@jsonValue, value, "UniformOutput", false);
    elseif islogical(value)
        value = logical(value);
    elseif isnumeric(value)
        value = double(value);
    end
end
