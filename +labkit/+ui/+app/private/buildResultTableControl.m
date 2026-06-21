% Private UI app helper. Expected caller: buildControl resultTable branch.
% Inputs are one validated resultTable spec, parent grid, target row, and
% semantic callback wiring. Output is the resultTable adapter.
% Side effects: creates MATLAB UI table controls.
function adapter = buildResultTableControl(tableSpec, parentGrid, row, callbacks)
    props = tableSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'title', tableSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [1 1]);
    grid.Padding = [8 8 8 8];

    columns = optionValue(props, 'columns', {});
    table = uitable(grid, 'ColumnName', columns, ...
        'RowName', optionValue(props, 'rowName', {}), ...
        'Data', tableDataForUi(optionValue(props, 'data', ...
        cell(0, numel(columns)))));
    if isfield(props, 'columnEditable')
        table.ColumnEditable = props.columnEditable;
    end
    if isfield(props, 'columnFormat')
        table.ColumnFormat = props.columnFormat;
    end

    table.CellEditCallback = callbacks.cellEdit;
    callbacks.setOriginalCallbackName(table, optionValue(props, 'onCellEdit', []));
    table.CellSelectionCallback = callbacks.selection;
    table.Layout.Row = 1;
    table.Layout.Column = 1;

    adapter = struct();
    adapter.id = tableSpec.id;
    adapter.kind = 'resultTable';
    adapter.spec = tableSpec;
    adapter.props = props;
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.table = table;
    adapter.valueHandle = table;
    adapter.getValue = @() table.Data;
    adapter.setValue = @(value) setTableData(table, value);
end

function setTableData(table, value)
    value = tableDataForUi(value);
    if isequaln(table.Data, value)
        return;
    end
    callback = table.CellEditCallback;
    cleanupObj = onCleanup(@() restoreTableEditCallback(table, callback));
    table.CellEditCallback = [];
    table.Data = value;
    clear cleanupObj;
end

function restoreTableEditCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle)
        handle.CellEditCallback = callback;
    end
end

function data = tableDataForUi(data)
    if istable(data) || isnumeric(data) || islogical(data)
        return;
    end
    if isempty(data)
        return;
    end
    if isstring(data)
        data = cellstr(data);
    end
    if ~iscell(data)
        data = cellstr(string(data));
    end
    for k = 1:numel(data)
        data{k} = tableCellValueForUi(data{k});
    end
end

function value = tableCellValueForUi(value)
    if isnumeric(value) || islogical(value) || ischar(value)
        return;
    end
    if isstring(value)
        if isscalar(value)
            value = char(value);
        else
            value = char(strjoin(value(:).', ", "));
        end
        return;
    end
    if iscell(value)
        value = char(strjoin(string(value(:)).', ", "));
    else
        value = char(string(value));
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
