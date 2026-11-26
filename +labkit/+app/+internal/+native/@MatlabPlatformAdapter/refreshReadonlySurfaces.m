function refreshReadonlySurfaces(obj)
    for component = obj.Readouts
        obj.updateReadonlyHeight(component, component.Value);
    end
end
