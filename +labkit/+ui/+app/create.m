function ui = create(spec, varargin)
%CREATE Build a LabKit UI 2.0 workbench from declarative specs.
%
% App-facing contract:
%   ui = labkit.ui.app.create(spec, "debug", debugContext)
%
% Inputs:
%   spec - scalar app spec from labkit.ui.spec.app. The app spec owns
%       controlTabs and workspace specs; all controls use globally unique ids.
%   debug - optional labkit.ui.diag debug context. When supplied, the created
%       figure is instrumented and the first logPanel mirrors trace lines.
%
% Output:
%   ui - registry struct with figure/fig, shell handles, controls, sections,
%       tabs, workspace, original spec, and optional debug context. Stable app
%       code should use semantic ids and named labkit.ui.view helpers rather
%       than adapter internals.

    opts = parseOptions(varargin);
    validateAppSpec(spec);

    appProps = spec.props;
    tabs = appProps.controlTabs;
    workspaceSpec = appProps.workspace;
    workspaceChildren = workspaceSpec.children;
    debug = optionValue(opts, 'debug', []);

    shell = createTabbedWorkbenchShell( ...
        optionValue(appProps, 'title', spec.id), ...
        optionValue(appProps, 'position', [90 70 1200 800]), ...
        optionValue(appProps, 'leftWidth', 420), ...
        struct('controlsPanel', 'Controls', ...
        'rightPanel', optionValue(workspaceSpec.props, 'title', 'Workspace')), ...
        tabShellSpecs(tabs), ...
        [max(1, numel(workspaceChildren)) 1], ...
        workspaceRowHeights(workspaceChildren), ...
        optionValue(workspaceSpec.props, 'rowSpacing', 8));

    ui = shell;
    ui.figure = shell.fig;
    ui.spec = spec;
    ui.debug = debug;
    ui.controls = struct();
    ui.sections = struct();
    ui.tabs = struct();
    ui.workspace = struct('id', workspaceSpec.id, ...
        'spec', workspaceSpec, 'grid', shell.rightGrid);

    buildControlTabs(tabs);
    buildWorkspace(workspaceSpec);
    attachDebug();

function buildControlTabs(tabs)
    for iTab = 1:numel(tabs)
        tabSpec = tabs{iTab};
        grid = ui.([tabSpec.id 'Grid']);
        ui.tabs.(tabSpec.id) = struct('id', tabSpec.id, ...
            'spec', tabSpec, 'grid', grid, ...
            'tab', ui.([tabSpec.id 'Tab']));
        for iSection = 1:numel(tabSpec.children)
            buildSection(tabSpec.children{iSection}, grid, iSection);
        end
    end
end

function buildSection(sectionSpec, parentGrid, row)
    childCount = max(1, numel(sectionSpec.children));
    sectionOptions = struct( ...
        'rowHeight', {sectionRowHeights(sectionSpec.children)}, ...
        'columnWidth', {{145, '1x'}});
    panelUi = labkit.ui.view.section(parentGrid, ...
        optionValue(sectionSpec.props, 'title', sectionSpec.id), ...
        row, [childCount 2], sectionOptions);
    adapter = baseAdapter(sectionSpec, 'section');
    adapter.panel = panelUi.panel;
    adapter.grid = panelUi.grid;
    ui.sections.(sectionSpec.id) = adapter;
    ui.controls.(sectionSpec.id) = adapter;

    for iChild = 1:numel(sectionSpec.children)
        buildControl(sectionSpec.children{iChild}, panelUi.grid, iChild);
    end
end

function buildWorkspace(workspaceSpec)
    for iChild = 1:numel(workspaceSpec.children)
        buildWorkspaceChild(workspaceSpec.children{iChild}, ui.rightGrid, iChild);
    end
end

function buildWorkspaceChild(childSpec, parentGrid, row)
    switch childSpec.kind
        case 'previewArea'
            buildPreviewArea(childSpec, parentGrid, row);
        case {'resultTable', 'statusPanel', 'logPanel', 'custom'}
            buildControl(childSpec, parentGrid, row);
        otherwise
            error('labkit:ui:app:UnsupportedWorkspaceChild', ...
                'Unsupported workspace child kind "%s".', childSpec.kind);
    end
end

function buildControl(controlSpec, parentGrid, row)
    switch controlSpec.kind
        case 'field'
            buildField(controlSpec, parentGrid, row);
        case 'rangeField'
            buildRangeField(controlSpec, parentGrid, row);
        case 'action'
            buildAction(controlSpec, parentGrid, row, [1 2]);
        case 'actionGroup'
            buildActionGroup(controlSpec, parentGrid, row);
        case 'pathPanel'
            buildPathPanel(controlSpec, parentGrid, row);
        case 'resultTable'
            buildResultTable(controlSpec, parentGrid, row);
        case 'logPanel'
            buildLogPanel(controlSpec, parentGrid, row);
        case 'statusPanel'
            buildStatusPanel(controlSpec, parentGrid, row);
        case 'custom'
            buildCustom(controlSpec, parentGrid, row);
        otherwise
            error('labkit:ui:app:UnsupportedControl', ...
                'Unsupported UI 2.0 control kind "%s".', controlSpec.kind);
    end
