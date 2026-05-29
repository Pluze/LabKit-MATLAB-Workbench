function varargout = gamrywb_VTResistance_app(varargin)
%GAMRYWB_VTRESISTANCE_APP VT resistance app entry point.
% The app implementation lives under apps/private and composes +gamrywb GUI
% and DTA APIs while keeping VT resistance workflow behavior in the app layer.

    [varargout{1:nargout}] = launchVTResistanceApp(varargin{:});
end
