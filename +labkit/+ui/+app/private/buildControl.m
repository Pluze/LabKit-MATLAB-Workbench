% Private UI app helper. Expected caller: buildSection or buildWorkspace.
% Inputs are the current UI registry, one validated control spec, a parent
% grid, target row, and debug context. Output is the updated registry after
% the requested control is built.
function ui = buildControl(ui, controlSpec, parentGrid, row, debug)
    switch controlSpec.kind
        case 'field'
            ui = buildField(ui, controlSpec, parentGrid, row);
        case 'rangeField'
            ui = buildRangeField(ui, controlSpec, parentGrid, row);
        case 'panner'
            ui = buildPanner(ui, controlSpec, parentGrid, row);
        case 'action'
            ui = buildAction(ui, controlSpec, parentGrid, row, [1 2]);
        case 'actionGroup'
            ui = buildActionGroup(ui, controlSpec, parentGrid, row);
        case 'pathPanel'
            ui = buildPathPanel(ui, controlSpec, parentGrid, row);
        case 'resultTable'
            ui = buildResultTable(ui, controlSpec, parentGrid, row);
        case 'logPanel'
            ui = buildLogPanel(ui, controlSpec, parentGrid, row, debug);
        case 'statusPanel'
            ui = buildStatusPanel(ui, controlSpec, parentGrid, row);
        case 'custom'
            ui = buildCustom(ui, controlSpec, parentGrid, row, debug);
        otherwise
            error('labkit:ui:app:UnsupportedControl', ...
                'Unsupported UI 2.0 control kind "%s".', controlSpec.kind);
    end
end

function ui = buildField(ui, fieldSpec, parentGrid, row)
    props = fieldSpec.props;
    kind = lower(char(string(props.kind)));
    labelText = optionValue(props, 'label', fieldSpec.id);
    enabled = optionValue(props, 'enabled', true);

    if strcmp(kind, 'checkbox')
        control = uicheckbox(parentGrid, 'Text', labelText, ...
            'Enable', onOff(enabled));
        control.Layout.Row = row;
        control.Layout.Column = [1 2];
        if isfield(props, 'value')
            control.Value = logical(props.value);
        end
        adapter = registerValueControl(fieldSpec, control, control, []);
        appCallback = optionValue(props, 'onChange', []);
        control.ValueChangedFcn = semanticValueCallback(fieldSpec.id, appCallback);
        setOriginalCallbackName(control, appCallback);
        ui.controls.(fieldSpec.id) = adapter;
        return;
    end

    label = uilabel(parentGrid, 'Text', labelText, ...
        'HorizontalAlignment', 'right');
    label.Layout.Row = row;
    label.Layout.Column = 1;
    control = createFieldControl(parentGrid, kind, props, enabled);
    control.Layout.Row = row;
    control.Layout.Column = 2;
    adapter = registerValueControl(fieldSpec, control, control, label);
    ui.controls.(fieldSpec.id) = adapter;
    if isprop(control, 'ValueChangedFcn')
        control.ValueChangedFcn = semanticValueCallback(fieldSpec.id, ...
            optionValue(props, 'onChange', []));
    end
end

function control = createFieldControl(parentGrid, kind, props, enabled)
    switch kind
        case 'text'
            control = uieditfield(parentGrid, 'text', 'Enable', onOff(enabled));
        case 'number'
            control = uieditfield(parentGrid, 'numeric', 'Enable', onOff(enabled));
        case 'spinner'
            control = uispinner(parentGrid, 'Enable', onOff(enabled));
        case 'dropdown'
            control = uidropdown(parentGrid, 'Enable', onOff(enabled));
            if isfield(props, 'items')
                control.Items = cellstr(string(props.items));
            end
        case 'slider'
            control = uislider(parentGrid, 'Enable', onOff(enabled));
        case 'readonly'
            control = uieditfield(parentGrid, 'text', ...
                'Editable', 'off', 'Enable', onOff(enabled));
        otherwise
            error('labkit:ui:app:UnsupportedFieldKind', ...
                'Unsupported UI 2.0 field kind "%s".', kind);
    end
    applyCommonValueProps(control, props);