end

function buildField(fieldSpec, parentGrid, row)
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

function buildRangeField(rangeSpec, parentGrid, row)
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

function buildActionGroup(groupSpec, parentGrid, row)
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
        actionAdapter = buildAction(actions{k}, grid, 1, k);
        ui.controls.(groupSpec.id).actions.(actions{k}.id) = actionAdapter;
    end
end

function adapter = buildAction(actionSpec, parentGrid, row, column)
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

function buildPathPanel(pathSpec, parentGrid, row)
    props = pathSpec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'label', pathSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [3 2]);
    grid.RowHeight = {'fit', '1x', 'fit'};
    grid.ColumnWidth = {'1x', '1x'};
    grid.Padding = [8 8 8 8];

    chooseButton = uibutton(grid, 'Text', chooseButtonText(props), ...
        'ButtonPushedFcn', semanticPathCallback(pathSpec.id, ...
        optionValue(props, 'onChoose', []), 'choose'));
    chooseButton.Layout.Row = 1;
    chooseButton.Layout.Column = 1;
    clearButton = uibutton(grid, 'Text', 'Clear', ...
        'ButtonPushedFcn', semanticPathCallback(pathSpec.id, ...
        optionValue(props, 'onClear', []), 'clear'));
    clearButton.Layout.Row = 1;
    clearButton.Layout.Column = 2;
    listbox = uilistbox(grid, 'Items', {optionValue(props, 'emptyText', 'No selection')}, ...
        'Multiselect', pathMultiselect(props));
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
    ui.controls.(pathSpec.id) = adapter;
end

function buildResultTable(tableSpec, parentGrid, row)
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

function buildLogPanel(logSpec, parentGrid, row)
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

function buildStatusPanel(statusSpec, parentGrid, row)
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

function buildPreviewArea(previewSpec, parentGrid, row)
    props = previewSpec.props;
    axisIds = previewAxisIds(props);
    count = numel(axisIds);
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'title', previewSpec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = 1;
    hasModes = isfield(props, 'viewModes') && ~isempty(props.viewModes);
    gridRows = 1 + double(hasModes);
    grid = uigridlayout(panel, [gridRows 1]);
    grid.Padding = [8 8 8 8];
    if hasModes
        grid.RowHeight = {'fit', '1x'};
        modeDropDown = uidropdown(grid, 'Items', cellstr(string(props.viewModes)));
        modeDropDown.Layout.Row = 1;
        modeDropDown.Layout.Column = 1;
        axesHostRow = 2;
    else
        grid.RowHeight = {'1x'};
        modeDropDown = [];
        axesHostRow = 1;
    end

    axesGrid = previewAxesGrid(grid, props.layout, count);
    axesGrid.Layout.Row = axesHostRow;
    axesGrid.Layout.Column = 1;
    axesHandles = gobjects(1, count);
    axesById = struct();
    for k = 1:count
        ax = uiaxes(axesGrid);
        ax.Layout.Row = axesRow(props.layout, k);
        ax.Layout.Column = axesColumn(props.layout, k);
        title(ax, axisTitle(previewSpec, axisIds, k));
        labkit.ui.view.draw(ax, 'popout');
        axesHandles(k) = ax;
        axesById.(axisIds{k}) = ax;
    end

    adapter = baseAdapter(previewSpec, 'previewArea');
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.axesGrid = axesGrid;
    adapter.axes = axesHandles;
    adapter.axesById = axesById;
    adapter.primaryAxes = axesHandles(1);
    adapter.viewModeDropDown = modeDropDown;
    ui.controls.(previewSpec.id) = adapter;
end

function buildCustom(customSpec, parentGrid, row)
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

function attachDebug()
    if isDebugEnabled(debug) && isfield(debug, 'instrumentFigure')
        debug.instrumentFigure(ui.figure);
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

function callback = semanticValueCallback(id, appCallback)
    if isempty(appCallback)
        callback = [];
        return;
    end
    callback = @wrapped;

    function wrapped(source, rawEvent)
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
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = id;
        if ~isempty(appCallback)
            appCallback(control, event);
        end
    end
end

function callback = semanticPathCallback(id, appCallback, action)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = action;
        event.mode = optionValue(control.props, 'mode', '');
        event.paths = currentPathValues(control);
        if ~isempty(appCallback)
            appCallback(control, event);
        end
    end
end

