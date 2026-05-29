function varargout = gamrywb_EIS_app(varargin)
%GAMRYWB_EIS_APP EIS app entry point.
% The app implementation lives under apps/private and composes +gamrywb GUI
% and DTA APIs without adding EIS app logic to the reusable library package.

    [varargout{1:nargout}] = launchEISApp(varargin{:});
end
