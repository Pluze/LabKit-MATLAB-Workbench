% Private UI debug helper. Expected caller: labkit.ui.debug.context and private
% debug callback wrappers. Input is a MATLAB graphics or UI handle. Output is a
% compact label that prefers user-visible properties when available and
% otherwise falls back to the MATLAB class name.
function label = debugHandleLabel(handle)

    label = class(handle);
    for propName = {'Text', 'Title', 'Name', 'Tag'}
        prop = propName{1};
        if isprop(handle, prop)
            try
                value = handle.(prop);
                if ~(isempty(value) || (isstring(value) && strlength(value) == 0))
                    label = sprintf('%s "%s"', class(handle), char(string(value)));
                    return;
                end
            catch
            end
        end
    end
end
