function varargout = labkit_RHSScreen_app(varargin)
%LABKIT_RHSSCREEN_APP Launch the RHS Screen app.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_RHSScreen_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_RHSScreen_app:TooManyOutputs', ...
                'labkit_RHSScreen_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_RHSScreen_app:TooManyOutputs', ...
            'labkit_RHSScreen_app returns at most the app figure handle.');
    end

    fig = rhs_screen.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
