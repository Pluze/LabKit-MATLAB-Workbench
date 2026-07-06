function varargout = labkit_NerveResponseAnalysis_app(varargin)
%LABKIT_NERVERESPONSEANALYSIS_APP Launch the Nerve Response Analysis app.

    requirements = nerve_response_analysis.requirements();
    appVersion = nerve_response_analysis.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.runtime.dispatchRequest( ...
        'labkit_NerveResponseAnalysis_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
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

    request = struct("debug", debugLog);
    fig = labkit.ui.runtime.run(nerve_response_analysis.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
