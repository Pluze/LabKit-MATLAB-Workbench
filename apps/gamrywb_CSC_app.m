function varargout = gamrywb_CSC_app(varargin)
%GAMRYWB_CSC_APP CV/CSC app entry point.
% The app implementation lives under apps/private and composes +gamrywb GUI
% and DTA APIs while keeping CV/CSC workflow behavior in the app layer.

    [varargout{1:nargout}] = launchCSCApp(varargin{:});
end
