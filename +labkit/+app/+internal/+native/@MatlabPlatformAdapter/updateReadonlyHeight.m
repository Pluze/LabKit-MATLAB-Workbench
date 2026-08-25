function updateReadonlyHeight(obj, component, value)
% Class-folder implementation of MatlabPlatformAdapter.updateReadonlyHeight.
    if isempty(component) || ~isvalid(component) || ...
            ~isstruct(component.UserData) || ...
            ~isfield(component.UserData, "NodeId")
        return
    end
    id = string(component.UserData.NodeId);
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    width = policy.ReadonlyDefaultWidth;
    figureHandle = ancestor(component, "figure");
    if ~isempty(figureHandle) && isvalid(figureHandle) && ...
            figureHandle.Visible == "on" && component.Parent.Position(3) > 0
        width = component.Parent.Position(3);
    end
    inset = policy.ReadonlyInset;
    contentWidth = max(1, width - inset(1) - inset(3));
    height = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
        value, contentWidth, component.FontSize);
    key = char(id);
    node = obj.node(id);
    chain = readonlyChain(obj, node);
    before = cell(1, numel(chain));
    for index = 1:numel(chain)
        before{index} = obj.preferredRowHeight(chain(index));
    end
    if isKey(obj.ReadonlyHeights, key) && ...
            abs(obj.ReadonlyHeights(key) - height) < 0.5
        return
    end
    obj.ReadonlyHeights(key) = height;
    for index = 1:numel(chain)
        after = obj.preferredRowHeight(chain(index));
        if ~(isnumeric(before{index}) && isnumeric(after))
            continue
        end
        delta = after - before{index};
        if abs(delta) < 0.5
            continue
        end
        if index == 1
            handle = component.UserData.LayoutContainer;
        else
            handle = obj.component(chain(index).Id);
            handle = labkit.app.internal.native.NativeAdapterValues.layoutHandle(handle);
        end
        adjustOwningRow(handle, delta);
    end
end

function chain = readonlyChain(obj, node)
owner = obj.owningNode(node.Id);
if isempty(owner) || owner.Kind == "workbench"
    chain = node;
else
    chain = [node, readonlyChain(obj, owner)];
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
