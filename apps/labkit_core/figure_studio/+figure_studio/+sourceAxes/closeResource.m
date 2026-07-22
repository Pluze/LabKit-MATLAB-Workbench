% Expected caller: Figure Studio source replacement and runtime cleanup.
% Input is a transient source-resource struct. Output is none; side effect is
% deletion of its private figure when it is still valid.
function closeResource(resource)
%CLOSERESOURCE Dispose a private Figure Studio native figure resource.
if ~isstruct(resource) || ~isfield(resource, "figure")
    return;
end
if isvalid(resource.figure)
    delete(resource.figure);
end
end
