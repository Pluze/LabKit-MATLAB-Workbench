function varargout = labkit_DICPreprocess_app(varargin)
%LABKIT_DICPREPROCESS_APP Image registration and paired-crop app for DIC workflows.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_DICPreprocess_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_DICPreprocess_app:TooManyOutputs', ...
                'labkit_DICPreprocess_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_DICPreprocess_app:TooManyOutputs', ...
            'labkit_DICPreprocess_app returns at most the app figure handle.');
    end

    fig = runDICPreprocessApp(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
