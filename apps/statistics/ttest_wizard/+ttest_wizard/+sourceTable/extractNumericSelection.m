% App selection parser; converts visible cell coordinates into one numeric-vector report.
function selection = extractNumericSelection(cells, indices)
%EXTRACTNUMERICSELECTION Copy finite numbers from selected table cells.
%
% Expected caller: T-Test Wizard capture-A and capture-B actions. cells is the
% displayed cell matrix and indices is N-by-2 [row column] coordinates from a
% resultTable selection event. Values are returned in visible row-major order.
% Numeric text is accepted; blanks and labels are counted and skipped;
% nonfinite numeric cells make selection.ok false. Side effects are none.

    assert(iscell(cells), 'ttest_wizard:InvalidSourceCells', ...
        'Source table data must be a cell matrix.');
    assert(isnumeric(indices) && size(indices, 2) == 2, ...
        'ttest_wizard:InvalidSelection', ...
        'Cell selection must be an N-by-2 numeric coordinate array.');
    indices = double(indices);
    valid = all(isfinite(indices), 2) & all(indices == fix(indices), 2) & ...
        indices(:, 1) >= 1 & indices(:, 1) <= size(cells, 1) & ...
        indices(:, 2) >= 1 & indices(:, 2) <= size(cells, 2);
    indices = unique(indices(valid, :), 'rows', 'stable');
    indices = sortrows(indices, [1 2]);

    values = zeros(size(indices, 1), 1);
    acceptedIndices = zeros(size(indices, 1), 2);
    acceptedCount = 0;
    numericTextCount = 0;
    blankCount = 0;
    textCount = 0;
    invalidCount = 0;
    for k = 1:size(indices, 1)
        value = cells{indices(k, 1), indices(k, 2)};
        [kind, number] = classifyCell(value);
        switch kind
            case "number"
                acceptedCount = acceptedCount + 1;
                values(acceptedCount) = number;
                acceptedIndices(acceptedCount, :) = indices(k, :);
            case "numeric_text"
                acceptedCount = acceptedCount + 1;
                values(acceptedCount) = number;
                acceptedIndices(acceptedCount, :) = indices(k, :);
                numericTextCount = numericTextCount + 1;
            case "blank"
                blankCount = blankCount + 1;
            case "text"
                textCount = textCount + 1;
            otherwise
                invalidCount = invalidCount + 1;
        end
    end
    values = values(1:acceptedCount);
    acceptedIndices = acceptedIndices(1:acceptedCount, :);

    addresses = cellAddresses(acceptedIndices);
    selectedLabel = selectionLabel(indices);
    selection = struct( ...
        "ok", ~isempty(values) && invalidCount == 0, ...
        "values", values, ...
        "indices", acceptedIndices, ...
        "addresses", addresses, ...
        "selectedCount", size(indices, 1), ...
        "acceptedCount", numel(values), ...
        "numericTextCount", numericTextCount, ...
        "blankCount", blankCount, ...
        "textCount", textCount, ...
        "invalidCount", invalidCount, ...
        "selectedLabel", selectedLabel, ...
        "message", selectionMessage(selectedLabel, numel(values), ...
            blankCount, textCount, invalidCount));
end

function [kind, number] = classifyCell(value)
    number = NaN;
    if isempty(value)
        kind = "blank";
        return;
    end
    if (isnumeric(value) || islogical(value)) && isscalar(value)
        number = double(value);
        if isfinite(number)
            kind = "number";
        else
            kind = "invalid";
        end
        return;
    end
    if ischar(value) || (isstring(value) && isscalar(value))
        text = strtrim(string(value));
        if ismissing(text) || strlength(text) == 0
            kind = "blank";
            return;
        end
        number = str2double(text);
        if isfinite(number)
            kind = "numeric_text";
        else
            kind = "text";
        end
        return;
    end
    try
        if isscalar(value) && ismissing(value)
            kind = "blank";
            return;
        end
    catch
    end
    kind = "text";
end

function addresses = cellAddresses(indices)
    names = ttest_wizard.sourceTable.spreadsheetColumnNames( ...
        max([0; indices(:, 2)]));
    addresses = strings(size(indices, 1), 1);
    for k = 1:size(indices, 1)
        addresses(k) = string(names{indices(k, 2)}) + indices(k, 1);
    end
end

function label = selectionLabel(indices)
    if isempty(indices)
        label = "no cells";
        return;
    end
    rows = unique(indices(:, 1));
    columns = unique(indices(:, 2));
    rectangle = size(indices, 1) == numel(rows) * numel(columns);
    if rectangle
        allPairs = zeros(numel(rows) * numel(columns), 2);
        cursor = 0;
        for r = rows(:).'
            for c = columns(:).'
                cursor = cursor + 1;
                allPairs(cursor, :) = [r c];
            end
        end
        rectangle = isequal(sortrows(indices), sortrows(allPairs));
    end
    if rectangle
        names = ttest_wizard.sourceTable.spreadsheetColumnNames(columns(end));
        first = string(names{columns(1)}) + rows(1);
        last = string(names{columns(end)}) + rows(end);
        if first == last
            label = first;
        else
            label = first + ":" + last;
        end
    else
        label = size(indices, 1) + " selected cells";
    end
end

function message = selectionMessage(label, accepted, blanks, text, invalid)
    parts = accepted + " number" + plural(accepted) + " accepted";
    if blanks > 0
        parts(end + 1) = blanks + " blank" + plural(blanks) + " skipped";
    end
    if text > 0
        parts(end + 1) = text + " label" + plural(text) + " skipped";
    end
    if invalid > 0
        parts(end + 1) = invalid + " nonfinite value" + ...
            plural(invalid) + " must be corrected";
    end
    message = "Selected " + label + ": " + strjoin(parts, "; ") + ".";
end

function suffix = plural(count)
    suffix = "";
    if count ~= 1
        suffix = "s";
    end
end
