% Private UI layout helper. Expected caller: labkit.ui.layout constructors.
% Normalizes heterogeneous child layout nodes to the required cell row vector shape
% and validates the common scalar layout node contract.
function children = layoutChildren(children)
    if nargin < 1 || isempty(children)
        children = {};
        return;
    end

    if ~iscell(children) || ~isrow(children)
        error('labkit:ui:layout:InvalidChildren', ...
            'UI layout children must be a cell row vector of scalar layout node structs.');
    end

    for k = 1:numel(children)
        child = children{k};
        if ~isstruct(child) || ~isscalar(child) || ...
                ~all(isfield(child, {'kind', 'id', 'props', 'children', 'slots'}))
            error('labkit:ui:layout:InvalidChildren', ...
                'UI layout child %d must be a scalar layout node struct.', k);
        end
    end
end
