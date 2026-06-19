% Expected caller: rhs_preview.run/buildSpec. Input is app state. Output is
% editable cell rows for protocol differential/association pairs.
function data = protocolPairsTableData(S)
%PROTOCOLPAIRSTABLEDATA Build display rows for protocol pair editing.

    rows = table();
    if isstruct(S) && isfield(S, "protocolPairRows") && ...
            istable(S.protocolPairRows)
        rows = S.protocolPairRows;
    end

    minRows = 5;
    data = cell(max(height(rows), minRows), 5);
    for r = 1:height(rows)
        data{r, 1} = char(rows.id(r));
        data{r, 2} = char(rows.label(r));
        data{r, 3} = char(rows.positive(r));
        data{r, 4} = char(rows.negative(r));
        data{r, 5} = char(rows.mode(r));
    end
    for r = (height(rows) + 1):size(data, 1)
        data{r, 1} = '';
        data{r, 2} = '';
        data{r, 3} = '';
        data{r, 4} = '';
        data{r, 5} = 'positive-minus-negative';
    end
end
