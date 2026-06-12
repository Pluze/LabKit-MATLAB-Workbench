function varargout = labkit_EIS_app(varargin)
%LABKIT_EIS_APP EIS overlay/export app.
% Single-file app that composes +labkit GUI/DTA APIs and owns EIS workflow choices.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_EIS_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_EIS_app:TooManyOutputs', ...
                'labkit_EIS_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_EIS_app:TooManyOutputs', 'labkit_EIS_app returns at most the app figure handle.');
    end

    fig = eis.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