function event = semanticEvent(control, source, rawEvent, sourceKind)
    event = struct();
    event.id = control.id;
    event.kind = control.kind;
    event.source = sourceKind;
    event.value = currentValue(source);
    event.previousValue = previousValue(rawEvent);
    event.ui = ui;
    event.rawEvent = rawEvent;
end

function value = currentValue(source)
    if ~isempty(source) && isprop(source, 'Value')
        value = source.Value;
    else
        value = [];
    end
end

function value = previousValue(rawEvent)
    value = [];
    if ~isempty(rawEvent) && isprop(rawEvent, 'PreviousValue')
        value = rawEvent.PreviousValue;
    end
end

function values = currentPathValues(control)
    values = {};
    if isfield(control, 'listbox') && isvalid(control.listbox)
        values = control.listbox.Value;
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

function specs = tabShellSpecs(tabs)
    specs = repmat(struct( ...
        'key', '', 'title', '', 'gridSize', [1 1], ...
        'rowHeight', {{'fit'}}, 'columnWidth', {{'1x'}}, ...
        'resize', 'none'), 1, numel(tabs));
    for k = 1:numel(tabs)
        tabSpec = tabs{k};
        rowCount = max(1, numel(tabSpec.children));
        specs(k).key = tabSpec.id;
        specs(k).title = optionValue(tabSpec.props, 'title', tabSpec.id);
        specs(k).gridSize = [rowCount 1];
        specs(k).rowHeight = tabRowHeights(tabSpec.children);
        specs(k).columnWidth = {'1x'};
        specs(k).resize = optionValue(tabSpec.props, 'resize', 'none');
    end
end

function rowHeight = tabRowHeights(children)
    count = max(1, numel(children));
    rowHeight = repmat({'fit'}, 1, count);
    for k = 1:numel(children)
        rowHeight{k} = heightValue(children{k}.props, 'fit');
    end
end

function rowHeight = sectionRowHeights(children)
    count = max(1, numel(children));
    rowHeight = repmat({'fit'}, 1, count);
    for k = 1:numel(children)
        rowHeight{k} = childRowHeight(children{k});
    end
end

function rowHeight = workspaceRowHeights(children)
    count = max(1, numel(children));
    rowHeight = repmat({'1x'}, 1, count);
    for k = 1:numel(children)
        rowHeight{k} = childRowHeight(children{k});
    end
end

function value = childRowHeight(spec)
    switch spec.kind
        case {'previewArea', 'resultTable', 'logPanel', 'statusPanel', 'pathPanel'}
            defaultValue = '1x';
        otherwise
            defaultValue = 'fit';
    end
    value = heightValue(spec.props, defaultValue);
end

function value = heightValue(props, defaultValue)
    value = optionValue(props, 'height', defaultValue);
    if ischar(value) || isstring(value)
        text = char(string(value));
        switch lower(text)
            case {'fit', 'fixed'}
                value = 'fit';
            case {'flex', 'fill', 'grow'}
                value = '1x';
            otherwise
                value = text;
        end
    end
end

function grid = previewAxesGrid(parent, layout, count)
    switch layout
        case 'single'
            grid = uigridlayout(parent, [1 1]);
            grid.RowHeight = {'1x'};
            grid.ColumnWidth = {'1x'};
        case 'pair'
            grid = uigridlayout(parent, [1 count]);
            grid.RowHeight = {'1x'};
            grid.ColumnWidth = repmat({'1x'}, 1, count);
        case 'stack'
            grid = uigridlayout(parent, [count 1]);
            grid.RowHeight = repmat({'1x'}, 1, count);
            grid.ColumnWidth = {'1x'};
        otherwise
            error('labkit:ui:app:InvalidPreviewLayout', ...
                'Unsupported previewArea layout "%s".', layout);
    end
    grid.Padding = [0 0 0 0];
end

function row = axesRow(layout, index)
    if strcmp(layout, 'stack')
        row = index;
    else
        row = 1;
    end
end

function column = axesColumn(layout, index)
    if strcmp(layout, 'pair')
        column = index;
    else
        column = 1;
    end
end

function ids = previewAxisIds(props)
    if isfield(props, 'axisIds') && ~isempty(props.axisIds)
        ids = cellstr(string(props.axisIds));
        validateAxisIds(ids);
        return;
    end

    switch props.layout
        case 'single'
            defaultCount = 1;
        case 'pair'
            defaultCount = 2;
        otherwise
            defaultCount = optionValue(props, 'count', 2);
    end
    count = optionValue(props, 'count', defaultCount);
    ids = cell(1, count);
    for k = 1:count
        ids{k} = sprintf('axis%d', k);
    end
end

function validateAxisIds(ids)
    for k = 1:numel(ids)
        if ~isvarname(ids{k})
            error('labkit:ui:app:InvalidAxisId', ...
                'previewArea axis id "%s" must be a valid MATLAB field name.', ids{k});
        end
    end
