function varargout = labkit_DICPostprocess_app(varargin)
%LABKIT_DICPOSTPROCESS_APP Ncorr strain summary and overlay export app.

    requirements = dic_postprocess.requirements();
    appVersion = dic_postprocess.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_DICPostprocess_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_DICPostprocess_app:TooManyOutputs', ...
                'labkit_DICPostprocess_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_DICPostprocess_app:TooManyOutputs', ...
            'labkit_DICPostprocess_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.app.run(dic_postprocess.definition(), request);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
