function varargout = labkit_CIC_app(varargin)
%LABKIT_CIC_APP Launch the CIC voltage-transient app.
% Single-file app that composes +labkit GUI/DTA APIs and owns CIC workflow choices.
% GUI for calculating CIC from Gamry MULTI_STEP_CHRONOPOT .DTA files.
% Layout updated to 3 left-side tabs with vertical file actions.
%
% Main features
%   - Parses Gamry chronopotentiometry DTA files (MULTI_STEP_CHRONOPOT)
%   - Supports loading one or multiple files
%   - Extracts pulse timing from ISTEP/TSTEP metadata when available
%   - Falls back to current-based automatic pulse detection when needed
%   - Calculates voltage-transient metrics used for CIC evaluation:
%         Emc = Vf at (end of cathodic pulse + delay)
%         Ema = Vf at (end of anodic   pulse + delay)
%   - Calculates injected charge from the measured current waveform
%   - Reports per-phase and total charge densities
%   - Highlights selected voltage points and pulse windows on VT / IT plots
%
% Notes
%   - This GUI is for single transient files and batch comparison across files.
%   - True "CIC limit" usually comes from a series of files acquired at different
%     current amplitudes; the GUI therefore marks each file safe/unsafe and also
%     reports the highest safe file among all loaded files.
%   - By default, the evaluation point is 10 us after the end of each phase,
%     matching the convention commonly used in the literature the user shared.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @cic.definition, @cic.requirements, @cic.version, varargin{:});
end
