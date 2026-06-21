% Private UI app helper. Expected caller: labkit.ui.app.create. Inputs are a
% validated app spec and optional debug context. Output is the initial UI
% registry shell before controls are populated.
function ui = buildShellFromSpec(spec, debug)
    tabs = spec.props.controlTabs;
    workspaceSpec = spec.props.workspace;
    workspaceChildren = workspaceSpec.children;

    shell = createTabbedWorkbenchShell( ...
        optionValue(spec.props, 'title', spec.id), ...
        [80 60 1500 900], ...
        420, ...
        struct('controlsPanel', 'Controls', ...
        'rightPanel', optionValue(workspaceSpec.props, 'title', 'Workspace')), ...
        tabShellSpecs(tabs), ...
        [max(1, numel(workspaceChildren)) 1], ...
        workspaceRowHeights(workspaceChildren), ...
        8, ...
        debug);

    ui = shell;
    ui.figure = shell.fig;
    ui.spec = spec;
    ui.debug = debug;
    ui.controls = struct();
    ui.sections = struct();
    ui.tabs = struct();
    ui.workspace = struct('id', workspaceSpec.id, ...
        'spec', workspaceSpec, 'grid', shell.rightGrid);
end

function specs = tabShellSpecs(tabs)
    specs = repmat(struct( ...
        'key', '', 'title', '', 'gridSize', [1 1], ...
        'rowHeight', {{'fit'}}, 'columnWidth', {{'1x'}}, ...
        'resize', 'betweenRows'), 1, numel(tabs));
    for k = 1:numel(tabs)
        tabSpec = tabs{k};
        rowCount = max(1, numel(tabSpec.children));
        specs(k).key = tabSpec.id;
        specs(k).title = optionValue(tabSpec.props, 'title', tabSpec.id);
        specs(k).gridSize = [rowCount 1];
        specs(k).rowHeight = tabRowHeights(tabSpec.children);
        specs(k).columnWidth = {'1x'};
        specs(k).resize = optionValue(tabSpec.props, 'resize', 'betweenRows');
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
        rowHeight{k} = specRowHeight(children{k}, 'fit');
    end
end

function tf = isGrowableTabChild(child)
    if strcmp(child.kind, 'section')
        tf = numel(child.children) == 1 && isGrowableTabChild(child.children{1});
        return;
    end
    tf = ismember(child.kind, ...
        {'previewArea', 'resultTable', 'logPanel', 'statusPanel', ...
        'usagePanel', 'pathPanel'});
end

function rowHeight = workspaceRowHeights(children)
    count = max(1, numel(children));
    rowHeight = repmat({'1x'}, 1, count);
    for k = 1:numel(children)
        rowHeight{k} = workspaceRowHeight(children{k});
    end
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