end

function ui = buildPanner(ui, pannerSpec, parentGrid, row)
    props = pannerSpec.props;
    labelText = optionValue(props, 'label', pannerSpec.id);
    enabled = optionValue(props, 'enabled', true);

    label = uilabel(parentGrid, 'Text', labelText, ...
        'HorizontalAlignment', 'right');
    label.Layout.Row = row;
    label.Layout.Column = 1;

    grid = uigridlayout(parentGrid, [1 3]);
    grid.Padding = [0 0 0 0];
    grid.ColumnSpacing = 6;
    grid.ColumnWidth = {34, '1x', 34};
    grid.Layout.Row = row;
    grid.Layout.Column = 2;

    leftButton = uibutton(grid, 'Text', optionValue(props, 'leftLabel', '<'), ...
        'Enable', onOff(enabled));
    leftButton.Layout.Row = 1;
    leftButton.Layout.Column = 1;
    slider = uislider(grid, 'Enable', onOff(enabled));
    slider.Layout.Row = 1;
    slider.Layout.Column = 2;
    applyCommonValueProps(slider, props);
    slider.Value = clampNumericValue(slider.Value, slider.Limits);
    rightButton = uibutton(grid, 'Text', optionValue(props, 'rightLabel', '>'), ...
        'Enable', onOff(enabled));
    rightButton.Layout.Row = 1;
    rightButton.Layout.Column = 3;

    adapter = baseAdapter(pannerSpec, 'panner');
    adapter.label = label;
    adapter.grid = grid;
    adapter.leftButton = leftButton;
    adapter.rightButton = rightButton;
    adapter.slider = slider;
    adapter.handle = slider;
    adapter.valueHandle = slider;
    adapter.getValue = @() slider.Value;
    adapter.setValue = @(value) setPannerValue(slider, value);
    ui.controls.(pannerSpec.id) = adapter;

    appCallback = optionValue(props, 'onChange', []);
    slider.ValueChangedFcn = semanticValueCallback(pannerSpec.id, appCallback);
    leftButton.ButtonPushedFcn = semanticPannerStepCallback( ...
        pannerSpec.id, -1, appCallback);
    rightButton.ButtonPushedFcn = semanticPannerStepCallback( ...
        pannerSpec.id, 1, appCallback);
    setOriginalCallbackName(slider, appCallback);
    setOriginalCallbackName(leftButton, appCallback);
    setOriginalCallbackName(rightButton, appCallback);
end

function setPannerValue(slider, value)
    value = clampNumericValue(value, slider.Limits);
    if isequaln(slider.Value, value)
        return;
    end
    callback = slider.ValueChangedFcn;
    cleanupObj = onCleanup(@() restoreValueChangedCallback(slider, callback));
    slider.ValueChangedFcn = [];
    slider.Value = value;
    clear cleanupObj;
end

function ui = buildRangeField(ui, rangeSpec, parentGrid, row)
    props = rangeSpec.props;
    labelText = optionValue(props, 'label', rangeSpec.id);
    value = optionValue(props, 'value', [0 0]);
    if numel(value) ~= 2
        error('labkit:ui:app:InvalidRangeValue', ...
            'rangeField "%s" value must have two elements.', rangeSpec.id);
    end

    label = uilabel(parentGrid, 'Text', labelText, ...
        'HorizontalAlignment', 'right');
    label.Layout.Row = row;
    label.Layout.Column = 1;
    grid = uigridlayout(parentGrid, [1 2]);
    grid.Padding = [0 0 0 0];
    grid.ColumnWidth = {'1x', '1x'};
    grid.Layout.Row = row;
    grid.Layout.Column = 2;
    first = uieditfield(grid, 'numeric');
    first.Layout.Row = 1;
    first.Layout.Column = 1;
    second = uieditfield(grid, 'numeric');
    second.Layout.Row = 1;
    second.Layout.Column = 2;
    first.Value = value(1);
    second.Value = value(2);
    if isfield(props, 'limits')
        first.Limits = props.limits;
        second.Limits = props.limits;
    end

    adapter = baseAdapter(rangeSpec, 'rangeField');
    adapter.label = label;
    adapter.grid = grid;
    adapter.startHandle = first;
    adapter.endHandle = second;
    adapter.getValue = @() [first.Value second.Value];
    adapter.setValue = @setRangeValue;
    ui.controls.(rangeSpec.id) = adapter;
    callback = semanticValueCallback(rangeSpec.id, optionValue(props, 'onChange', []));
    first.ValueChangedFcn = callback;
    second.ValueChangedFcn = callback;

    function setRangeValue(newValue)
        if numel(newValue) ~= 2
            error('labkit:ui:view:InvalidRangeValue', ...
                'rangeField "%s" value must have two elements.', rangeSpec.id);
        end
        first.Value = newValue(1);
        second.Value = newValue(2);
    end
