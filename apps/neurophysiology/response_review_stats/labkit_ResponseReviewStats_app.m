function varargout = labkit_ResponseReviewStats_app(varargin)
%LABKIT_RESPONSEREVIEWSTATS_APP Launch the Response Review Stats app.

    requirements = response_review_stats.requirements();
    appVersion = response_review_stats.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.runtime.dispatchRequest( ...
        'labkit_ResponseReviewStats_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ResponseReviewStats_app:TooManyOutputs', ...
                'labkit_ResponseReviewStats_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ResponseReviewStats_app:TooManyOutputs', ...
            'labkit_ResponseReviewStats_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.runtime.run(response_review_stats.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
