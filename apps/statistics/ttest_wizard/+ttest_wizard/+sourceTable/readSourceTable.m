% App table reader; returns one visible cell-grid record and only reads the selected file.
function source = readSourceTable(filepath, requestedSheet)
%READSOURCETABLE Read one CSV, TSV, XLSX, or XLS as a visible cell grid.
%
% Expected caller: T-Test Wizard source actions and session reconstruction.
% filepath is a scalar path. requestedSheet is optional text; blank selects
% the first worksheet. The output contains displayName, sheet, sheetNames,
% cells, columnNames, rowNames, rowCount, columnCount, and message. Headers
% remain in cells so displayed coordinates match the original source.
% Reading is the only side effect.

    if nargin < 2
        requestedSheet = "";
    end
    filepath = string(filepath);
    requestedSheet = string(requestedSheet);
    assert(isscalar(filepath) && strlength(filepath) > 0 && isfile(filepath), ...
        'ttest_wizard:SourceNotFound', ...
        'The selected table file does not exist.');
    assert(isscalar(requestedSheet), 'ttest_wizard:InvalidSheet', ...
        'Worksheet selection must be scalar text.');

    sheetNames = ttest_wizard.sourceTable.listWorkbookSheets(filepath);
    sheet = chooseSheet(sheetNames, requestedSheet);
    [~, name, extension] = fileparts(filepath);
    extension = lower(string(extension));
    switch extension
        case ".csv"
            cells = readcell(filepath, 'FileType', 'text', ...
                'Delimiter', ',');
        case ".tsv"
            cells = readcell(filepath, 'FileType', 'text', ...
                'Delimiter', char(9));
        otherwise
            cells = readcell(filepath, 'Sheet', sheet);
    end
    if ~iscell(cells)
        cells = num2cell(cells);
    end
    cells = trimEmptyEdges(cells);
    rowCount = size(cells, 1);
    columnCount = size(cells, 2);
    source = struct( ...
        "ok", true, ...
        "filepath", filepath, ...
        "displayName", string(name) + string(extension), ...
        "sheet", sheet, ...
        "sheetNames", sheetNames, ...
        "cells", {cells}, ...
        "columnNames", {ttest_wizard.sourceTable.spreadsheetColumnNames( ...
            columnCount)}, ...
        "rowNames", {cellstr(string((1:rowCount).'))}, ...
        "rowCount", rowCount, ...
        "columnCount", columnCount, ...
        "message", sprintf('%d rows x %d columns | %s', ...
            rowCount, columnCount, sheet));
end

function sheet = chooseSheet(names, requested)
    if strlength(requested) > 0
        match = find(names == requested, 1);
    else
        match = [];
    end
    if isempty(match)
        sheet = names(1);
    else
        sheet = names(match);
    end
end

function cells = trimEmptyEdges(cells)
    if isempty(cells)
        cells = cell(0, 0);
        return;
    end
    occupied = false(size(cells));
    for k = 1:numel(cells)
        occupied(k) = ~blankCell(cells{k});
    end
    rows = find(any(occupied, 2));
    columns = find(any(occupied, 1));
    if isempty(rows) || isempty(columns)
        cells = cell(0, 0);
    else
        cells = cells(1:rows(end), 1:columns(end));
    end
end

function tf = blankCell(value)
    tf = isempty(value);
    if tf
        return;
    end
    if ischar(value) || (isstring(value) && isscalar(value))
        tf = strlength(strtrim(string(value))) == 0 || ismissing(string(value));
        return;
    end
    if isscalar(value)
        try
            tf = logical(ismissing(value));
        catch
            tf = false;
        end
    end
end
