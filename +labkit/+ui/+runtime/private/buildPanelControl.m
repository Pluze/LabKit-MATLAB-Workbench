% Private UI runtime helper. Expected caller: buildControl panel branches.
% Inputs are a panel kind, validated control spec, parent grid, target row,
% and debug context. Output is the semantic panel adapter.
% Side effects: creates MATLAB panel/text controls.
function adapter = buildPanelControl(kind, spec, parentGrid, row, debug)
    switch kind
        case 'logPanel'
            adapter = buildTextPanel(spec, parentGrid, row, {'Ready.'}, kind);
            if isDebugEnabled(debug)
                debug.attachTextLog(adapter.textArea);
            end
        case 'usagePanel'
            adapter = buildTextPanel(spec, parentGrid, row, {''}, kind);
        case 'statusPanel'
            adapter = buildTextPanel(spec, parentGrid, row, {''}, kind);
        otherwise
            error('labkit:ui:runtime:UnsupportedPanelKind', ...
                'Unsupported panel control kind "%s".', kind);
    end
end

function adapter = buildTextPanel(spec, parentGrid, row, defaultValue, kind)
    props = spec.props;
    panel = uipanel(parentGrid, 'Title', optionValue(props, 'title', spec.id));
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];
    isLogPanel = strcmp(kind, 'logPanel');
    gridRows = 1 + double(isLogPanel);
    grid = uigridlayout(panel, [gridRows 1]);
    grid.Padding = [8 8 8 8];
    if isLogPanel
        grid.RowHeight = {'fit', '1x'};
        followButton = uibutton(grid, 'Text', 'Pause auto-scroll');
        applyTextFit(followButton, 'charsPerStep', 18, 'maxShrinkSteps', 2);
        followButton.Layout.Row = 1;
        followButton.Layout.Column = 1;
        textRow = 2;
    else
        grid.RowHeight = {'1x'};
        followButton = [];
        textRow = 1;
    end
    textArea = uitextarea(grid, 'Editable', 'off', ...
        'Value', textLines(optionValue(props, 'value', defaultValue)));
    applyTextFit(textArea, 'charsPerStep', 48, 'maxShrinkSteps', 1);
    textArea.Layout.Row = textRow;
    textArea.Layout.Column = 1;

    adapter = baseAdapter(spec, kind);
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.textArea = textArea;
    adapter.valueHandle = textArea;
    if isLogPanel
        adapter.followLatestButton = followButton;
        adapter = configureLogFollowLatest(adapter);
    end
end

function adapter = configureLogFollowLatest(adapter)
    textArea = adapter.textArea;
    button = adapter.followLatestButton;
    setappdata(textArea, logFollowKey(), true);
    setappdata(textArea, logFollowMenuKey(), []);
    setappdata(textArea, logFollowButtonKey(), button);
    button.ButtonPushedFcn = @(src, ~) toggleLogFollowLatest(textArea, [], src);
    try
        fig = ancestor(textArea, 'figure');
        menu = uicontextmenu(fig);
        item = uimenu(menu, 'Text', 'Pause auto-scroll', ...
            'Checked', 'on', ...
            'MenuSelectedFcn', @(src, ~) toggleLogFollowLatest(textArea, src, []));
        textArea.ContextMenu = menu;
        setappdata(textArea, logFollowMenuKey(), item);
        adapter.followLatestMenu = item;
    catch
        adapter.followLatestMenu = [];
    end
    scrollLogToBottom(textArea);
end

function toggleLogFollowLatest(textArea, menuItem, button)
    enabled = ~logFollowLatest(textArea);
    setLogFollowLatest(textArea, enabled);
    updateLogFollowControls(textArea, menuItem, button);
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

function updateLogFollowControls(textArea, menuItem, button)
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
    if nargin < 3 || isempty(button)
        button = [];
        try
            if isappdata(textArea, logFollowButtonKey())
                button = getappdata(textArea, logFollowButtonKey());
            end
        catch
            button = [];
        end
    end
    if logFollowLatest(textArea)
        label = 'Pause auto-scroll';
        checked = 'on';
    else
        label = 'Follow latest';
        checked = 'off';
    end
    if ~isempty(menuItem) && isvalid(menuItem)
        menuItem.Text = label;
        menuItem.Checked = checked;
    end
    if ~isempty(button) && isvalid(button)
        button.Text = label;
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

function key = logFollowButtonKey()
    key = 'labkitLogFollowLatestButton';
end

function adapter = baseAdapter(spec, kind)
    adapter = struct();
    adapter.id = spec.id;
    adapter.kind = kind;
    adapter.layout = spec;
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
