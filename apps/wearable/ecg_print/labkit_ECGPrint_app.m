function varargout = labkit_ECGPrint_app(varargin)
%LABKIT_ECGPRINT_APP Explore ECG quality, SNR, and printable waveforms.

    requirements = ecg_print.requirements();
    appVersion = ecg_print.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ECGPrint_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ECGPrint_app:TooManyOutputs', ...
                'labkit_ECGPrint_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ECGPrint_app:TooManyOutputs', ...
            'labkit_ECGPrint_app returns at most the app figure handle.');
    end

    fig = ecg_print.run(debugLog);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
