% Expected caller: rhs_preview.run and unit tests. Inputs are GUI table cell
% data for protocol pairs. Output is a normalized pair table with blank rows
% removed. No UI handles or files are touched.
function rows = applyProtocolPairsTableData(data)
%APPLYPROTOCOLPAIRSTABLEDATA Apply edits from the protocol pair table.

    rows = emptyRows();
    if isempty(data)
        return;
    end

    maxRows = size(data, 1);
    idCol = strings(maxRows, 1);
    labelCol = strings(maxRows, 1);
    positiveCol = strings(maxRows, 1);
    negativeCol = strings(maxRows, 1);
    modeCol = strings(maxRows, 1);
    count = 0;
    for r = 1:size(data, 1)
        id = strtrim(string(data{r, 1}));
        label = strtrim(string(data{r, 2}));
        positive = strtrim(string(data{r, 3}));
        negative = strtrim(string(data{r, 4}));
        mode = strtrim(string(data{r, 5}));
        if strlength(id) == 0 && strlength(label) == 0 && ...
                strlength(positive) == 0 && strlength(negative) == 0
            continue;
        end
        if strlength(id) == 0 && strlength(label) > 0
            id = matlab.lang.makeValidName(char(lower(strrep(label, " ", "_"))));
        end
        if strlength(label) == 0
            label = id;
        end
        if strlength(mode) == 0
            mode = "positive-minus-negative";
        end
        count = count + 1;
        idCol(count) = id;
        labelCol(count) = label;
        positiveCol(count) = positive;
        negativeCol(count) = negative;
        modeCol(count) = mode;
    end
    if count > 0
        rows = table(idCol(1:count), labelCol(1:count), ...
            positiveCol(1:count), negativeCol(1:count), modeCol(1:count), ...
            'VariableNames', {'id', 'label', 'positive', 'negative', 'mode'});
    end
end

function rows = emptyRows()
    rows = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        strings(0, 1), strings(0, 1), ...
        'VariableNames', {'id', 'label', 'positive', 'negative', 'mode'});
end