end

function ui = buildActionGroup(ui, groupSpec, parentGrid, row)
    actions = groupSpec.children;
    count = max(1, numel(actions));
    grid = uigridlayout(parentGrid, [1 count]);
    grid.Padding = [0 0 0 0];
    grid.ColumnSpacing = 8;
    grid.ColumnWidth = repmat({'1x'}, 1, count);
    grid.Layout.Row = row;
    grid.Layout.Column = [1 2];
    adapter = baseAdapter(groupSpec, 'actionGroup');
    adapter.grid = grid;
    adapter.actions = struct();
    ui.controls.(groupSpec.id) = adapter;
    for k = 1:numel(actions)
        [ui, actionAdapter] = buildAction(ui, actions{k}, grid, 1, k);
        ui.controls.(groupSpec.id).actions.(actions{k}.id) = actionAdapter;
    end
end

function [ui, adapter] = buildAction(ui, actionSpec, parentGrid, row, column)
    props = actionSpec.props;
    button = uibutton(parentGrid, 'Text', optionValue(props, 'label', actionSpec.id), ...
        'Enable', onOff(optionValue(props, 'enabled', true)));
    button.Layout.Row = row;
    button.Layout.Column = column;
    adapter = baseAdapter(actionSpec, 'action');
    adapter.button = button;
    adapter.handle = button;
    adapter.valueHandle = button;
    ui.controls.(actionSpec.id) = adapter;
    appCallback = optionValue(props, 'onInvoke', []);
    button.ButtonPushedFcn = semanticActionCallback(actionSpec.id, appCallback);
    setOriginalCallbackName(button, appCallback);
end

function ui = buildPathPanel(ui, pathSpec, parentGrid, row)
    props = pathSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'label', pathSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [3 2]);
    grid.RowHeight = {'fit', '1x', 'fit'};
    grid.ColumnWidth = {'1x', '1x'};
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;
    grid.Padding = [8 8 8 8];

    chooseButton = uibutton(grid, 'Text', chooseButtonText(props), ...
        'ButtonPushedFcn', semanticPathChooseCallback(pathSpec.id, ...
        optionValue(props, 'onChoose', [])));
    setOriginalCallbackName(chooseButton, optionValue(props, 'onChoose', []));
    chooseButton.Layout.Row = 1;
    chooseButton.Layout.Column = 1;
    clearButton = uibutton(grid, 'Text', optionValue(props, 'clearLabel', 'Clear'), ...
        'ButtonPushedFcn', semanticPathClearCallback(pathSpec.id, ...
        optionValue(props, 'onClear', [])));
    setOriginalCallbackName(clearButton, optionValue(props, 'onClear', []));
    clearButton.Layout.Row = 1;
    clearButton.Layout.Column = 2;
    emptyText = emptyPathText(props);
    listbox = uilistbox(grid, 'Items', {emptyText}, ...
        'Multiselect', pathMultiselect(props));
    if strcmp(listbox.Multiselect, 'on')
        listbox.Value = {emptyText};
    else
        listbox.Value = emptyText;
    end
    listbox.ValueChangedFcn = semanticPathSelectionCallback(pathSpec.id, ...
        optionValue(props, 'onSelectionChange', []));
    setOriginalCallbackName(listbox, optionValue(props, 'onSelectionChange', []));
    listbox.Layout.Row = 2;
    listbox.Layout.Column = [1 2];
    status = uieditfield(grid, 'text', 'Editable', 'off', ...
        'Value', pathStatusText(props, {}));
    status.Layout.Row = 3;
    status.Layout.Column = [1 2];

    adapter = baseAdapter(pathSpec, 'pathPanel');
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.chooseButton = chooseButton;
    adapter.clearButton = clearButton;
    adapter.listbox = listbox;
    adapter.status = status;
    adapter.valueHandle = listbox;
    adapter.getValue = @() currentPathValues(adapter);
    adapter.setValue = @(paths) applyPathSelection(adapter, paths, true);
    ui.controls.(pathSpec.id) = adapter;
