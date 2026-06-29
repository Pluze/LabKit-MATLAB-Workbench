% Private UI app helper. Expected caller: labkit.ui.app.create. Input is one
% data-only app spec. Output is validation-by-success; errors are raised for
% duplicate ids, invalid tree shape, or unsupported child relationships before
% GUI construction begins.
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
    ids = collectSpecIds(spec, {});
    duplicate = firstDuplicate(ids);
    if strlength(duplicate) > 0
        error('labkit:ui:app:DuplicateId', ...
            'Duplicate UI 3.0 spec id "%s".', char(duplicate));
    end
    validateTreeShape(spec);
end

function ids = collectSpecIds(spec, ids)
    ids{end + 1} = spec.id;
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
    validateNoAppLayoutProps(spec);
    switch spec.kind
        case 'app'
            for k = 1:numel(spec.props.controlTabs)
                assertSpecKind(spec.props.controlTabs{k}, 'tab');
                validateTreeShape(spec.props.controlTabs{k});
            end
            validateTreeShape(spec.props.workspace);
        case 'workspace'
            validateChildKinds(spec, {'previewArea', 'resultTable', ...
                'statusPanel', 'usagePanel', 'logPanel'});
        case 'tab'
            validateChildKinds(spec, {'section'});
        case 'section'
            validateNonEmptySection(spec);
            validateChildKinds(spec, {'field', 'rangeField', 'panner', 'action', ...
                'actionGroup', 'filePanel', 'resultTable', 'statusPanel', ...
                'usagePanel', 'logPanel', 'toolPanel'});
        case 'actionGroup'
            validateChildKinds(spec, {'action'});
        otherwise
            validateChildKinds(spec, {});
    end
end

function validateNonEmptySection(spec)
    if isempty(spec.children)
        error('labkit:ui:app:EmptySection', ...
            ['Spec "%s" declares an empty section. Add semantic controls, ' ...
            'or use labkit.ui.spec.toolPanel for reusable tool hosts.'], ...
            spec.id);
    end
end

function validateNoAppLayoutProps(spec)
    layoutProps = {'height', 'minRows', 'minHeight', 'maxColumns', ...
        'rowSpacing', 'columnSpacing', 'padding', 'chrome', ...
        'columnWidth', 'rowHeight', 'position', 'leftWidth'};
    for k = 1:numel(layoutProps)
        if isfield(spec.props, layoutProps{k})
            error('labkit:ui:app:RetiredLayoutProperty', ...
                ['Spec "%s" uses app-owned layout property "%s". ' ...
                'Apps may declare pages, sections, controls, order, and ' ...
                'semantic options; LabKit owns concrete layout.'], ...
                spec.id, layoutProps{k});
        end
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
            'UI 3.0 specs must be scalar structs with cell row children.');
    end
end
