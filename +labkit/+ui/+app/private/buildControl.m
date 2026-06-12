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
        control.ValueChangedFcn = semanticValueCallback(fieldSpec.id, ...
            optionValue(props, 'onChange', []));
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
    button.ButtonPushedFcn = semanticActionCallback(actionSpec.id, ...
        optionValue(props, 'onInvoke', []));
end

function ui = buildPathPanel(ui, pathSpec, parentGrid, row)
    props = pathSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'label', pathSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [3 2]);
    grid.RowHeight = {'fit', '1x', 'fit'};
    grid.ColumnWidth = {'1x', '1x'};
    grid.Padding = [8 8 8 8];

    chooseButton = uibutton(grid, 'Text', chooseButtonText(props), ...
        'ButtonPushedFcn', semanticPathChooseCallback(pathSpec.id, ...
        optionValue(props, 'onChoose', [])));
    chooseButton.Layout.Row = 1;
    chooseButton.Layout.Column = 1;
    clearButton = uibutton(grid, 'Text', optionValue(props, 'clearLabel', 'Clear'), ...
        'ButtonPushedFcn', semanticPathClearCallback(pathSpec.id, ...
        optionValue(props, 'onClear', [])));
    clearButton.Layout.Row = 1;
    clearButton.Layout.Column = 2;
    listbox = uilistbox(grid, 'Items', {char(string(optionValue(props, ...
        'emptyText', 'No selection')))}, ...
        'Multiselect', pathMultiselect(props));
    listbox.ValueChangedFcn = semanticPathSelectionCallback(pathSpec.id, ...
        optionValue(props, 'onSelectionChange', []));
    listbox.Layout.Row = 2;
    listbox.Layout.Column = [1 2];
    status = uieditfield(grid, 'text', 'Editable', 'off', ...
        'Value', optionValue(props, 'status', 'No selection'));
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
        'Data', optionValue(props, 'data', cell(0, numel(columns))));
    table.Layout.Row = 1;
    table.Layout.Column = 1;
    adapter = baseAdapter(tableSpec, 'resultTable');
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.table = table;
    adapter.valueHandle = table;
    ui.controls.(tableSpec.id) = adapter;
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
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        if isfield(control, 'getValue')
            event.value = control.getValue();
        end
        appCallback(control, event);
    end
end

function callback = semanticActionCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = id;
        if ~isempty(appCallback)
            appCallback(control, event);
        end
    end
end

function callback = semanticPathChooseCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
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
        event.paths = paths;
        event.selection = currentPathValues(control);
        event.value = event.selection;
        if ~isempty(appCallback)
            appCallback(control, event);
        end
    end
end

function callback = semanticPathClearCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        control = ui.controls.(id);
        control = applyPathSelection(control, {}, true);
        ui.controls.(id) = control;
        setappdata(ui.figure, 'labkitUiRegistry', ui);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = 'clear';
        event.mode = optionValue(control.props, 'mode', '');
        event.paths = {};
        event.selection = {};
        event.value = {};
        if ~isempty(appCallback)
            appCallback(control, event);
        end
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
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = 'select';
        event.mode = optionValue(control.props, 'mode', '');
        event.paths = currentPathValues(control);
        event.selection = event.paths;
        event.value = event.paths;
        appCallback(control, event);
    end
end

function control = applyPathSelection(control, paths, updateStatus)
    items = normalizedPaths(paths);
    emptyText = optionValue(control.props, 'emptyText', 'No selection');
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
    filters = optionValue(props, 'filters', {'*.*', 'All files'});
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
        paths{k} = fullfile(folder, files{k});
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
    if isempty(paths)
        paths = {};
        return;
    end
    if ischar(paths) || isstring(paths)
        paths = cellstr(string(paths));
    elseif ~iscell(paths)
        paths = cellstr(string(paths));
    end
    paths = cellfun(@(value) char(string(value)), reshape(paths, 1, []), ...
        'UniformOutput', false);
end

function text = pathStatusText(props, paths)
    if isempty(paths)
        text = optionValue(props, 'status', 'No selection');
    elseif numel(paths) == 1
        text = paths{1};
    else
        text = sprintf('%d selected', numel(paths));
    end
end

function values = currentPathValues(control)
    values = {};
    if isfield(control, 'listbox') && isvalid(control.listbox)
        if isempty(control.listbox.Items) || ...
                (numel(control.listbox.Items) == 1 && strcmp(control.listbox.Items{1}, ...
                optionValue(control.props, 'emptyText', 'No selection')))
            values = {};
            return;
        end
        values = cellstr(string(control.listbox.Value));
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
