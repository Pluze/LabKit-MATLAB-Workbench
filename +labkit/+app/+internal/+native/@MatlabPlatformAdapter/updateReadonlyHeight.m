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
    obj.updateContentHeight(id, height);
end
