% Private UI app helper. Expected caller: buildControl panel branches.
% Inputs are a panel kind, validated control spec, parent grid, target row,
% debug context, and UI registry. Output is the semantic panel adapter.
% Side effects: creates MATLAB panel/text/custom controls.
function adapter = buildPanelControl(kind, spec, parentGrid, row, debug, ui)
    switch kind
        case 'logPanel'
            adapter = buildTextPanel(spec, parentGrid, row, {'Ready.'}, kind);
            if isDebugEnabled(debug)
                debug.attachTextLog(adapter.textArea);
            end
        case 'statusPanel'
            adapter = buildTextPanel(spec, parentGrid, row, {''}, kind);
        case 'custom'
            adapter = buildCustomPanel(spec, parentGrid, row, debug, ui);
        otherwise
            error('labkit:ui:app:UnsupportedPanelKind', ...
                'Unsupported panel control kind "%s".', kind);
    end
end

function adapter = buildTextPanel(spec, parentGrid, row, defaultValue, kind)
    props = spec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'title', spec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    grid = uigridlayout(panel, [1 1]);
    grid.Padding = [8 8 8 8];
    textArea = uitextarea(grid, 'Editable', 'off', ...
        'Value', textLines(optionValue(props, 'value', defaultValue)));
    textArea.Layout.Row = 1;
    textArea.Layout.Column = 1;

    adapter = baseAdapter(spec, kind);
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.textArea = textArea;
    adapter.valueHandle = textArea;
    if strcmp(kind, 'logPanel')
        adapter = configureLogFollowLatest(adapter);
    end
end

function adapter = configureLogFollowLatest(adapter)
    textArea = adapter.textArea;
    setappdata(textArea, logFollowKey(), true);
    setappdata(textArea, logFollowMenuKey(), []);
    try
        fig = ancestor(textArea, 'figure');
        menu = uicontextmenu(fig);
        item = uimenu(menu, 'Text', 'Pause auto-scroll', ...
            'Checked', 'on', ...
            'MenuSelectedFcn', @(src, ~) toggleLogFollowLatest(textArea, src));
        textArea.ContextMenu = menu;
        setappdata(textArea, logFollowMenuKey(), item);
        adapter.followLatestMenu = item;
    catch
        adapter.followLatestMenu = [];
    end
    scrollLogToBottom(textArea);
end

function toggleLogFollowLatest(textArea, menuItem)
    enabled = ~logFollowLatest(textArea);
    setLogFollowLatest(textArea, enabled);
    updateLogFollowMenu(textArea, menuItem);
    if enabled
        scrollLogToBottom(textArea);
    end
end

function setLogFollowLatest(textArea, enabled)
    setappdata(textArea, logFollowKey(), logical(enabled));
end

function enabled = logFollowLatest(textArea)
    enabled = true;
    try
        if isappdata(textArea, logFollowKey())
            enabled = logical(getappdata(textArea, logFollowKey()));
        end
    catch
        enabled = true;
    end
end

function updateLogFollowMenu(textArea, menuItem)
    if nargin < 2 || isempty(menuItem)
        menuItem = [];
        try
            if isappdata(textArea, logFollowMenuKey())
                menuItem = getappdata(textArea, logFollowMenuKey());
            end
        catch
            menuItem = [];
        end
    end
    if isempty(menuItem) || ~isvalid(menuItem)
        return;
    end
    if logFollowLatest(textArea)
        menuItem.Text = 'Pause auto-scroll';
        menuItem.Checked = 'on';
    else
        menuItem.Text = 'Follow latest';
        menuItem.Checked = 'off';
    end
end

function scrollLogToBottom(textArea)
    try
        scroll(textArea, 'bottom');
    catch
    end
end

function key = logFollowKey()
    key = 'labkitLogFollowLatest';
end

function key = logFollowMenuKey()
    key = 'labkitLogFollowLatestMenu';
end

function adapter = buildCustomPanel(spec, parentGrid, row, debug, ui)
    props = spec.props;
    panel = uipanel(parentGrid, 'Title', spec.id);
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    context = struct('ui', ui, 'debug', debug, 'spec', spec);
    handle = props.builder(panel, spec.id, context, props);

    adapter = baseAdapter(spec, 'custom');
    adapter.panel = panel;
    adapter.handle = handle;
end

function adapter = baseAdapter(spec, kind)
    adapter = struct();
    adapter.id = spec.id;
    adapter.kind = kind;
    adapter.spec = spec;
    adapter.props = spec.props;
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