end

function ui = buildResultTable(ui, tableSpec, parentGrid, row)
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
    if isfield(props, 'columnWidth')
        table.ColumnWidth = props.columnWidth;
    end
    appCellEditCallback = optionValue(props, 'onCellEdit', []);
    table.CellEditCallback = semanticTableCellEditCallback(tableSpec.id, ...
        appCellEditCallback);
    setOriginalCallbackName(table, appCellEditCallback);
    table.CellSelectionCallback = semanticTableSelectionCallback(tableSpec.id, ...
        optionValue(props, 'onSelectionChange', []));
    table.Layout.Row = 1;
    table.Layout.Column = 1;
    adapter = baseAdapter(tableSpec, 'resultTable');
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.table = table;
    adapter.valueHandle = table;
    adapter.getValue = @() table.Data;
    adapter.setValue = @(value) setTableData(table, value);
    ui.controls.(tableSpec.id) = adapter;
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

function ui = buildLogPanel(ui, logSpec, parentGrid, row, debug)
    props = logSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'title', logSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [1 1]);
    grid.Padding = [8 8 8 8];
    textArea = uitextarea(grid, 'Editable', 'off', ...
        'Value', textLines(optionValue(props, 'value', {'Ready.'})));
    textArea.Layout.Row = 1;
    textArea.Layout.Column = 1;
    adapter = baseAdapter(logSpec, 'logPanel');
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.textArea = textArea;
    adapter.valueHandle = textArea;
    ui.controls.(logSpec.id) = adapter;
    if isDebugEnabled(debug)
        debug.attachTextLog(textArea);
    end
end

function ui = buildStatusPanel(ui, statusSpec, parentGrid, row)
    props = statusSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'title', statusSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [1 1]);
    grid.Padding = [8 8 8 8];
    textArea = uitextarea(grid, 'Editable', 'off', ...
        'Value', textLines(optionValue(props, 'value', {''})));
    textArea.Layout.Row = 1;
    textArea.Layout.Column = 1;
    adapter = baseAdapter(statusSpec, 'statusPanel');
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.textArea = textArea;
    adapter.valueHandle = textArea;
    ui.controls.(statusSpec.id) = adapter;
end

function ui = buildCustom(ui, customSpec, parentGrid, row, debug)
    props = customSpec.props;
    panel = uipanel(parentGrid, 'Title', customSpec.id);
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    context = struct('ui', ui, 'debug', debug, 'spec', customSpec);
    handle = props.builder(panel, customSpec.id, context, props);
    adapter = baseAdapter(customSpec, 'custom');
    adapter.panel = panel;
    adapter.handle = handle;
    ui.controls.(customSpec.id) = adapter;
end

