function varargout = gamrywb_VTResistance_app(varargin)
%GAMRYWB_VTRESISTANCE_APP Package-backed VT resistance app entry point.
% GUI for estimating cathodic/anodic steady-state resistance from Gamry
% MULTI_STEP_CHRONOPOT .DTA files.

    [varargout{1:nargout}] = gamrywb.app.launchVTResistanceApp(varargin{:});
end
