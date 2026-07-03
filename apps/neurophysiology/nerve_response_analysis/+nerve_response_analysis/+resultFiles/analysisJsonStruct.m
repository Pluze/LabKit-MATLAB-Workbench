% Expected caller: nerve_response_analysis.resultFiles.writeAnalysisJson and
% tests. Input is a session analysis struct. Output is JSON-safe data.
function payload = analysisJsonStruct(analysis)
%ANALYSISJSONSTRUCT Convert analysis tables to JSON-safe struct arrays.

    payload = analysis;
    tableFields = ["events", "trains", "metrics", "issues"];
    for k = 1:numel(tableFields)
        fieldName = tableFields(k);
        if isfield(payload, fieldName) && istable(payload.(fieldName))
            payload.(fieldName) = tableToStructArray(payload.(fieldName));
        end
    end
    payload.exportedBy = "labkit_NerveResponseAnalysis_app";
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
            item.(names{c}) = jsonValue(T{r, c});
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
    elseif isnumeric(value)
        value = double(value);
    elseif islogical(value)
        value = logical(value);
    end
end
