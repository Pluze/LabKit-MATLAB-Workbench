% Private UI app helper. Expected caller: buildControlTabs. Inputs are the
% current UI registry, one validated section spec, a parent grid, target row,
% and debug context. Output is the updated registry after the section and its
% children are built.
function ui = buildSection(ui, sectionSpec, parentGrid, row, debug)
    childCount = max(1, numel(sectionSpec.children));
    panelArgs = {};
    if sectionDrawsOwnTitle(sectionSpec) && hasPanelChrome(sectionSpec)
        panelArgs = {'Title', optionValue(sectionSpec.props, 'title', sectionSpec.id)};
    else
        panelArgs = {'BorderType', 'none'};
    end
    panel = uipanel(parentGrid, panelArgs{:});
    panel.Layout.Row = row;
    panel.Layout.Column = 1;

    grid = uigridlayout(panel, [childCount 2]);
    grid.RowHeight = sectionRowHeights(sectionSpec.children);
    grid.ColumnWidth = {145, '1x'};
    grid.RowSpacing = optionValue(sectionSpec.props, 'rowSpacing', 8);
    grid.ColumnSpacing = optionValue(sectionSpec.props, 'columnSpacing', 8);
    grid.Padding = optionValue(sectionSpec.props, 'padding', [8 8 8 8]);

    adapter = baseAdapter(sectionSpec, 'section');
    adapter.panel = panel;
    adapter.grid = grid;
    ui.sections.(sectionSpec.id) = adapter;
    ui.controls.(sectionSpec.id) = adapter;

    for iChild = 1:numel(sectionSpec.children)
        ui = buildControl(ui, sectionSpec.children{iChild}, grid, iChild, debug);
    end
end

function tf = sectionDrawsOwnTitle(sectionSpec)
    tf = true;
    if numel(sectionSpec.children) ~= 1
        return;
    end
    child = sectionSpec.children{1};
    tf = ~ismember(child.kind, ...
        {'previewArea', 'resultTable', 'logPanel', 'statusPanel', 'pathPanel'});
end

function tf = hasPanelChrome(sectionSpec)
    chrome = optionValue(sectionSpec.props, 'chrome', 'panel');
    tf = ~strcmpi(char(string(chrome)), 'none');
end

function rowHeight = sectionRowHeights(children)
    count = max(1, numel(children));
    rowHeight = repmat({'fit'}, 1, count);
    if numel(children) == 1 && isGrowableSectionChild(children{1})
        rowHeight{1} = '1x';
        return;
    end
    for k = 1:numel(children)
        rowHeight{k} = specRowHeight(children{k}, 'fit');
    end
end

function tf = isGrowableSectionChild(child)
    tf = ismember(child.kind, ...
        {'previewArea', 'resultTable', 'logPanel', 'statusPanel', 'pathPanel'});
end

function adapter = baseAdapter(spec, kind)
    adapter = struct();
    adapter.id = spec.id;
    adapter.kind = kind;
    adapter.spec = spec;
    adapter.props = spec.props;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
