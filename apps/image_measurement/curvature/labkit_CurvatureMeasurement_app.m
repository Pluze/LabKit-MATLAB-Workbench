function varargout = labkit_CurvatureMeasurement_app(varargin)
%LABKIT_CURVATUREMEASUREMENT_APP Measure curve radius and curvature from images.

    requirements = curvature.requirements();
    appVersion = curvature.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_CurvatureMeasurement_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_CurvatureMeasurement_app:TooManyOutputs', ...
                'labkit_CurvatureMeasurement_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_CurvatureMeasurement_app:TooManyOutputs', ...
            'labkit_CurvatureMeasurement_app returns at most the app figure handle.');
    end

    fig = curvature.run(debugLog);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
