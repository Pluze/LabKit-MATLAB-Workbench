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
        case 'filePanel'
            ui = buildFilePanel(ui, controlSpec, parentGrid, row);
        case 'resultTable'
            ui = buildResultTable(ui, controlSpec, parentGrid, row);
        case 'logPanel'
            ui = buildLogPanel(ui, controlSpec, parentGrid, row, debug);
        case 'usagePanel'
            ui = buildUsagePanel(ui, controlSpec, parentGrid, row);
        case 'statusPanel'
            ui = buildStatusPanel(ui, controlSpec, parentGrid, row);
        otherwise
            error('labkit:ui:app:UnsupportedControl', ...
                'Unsupported UI 3.0 control kind "%s".', controlSpec.kind);
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
        applyTextFit(control);
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
    applyTextFit(label);
    label.Layout.Row = row;
    label.Layout.Column = 1;
    control = createFieldControl(parentGrid, kind, props, enabled);
    control.Layout.Row = row;
    control.Layout.Column = 2;
    adapter = registerValueControl(fieldSpec, control, control, label);
    if strcmp(kind, 'readonly')
        adapter.getValue = @() getReadonlyText(control);
        adapter.setValue = @(value) setReadonlyText(control, value);
    end
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
            control = uitextarea(parentGrid, ...
                'Value', char(string(optionValue(props, 'value', ''))), ...
                'Editable', 'off', ...
                'Enable', onOff(enabled), ...
                'Tag', 'LabKitReadonlyText');
            applyTextFit(control);
        otherwise
            error('labkit:ui:app:UnsupportedFieldKind', ...
                'Unsupported UI 3.0 field kind "%s".', kind);
    end
    applyCommonValueProps(control, props);
end

function ui = buildPanner(ui, pannerSpec, parentGrid, row)
    props = pannerSpec.props;
    labelText = optionValue(props, 'label', pannerSpec.id);
    enabled = optionValue(props, 'enabled', true);

    label = uilabel(parentGrid, 'Text', labelText, ...
        'HorizontalAlignment', 'right');
    applyTextFit(label);
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
    applyTextFit(leftButton, 'charsPerStep', 12, 'maxShrinkSteps', 2);
    leftButton.Layout.Row = 1;
    leftButton.Layout.Column = 1;
    slider = uislider(grid, 'Enable', onOff(enabled));
    slider.Layout.Row = 1;
    slider.Layout.Column = 2;
    applyCommonValueProps(slider, props);
    slider.Value = clampNumericValue(slider.Value, slider.Limits);
    rightButton = uibutton(grid, 'Text', optionValue(props, 'rightLabel', '>'), ...
        'Enable', onOff(enabled));
    applyTextFit(rightButton, 'charsPerStep', 12, 'maxShrinkSteps', 2);
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
    applyTextFit(label);
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
    maxColumns = actionGroupMaxColumns(groupSpec);
    columnCount = min(count, maxColumns);
    rowCount = max(1, ceil(count / columnCount));
    grid = uigridlayout(parentGrid, [rowCount columnCount]);
    grid.Padding = [0 0 0 0];
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;
    grid.RowHeight = repmat({'fit'}, 1, rowCount);
    grid.ColumnWidth = repmat({'1x'}, 1, columnCount);
    grid.Layout.Row = row;
    grid.Layout.Column = [1 2];
    adapter = baseAdapter(groupSpec, 'actionGroup');
    adapter.grid = grid;
    adapter.actions = struct();
    ui.controls.(groupSpec.id) = adapter;
    for k = 1:numel(actions)
        actionRow = ceil(k / columnCount);
        actionColumn = mod(k - 1, columnCount) + 1;
        if columnCount > 1 && actionColumn == 1 && k == numel(actions) && ...
                mod(numel(actions), columnCount) == 1
            actionColumn = [1 columnCount];
        end
        [ui, actionAdapter] = buildAction(ui, actions{k}, grid, ...
            actionRow, actionColumn);
        ui.controls.(groupSpec.id).actions.(actions{k}.id) = actionAdapter;
    end
end

function maxColumns = actionGroupMaxColumns(groupSpec)
    maxColumns = 2;
    labels = actionLabels(groupSpec.children);
    if any(strlength(labels) > 28)
        maxColumns = 1;
    end
end

function labels = actionLabels(actions)
    labels = strings(1, numel(actions));
    for k = 1:numel(actions)
        labels(k) = string(optionValue(actions{k}.props, ...
            'label', actions{k}.id));
    end
end

function [ui, adapter] = buildAction(ui, actionSpec, parentGrid, row, column)
    props = actionSpec.props;
    button = uibutton(parentGrid, 'Text', optionValue(props, 'label', actionSpec.id), ...
        'Enable', onOff(optionValue(props, 'enabled', true)));
    applyTextFit(button, 'charsPerStep', 18, 'maxShrinkSteps', 3);
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

function ui = buildFilePanel(ui, fileSpec, parentGrid, row)
    callbacks = struct( ...
        'choose', semanticFileChooseCallback(fileSpec.id, ...
            optionValue(fileSpec.props, 'onChoose', [])), ...
        'remove', semanticFileRemoveCallback(fileSpec.id, ...
            optionValue(fileSpec.props, 'onRemove', [])), ...
        'clear', semanticFileClearCallback(fileSpec.id, ...
            optionValue(fileSpec.props, 'onClear', [])), ...
        'selection', semanticFileSelectionCallback(fileSpec.id, ...
            optionValue(fileSpec.props, 'onSelectionChange', [])), ...
        'trace', @(source, eventName, reason) traceFilePanelFromSource( ...
            fileSpec.id, source, eventName, reason), ...
        'setOriginalCallbackName', @setOriginalCallbackName);
    adapter = buildFilePanelControl(fileSpec, parentGrid, row, callbacks);
    ui.controls.(fileSpec.id) = adapter;
