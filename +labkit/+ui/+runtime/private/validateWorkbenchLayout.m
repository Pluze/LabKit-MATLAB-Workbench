% Private UI runtime helper. Expected caller: labkit.ui.runtime.create. Input is one
% data-only workbench layout. Output is validation-by-success; errors are raised for
% duplicate ids, invalid tree shape, or unsupported child relationships before
% GUI construction begins.
function validateWorkbenchLayout(layout)
    assertLayoutKind(layout, 'app');
    if ~isfield(layout.props, 'controlTabs') || ...
            ~iscell(layout.props.controlTabs) || ~isrow(layout.props.controlTabs)
        error('labkit:ui:runtime:InvalidLayout', ...
            'workbench layout requires controlTabs as a cell row vector.');
    end
    if ~isfield(layout.props, 'workspace') || ...
            ~isstruct(layout.props.workspace) || ~isscalar(layout.props.workspace)
        error('labkit:ui:runtime:InvalidLayout', ...
            'workbench layout requires one workspace layout.');
    end

    assertLayoutKind(layout.props.workspace, 'workspace');
    ids = collectLayoutIds(layout, {});
    duplicate = firstDuplicate(ids);
    if strlength(duplicate) > 0
        error('labkit:ui:runtime:DuplicateId', ...
            'Duplicate declarative layout id "%s".', char(duplicate));
    end
    validateTreeShape(layout);
end

function ids = collectLayoutIds(node, ids)
    ids{end + 1} = node.id;
    if strcmp(node.kind, 'app') && isfield(node.props, 'controlTabs')
        for k = 1:numel(node.props.controlTabs)
            ids = collectLayoutIds(node.props.controlTabs{k}, ids);
        end
        ids = collectLayoutIds(node.props.workspace, ids);
    end
    for k = 1:numel(node.children)
        ids = collectLayoutIds(node.children{k}, ids);
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

function validateTreeShape(node)
    assertCommonLayoutNode(node);
    validateNoAppLayoutProps(node);
    switch node.kind
        case 'app'
            for k = 1:numel(node.props.controlTabs)
                assertLayoutKind(node.props.controlTabs{k}, 'tab');
                validateTreeShape(node.props.controlTabs{k});
            end
            validateTreeShape(node.props.workspace);
        case 'workspace'
            validateChildKinds(node, {'previewArea', 'resultTable', ...
                'statusPanel', 'usagePanel', 'logPanel'});
        case 'tab'
            validateChildKinds(node, {'section'});
        case 'section'
            validateNonEmptySection(node);
            validateChildKinds(node, {'field', 'rangeField', 'panner', 'action', ...
                'group', 'filePanel', 'resultTable', 'statusPanel', ...
                'usagePanel', 'logPanel', 'toolPanel'});
        case 'group'
            validateNonEmptyGroup(node);
            validateGroupLayout(node);
            validateChildKinds(node, {'field', 'rangeField', 'panner', ...
                'action', 'group'});
        otherwise
            validateChildKinds(node, {});
    end
end

function validateNonEmptySection(node)
    if isempty(node.children)
        error('labkit:ui:runtime:EmptySection', ...
            ['Layout "%s" declares an empty section. Add semantic controls, ' ...
            'or use labkit.ui.layout.toolPanel for reusable tool hosts.'], ...
            node.id);
    end
end

function validateNonEmptyGroup(node)
    if isempty(node.children)
        error('labkit:ui:runtime:EmptyGroup', ...
            'Layout "%s" declares an empty group. Add semantic child controls.', ...
            node.id);
    end
end

function validateGroupLayout(node)
    groupLayout = string(optionValue(node.props, 'layout', 'auto'));
    allowed = ["auto", "actions", "form", "inline", "grid"];
    if ~isscalar(groupLayout) || ~any(groupLayout == allowed)
        error('labkit:ui:runtime:InvalidGroupLayout', ...
            'Layout "%s" uses unsupported group layout "%s".', ...
            node.id, char(groupLayout));
    end
    if groupLayout == "actions" && ~allGroupChildrenAre(node, 'action')
        error('labkit:ui:runtime:InvalidGroupLayout', ...
            'Layout "%s" uses action layout but contains non-action children.', ...
            node.id);
    end
end

function tf = allGroupChildrenAre(node, kind)
    tf = true;
    for k = 1:numel(node.children)
        tf = tf && strcmp(node.children{k}.kind, kind);
    end
end

function validateNoAppLayoutProps(node)
    layoutProps = {'height', 'minRows', 'minHeight', 'maxColumns', ...
        'rowSpacing', 'columnSpacing', 'padding', 'chrome', ...
        'columnWidth', 'rowHeight', 'position', 'leftWidth'};
    for k = 1:numel(layoutProps)
        if isfield(node.props, layoutProps{k})
            error('labkit:ui:runtime:RetiredLayoutProperty', ...
                ['Layout "%s" uses app-owned layout property "%s". ' ...
                'Apps may declare pages, sections, controls, order, and ' ...
                'semantic options; LabKit owns concrete layout.'], ...
                node.id, layoutProps{k});
        end
    end
end

function validateChildKinds(node, allowedKinds)
    for k = 1:numel(node.children)
        child = node.children{k};
        if ~any(strcmp(child.kind, allowedKinds))
            error('labkit:ui:runtime:InvalidChildKind', ...
                'Layout "%s" cannot contain child kind "%s".', node.id, child.kind);
        end
        validateTreeShape(child);
    end
end

function assertLayoutKind(node, kind)
    assertCommonLayoutNode(node);
    if ~strcmp(node.kind, kind)
        error('labkit:ui:runtime:InvalidLayoutKind', ...
            'Expected %s layout node, got "%s".', kind, node.kind);
    end
end

function assertCommonLayoutNode(node)
    if ~isstruct(node) || ~isscalar(node) || ...
            ~all(isfield(node, {'kind', 'id', 'props', 'children', 'slots'})) || ...
            ~iscell(node.children) || ...
            ~(isempty(node.children) || isrow(node.children))
        error('labkit:ui:runtime:InvalidLayout', ...
            'Declarative layout nodes must be scalar structs with cell row children.');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