function callback = semanticValueCallback(id, appCallback)
    if isempty(appCallback)
        callback = [];
        return;
    end
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        if isfield(control, 'getValue')
            event.value = control.getValue();
        end
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function callback = semanticPannerStepCallback(id, direction, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        previousValue = control.getValue();
        nextValue = pannerStepValue(control, direction);
        control.setValue(nextValue);
        if isempty(appCallback) || isequaln(previousValue, control.getValue())
            return;
        end
        event = semanticEvent(control, control.valueHandle, rawEvent, 'user');
        event.value = control.getValue();
        event.previousValue = previousValue;
        event.stepDirection = direction;
        event.action = 'step';
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function callback = semanticTableCellEditCallback(id, appCallback)
    if isempty(appCallback)
        callback = [];
        return;
    end
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.value = source.Data;
        event.indices = rawEventValue(rawEvent, 'Indices', []);
        event.previousData = rawEventValue(rawEvent, 'PreviousData', []);
        event.newData = rawEventValue(rawEvent, 'NewData', []);
        event.editData = rawEventValue(rawEvent, 'EditData', []);
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function value = pannerStepValue(control, direction)
    slider = control.valueHandle;
    limits = double(slider.Limits);
    span = max(eps, diff(limits));
    step = optionValue(control.props, 'step', NaN);
    if ~isfinite(step) || step <= 0
        fraction = optionValue(control.props, 'stepFraction', 0.002);
        step = span .* max(eps, double(fraction));
    end
    if isfield(control.props, 'minStep')
        step = max(step, double(control.props.minStep));
    end
    if isfield(control.props, 'maxStep')
        step = min(step, double(control.props.maxStep));
    end
    value = clampNumericValue(slider.Value + direction .* step, limits);
end

function value = clampNumericValue(value, limits)
    value = double(value);
    if ~isfinite(value)
        value = limits(1);
    end
    value = min(limits(2), max(limits(1), value));
end

function callback = semanticTableSelectionCallback(id, appCallback)
    if isempty(appCallback)
        callback = [];
        return;
    end
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.value = source.Data;
        event.indices = rawEventValue(rawEvent, 'Indices', []);
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function setOriginalCallbackName(handle, callback)
    if isempty(callback) || ~isa(callback, 'function_handle')
        return;
    end
    try
        setappdata(handle, 'labkit_ui_original_callback_name', func2str(callback));
    catch
    end
end

function callback = semanticActionCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = id;
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function message = actionBusyMessage(id, props)
    message = optionValue(props, 'busyMessage', "");
    if strlength(string(message)) == 0
        message = optionValue(props, 'label', id);
    end
    message = char(string(message));
end

function runSemanticAppCallback(ui, control, event, appCallback, id)
    if isempty(appCallback)
        return;
    end

    labkit.ui.app.runBusy(ui.figure, actionBusyMessage(id, control.props), ...
        @() appCallback(control, event), ...
        struct('freezeInteractions', false));
end

function tf = isFigureBusy(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiBusy') && ...
            logical(getappdata(fig, 'labkitUiBusy'));
    catch
        tf = false;
    end
end

function callback = semanticPathChooseCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        paths = choosePaths(control);
        if isempty(paths)
            return;
        end
        control = applyPathSelection(control, paths, true);
        ui.controls.(id) = control;
        setappdata(ui.figure, 'labkitUiRegistry', ui);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = 'choose';
        event.mode = optionValue(control.props, 'mode', '');
        event.paths = normalizePathList(paths);
        event.selection = currentPathValues(control);
        event.value = event.selection;
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function callback = semanticPathClearCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        control = applyPathSelection(control, {}, true);
        ui.controls.(id) = control;
        setappdata(ui.figure, 'labkitUiRegistry', ui);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = 'clear';
        event.mode = optionValue(control.props, 'mode', '');
        event.paths = strings(0, 1);
        event.selection = strings(0, 1);
        event.value = strings(0, 1);
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function callback = semanticPathSelectionCallback(id, appCallback)
    if isempty(appCallback)
        callback = [];
        return;
    end
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = 'select';
        event.mode = optionValue(control.props, 'mode', '');
        event.paths = currentPathValues(control);
        event.selection = event.paths;
        event.value = event.paths;
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function control = applyPathSelection(control, paths, updateStatus)
    items = normalizedPaths(paths);
    emptyText = emptyPathText(control.props);
    if isempty(items)
        control.listbox.Items = {emptyText};
        if strcmp(control.listbox.Multiselect, 'on')
            control.listbox.Value = {emptyText};
        else
            control.listbox.Value = emptyText;
        end
    else
        control.listbox.Items = items;
        if strcmp(control.listbox.Multiselect, 'on')
            control.listbox.Value = items;
        else
            control.listbox.Value = items{1};
        end
    end
    if updateStatus
        control.status.Value = pathStatusText(control.props, items);
    end
end

function paths = choosePaths(control)
    props = control.props;
    if isfield(props, 'dialogProvider') && isa(props.dialogProvider, 'function_handle')
        paths = normalizedPaths(props.dialogProvider(props));
        return;
    end

    mode = optionValue(props, 'mode', 'singleFile');
    switch mode
        case 'singleFile'
            paths = chooseFiles(props, false);
        case 'multiFile'
            paths = chooseFiles(props, true);
        case {'folder', 'outputFolder'}
            paths = chooseFolder(optionValue(props, 'startPath', pwd));
        case 'multiFolder'
            paths = chooseMultipleFolders(optionValue(props, 'startPath', pwd));
        otherwise
            error('labkit:ui:app:InvalidPathMode', ...
                'Unsupported pathPanel mode "%s".', mode);
    end
end

function paths = chooseFiles(props, allowMulti)
    filters = normalizeFileFilters(optionValue(props, 'filters', ...
        {'*.*', 'All files'}));
    titleText = optionValue(props, 'dialogTitle', chooseButtonText(props));
    startPath = optionValue(props, 'startPath', pwd);
    if allowMulti
        [files, folder] = uigetfile(filters, titleText, startPath, 'MultiSelect', 'on');
    else
        [files, folder] = uigetfile(filters, titleText, startPath);
    end
    if isequal(files, 0) || isequal(folder, 0)
        paths = {};
        return;
    end
    if ischar(files) || isstring(files)
        files = {char(string(files))};
    end
    files = reshape(files, 1, []);
    paths = cell(1, numel(files));
    for k = 1:numel(files)
        paths{k} = fullfile(folder, char(string(files{k})));
    end
end

function paths = chooseFolder(startPath)
    folder = uigetdir(startPath, 'Choose folder');
    if isequal(folder, 0)
        paths = {};
    else
        paths = {folder};
    end
end

function paths = chooseMultipleFolders(startPath)
    paths = {};
    nextPath = startPath;
    while true
        folder = uigetdir(nextPath, sprintf('Choose folder %d', numel(paths) + 1));
        if isequal(folder, 0)
            break;
        end
        paths{end + 1} = folder;
        nextPath = folder;
        choice = questdlg('Add another folder?', 'Select folders', ...
            'Add another', 'Done', 'Done');
        if ~strcmp(choice, 'Add another')
            break;
        end
    end
    paths = unique(paths, 'stable');
end

function paths = normalizedPaths(paths)
    paths = cellstr(normalizePathList(paths).');
end

function text = pathStatusText(props, paths)
    if isempty(paths)
        text = emptyStatusText(props);
    elseif numel(paths) == 1
        text = char(string(paths{1}));
    else
        text = sprintf('%d selected', numel(paths));
    end
end

function values = currentPathValues(control)
    values = strings(0, 1);
    if isfield(control, 'listbox') && isvalid(control.listbox)
        emptyText = emptyPathText(control.props);
        if isempty(control.listbox.Items) || ...
                (numel(control.listbox.Items) == 1 && strcmp(control.listbox.Items{1}, ...
                emptyText))
            return;
        end
        values = normalizePathList(control.listbox.Value);
    end
end

function paths = normalizePathList(value)
    if isempty(value)
        paths = strings(0, 1);
    elseif ischar(value)
        paths = string({value});
    elseif isstring(value)
        paths = value;
    elseif iscell(value)
        if ~all(cellfun(@isTextScalar, value))
            error('labkit:ui:app:InvalidPathList', ...
                'Path panel values must be text scalars.');
        end
        paths = string(value);
    else
        error('labkit:ui:app:InvalidPathList', ...
            'Path panel values must be char, string, or a cell array of text.');
    end
    paths = paths(:);
    paths = paths(strlength(paths) > 0);
end

function tf = isTextScalar(value)
    tf = (ischar(value) && (isrow(value) || isempty(value))) || ...
        (isstring(value) && isscalar(value));
end

function text = emptyStatusText(props)
    if isstruct(props) && isfield(props, 'status')
        text = char(string(props.status));
    else
        text = emptyPathText(props);
    end
end

function text = emptyPathText(props)
    if isstruct(props) && isfield(props, 'emptyText')
        text = char(string(props.emptyText));
        return;
    end
    if isstruct(props) && isfield(props, 'status')
        text = char(string(props.status));
        return;
    end

    mode = char(string(optionValue(props, 'mode', 'singleFile')));
    switch mode
        case 'multiFile'
            text = 'No files selected';
        case {'folder', 'multiFolder'}
            text = 'No folder selected';
        case 'outputFolder'
            text = 'No output folder selected';
        otherwise
            text = 'No file selected';
    end
end

function filters = normalizeFileFilters(filters)
    if iscell(filters) && numel(filters) == 1 && iscell(filters{1})
        filters = filters{1};
    end
    if ischar(filters)
        return;
    end
    if isstring(filters)
        if isscalar(filters)
            filters = char(filters);
            return;
        end
        filters = cellstr(filters);
    end
    if iscell(filters)
        filters = cellfun(@(value) char(string(value)), filters, ...
            'UniformOutput', false);
    end
end

function ui = currentUiRegistry(source)
    fig = ancestor(source, 'figure');
    if isempty(fig) || ~isappdata(fig, 'labkitUiRegistry')
        error('labkit:ui:app:MissingRegistry', ...
            'UI registry appdata was not found on the current figure.');
    end
    ui = getappdata(fig, 'labkitUiRegistry');
end

function restoreTableEditCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle)
        handle.CellEditCallback = callback;
    end
end

function restoreValueChangedCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle)
        handle.ValueChangedFcn = callback;
    end
end

function value = rawEventValue(rawEvent, propertyName, defaultValue)
    value = defaultValue;
    if isstruct(rawEvent) && isfield(rawEvent, propertyName)
        value = rawEvent.(propertyName);
    elseif ~isempty(rawEvent) && isprop(rawEvent, propertyName)
        value = rawEvent.(propertyName);
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

function applyCommonValueProps(control, props)
    if isfield(props, 'items') && isprop(control, 'Items')
        control.Items = cellstr(string(props.items));
    end
    if isfield(props, 'limits') && isprop(control, 'Limits')
        control.Limits = props.limits;
    end
    if isfield(props, 'step') && isprop(control, 'Step')
        control.Step = props.step;
    end
    if isfield(props, 'valueDisplayFormat') && isprop(control, 'ValueDisplayFormat')
        control.ValueDisplayFormat = props.valueDisplayFormat;
    end
    if isfield(props, 'value') && isprop(control, 'Value')
        control.Value = props.value;
    end
end

function text = chooseButtonText(props)
    if isfield(props, 'chooseLabel')
        text = char(string(props.chooseLabel));
        return;
    end

    mode = optionValue(props, 'mode', 'singleFile');
    switch mode
        case {'folder', 'multiFolder', 'outputFolder'}
            text = 'Choose folder';
        otherwise
            text = 'Choose files';
    end
end

function value = pathMultiselect(props)
    mode = optionValue(props, 'selectionMode', defaultSelectionMode( ...
        optionValue(props, 'mode', 'singleFile')));
    if strcmp(mode, 'multiple')
        value = 'on';
    else
        value = 'off';
    end
end

function mode = defaultSelectionMode(pathMode)
    if any(strcmp(pathMode, {'multiFile', 'multiFolder'}))
        mode = 'multiple';
    else
        mode = 'single';
    end
end

function lines = textLines(value)
    if isstring(value)
        lines = cellstr(value);
    elseif ischar(value)
        lines = {value};
    elseif iscell(value)
        lines = cellstr(string(value));
    else
        lines = cellstr(string(value));
    end
end

function adapter = baseAdapter(spec, kind)
    adapter = struct();
    adapter.id = spec.id;
    adapter.kind = kind;
    adapter.spec = spec;
    adapter.props = spec.props;
end

function adapter = registerValueControl(spec, handle, valueHandle, label)
    adapter = baseAdapter(spec, 'field');
    adapter.handle = handle;
    adapter.valueHandle = valueHandle;
    adapter.label = label;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function tf = isDebugEnabled(debugContext)
    tf = isstruct(debugContext) && isfield(debugContext, 'enabled') && ...
        logical(debugContext.enabled);
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
