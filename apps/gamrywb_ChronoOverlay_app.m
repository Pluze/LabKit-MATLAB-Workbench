function varargout = gamrywb_ChronoOverlay_app(varargin)
%GAMRYWB_CHRONOOVERLAY_APP Chrono overlay/export app entry point.
% The app implementation lives under apps/private and composes +gamrywb GUI
% and DTA APIs while keeping overlay workflow behavior in the app layer.

    [varargout{1:nargout}] = launchChronoOverlayApp(varargin{:});
end
