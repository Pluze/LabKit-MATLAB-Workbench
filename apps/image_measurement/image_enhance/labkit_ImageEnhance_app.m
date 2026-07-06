function varargout = labkit_ImageEnhance_app(varargin)
%LABKIT_IMAGEENHANCE_APP Image enhancement and color matching app for figures.

    requirements = image_enhance.requirements();
    appVersion = image_enhance.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.runtime.dispatchRequest( ...
        'labkit_ImageEnhance_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ImageEnhance_app:TooManyOutputs', ...
                'labkit_ImageEnhance_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ImageEnhance_app:TooManyOutputs', ...
            'labkit_ImageEnhance_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.runtime.run(image_enhance.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
