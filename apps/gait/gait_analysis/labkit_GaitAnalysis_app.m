function varargout = labkit_GaitAnalysis_app(varargin)
%LABKIT_GAITANALYSIS_APP Analyze gait metrics from tracked pose coordinates.

    requirements = gait_analysis.requirements();
    appVersion = gait_analysis.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.runtime.dispatchRequest( ...
        'labkit_GaitAnalysis_app', varargin, nargout, ...
        "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_GaitAnalysis_app:TooManyOutputs', ...
                'labkit_GaitAnalysis_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_GaitAnalysis_app:TooManyOutputs', ...
            'labkit_GaitAnalysis_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.runtime.run(gait_analysis.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
