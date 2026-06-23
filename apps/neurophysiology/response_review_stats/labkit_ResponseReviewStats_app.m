function varargout = labkit_ResponseReviewStats_app(varargin)
%LABKIT_RESPONSEREVIEWSTATS_APP Launch the Response Review Stats app.

    requirements = response_review_stats.requirements();
    appVersion = response_review_stats.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
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

    fig = response_review_stats.run(debugLog);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
