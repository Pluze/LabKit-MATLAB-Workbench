function varargout = labkit_NerveResponseAnalysis_app(varargin)
%LABKIT_NERVERESPONSEANALYSIS_APP Launch the Nerve Response Analysis app.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_NerveResponseAnalysis_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_NerveResponseAnalysis_app:TooManyOutputs', ...
                'labkit_NerveResponseAnalysis_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_NerveResponseAnalysis_app:TooManyOutputs', ...
            'labkit_NerveResponseAnalysis_app returns at most the app figure handle.');
    end

    fig = nerve_response_analysis.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