end

function ui = buildResultTable(ui, tableSpec, parentGrid, row)
    callbacks = struct( ...
        'cellEdit', semanticTableCellEditCallback(tableSpec.id, ...
            optionValue(tableSpec.props, 'onCellEdit', [])), ...
        'selection', semanticTableSelectionCallback(tableSpec.id, ...
            optionValue(tableSpec.props, 'onSelectionChange', [])), ...
        'setOriginalCallbackName', @setOriginalCallbackName);
    adapter = buildResultTableControl(tableSpec, parentGrid, row, callbacks);
    ui.controls.(tableSpec.id) = adapter;
end

function ui = buildLogPanel(ui, logSpec, parentGrid, row, debug)
    ui.controls.(logSpec.id) = buildPanelControl('logPanel', logSpec, ...
        parentGrid, row, debug);
end

function ui = buildUsagePanel(ui, usageSpec, parentGrid, row)
    ui.controls.(usageSpec.id) = buildPanelControl('usagePanel', usageSpec, ...
        parentGrid, row, struct());
end

function ui = buildStatusPanel(ui, statusSpec, parentGrid, row)
    ui.controls.(statusSpec.id) = buildPanelControl('statusPanel', statusSpec, ...
        parentGrid, row, struct());
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

function tf = isFigureBusy(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiBusy') && ...
            logical(getappdata(fig, 'labkitUiBusy'));
    catch
        tf = false;
    end
end

function callback = semanticFileChooseCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        traceFilePanelFromSource(id, source, 'choose requested', 'user');
        paths = control.normalizePathList(control.choosePaths(control));
        traceFilePanelFromSource(id, source, 'paths selected', ...
            sprintf('count=%d', numel(paths)));
        if isempty(paths)
            return;
        end
        [control, addedFiles] = control.appendSelection(control, paths);
        control = control.setFileSelection(control, addedFiles);
        ui.controls.(id) = control;
        setappdata(ui.figure, 'labkitUiRegistry', ui);
        labkit.ui.view.setFileSelection(ui, id, control.currentSelectedFiles());
        traceFilePanelFromSource(id, source, 'selection updated', sprintf( ...
            'total=%d added=%d selected=%d', numel(control.currentFiles()), ...
            numel(addedFiles), numel(control.currentSelectedFiles())));
        event = fileEvent(control, source, rawEvent, 'choose');
        event.addedFiles = addedFiles;
        traceFilePanelFromSource(id, source, 'callback start', 'action=choose');
        runSemanticAppCallback(ui, control, event, appCallback, id);
        traceFilePanelFromSource(id, source, 'callback end', 'action=choose');
    end
end

function callback = semanticFileRemoveCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        [control, removedFiles] = control.removeSelection(control);
        ui.controls.(id) = control;
        setappdata(ui.figure, 'labkitUiRegistry', ui);
        labkit.ui.view.setFileSelection(ui, id, control.currentSelectedFiles());
        traceFilePanelFromSource(id, source, 'selection updated', sprintf( ...
            'total=%d removed=%d selected=%d', numel(control.currentFiles()), ...
            numel(removedFiles), numel(control.currentSelectedFiles())));
        event = fileEvent(control, source, rawEvent, 'remove');
        event.removedFiles = removedFiles;
        traceFilePanelFromSource(id, source, 'callback start', 'action=remove');
        runSemanticAppCallback(ui, control, event, appCallback, id);
        traceFilePanelFromSource(id, source, 'callback end', 'action=remove');
    end
end

function callback = semanticFileClearCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        previousFiles = control.currentFiles();
        control = control.applySelection(control, {}, true);
        ui.controls.(id) = control;
        setappdata(ui.figure, 'labkitUiRegistry', ui);
        labkit.ui.view.setFileSelection(ui, id, control.currentSelectedFiles());
        traceFilePanelFromSource(id, source, 'selection updated', sprintf( ...
            'total=0 removed=%d selected=0', numel(previousFiles)));
        event = fileEvent(control, source, rawEvent, 'clear');
        event.removedFiles = previousFiles;
        traceFilePanelFromSource(id, source, 'callback start', 'action=clear');
        runSemanticAppCallback(ui, control, event, appCallback, id);
        traceFilePanelFromSource(id, source, 'callback end', 'action=clear');
    end
end

function callback = semanticFileSelectionCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        labkit.ui.view.setFileSelection(ui, id, control.currentSelectedFiles());
        traceFilePanelFromSource(id, source, 'selection changed', sprintf( ...
            'selected=%d', numel(control.currentSelectedFiles())));
        if isempty(appCallback)
            return;
        end
        event = fileEvent(control, source, rawEvent, 'select');
        traceFilePanelFromSource(id, source, 'callback start', 'action=select');
        runSemanticAppCallback(ui, control, event, appCallback, id);
        traceFilePanelFromSource(id, source, 'callback end', 'action=select');
    end
end

function event = fileEvent(control, source, rawEvent, action)
    event = semanticEvent(control, source, rawEvent, 'user');
    event.action = action;
    event.mode = 'filePanel';
    event.files = control.currentFiles();
    event.selectedFiles = control.currentSelectedFiles();
    event.value = event.selectedFiles;
end

function ui = currentUiRegistry(source)
    fig = ancestor(source, 'figure');
    if isempty(fig) || ~isappdata(fig, 'labkitUiRegistry')
        error('labkit:ui:app:MissingRegistry', ...
            'UI registry appdata was not found on the current figure.');
    end
    ui = getappdata(fig, 'labkitUiRegistry');
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
