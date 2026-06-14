function varargout = labkit_ProjectGovernance_app(varargin)
%LABKIT_PROJECTGOVERNANCE_APP Visual entry point for LabKit project governance.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ProjectGovernance_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ProjectGovernance_app:TooManyOutputs', ...
                'labkit_ProjectGovernance_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ProjectGovernance_app:TooManyOutputs', ...
            'labkit_ProjectGovernance_app returns at most the app figure handle.');
    end

    fig = project_governance.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
