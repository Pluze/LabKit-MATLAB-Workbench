% Private UI debug helper. Expected caller: labkit.ui.debug.context
% instrumentation. Inputs are a GUI handle callback property and debug lifecycle
% hooks. Output is a wrapped callback preserving the original callback calling
% convention while emitting BEGIN, END, and ERROR trace lines.
function wrapped = callbackWrapperForHandle(handle, propName, callback, traceFcn, startOperationFcn, finishOperationFcn)

    if isa(callback, 'function_handle')
        wrapped = @wrappedFunctionHandle;
    elseif iscell(callback) && ~isempty(callback) && isa(callback{1}, 'function_handle')
        wrapped = @wrappedCellCallback;
    else
        wrapped = [];
    end

    function varargout = wrappedFunctionHandle(varargin)
        label = callbackTraceLabel(handle, propName, callback);
        op = startOperationFcn(label);
        traceFcn(sprintf('BEGIN %s', label));
        try
            if nargout == 0
                callback(varargin{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            else
                [varargout{1:nargout}] = callback(varargin{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            end
        catch ME
            traceFcn(sprintf('ERROR %s: %s %s', label, ME.identifier, ME.message));
            finishOperationFcn(op, "error", ME);
            rethrow(ME);
        end
    end

    function varargout = wrappedCellCallback(varargin)
        callbackFcn = callback{1};
        callbackArgs = callback(2:end);
        label = callbackTraceLabel(handle, propName, callbackFcn);
        op = startOperationFcn(label);
        traceFcn(sprintf('BEGIN %s', label));
        try
            if nargout == 0
                callbackFcn(varargin{:}, callbackArgs{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            else
                [varargout{1:nargout}] = callbackFcn(varargin{:}, callbackArgs{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            end
        catch ME
            traceFcn(sprintf('ERROR %s: %s %s', label, ME.identifier, ME.message));
            finishOperationFcn(op, "error", ME);
            rethrow(ME);
        end
    end
end

function label = callbackTraceLabel(handle, propName, callback)
    label = sprintf('%s %s', char(string(propName)), debugHandleLabel(handle));
    callbackName = originalCallbackName(handle);
    if strlength(callbackName) == 0
        callbackName = callbackNameText(callback);
    end
    if strlength(callbackName) > 0
        label = sprintf('%s -> %s', label, char(callbackName));
    end
end

function txt = originalCallbackName(handle)
    txt = "";
    try
        if isappdata(handle, 'labkit_ui_original_callback_name')
            txt = string(getappdata(handle, 'labkit_ui_original_callback_name'));
        end
    catch
        txt = "";
    end
end

function txt = callbackNameText(callback)
    txt = "";
    if ~isa(callback, 'function_handle')
        return;
    end
    try
        txt = string(func2str(callback));
    catch
        txt = "";
    end
end
