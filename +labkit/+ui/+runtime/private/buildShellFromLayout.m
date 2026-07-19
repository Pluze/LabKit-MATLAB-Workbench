% Private UI runtime helper. Expected caller: labkit.ui.runtime.create. Inputs are a
% validated workbench layout and optional debug context. Output is the initial UI
% registry shell before controls are populated.
function ui = buildShellFromLayout(layout, debug)
    tabs = layout.props.controlTabs;
    workspaceLayout = layout.props.workspace;
    workspaceChildren = workspaceLayout.children;

    shell = createTabbedWorkbenchShell( ...
        optionValue(layout.props, 'title', layout.id), ...
        [80 60 1500 900], ...
        420, ...
        struct('controlsPanel', 'Controls', ...
        'rightPanel', optionValue(workspaceLayout.props, 'title', 'Workspace')), ...
        tabShellLayouts(tabs), ...
        workspaceGridSize(workspaceChildren), ...
        workspaceRowHeights(workspaceChildren), ...
        8, ...
        debug, ...
        optionValue(layout.props, 'utilities', struct()));

    ui = shell;
    ui.figure = shell.fig;
    ui.layout = layout;
    ui.debug = debug;
    ui.controls = struct();
    ui.sections = struct();
    ui.tabs = struct();
    ui.workspace = struct('id', workspaceLayout.id, ...
        'layout', workspaceLayout, 'grid', shell.rightGrid);
end

function layouts = tabShellLayouts(tabs)
    layouts = repmat(struct( ...
        'key', '', 'title', '', 'gridSize', [1 1], ...
        'rowHeight', {{'fit'}}, 'columnWidth', {{'1x'}}, ...
        'resize', 'betweenRows'), 1, numel(tabs));
    for k = 1:numel(tabs)
        tabLayout = tabs{k};
        rowCount = max(1, numel(tabLayout.children));
        layouts(k).key = tabLayout.id;
        layouts(k).title = optionValue(tabLayout.props, 'title', tabLayout.id);
        layouts(k).gridSize = [rowCount 1];
        layouts(k).rowHeight = tabRowHeights(tabLayout.children);
        layouts(k).columnWidth = {'1x'};
        layouts(k).resize = optionValue(tabLayout.props, 'resize', 'betweenRows');
    end
end

function rowHeight = tabRowHeights(children)
    count = max(1, numel(children));
    rowHeight = repmat({'fit'}, 1, count);
    if numel(children) == 1 && isGrowableTabChild(children{1})
        rowHeight{1} = '1x';
        return;
    end
    for k = 1:numel(children)
        rowHeight{k} = layoutRowHeight(children{k}, 'fit');
    end
end

function tf = isGrowableTabChild(child)
    if strcmp(child.kind, 'section')
        tf = numel(child.children) == 1 && isGrowableTabChild(child.children{1});
        return;
    end
    if strcmp(child.kind, 'filePanel')
        tf = strcmp(char(string(optionValue(child.props, 'mode', 'multi'))), 'multi');
        return;
    end
    tf = ismember(child.kind, ...
        {'previewArea', 'resultTable', 'logPanel', 'statusPanel', ...
        'usagePanel'});
end

function rowHeight = workspaceRowHeights(children)
    if workspaceUsesTabs(children)
        rowHeight = {'1x'};
        return;
    end
    count = max(1, numel(children));
    rowHeight = repmat({'1x'}, 1, count);
    for k = 1:numel(children)
        rowHeight{k} = workspaceRowHeight(children{k});
    end
end

function value = workspaceGridSize(children)
    if workspaceUsesTabs(children)
        value = [1 1];
    else
        value = [max(1, numel(children)) 1];
    end
end

function tf = workspaceUsesTabs(children)
    tf = numel(children) >= 2 && ...
        all(cellfun(@(child) strcmp(child.kind, 'tab'), children));
end

function value = workspaceRowHeight(~)
    value = '1x';
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
