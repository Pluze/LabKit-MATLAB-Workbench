% Private UI runtime diagnostic helper. Expected caller: UI control builders. Input
% is a MATLAB UI handle and app callback. Side effects: stores the callback
% function name for debug instrumentation labels when available.
function setOriginalCallbackName(handle, callback)
    if isempty(callback) || ~isa(callback, 'function_handle')
        return;
    end
    try
        setappdata(handle, 'labkit_ui_original_callback_name', func2str(callback));
    catch
    end
end
