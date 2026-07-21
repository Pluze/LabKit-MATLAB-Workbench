function closeResource(resource)
%CLOSERESOURCE Dispose a private Figure Studio native figure resource.
if ~isstruct(resource) || ~isfield(resource, "figure")
    return;
end
if isvalid(resource.figure)
    delete(resource.figure);
end
end
