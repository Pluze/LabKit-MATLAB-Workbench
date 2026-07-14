% Private UI runtime helper. Expected caller: runV2App. Inputs are a v2
% definition, generated action callbacks, and canonical initial state. Outputs
% are the data-only layout with binding callbacks installed and the binding
% inventory used during presentation commits.
function [layout, bindings] = prepareV2Layout(def, callbacks, state, bindingCallback)
    layout = invokeLayout(def.layout, callbacks, state);
    bindings = emptyBindings();
    [layout, bindings] = visitValue(layout, state, bindingCallback, bindings);
    layout.props.utilities = v2Utilities(def.utilities, layout);
end

function utilities = v2Utilities(overrides, layout)
    utilities = struct( ...
        "Visible", true, ...
        "Plot", containsLayoutKind(layout, "previewArea"), ...
        "Screenshot", true, ...
        "State", "off");
    if isempty(overrides)
        return;
    end
    names = fieldnames(overrides);
    for k = 1:numel(names)
        utilities.(names{k}) = overrides.(names{k});
    end
end

function tf = containsLayoutKind(value, target)
    tf = false;
    if iscell(value)
        for k = 1:numel(value)
            if containsLayoutKind(value{k}, target)
                tf = true;
                return;
            end
        end
        return;
    end
    if ~isstruct(value)
        return;
    end
    for element = 1:numel(value)
        if isfield(value(element), 'kind') && ...
                string(value(element).kind) == target
            tf = true;
            return;
        end
        names = fieldnames(value(element));
        for k = 1:numel(names)
            if containsLayoutKind(value(element).(names{k}), target)
                tf = true;
                return;
            end
        end
    end
end

function layout = invokeLayout(factory, callbacks, state)
    count = nargin(factory);
    if count == 0
        layout = factory();
    elseif count == 1
        layout = factory(callbacks);
    else
        layout = factory(callbacks, state);
    end
end

function [value, bindings] = visitValue(value, state, callback, bindings)
    if iscell(value)
        for k = 1:numel(value)
            [value{k}, bindings] = visitValue(value{k}, state, callback, bindings);
        end
        return;
    end
    if ~isstruct(value)
        return;
    end
    for element = 1:numel(value)
        if isLayoutNode(value(element))
            [value(element), bindings] = bindNode( ...
                value(element), state, callback, bindings);
        end
        fields = fieldnames(value(element));
        for k = 1:numel(fields)
            field = fields{k};
            if strcmp(field, 'props') && isLayoutNode(value(element))
                continue;
            end
            [value(element).(field), bindings] = visitValue( ...
                value(element).(field), state, callback, bindings);
        end
        if isLayoutNode(value(element))
            [value(element).props, bindings] = visitValue( ...
                value(element).props, state, callback, bindings);
        end
    end
end

function tf = isLayoutNode(value)
    tf = isfield(value, 'kind') && isfield(value, 'id') && ...
        isfield(value, 'props') && isfield(value, 'children');
end

function [node, bindings] = bindNode(node, state, callback, bindings)
    [found, path] = propertyValue(node.props, "Bind");
    if ~found
        return;
    end
    path = string(path);
    assertBindingPath(path);
    [hasEvent, eventId] = propertyValue(node.props, "Event");
    if ~hasEvent
        eventId = "";
    end
    current = valueAtPath(state, path);
    node.props.value = current;
    node.props.onChange = @(control, event) callback( ...
        control, event, path, string(eventId));
    binding = struct("id", string(node.id), "path", path, ...
        "eventId", string(eventId));
    bindings(end + 1) = binding;
end

function assertBindingPath(path)
    parts = split(path, ".");
    if ~isscalar(path) || strlength(path) == 0 || numel(parts) < 3 || ...
            ~any(parts(1) == ["project", "session"]) || ...
            any(strlength(parts) == 0)
        error('labkit:ui:runtime:InvalidBinding', ...
            'Bind must name a project or session state path.');
    end
end

function value = valueAtPath(state, path)
    parts = split(path, ".");
    value = state;
    for k = 1:numel(parts)
        field = char(parts(k));
        if ~isstruct(value) || ~isscalar(value) || ~isfield(value, field)
            error('labkit:ui:runtime:InvalidBinding', ...
                'Bind path "%s" does not exist in initial state.', path);
        end
        value = value.(field);
    end
end

function [found, value] = propertyValue(props, name)
    found = false;
    value = [];
    names = string(fieldnames(props));
    index = find(strcmpi(names, name), 1, 'first');
    if ~isempty(index)
        found = true;
        value = props.(char(names(index)));
    end
end

function bindings = emptyBindings()
    bindings = struct("id", {}, "path", {}, "eventId", {});
end
