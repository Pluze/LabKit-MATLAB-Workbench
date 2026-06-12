function varargout = labkit_TemplateApp_app(varargin)
%LABKIT_TEMPLATEAPP_APP Starter app that demonstrates the current UI 2.0 app shape.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_TemplateApp_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_TemplateApp_app:TooManyOutputs', ...
                'labkit_TemplateApp_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_TemplateApp_app:TooManyOutputs', ...
            'labkit_TemplateApp_app returns at most the app figure handle.');
    end

    fig = starter_app.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