end

function titleText = axisTitle(previewSpec, axisIds, index)
    titles = optionValue(previewSpec.props, 'axisTitles', {});
    if numel(titles) >= index
        titleText = char(string(titles{index}));
    elseif numel(axisIds) == 1
        titleText = optionValue(previewSpec.props, 'title', previewSpec.id);
    else
        titleText = axisIds{index};
    end
end

function text = chooseButtonText(props)
    mode = optionValue(props, 'mode', 'singleFile');
    switch mode
        case {'folder', 'multiFolder', 'outputFolder'}
            text = 'Choose folder';
        otherwise
            text = 'Choose files';
    end
end

function value = pathMultiselect(props)
    mode = optionValue(props, 'mode', 'singleFile');
    if any(strcmp(mode, {'multiFile', 'multiFolder'}))
        value = 'on';
    else
        value = 'off';
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

function validateAppSpec(spec)
    assertSpecKind(spec, 'app');
    if ~isfield(spec.props, 'controlTabs') || ...
            ~iscell(spec.props.controlTabs) || ~isrow(spec.props.controlTabs)
        error('labkit:ui:app:InvalidSpec', ...
            'app spec requires controlTabs as a cell row vector.');
    end
    if ~isfield(spec.props, 'workspace') || ...
            ~isstruct(spec.props.workspace) || ~isscalar(spec.props.workspace)
        error('labkit:ui:app:InvalidSpec', ...
            'app spec requires one workspace spec.');
    end

    assertSpecKind(spec.props.workspace, 'workspace');
    ids = {};
    ids = collectSpecIds(spec, ids);
    duplicate = firstDuplicate(ids);
    if strlength(duplicate) > 0
        error('labkit:ui:app:DuplicateId', ...
            'Duplicate UI 2.0 spec id "%s".', char(duplicate));
    end
    validateTreeShape(spec);
end

function ids = collectSpecIds(spec, ids)
    ids{end+1} = spec.id;
    if strcmp(spec.kind, 'app') && isfield(spec.props, 'controlTabs')
        for k = 1:numel(spec.props.controlTabs)
            ids = collectSpecIds(spec.props.controlTabs{k}, ids);
        end
        ids = collectSpecIds(spec.props.workspace, ids);
    end
    for k = 1:numel(spec.children)
        ids = collectSpecIds(spec.children{k}, ids);
    end
end

function duplicate = firstDuplicate(ids)
    duplicate = "";
    seen = containers.Map();
    for k = 1:numel(ids)
        id = ids{k};
        if isKey(seen, id)
            duplicate = string(id);
            return;
        end
        seen(id) = true;
    end
end

function validateTreeShape(spec)
    assertCommonSpec(spec);
    switch spec.kind
        case 'app'
            for k = 1:numel(spec.props.controlTabs)
                assertSpecKind(spec.props.controlTabs{k}, 'tab');
                validateTreeShape(spec.props.controlTabs{k});
            end
            validateTreeShape(spec.props.workspace);
        case 'workspace'
            validateChildKinds(spec, {'previewArea', 'resultTable', ...
                'statusPanel', 'logPanel', 'custom'});
        case 'tab'
            validateChildKinds(spec, {'section'});
        case 'section'
            validateChildKinds(spec, {'field', 'rangeField', 'action', ...
                'actionGroup', 'pathPanel', 'resultTable', 'statusPanel', ...
                'logPanel', 'custom'});
        case 'actionGroup'
            validateChildKinds(spec, {'action'});
        otherwise
            validateChildKinds(spec, {});
    end
end

function validateChildKinds(spec, allowedKinds)
    for k = 1:numel(spec.children)
        child = spec.children{k};
        if ~any(strcmp(child.kind, allowedKinds))
            error('labkit:ui:app:InvalidChildKind', ...
                'Spec "%s" cannot contain child kind "%s".', spec.id, child.kind);
        end
        validateTreeShape(child);
    end
end

function assertSpecKind(spec, kind)
    assertCommonSpec(spec);
    if ~strcmp(spec.kind, kind)
        error('labkit:ui:app:InvalidSpecKind', ...
            'Expected %s spec, got "%s".', kind, spec.kind);
    end
end

function assertCommonSpec(spec)
    if ~isstruct(spec) || ~isscalar(spec) || ...
            ~all(isfield(spec, {'kind', 'id', 'props', 'children', 'slots'})) || ...
            ~iscell(spec.children) || ...
            ~(isempty(spec.children) || isrow(spec.children))
        error('labkit:ui:app:InvalidSpec', ...
            'UI 2.0 specs must be scalar structs with cell row children.');
    end
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:app:InvalidOptions', ...
            'labkit.ui.app.create options must be name/value pairs.');
    end
    opts = struct();
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
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
end
