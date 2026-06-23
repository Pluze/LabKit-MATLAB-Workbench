function varargout = labkit_BatchImageCrop_app(varargin)
%LABKIT_BATCHIMAGECROP_APP Batch crop microscope images at fixed pixel size.

    requirements = batch_crop.requirements();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_BatchImageCrop_app', varargin, nargout, "Requirements", requirements);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_BatchImageCrop_app:TooManyOutputs', ...
                'labkit_BatchImageCrop_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_BatchImageCrop_app:TooManyOutputs', ...
            'labkit_BatchImageCrop_app returns at most the app figure handle.');
    end

    fig = batch_crop.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
