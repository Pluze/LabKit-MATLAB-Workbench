function varargout = scaffold_App_app(varargin)
%SCAFFOLD_APP_APP Launch the LabKit scaffold app.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'scaffold_App_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('scaffold_App_app:TooManyOutputs', ...
                'scaffold_App_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('scaffold_App_app:TooManyOutputs', ...
            'scaffold_App_app returns at most the app figure handle.');
    end

    fig = scaffold_app.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
