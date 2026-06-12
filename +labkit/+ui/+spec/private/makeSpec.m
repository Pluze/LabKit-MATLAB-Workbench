% Private UI spec helper. Expected caller: labkit.ui.spec constructors.
% Builds the canonical scalar UI spec struct. The struct is data only and
% never creates MATLAB graphics handles.
function spec = makeSpec(kind, id, props, children, slots)
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
    children = specChildren(children);
    slots = normalizeSlots(slots);

    if ~isstruct(props) || ~isscalar(props)
        error('labkit:ui:spec:InvalidProps', ...
            'UI spec props must be a scalar struct.');
    end

    spec = struct( ...
        'kind', char(string(kind)), ...
        'id', id, ...
        'props', props, ...
        'children', {children}, ...
        'slots', slots);
end

function id = normalizeId(id)
    if ~(ischar(id) || (isstring(id) && isscalar(id)))
        error('labkit:ui:spec:InvalidId', ...
            'UI spec id must be a text scalar.');
    end

    id = char(string(id));
    if ~isvarname(id)
        error('labkit:ui:spec:InvalidId', ...
            'UI spec id "%s" must be a valid MATLAB field name.', id);
    end
end

function slots = normalizeSlots(slots)
    if ~isstruct(slots) || ~isscalar(slots)
        error('labkit:ui:spec:InvalidSlots', ...
            'UI spec slots must be a scalar struct.');
    end

    names = fieldnames(slots);
    for k = 1:numel(names)
        value = slots.(names{k});
        if iscell(value)
            slots.(names{k}) = specChildren(value);
        end
    end
end
