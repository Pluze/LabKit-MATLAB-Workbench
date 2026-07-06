function varargout = labkit_FigureStudio_app(varargin)
%LABKIT_FIGURESTUDIO_APP Inspect, style, and export MATLAB figures.

    [studioRequest, dispatchArgs] = figure_studio.launchRequest(varargin);
    requirements = figure_studio.requirements();
    appVersion = figure_studio.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_FigureStudio_app', dispatchArgs, nargout, ...
        "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_FigureStudio_app:TooManyOutputs', ...
                'labkit_FigureStudio_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_FigureStudio_app:TooManyOutputs', ...
            'labkit_FigureStudio_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog, "launch", studioRequest);
    fig = labkit.ui.app.run(figure_studio.definition(), request);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
