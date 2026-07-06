function varargout = labkit_RHSPreview_app(varargin)
%LABKIT_RHSPREVIEW_APP Launch the RHS Preview app.

    requirements = rhs_preview.requirements();
    appVersion = rhs_preview.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.runtime.dispatchRequest( ...
        'labkit_RHSPreview_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_RHSPreview_app:TooManyOutputs', ...
                'labkit_RHSPreview_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_RHSPreview_app:TooManyOutputs', ...
            'labkit_RHSPreview_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.runtime.run(rhs_preview.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
