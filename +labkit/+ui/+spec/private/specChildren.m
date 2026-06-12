% Private UI spec helper. Expected caller: labkit.ui.spec constructors.
% Normalizes heterogeneous child specs to the required cell row vector shape
% and validates the common scalar spec struct contract.
function children = specChildren(children)
    if nargin < 1 || isempty(children)
        children = {};
        return;
    end

    if ~iscell(children) || ~isrow(children)
        error('labkit:ui:spec:InvalidChildren', ...
            'UI spec children must be a cell row vector of scalar spec structs.');
    end

    for k = 1:numel(children)
        child = children{k};
        if ~isstruct(child) || ~isscalar(child) || ...
                ~all(isfield(child, {'kind', 'id', 'props', 'children', 'slots'}))
            error('labkit:ui:spec:InvalidChildren', ...
                'UI spec child %d must be a scalar spec struct.', k);
        end
    end
end
