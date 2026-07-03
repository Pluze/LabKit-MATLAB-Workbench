function varargout = labkit_VTResistance_app(varargin)
%LABKIT_VTRESISTANCE_APP Launch the VT resistance app.
% Single-file app that composes +labkit GUI/DTA APIs and owns VT resistance workflow choices.
% GUI for estimating cathodic/anodic steady-state resistance from Gamry
% MULTI_STEP_CHRONOPOT .DTA files.
%
% The pulse detection and current estimation follow the CIC VT GUI pattern:
%   - Use ISTEP/TSTEP metadata first, with optional current-waveform fallback.
%   - Estimate phase current by median(Im) in the selected pulse window.
%   - Estimate steady phase voltage by median(Vf) in the same selected window.
%   - Compute baseline-corrected resistance as abs((Vss - Vbaseline) / Iss).

    requirements = vt_resistance.requirements();
    appVersion = vt_resistance.version();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_VTResistance_app', varargin, nargout, "Requirements", requirements, "Version", appVersion);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_VTResistance_app:TooManyOutputs', ...
                'labkit_VTResistance_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_VTResistance_app:TooManyOutputs', 'labkit_VTResistance_app returns at most the app figure handle.');
    end

    request = struct("debug", debugLog);
    fig = labkit.ui.app.run(vt_resistance.definition(), request);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
