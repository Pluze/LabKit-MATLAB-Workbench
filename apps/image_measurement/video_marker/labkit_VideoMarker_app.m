function varargout = labkit_VideoMarker_app(varargin)
%LABKIT_VIDEOMARKER_APP Manually mark ordered feature points across video frames.

    requirements = video_marker.requirements();
    appVersion = video_marker.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.runtime.dispatchRequest( ...
        'labkit_VideoMarker_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_VideoMarker_app:TooManyOutputs', ...
                'labkit_VideoMarker_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_VideoMarker_app:TooManyOutputs', ...
            'labkit_VideoMarker_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.runtime.run(video_marker.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
