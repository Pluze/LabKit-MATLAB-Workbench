function varargout = labkit_CSC_app(varargin)
%LABKIT_CSC_APP Launch the CV/CSC app.
% Single-file app that composes +labkit GUI/DTA APIs and owns CV/CSC workflow choices.
%
% Assumptions
%   - CV data is already constrained to the intended water window during acquisition.
%   - No additional window cropping is applied inside the GUI.
%
% Integration rules
%   - Cathodic charge: integrate only the negative current portion.
%   - Anodic  charge: integrate only the positive current portion.
%   - Full charge     : cathodic + anodic.
%
% CT charge
%   Qct = integral(I dt) using recorded time.
%
% CV charge (constant scan rate v)
%   dt = |dV| / v, so Qcv = integral(I * |dV| / v) (not trapz(V, I) directly).
%
% Optional normalization
%   CSC = Q / area (cm^2); both charge and normalized CSC are shown.
%
    requirements = csc.requirements();
    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_CSC_app', varargin, nargout, "Requirements", requirements);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_CSC_app:TooManyOutputs', ...
                'labkit_CSC_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_CSC_app:TooManyOutputs', 'labkit_CSC_app returns at most the app figure handle.');
    end

    % Application state container

    fig = csc.run(debugLog);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end
end
