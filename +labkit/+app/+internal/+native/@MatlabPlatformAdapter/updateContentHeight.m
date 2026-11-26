function updateContentHeight(obj, id, height)
% Propagate a changed preferred height through fixed rows, preserving user resize offsets.
    key = char(id);
    if isfield(obj.ContentHeights, key) && ...
            isequal(obj.ContentHeights.(key),height)
        return
    end
    node = obj.node(id);
    chain = heightChain(obj, node);
    before = cell(1, numel(chain));
    for index = 1:numel(chain)
        before{index} = obj.preferredRowHeight(chain(index));
    end
    % Container preferences depend on their children; unrelated branches keep their measurements.
    if numel(chain) > 1
        obj.ContentHeights = rmfield(obj.ContentHeights,cellstr(string({chain(2:end).Id})));
    end
    obj.ContentHeights.(key) = height;
    for index = 1:numel(chain)
        after = obj.preferredRowHeight(chain(index));
        if ~(isnumeric(before{index}) && isnumeric(after))
            continue
        end
        delta = after - before{index};
        if abs(delta) < 0.5
            continue
        end
        handle = obj.component(chain(index).Id);
        handle = labkit.app.internal.native.NativeAdapterValues.layoutHandle(handle);
        adjustOwningRow(handle, delta);
    end
end

function chain = heightChain(obj, node)
owner = obj.owningNode(node.Id);
if isempty(owner) || owner.Kind == "workbench"
    chain = node;
else
    chain = [node, heightChain(obj, owner)];
end
end

function adjustOwningRow(handle, delta)
if isempty(handle) || ~isvalid(handle) || ...
        ~isprop(handle, "Layout") || ...
        ~isa(handle.Parent, "matlab.ui.container.GridLayout")
    return
end
row = handle.Layout.Row;
if ~isscalar(row) || row < 1 || row > numel(handle.Parent.RowHeight)
    return
end
heights = handle.Parent.RowHeight;
current = heights{row};
if ~(isnumeric(current) && isscalar(current) && isfinite(current))
    return
end
heights{row} = max(1, current + delta);
handle.Parent.RowHeight = heights;
end
