% Private UI app helper. Expected caller: labkit.ui.app.create. Inputs are the
% current UI registry, one validated workspace spec, and debug context. Output
% is the updated registry after workspace children are built.
function ui = buildWorkspace(ui, workspaceSpec, debug)
    for iChild = 1:numel(workspaceSpec.children)
        childSpec = workspaceSpec.children{iChild};
        switch childSpec.kind
            case 'previewArea'
                ui = buildPreviewArea(ui, childSpec, ui.rightGrid, iChild);
            case {'resultTable', 'statusPanel', 'logPanel', 'custom'}
                ui = buildControl(ui, childSpec, ui.rightGrid, iChild, debug);
            otherwise
                error('labkit:ui:app:UnsupportedWorkspaceChild', ...
                    'Unsupported workspace child kind "%s".', childSpec.kind);
        end
    end
end

function ui = buildPreviewArea(ui, previewSpec, parentGrid, row)
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
        modeDropDown.ValueChangedFcn = semanticPreviewModeCallback( ...
            previewSpec.id, optionValue(props, 'onModeChange', []));
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
        xlabel(ax, axisLabel(props, 'xLabels', k));
        ylabel(ax, axisLabel(props, 'yLabels', k));
        enableAxesPopout(ax);
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
    if ~isempty(modeDropDown)
        adapter.valueHandle = modeDropDown;
    end
    ui.controls.(previewSpec.id) = adapter;
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

function labelText = axisLabel(props, fieldName, index)
    labels = optionValue(props, fieldName, {});
    if numel(labels) >= index
        labelText = char(string(labels{index}));
    else
        labelText = '';
    end
end

function adapter = baseAdapter(spec, kind)
    adapter = struct();
    adapter.id = spec.id;
    adapter.kind = kind;
    adapter.spec = spec;
    adapter.props = spec.props;
end

function callback = semanticPreviewModeCallback(id, appCallback)
    if isempty(appCallback)
        callback = [];
        return;
    end
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        control = ui.controls.(id);
        event = semanticEvent(control, source, rawEvent, 'user');
        event.action = 'mode';
        event.mode = source.Value;
        event.value = source.Value;
        appCallback(control, event);
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

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
