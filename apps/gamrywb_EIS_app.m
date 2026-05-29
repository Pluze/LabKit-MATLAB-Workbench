function varargout = gamrywb_EIS_app(varargin)
%GAMRYWB_EIS_APP Package-backed EIS app entry point.
% Uses +gamrywb parser, data, plotting, and export helpers without delegating to legacy.

    [varargout{1:nargout}] = gamrywb.app.launchEISApp(varargin{:});
end
