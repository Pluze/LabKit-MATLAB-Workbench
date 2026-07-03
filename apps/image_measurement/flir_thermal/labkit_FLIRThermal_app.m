function varargout = labkit_FLIRThermal_app(varargin)
%LABKIT_FLIRTHERMAL_APP FLIR radiometric image post-processing app.

    requirements = flir_thermal.requirements();
    appVersion = flir_thermal.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_FLIRThermal_app', varargin, nargout, ...
        "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_FLIRThermal_app:TooManyOutputs', ...
                'labkit_FLIRThermal_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_FLIRThermal_app:TooManyOutputs', ...
            'labkit_FLIRThermal_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.app.run(flir_thermal.definition(), request);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
