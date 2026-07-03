function varargout = labkit_FocusStack_app(varargin)
%LABKIT_FOCUSSTACK_APP Fuse a focus image stack into one all-in-focus image.

    requirements = focus_stack.requirements();
    appVersion = focus_stack.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_FocusStack_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_FocusStack_app:TooManyOutputs', ...
                'labkit_FocusStack_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_FocusStack_app:TooManyOutputs', ...
            'labkit_FocusStack_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.app.run(focus_stack.definition(), request);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
