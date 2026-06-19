% Expected caller: rhs_preview.export.writeFilterRecordJson and tests. Input
% is RHS Preview app state. Output is a JSON-safe manual file filter record.
function payload = filterRecordJsonStruct(S)
%FILTERRECORDJSONSTRUCT Convert file filter rows to JSON-safe data.

    rows = table();
    if isstruct(S) && isfield(S, "filterRows") && istable(S.filterRows)
        rows = S.filterRows;
    end

    payload = struct( ...
        "type", "rhsFilterRecord", ...
        "version", 1, ...
        "exportedBy", "labkit_RHSPreview_app", ...
        "rootFolder", string(fieldOrDefault(S, "rhsFolder", "")), ...
        "recordings", tableToStructArray(rows));
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

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
