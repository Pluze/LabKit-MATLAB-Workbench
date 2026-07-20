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
    [varargout{1:nargout}] = csc.definition().launch(varargin{:});
end
