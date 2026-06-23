function varargout = labkit_ImageMatch_app(varargin)
%LABKIT_IMAGEMATCH_APP Reference image matching app for figure images.

    requirements = image_match.requirements();
    appVersion = image_match.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ImageMatch_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ImageMatch_app:TooManyOutputs', ...
                'labkit_ImageMatch_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ImageMatch_app:TooManyOutputs', ...
            'labkit_ImageMatch_app returns at most the app figure handle.');
    end

    fig = image_match.run(debugLog);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
