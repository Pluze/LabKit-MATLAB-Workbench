function parent = contentParent(obj, id)
% Class-folder implementation of MatlabPlatformAdapter.contentParent.
    key = char(id);
    if isKey(obj.Layouts, key)
        parent = obj.Layouts(key);
    else
        parent = obj.component(id);
    end
end
