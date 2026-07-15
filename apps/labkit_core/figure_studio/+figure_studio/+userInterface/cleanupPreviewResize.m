% Expected caller: the Runtime V2 resource registry. Input is one Figure
% Studio resize resource. Side effect stops/deletes its timer and listeners.
function cleanupPreviewResize(resource)
    if ~isstruct(resource)
        return;
    end
    if isfield(resource, 'timer') && ~isempty(resource.timer) && ...
            isvalid(resource.timer)
        stop(resource.timer);
        delete(resource.timer);
    end
    if isfield(resource, 'listeners')
        listeners = resource.listeners;
        for k = 1:numel(listeners)
            if ~isempty(listeners{k}) && isvalid(listeners{k})
                delete(listeners{k});
            end
        end
    end
end
