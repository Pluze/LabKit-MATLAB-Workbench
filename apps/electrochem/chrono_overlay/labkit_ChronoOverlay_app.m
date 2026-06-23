function varargout = labkit_ChronoOverlay_app(varargin)
%LABKIT_CHRONOOVERLAY_APP Chrono voltage/current overlay and export app.
% Single-file app that composes +labkit GUI/DTA APIs and owns overlay workflow choices.

    requirements = chrono_overlay.requirements();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ChronoOverlay_app', varargin, nargout, "Requirements", requirements);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ChronoOverlay_app:TooManyOutputs', ...
                'labkit_ChronoOverlay_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ChronoOverlay_app:TooManyOutputs', 'labkit_ChronoOverlay_app returns at most the app figure handle.');
    end

    fig = chrono_overlay.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
