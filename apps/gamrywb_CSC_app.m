function varargout = gamrywb_CSC_app(varargin)
%GAMRYWB_CSC_APP Package-backed CV/CSC app entry point.
% Uses +gamrywb parser, data, plotting, and analysis helpers without delegating to legacy.

    [varargout{1:nargout}] = gamrywb.app.launchCSCApp(varargin{:});
end
