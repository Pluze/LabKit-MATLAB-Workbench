function varargout = labkit_ImageEnhance_app(varargin)
%LABKIT_IMAGEENHANCE_APP Image enhancement and color matching app for figures.

    requirements = image_enhance.requirements();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ImageEnhance_app', varargin, nargout, "Requirements", requirements);
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

    fig = image_enhance.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
