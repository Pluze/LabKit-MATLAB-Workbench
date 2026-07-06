% Private UI layout helper. Expected caller: labkit.ui.layout constructors.
% Builds the canonical scalar UI layout struct. The struct is data only and
% never creates MATLAB graphics handles.
function layout = makeLayoutNode(kind, id, props, children, slots)
    if nargin < 3 || isempty(props)
        props = struct();
    end
    if nargin < 4
        children = {};
    end
    if nargin < 5 || isempty(slots)
        slots = struct();
    end

    id = normalizeId(id);
    children = layoutChildren(children);
    slots = normalizeSlots(slots);

    if ~isstruct(props) || ~isscalar(props)
        error('labkit:ui:layout:InvalidProps', ...
            'UI layout props must be a scalar struct.');
    end

    layout = struct( ...
        'kind', char(string(kind)), ...
        'id', id, ...
        'props', props, ...
        'children', {children}, ...
        'slots', slots);
end

function id = normalizeId(id)
    if ~(ischar(id) || (isstring(id) && isscalar(id)))
        error('labkit:ui:layout:InvalidId', ...
            'UI layout id must be a text scalar.');
    end

    id = char(string(id));
    if ~isvarname(id)
        error('labkit:ui:layout:InvalidId', ...
            'UI layout id "%s" must be a valid MATLAB field name.', id);
    end
end

function slots = normalizeSlots(slots)
    if ~isstruct(slots) || ~isscalar(slots)
        error('labkit:ui:layout:InvalidSlots', ...
            'UI layout slots must be a scalar struct.');
    end

    names = fieldnames(slots);
    for k = 1:numel(names)
        value = slots.(names{k});
        if iscell(value)
            slots.(names{k}) = layoutChildren(value);
        end
    end
end
