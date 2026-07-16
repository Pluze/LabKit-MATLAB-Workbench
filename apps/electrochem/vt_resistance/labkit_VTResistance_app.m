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

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @vt_resistance.definition, @vt_resistance.requirements, ...
        @vt_resistance.version, varargin{:});
end
