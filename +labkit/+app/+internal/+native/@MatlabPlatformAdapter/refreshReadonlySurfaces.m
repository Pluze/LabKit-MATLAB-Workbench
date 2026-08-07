function refreshReadonlySurfaces(obj)
% Class-folder implementation of MatlabPlatformAdapter.refreshReadonlySurfaces.
    if isempty(obj.Components)
        return
    end
    components = values(obj.Components);
    for index = 1:numel(components)
        component = components{index};
        if isempty(component) || ~isvalid(component) || ...
                ~isprop(component, "UserData") || ...
                ~isstruct(component.UserData) || ...
                ~isfield(component.UserData, "Readonly") || ...
                ~component.UserData.Readonly
            continue
        end
        obj.updateReadonlyHeight(component, component.Value);
    end
end
