function varargout = gamrywb_ChronoOverlay_app(varargin)
%GAMRYWB_CHRONOOVERLAY_APP Package-backed chrono overlay/export app entry point.
% Load multiple Gamry .DTA files, overlay voltage/current curves, and
% export aligned curves to CSV.

    [varargout{1:nargout}] = gamrywb.app.launchChronoOverlayApp(varargin{:});
end
